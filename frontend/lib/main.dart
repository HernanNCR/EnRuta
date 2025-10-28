import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/models/saved_route_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert'; import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb; import 'package:geolocator/geolocator.dart';

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

  // Variables Globales
  bool banderaIcon = false;
  int _paginaActual = 0;
  MapboxMap? mapboxMap;
  late PolylineAnnotationManager polylineAnnotationManager; // Managers de anotaciones
  List<SavedRoute> _savedRoutes = []; //variable de rutas
  bool _polylineReady = false; //inicializa si dibuar o no en el mapa
  final List<mb.Point> _rutaManual = [];
  late final List<Widget> _paginas; //ver mas paginas

  @override
  void initState() {
    super.initState();
    _paginas = [
      _buildMapPage(),
      const PaginaBoton(),
    ];
    _loadSavedRoutes();
  }

  //Página del mapa con botones
  Widget _buildMapPage() {
    // Botones
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

        //Botón flotante para centrar ubicación
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

        // ver rutas de colectivos
        Positioned(
          bottom: 10, // justo arriba de la barra de navegación
          right: 16,
          child: banderaIcon
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
                  backgroundColor: Colors.deepPurple,
                  onPressed: () {
                    _mostrarAlertaRutas(context, (ruta) {
                      setState(() {
                        // rutaSeleccionada = ruta;
                        // ColectivoFuture = ApiService.getColectivosPorRuta(
                        //   int.parse(ruta),
                        // );
                        banderaIcon = true;
                      });
                    });
                  },
                  child: const Icon(
                    Icons.directions_bus,
                    size: 40,
                    color: Colors.white,
                  ),
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
                // onPressed: _rutaManual.isNotEmpty ? _onSaveRoutePressed : null,
                onPressed: _onSaveRoutePressed,
                child: const Icon(Icons.save, color: Colors.white),
              ),
            ],
          ),
        ),

        // Botón para ver rutas guardadas
        // Positioned(
        //   bottom: 300,
        //   left: 16,
        //   child: FloatingActionButton(
        //     heroTag: "btnListRutas",
        //     backgroundColor: Colors.green[700],
        //     onPressed: _showSavedRoutesDialog,
        //     child: const Icon(Icons.list, color: Colors.white),
        //   ),
        // ),
      ],
    );
  }

  // barra de naevgacion(no se utiliza) -> ELIMINAR
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

  // funcion para mostrar rutas que el usuario quiera seleccionar
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

  // traer todas las unidades de la ruta seleccionada
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
  // borrar lista de rutas
  void _retirarAlertaRutas(BuildContext context) async {
    setState(() {
      banderaIcon = false;
      // rutaSeleccionada = null;
      // ColectivoFuture = null;
    });
  }

  //Configuración del mapa al crearse
  void _onMapCreated(MapboxMap controller) async {
    mapboxMap = controller;

    // inicializa manager de polilíneas
    polylineAnnotationManager = await mapboxMap!.annotations
      .createPolylineAnnotationManager();
    _polylineReady = true;

    // activar componente de ubicación
    await mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    // centrar cámara
    await mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: mb.Position(-93.1162, 16.7503)),
        zoom: 12.0,
      ),
    );

    await _centrarUsuario();
    // await _loadSavedRoutes();
  }

  // --- RUTAS MANUALES: dibujar y limpiar ---
  Future<void> _dibujarRutaManual() async {await _renderAllRoutes();}

  // Renderiza en el mapa todas las rutas guardadas y la ruta en edición
  Future<void> _renderAllRoutes() async {
    if (mapboxMap == null) return;
    if (!_polylineReady) return;

    await polylineAnnotationManager.deleteAll();

    for (var saved in _savedRoutes) {
      try {
        final decoded = jsonDecode(saved.geojson);

        if (decoded is Map && decoded['type'] == 'LineString') {
          final coords = decoded['coordinates'] as List;
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
      } catch (e) {
        print('Error renderizando ruta guardada ${saved.id}: $e');
      }
    }

    // Renderizar ruta manual si existe
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

  // limpiar ruta dibujada
  Future<void> _clearRutaManual() async {
    _rutaManual.clear();
    if (mapboxMap != null) {
      await polylineAnnotationManager.deleteAll();
    }
    setState(() {});
  }

  // Exportar la ruta actual a GeoJSON (obtener geojson de la ruta)
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

  // Importar GeoJSON (LineString) a _rutaManual (acomodar geojson)
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

  // Gaurdar ruta seleccionada
  void _onSaveRoutePressed() async {

    final geojsonString = exportRouteGeoJson();
    final geojson = jsonDecode(geojsonString);

    await ApiService.enviarRutaGeoJson(geojson);
  }

  // Funcion buscar rutas en general en la BD
  Future<void> _loadSavedRoutes() async {
    try {
      final rutasJson =
          await ApiService.getRutasCoordenadas(); // List<Map<String, dynamic>>

      print("Datos recibidos del backend:");

      // Limpiamos la lista antes de agregar
      _savedRoutes.clear();

      for (var rutaJson in rutasJson) {
        try {
          final ruta = SavedRoute.fromJson(
            rutaJson,
          ); // ✅ Convertir a SavedRoute
          _savedRoutes.add(ruta);

          // ✅ Ahora imprimimos usando las propiedades correctas
          print(
            '✅ Ruta convertida: id=${ruta.id}, color=${ruta.color}, geojson=${ruta.geojson}',
          );
        } catch (e) {
          // Si algo falla en la conversión, mostrar el error y los datos
          print('❌ Error parseando ruta: $e, datos originales: $rutaJson');
        }
      }

      // print('Total rutas convertidas: ${_savedRoutes.length}');
      await _renderAllRoutes();

      setState(() {}); // Refresca la UI si es necesario
    } catch (e) {
      print('❌ Error cargando rutas desde el servidor: $e');
    }
  }

  // Función para centrar la cámara en la ubicación actual
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


// -----------------------------------------------------------------------
// FUNCIONES ANTES DE IMPLEMENTACION DE MAPBOX
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
