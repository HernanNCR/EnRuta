import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo simple para rutas guardadas
class SavedRoute {
  final String id;
  final String name;
  final int color; // valor ARGB
  final String geojson;

  SavedRoute({
    required this.id,
    required this.name,
    required this.color,
    required this.geojson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'geojson': geojson,
  };

  factory SavedRoute.fromJson(Map<String, dynamic> j) => SavedRoute(
    id: j['id'] as String,
    name: j['name'] as String,
    color: (j['color'] as num).toInt(),
    geojson: j['geojson'] as String,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  await dotenv.load(fileName: ".env");
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  if (token.isEmpty) {
    print('⚠️ MAPBOX_ACCESS_TOKEN vacía. Verifica tu archivo .env');
  } else {
    print('✅ MAPBOX_ACCESS_TOKEN cargado correctamente');
  }

  // Configura token global de Mapbox
  MapboxOptions.setAccessToken(token);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enruta tu Colectivo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paginaActual = 0;
  MapboxMap? mapboxMap;
  // Managers de anotaciones
  late PolylineAnnotationManager polylineAnnotationManager;
  // Rutas guardadas en la app
  final List<SavedRoute> _savedRoutes = [];
  static const String _prefsKey = 'saved_routes_v1';
  bool _polylineReady = false;
  // (Solo usamos PolylineAnnotationManager en esta versión simplificada)

  // Ruta manual (lista de coordenadas tipo mb.Point)
  final List<mb.Point> _rutaManual = [];
  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = [
      _buildMapPage(), // 🗺️ el mapa como primer tab
      const PaginaBoton(),
    ];
    _loadSavedRoutes();
  }

  // Versión simplificada: no marcadores ni deshacer; solo dibujar y limpiar

  /// 🗺️ Página del mapa con botón flotante sobre la barra
  Widget _buildMapPage() {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: mb.Point(coordinates: mb.Position(-93.1162, 16.7503)),
            zoom: 12.0,
          ),
          onMapCreated: _onMapCreated,
        ),
        // Overlay para capturar taps y convertirlos a coordenadas del mapa
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) async {
              if (mapboxMap == null) return;
              final screenCoord = ScreenCoordinate(
                x: details.localPosition.dx,
                y: details.localPosition.dy,
              );
              final point = await mapboxMap!.coordinateForPixel(screenCoord);
              setState(() {
                _rutaManual.add(point);
              });
              await _dibujarRutaManual();
            },
          ),
        ),
        // 📍 Botón flotante para centrar ubicación
        Positioned(
          bottom: 75, // justo arriba de la barra de navegación
          right: 16,
          child: FloatingActionButton(
            heroTag: "btnLocation",
            backgroundColor: Colors.deepPurple,
            onPressed: _centrarUsuario,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
        // 📍 Botón flotante para centrar ubicación
        Positioned(
          bottom: 150, // justo arriba de la barra de navegación
          right: 16,
          child: FloatingActionButton(
            heroTag: "btnRutas",
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ColectivoPage()));
            },
            child: const Icon(Icons.change_circle, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 225, // justo arriba de la barra de navegación
          right: 16,
          child: FloatingActionButton(
            heroTag: "btnEmergencia",
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ColectivoPage()));
            },
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
        ),
        // Controles de ruta: limpiar y guardar
        Positioned(
          bottom: 300,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "btnLimpiarRuta",
                backgroundColor: Colors.deepPurple,
                onPressed: _clearRutaManual,
                child: const Icon(Icons.clear_all, color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Botón Guardar (prepara GeoJSON para backend, no lo envía)
              FloatingActionButton(
                heroTag: "btnGuardarRuta",
                backgroundColor: Colors.deepPurple,
                onPressed: _rutaManual.isNotEmpty ? _onSaveRoutePressed : null,
                child: const Icon(Icons.save, color: Colors.white),
              ),
            ],
          ),
        ),
        // Botón para ver rutas guardadas
        Positioned(
          bottom: 300,
          left: 16,
          child: FloatingActionButton(
            heroTag: "btnListRutas",
            backgroundColor: Colors.green[700],
            onPressed: _showSavedRoutesDialog,
            child: const Icon(Icons.list, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _paginaActual,
        onTap: (index) {
          setState(() {
            _paginaActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: "Rutas"),
          BottomNavigationBarItem(
            icon: Icon(Icons.change_circle),
            label: "Cambios",
          ),
        ],
      ),
    );
  }

  /// 🎯 Configuración del mapa al crearse
  ///
  void _onMapCreated(MapboxMap controller) async {
    mapboxMap = controller;
    // inicializa managers de anotaciones (Polyline y Point)
    mapboxMap!.annotations.createPolylineAnnotationManager().then((mgr) {
      polylineAnnotationManager = mgr;
      _polylineReady = true;
      // una vez creado el manager, renderizamos las rutas guardadas
      _renderAllRoutes();
    });

    // (sin PointAnnotationManager en la versión simplificada)

    // activar componente de ubicación (mostrar puck) — requiere permisos activos
    await mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    // centrar en la ciudad, luego opcionalmente intentar centrar en usuario
    await mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: mb.Position(-93.1162, 16.7503)),
        zoom: 12.0,
      ),
    );
    await _centrarUsuario();
  }

  // --- RUTAS MANUALES: dibujar y limpiar ---
  Future<void> _dibujarRutaManual() async {
    // delegamos en _renderAllRoutes que dibuja todas las rutas (guardadas + actual)
    await _renderAllRoutes();
  }

  // Renderiza en el mapa todas las rutas guardadas y la ruta en edición
  Future<void> _renderAllRoutes() async {
    if (mapboxMap == null) return;
    // espera a que el manager esté inicializado
    if (!_polylineReady) return;

    // eliminar polilíneas actuales y volver a crear desde los datos
    await polylineAnnotationManager.deleteAll();

    // primero renderizar rutas guardadas (cada una con su color)
    for (var saved in _savedRoutes) {
      try {
        final decoded = jsonDecode(saved.geojson);
        if (decoded is Map && decoded['features'] is List) {
          final features = decoded['features'] as List;
          if (features.isNotEmpty) {
            final geometry = features[0]['geometry'];
            if (geometry != null && geometry['type'] == 'LineString') {
              final coords = geometry['coordinates'] as List;
              final positions = coords.map((c) {
                final lon = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                return mb.Position(lon, lat);
              }).toList();

              final options = PolylineAnnotationOptions(
                geometry: LineString(coordinates: positions),
                lineColor: saved.color,
                lineWidth: 4.0,
                lineOpacity: 0.95,
              );

              await polylineAnnotationManager.create(options);
            }
          }
        }
      } catch (e) {
        print('Error renderizando ruta guardada ${saved.id}: $e');
      }
    }

    // luego renderizar la ruta en edición (si tiene al menos 2 puntos)
    if (_rutaManual.length >= 2) {
      final coordinates = _rutaManual.map((p) => p.coordinates).toList();
      final options = PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: Colors.red.value,
        lineWidth: 4.5,
        lineOpacity: 0.9,
      );
      await polylineAnnotationManager.create(options);
    }
    setState(() {});
  }

  Future<void> _clearRutaManual() async {
    _rutaManual.clear();
    if (mapboxMap != null) {
      await polylineAnnotationManager.deleteAll();
    }
    setState(() {});
  }

  // Exportar la ruta actual a GeoJSON (FeatureCollection con una LineString)
  String exportRouteGeoJson() {
    final coordinates = _rutaManual.map((p) {
      final pj = p.toJson();
      // punto GeoJSON: { 'type': 'Point', 'coordinates': [lon, lat] }
      final list = pj['coordinates'] as List;
      final lon = (list[0] as num).toDouble();
      final lat = (list[1] as num).toDouble();
      return [lon, lat];
    }).toList();

    final geojson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
        },
      ],
    };

    return jsonEncode(geojson);
  }

  // Importar GeoJSON (LineString) a _rutaManual
  Future<void> importRouteFromGeoJson(String geoJson) async {
    try {
      final decoded = jsonDecode(geoJson);
      if (decoded is Map && decoded['features'] is List) {
        final features = decoded['features'] as List;
        if (features.isNotEmpty) {
          final geometry = features[0]['geometry'];
          if (geometry != null && geometry['type'] == 'LineString') {
            final coords = geometry['coordinates'] as List;
            setState(() {
              _rutaManual.clear();
              for (var c in coords) {
                final lon = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                _rutaManual.add(mb.Point(coordinates: mb.Position(lon, lat)));
              }
            });
            await _dibujarRutaManual();
          }
        }
      }
    } catch (e) {
      print('Error importando GeoJSON: $e');
    }
  }

  // Preparar payload listo para enviar al backend (no hace la petición)
  Map<String, dynamic> prepareRoutePayload({required String colectivoId}) {
    final geojson = jsonDecode(exportRouteGeoJson());
    return {
      'colectivoId': colectivoId,
      'geojson': geojson,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  // Handler para el botón Guardar: muestra el GeoJSON y permite copiarlo
  void _onSaveRoutePressed() async {
    // Dialogo para pedir nombre y color, luego guardar la ruta en SharedPreferences
    final nameController = TextEditingController();
    Color? selectedColor = Colors.blue;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Guardar ruta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la ruta',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _colorOption(
                    Colors.red,
                    selectedColor,
                    (c) => selectedColor = c,
                  ),
                  _colorOption(
                    Colors.blue,
                    selectedColor,
                    (c) => selectedColor = c,
                  ),
                  _colorOption(
                    Colors.green,
                    selectedColor,
                    (c) => selectedColor = c,
                  ),
                  _colorOption(
                    Colors.orange,
                    selectedColor,
                    (c) => selectedColor = c,
                  ),
                  _colorOption(
                    Colors.purple,
                    selectedColor,
                    (c) => selectedColor = c,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa un nombre para la ruta'),
                    ),
                  );
                  return;
                }
                final geojson = exportRouteGeoJson();
                final saved = SavedRoute(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  color: (selectedColor ?? Colors.blue).value,
                  geojson: geojson,
                );
                _savedRoutes.add(saved);
                await _saveRoutesToPrefs();
                // redraw
                await _renderAllRoutes();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Ruta guardada')));
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _colorOption(
    Color color,
    Color? selected,
    void Function(Color) onTap,
  ) {
    final isSelected = selected?.value == color.value;
    return GestureDetector(
      onTap: () => setState(() => onTap(color)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
      ),
    );
  }

  // Persistencia: cargar y guardar rutas en SharedPreferences
  Future<void> _loadSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _savedRoutes.clear();
      for (var item in decoded) {
        _savedRoutes.add(SavedRoute.fromJson(Map<String, dynamic>.from(item)));
      }
      // si el manager ya está listo, redibujar
      if (_polylineReady) {
        await _renderAllRoutes();
      }
      setState(() {});
    } catch (e) {
      print('Error cargando rutas guardadas: $e');
    }
  }

  Future<void> _saveRoutesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedRoutes.map((s) => s.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (e) {
      print('Error guardando rutas: $e');
    }
  }

  // Mostrar diálogo con la lista de rutas guardadas (cargar/eliminar)
  void _showSavedRoutesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rutas guardadas'),
        content: SizedBox(
          width: double.maxFinite,
          child: _savedRoutes.isEmpty
              ? const Text('No hay rutas guardadas')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedRoutes.length,
                  itemBuilder: (context, index) {
                    final r = _savedRoutes[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Color(r.color)),
                      title: Text(r.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await importRouteFromGeoJson(r.geojson);
                              // centrar cámara en el primer punto
                              try {
                                final decoded = jsonDecode(r.geojson);
                                final coords =
                                    decoded['features'][0]['geometry']['coordinates']
                                        as List;
                                if (coords.isNotEmpty) {
                                  final lon = (coords[0][0] as num).toDouble();
                                  final lat = (coords[0][1] as num).toDouble();
                                  await mapboxMap?.setCamera(
                                    CameraOptions(
                                      center: Point(
                                        coordinates: mb.Position(lon, lat),
                                      ),
                                      zoom: 14.0,
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // confirmar
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Eliminar ruta'),
                                  content: const Text('¿Eliminar esta ruta?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                _savedRoutes.removeAt(index);
                                await _saveRoutesToPrefs();
                                await _renderAllRoutes();
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ruta eliminada'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// 📍 Función para centrar la cámara en la ubicación actual
  Future<void> _centrarUsuario() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa los servicios de ubicación')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso denegado permanentemente')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // mover cámara a la ubicación real
      await mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: mb.Position(pos.longitude, pos.latitude)),
          zoom: 15.5,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }
}

class ColectivoPage extends StatefulWidget {
  const ColectivoPage({super.key});

  @override
  State<ColectivoPage> createState() => _ColectivoPageState();
}

class _ColectivoPageState extends State<ColectivoPage> {
  String? rutaSeleccionada;
  late Future<List<Colectivo>>? ColectivoFuture;

  bool banderaIcon = false;

  @override
  void initState() {
    super.initState();
    ColectivoFuture = ApiService.getColectivo();
  }

  // ignore: unused_element
  void _addColectivo() async {
    final newColectivo = Colectivo(
      id: '',
      numero_economico: 5213,
      placa: "BHY-13",
      latitud: -12345,
      longitud: 54321,
      lugaresDisponibles: 2,
      rute: 58,
    );
    await ApiService.createColectivo(newColectivo);
    setState(() {
      ColectivoFuture = ApiService.getColectivo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Colectivos")),

      body: rutaSeleccionada == null
          ? const Center(child: Text("Seleccione una ruta"))
          : FutureBuilder<List<Colectivo>>(
              future:
                  ColectivoFuture, // este Future se actualiza cuando eliges la ruta
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No hay colectivos en esta ruta"),
                  );
                } else {
                  final colectivos = snapshot.data!;

                  return ListView.builder(
                    itemCount: colectivos.length,
                    itemBuilder: (context, index) {
                      final colectivo = colectivos[index];
                      return ListTile(
                        leading: IconButton(
                          icon: const Icon(Icons.directions_bus),
                          onPressed: () {
                            _mostrarAlertaColectivos(
                              context,
                              colectivo.numero_economico,
                              colectivo.lugaresDisponibles,
                              colectivo.latitud,
                              colectivo.longitud,
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),

      floatingActionButton: banderaIcon
          ? FloatingActionButton(
              onPressed: () {
                _retirarAlertaRutas(context);
              },
              child: const Icon(
                Icons.no_transfer_rounded,
                size: 40,
                color: Color.fromARGB(255, 181, 63, 63),
              ),
            )
          : FloatingActionButton(
              onPressed: () {
                _mostrarAlertaRutas(context, (ruta) {
                  setState(() {
                    rutaSeleccionada = ruta;
                    ColectivoFuture = ApiService.getColectivosPorRuta(
                      int.parse(ruta),
                    );
                    banderaIcon = true;
                  });
                });
              },
              child: const Icon(
                Icons.directions_bus,
                size: 40,
                color: Colors.indigo,
              ),
            ),
    );
  }

  void _mostrarAlertaColectivos(
    BuildContext context,
    int idColectivo,
    int lugaresDisponibles,
    double latitud,
    double longitud,
  ) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$idColectivo"),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // importante para que no ocupe todo el alto
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  children: [
                    TextSpan(
                      text: lugaresDisponibles > 0
                          ? "Lugares Disponibles: "
                          : "LLeva Cupo Extra: ",
                    ),
                    TextSpan(
                      text: "$lugaresDisponibles",
                      style: TextStyle(
                        color: lugaresDisponibles > 0
                            ? Colors.green
                            : Colors.red,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Text("Latitud: $latitud"),
              Text("Longitud: $longitud"),
            ],
          ),
        );
      },
    );
  }

  void _mostrarAlertaRutas(
    BuildContext context,
    Function(String) onRutaSeleccionada,
  ) async {
    List<String> rutas = [];
    try {
      rutas = await ApiService.getRutas(); // traer rutas del backend
    } catch (e) {
      // si hay error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar rutas")));
      return;
    }

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: rutas.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onRutaSeleccionada(rutas[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(rutas[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _retirarAlertaRutas(BuildContext context) async {
    setState(() {
      banderaIcon = false;
      rutaSeleccionada = null;
      ColectivoFuture = null;
    });
  }

  // void _mostrarAlertaRutaSeleccionada(
  //   BuildContext context,
  //   String RutaSeleccionada,
  // ) {
  //   showDialog(
  //     barrierDismissible: true,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(content: Text(RutaSeleccionada));
  //     },
  //   );
  // }
}

class PaginaBoton extends StatefulWidget {
  const PaginaBoton({super.key});

  @override
  _PaginaMenuStateBoton createState() => _PaginaMenuStateBoton();
}

class _PaginaMenuStateBoton extends State<PaginaBoton> {
  String? rutaSeleccionada;
  late Future<List<Colectivo>>? ColectivoFuture;

  bool banderaIcon = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ColectivoFuture = ApiService.getColectivo();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // aquí recorres todos los colectivos
          ColectivoFuture?.then((colectivos) {
            for (var colectivo in colectivos) {
              _cambiarUbicacion(context, colectivo.id);
              _cambiarPasajeros(context, colectivo.id);
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔥 evitar fugas de memoria
    super.dispose();
  }

  // Cada 3 segundos ejecutar para todos los colectivos visibles

  // ignore: unused_element
  void _addColectivo() async {
    final newColectivo = Colectivo(
      id: '',
      numero_economico: 5213,
      placa: "BHY-13",
      latitud: -12345,
      longitud: 54321,
      lugaresDisponibles: 2,
      rute: 58,
    );
    await ApiService.createColectivo(newColectivo);
    setState(() {
      ColectivoFuture = ApiService.getColectivo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar Colectivos")),

      body: rutaSeleccionada == null
          ? const Center(child: Text("Seleccione una ruta"))
          : FutureBuilder<List<Colectivo>>(
              future:
                  ColectivoFuture, // este Future se actualiza cuando eliges la ruta
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No hay colectivos en esta ruta"),
                  );
                } else {
                  final colectivos = snapshot.data!;

                  return ListView.builder(
                    itemCount: colectivos.length,
                    itemBuilder: (context, index) {
                      final colectivo = colectivos[index];
                      return ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.directions),
                              onPressed: () {
                                _mostrarAlertaColectivos(
                                  context,
                                  colectivo.numero_economico,
                                  colectivo.lugaresDisponibles,
                                );
                              },
                            ),
                            Text("${colectivo.numero_economico}"),

                            // TextButton(
                            //   onPressed: () {
                            //     // print("Cambio ${colectivo.id}");
                            //     _cambiarUbicacion(context, colectivo.id);
                            //     _cambiarPasajeros(context, colectivo.id);
                            //   },
                            //   child: const Text("Cambiar"),
                            // ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),

      floatingActionButton: banderaIcon
          ? FloatingActionButton(
              onPressed: () {
                _retirarAlertaRutas(context);
              },
              child: const Icon(
                Icons.no_transfer_rounded,
                size: 40,
                color: Color.fromARGB(255, 181, 63, 63),
              ),
            )
          : FloatingActionButton(
              onPressed: () {
                _mostrarAlertaRutas(context, (ruta) {
                  setState(() {
                    rutaSeleccionada = ruta;
                    ColectivoFuture = ApiService.getColectivosPorRuta(
                      int.parse(ruta),
                    );
                    banderaIcon = true;
                  });
                });
              },
              child: const Icon(
                Icons.directions_bus,
                size: 40,
                color: Colors.indigo,
              ),
            ),
    );
  }

  void _cambiarUbicacion(BuildContext context, String id) async {
    var random = Random();
    int numero1 = random.nextInt(1000);
    int numero2 = random.nextInt(1000);

    print("cambio $id");
    print("numero 1: $numero1 numero 2: $numero2");

    try {
      final actualizado = await ApiService.updateUbicacion(
        id,
        numero1,
        numero2,
      );
      print("Colectivo actualizado: ${actualizado.numero_economico}");
      setState(() {
        // Aquí puedes actualizar tu Future o lista de colectivos para refrescar la UI
        ColectivoFuture = ApiService.getColectivosPorRuta(
          int.parse(rutaSeleccionada!),
        );
      });
    } catch (e) {
      print("Error al actualizar: $e");
    }
  }

  void _cambiarPasajeros(BuildContext context, String id) async {
    var random = Random();
    int numero1 = random.nextInt(16);

    print("cambio $id");
    print("numero 1: $numero1");

    try {
      final actualizado = await ApiService.updatePassenger(id, numero1);
      print("pasajeros actualizados: ${actualizado.lugaresDisponibles}");
      setState(() {
        // Aquí puedes actualizar tu Future o lista de colectivos para refrescar la UI
        ColectivoFuture = ApiService.getColectivosPorRuta(
          int.parse(rutaSeleccionada!),
        );
      });
    } catch (e) {
      print("Error al actualizar: $e");
    }
  }

  void _mostrarAlertaColectivos(
    BuildContext context,
    int idColectivo,
    int lugaresDisponibles,
  ) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$idColectivo"),
          content: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.black),
              children: [
                TextSpan(
                  text: lugaresDisponibles > 0
                      ? "Lugares Disponibles: "
                      : "LLeva Cupo Extra: ",
                ),
                TextSpan(
                  text: "$lugaresDisponibles",
                  style: TextStyle(
                    color: lugaresDisponibles > 0 ? Colors.green : Colors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarAlertaRutas(
    BuildContext context,
    Function(String) onRutaSeleccionada,
  ) async {
    List<String> rutas = [];
    try {
      rutas = await ApiService.getRutas(); // traer rutas del backend
    } catch (e) {
      // si hay error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar rutas")));
      return;
    }

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: rutas.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onRutaSeleccionada(rutas[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(rutas[index]),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _retirarAlertaRutas(BuildContext context) async {
    setState(() {
      banderaIcon = false;
      rutaSeleccionada = null;
      ColectivoFuture = null;
    });
  }
}
