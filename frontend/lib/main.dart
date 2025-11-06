import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/models/saved_route_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:geolocator/geolocator.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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

  MapboxMap? mapboxMap;
  late PolylineAnnotationManager
  polylineAnnotationManager; // Managers de anotaciones
  final List<SavedRoute> _savedRoutes = []; //variable de rutas
  bool _polylineReady = false; //inicializa si dibuar o no en el mapa
  final List<mb.Point> _rutaManual = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMapPage(), // tu mapa principal
    );
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
        // Positioned.fill(
        //   child: GestureDetector(
        //     behavior: HitTestBehavior.translucent,
        //     onTapUp: (details) async {
        //       if (mapboxMap == null) return;
        //       final screenCoord = ScreenCoordinate(
        //         x: details.localPosition.dx,
        //         y: details.localPosition.dy,
        //       );
        //       final point = await mapboxMap!.coordinateForPixel(screenCoord);
        //       setState(() {
        //         _rutaManual.add(point);
        //       });
        //       await _dibujarRutaManual();
        //     },
        //   ),
        // ),

        //Botón flotante para centrar ubicación
        Positioned(
          bottom: 165, // justo arriba de la barra de navegación
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
          bottom: 100, // justo arriba de la barra de navegación
          right: 16,
          child: banderaIcon
              ? FloatingActionButton(
                  onPressed: () {
                    _retirarAlertaRutas(context);
                    _clearRutaManual();
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
                    _mostrarAlertaRutas(context, (ruta) async {
                      setState(() {
                        banderaIcon = true;
                      });

                      final rutasJson = await ApiService.getRutaPorColectivo(
                        int.parse(ruta),
                      );

                      await _loadSavedRoutes(rutasJson);
                      await _mostrarColectivosEnMapa(int.parse(ruta));
                    });
                  },
                  child: const Icon(
                    Icons.directions_bus,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
        ),

        // // Controles de ruta: limpiar y guardar
        // Positioned(
        //   bottom: 300,
        //   right: 16,
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       FloatingActionButton(
        //         heroTag: "btnLimpiarRuta",
        //         backgroundColor: Colors.deepPurple,
        //         onPressed: _clearRutaManual,
        //         child: const Icon(Icons.clear_all, color: Colors.white),
        //       ),
        //       const SizedBox(height: 8),
        //       // Botón Guardar (prepara GeoJSON para backend, no lo envía)
        //       FloatingActionButton(
        //         heroTag: "btnGuardarRuta",
        //         backgroundColor: Colors.deepPurple,
        //         // onPressed: _rutaManual.isNotEmpty ? _onSaveRoutePressed : null,
        //         onPressed: _onSaveRoutePressed,
        //         child: const Icon(Icons.save, color: Colors.white),
        //       ),
        //     ],
        //   ),
        // ),


      ],
    );
  }

  // funcion para mostrar rutas que el usuario quiera seleccionar

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

  late PointAnnotationManager pointAnnotationManager;
  //Configuración del mapa al crearse
  void _onMapCreated(MapboxMap controller) async {
    mapboxMap = controller;

    polylineAnnotationManager = await mapboxMap!.annotations
        .createPolylineAnnotationManager();

    pointAnnotationManager = await mapboxMap!.annotations
        .createPointAnnotationManager();

    _polylineReady = true;

    await mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

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
    await _renderAllRoutes();
  }

  // Renderiza en el mapa todas las rutas guardadas y la ruta en edición
  Future<void> _renderAllRoutes() async {
    if (mapboxMap == null) return;
    if (!_polylineReady) return;

    // Elimina las polilíneas anteriores
    await polylineAnnotationManager.deleteAll();

    // 🔹 Recorremos todas las rutas guardadas
    for (var saved in _savedRoutes) {
      try {
        final decoded = jsonDecode(saved.geojson);

        if (decoded is Map && decoded['type'] == 'LineString') {
          final coords = decoded['coordinates'] as List;

          // Convertir los puntos en posiciones válidas para Mapbox
          final List<mb.Position> positions = coords.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return mb.Position(lon, lat);
          }).toList();

          // Crear una línea solo si hay suficientes puntos
          if (positions.length >= 2) {
            // ✅ Convierte el string de la BD a color Flutter
            final colorValue = _parseColor(saved.color);

            print('🟩 Dibujando ruta ${saved.id} con color ${saved.color}');

            final options = PolylineAnnotationOptions(
              geometry: LineString(coordinates: positions),
              lineColor: colorValue,
              lineWidth: 4.0,
              lineOpacity: 0.95,
            );

            await polylineAnnotationManager.create(options);
          }
        }
      } catch (e) {
        print('❌ Error renderizando ruta guardada ${saved.id}: $e');
      }
    }

    // 🔹 Renderizar ruta manual (si existe)
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
      await pointAnnotationManager.deleteAll();
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

  // Guardar ruta seleccionada (Funciona con el boton de guardar ruta)
  void _onSaveRoutePressed() async {
    final geojsonString = exportRouteGeoJson();
    final geojson = jsonDecode(geojsonString);

    await ApiService.enviarRutaGeoJson(geojson);
  }

  // Funcion para cargar las rutas de la BD (recibe una variable)
  Future<void> _loadSavedRoutes(List<Map<String, dynamic>> rutasJson) async {
    try {
      print(rutasJson);
      _savedRoutes.clear();

      for (var rutaJson in rutasJson) {
        try {
          final ruta = SavedRoute.fromJson(rutaJson);
          _savedRoutes.add(ruta);

          print(
            '✅ Ruta convertida: id=${ruta.id}, color=${ruta.color}, geojson=${ruta.geojson}',
          );
        } catch (e) {
          print('❌ Error parseando ruta: $e, datos originales: $rutaJson');
        }
      }

      await _renderAllRoutes();
      setState(() {});
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
          zoom: 13,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  // cargar imagen de colectivo en el mapa con coordenadas
  Future<void> _mostrarColectivosEnMapa(int ruta) async {
    if (mapboxMap == null) return;

    // 1️⃣ Obtener colectivos desde la API
    List<Colectivo> colectivos = await ApiService.getColectivosPorRuta(ruta);

    // 2️⃣ Limpiar marcadores anteriores
    await pointAnnotationManager.deleteAll();

    // 3️⃣ Registrar imagen del bus
    final ByteData byteData = await rootBundle.load('assets/images/bus.png');
    final Uint8List imageData = byteData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(imageData);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image uiImage = fi.image;
    final mb.MbxImage mbxImage = mb.MbxImage(
      width: uiImage.width,
      height: uiImage.height,
      data: imageData,
    );

    try {
      await mapboxMap!.style.addStyleImage(
        'bus-icon',
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
    } catch (_) {}

    // 4️⃣ Crear marcadores y mapa de ID -> Colectivo
    Map<String, Colectivo> marcadorPorColectivo = {};

    for (var c in colectivos) {
      final annotation = await pointAnnotationManager.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(c.longitud, c.latitud)),
          iconImage: 'bus-icon',
          iconSize: 0.05,
        ),
      );

      marcadorPorColectivo[annotation.id] = c;
    }

    // 5️⃣ Listener para los taps sobre los marcadores
    pointAnnotationManager.addOnPointAnnotationClickListener(
      ColectivoClickListener(context, marcadorPorColectivo),
    );

    print("🚌 Marcadores de colectivos agregados al mapa");
  }
}


// convertir el string de un color a un valor color
int _parseColor(String colorString) {
  if (colorString == null) return Colors.grey.value;

  colorString = colorString.toLowerCase().trim();

  switch (colorString) {
    case 'red':
      return Colors.red.value;
    case 'blue':
      return Colors.blue.value;
    case 'green':
      return Colors.green.value;
    case 'yellow':
      return Colors.yellow.value;
    case 'orange':
      return Colors.orange.value;
    case 'purple':
      return Colors.purple.value;
    case 'pink':
      return Colors.pink.value;
    case 'brown':
      return Colors.brown.value;
    case 'black':
      return Colors.black.value;
    case 'white':
      return Colors.white.value;
    case 'gray':
    case 'grey':
      return Colors.grey.value;

    // Si en la BD guardas códigos hexadecimales (#RRGGBB)
    default:
      try {
        if (colorString.startsWith('#')) {
          colorString = colorString.substring(1);
        }
        if (colorString.length == 6) {
          colorString = 'FF' + colorString; // agrega alpha
        }
        return int.parse('0x$colorString');
      } catch (e) {
        print('⚠️ Color inválido "$colorString", usando gris por defecto.');
        return Colors.grey.value;
      }
  }
}

// clicker bus y mostrar datos del colectivo
class ColectivoClickListener extends mb.OnPointAnnotationClickListener {
  final Map<String, Colectivo> marcadorPorColectivo;
  final BuildContext context;

  ColectivoClickListener(this.context, this.marcadorPorColectivo);

  @override
  void onPointAnnotationClick(mb.PointAnnotation annotation) {
    final colectivo = marcadorPorColectivo[annotation.id];
    if (colectivo != null) {
      print("🚌 Colectivo clickeado: ${colectivo.numero_economico}");
      // Aquí puedes llamar tu función de alerta si quieres
      _mostrarAlertaColectivos(
        context,
        colectivo.numero_economico,
        colectivo.lugaresDisponibles,
      );
    }
  }
}

// alerta del colectivo
void _mostrarAlertaColectivos(
  BuildContext context,
  int idColectivo,
  int lugaresDisponibles,
  // double latitud,
  // double longitud,
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
                      color: lugaresDisponibles > 0 ? Colors.green : Colors.red,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Text("Latitud: $latitud"),
            // Text("Longitud: $longitud"),
          ],
        ),
      );
    },
  );
}

