import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/models/saved_route_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(const MyApp());
}

Future<void> setup() async {
  await dotenv.load(fileName: ".env");
  final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  if (googleApiKey.isEmpty) {
    print('⚠️ GOOGLE_MAPS_API_KEY vacía. Verifica tu archivo .env');
  } else {
    print('✅ GOOGLE_MAPS_API_KEY cargado correctamente');
  }
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
      home: const HomePageGoogle(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePageGoogle extends StatefulWidget {
  const HomePageGoogle({super.key});

  @override
  State<HomePageGoogle> createState() => _HomePageGoogleState();
}

class _HomePageGoogleState extends State<HomePageGoogle> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<SavedRoute> _savedRoutes = [];
  bool banderaIcon = false;
  bool _isDrawingMode = false;
  List<LatLng> _drawnRoute = [];
  Marker? _userLocationMarker;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(16.7503, -93.1162),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: _onMapTapped,
          ),
          // Botón flotante para centrar ubicación
          Positioned(
            bottom: 165,
            right: 16,
            child: FloatingActionButton(
              heroTag: "btnLocation",
              backgroundColor: Colors.deepPurple,
              onPressed: _centrarUsuario,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          // Botón para guardar ruta dibujada
          Positioned(
            bottom: 230,
            right: 16,
            child: FloatingActionButton(
              heroTag: "btnSaveRoute",
              backgroundColor: Colors.green,
              onPressed: _saveDrawnRoute,
              child: const Icon(Icons.save, color: Colors.white),
            ),
          ),
          // Botón para habilitar/deshabilitar modo dibujo
          Positioned(
            bottom: 295,
            right: 16,
            child: FloatingActionButton(
              heroTag: "btnDrawingMode",
              backgroundColor: _isDrawingMode ? Colors.red : Colors.blue,
              onPressed: _toggleDrawingMode,
              child: Icon(
                _isDrawingMode ? Icons.edit_off : Icons.edit,
                color: Colors.white,
              ),
            ),
          ),
          // ver rutas de colectivos
          Positioned(
            bottom: 100,
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
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // El mapa se muestra inicialmente en Tuxtla Gutiérrez
    // El usuario puede presionar el botón para centrar en su ubicación
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
      );

      // Agregar marcador azul para ubicación del usuario
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      );

      setState(() {
        _userLocationMarker = userMarker;
        _markers.removeWhere((m) => m.markerId.value == 'user_location');
        _markers.add(userMarker);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  // Función para manejar toques en el mapa
  void _onMapTapped(LatLng position) {
    if (_isDrawingMode) {
      _addPointToRoute(position);
    }
  }

  // Agregar punto a la ruta dibujada
  void _addPointToRoute(LatLng point) {
    setState(() {
      _drawnRoute.add(point);
      _updateDrawnPolyline();
    });
  }

  // Actualizar la polyline de la ruta dibujada
  void _updateDrawnPolyline() {
    _polylines.removeWhere((p) => p.polylineId.value == 'drawn_route');
    if (_drawnRoute.length >= 2) {
      final polyline = Polyline(
        polylineId: const PolylineId('drawn_route'),
        points: _drawnRoute,
        color: Colors.red,
        width: 4,
      );
      _polylines.add(polyline);
    }
  }

  // Toggle modo dibujo
  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _clearDrawnRoute();
      }
    });
  }

  // Guardar ruta dibujada
  void _saveDrawnRoute() {
    if (_drawnRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ruta dibujada para guardar')),
      );
      return;
    }

    final geojson = exportRouteGeoJson(_drawnRoute);
    ApiService.enviarRutaGeoJson(jsonDecode(geojson));
    _clearDrawnRoute();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ruta guardada exitosamente')));
  }

  // Limpiar ruta dibujada
  void _clearDrawnRoute() {
    setState(() {
      _drawnRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value == 'drawn_route');
    });
  }

  // funcion para mostrar rutas que el usuario quiera seleccionar
  void _mostrarAlertaRutas(
    BuildContext context,
    Function(String) onRutaSeleccionada,
  ) async {
    List<String> rutas = [];
    try {
      rutas = await ApiService.getRutas(); // traer rutas del backend
    } catch (e) {
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
    });
  }

  // limpiar ruta dibujada
  Future<void> _clearRutaManual() async {
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value.startsWith('colectivo_'));
    if (_userLocationMarker != null) {
      _markers.add(_userLocationMarker!);
    }
    setState(() {});
  }

  // Exportar la ruta actual a GeoJSON
  String exportRouteGeoJson(List<LatLng> ruta) {
    final coordinates = ruta.map((p) {
      return [p.longitude, p.latitude];
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

  // Importar GeoJSON (LineString) a una lista de LatLng
  Future<List<LatLng>> importRouteFromGeoJson(String geoJson) async {
    try {
      final decoded = jsonDecode(geoJson);
      List<LatLng> puntos = [];

      if (decoded is Map && decoded['features'] is List) {
        final features = decoded['features'] as List;
        if (features.isNotEmpty) {
          final geometry = features[0]['geometry'];
          if (geometry != null && geometry['type'] == 'LineString') {
            final coords = geometry['coordinates'] as List;
            for (var c in coords) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              puntos.add(LatLng(lat, lon));
            }
          }
        }
      }

      return puntos;
    } catch (e) {
      print('Error importando GeoJSON: $e');
      return [];
    }
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

  // Renderiza en el mapa todas las rutas guardadas
  Future<void> _renderAllRoutes() async {
    _polylines.clear();

    for (var saved in _savedRoutes) {
      try {
        final decoded = jsonDecode(saved.geojson);

        if (decoded is Map && decoded['type'] == 'LineString') {
          final coords = decoded['coordinates'] as List;

          final List<LatLng> points = coords.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          if (points.length >= 2) {
            final color = _parseColor(saved.color);

            final polyline = Polyline(
              polylineId: PolylineId('route_${saved.id}'),
              points: points,
              color: color,
              width: 4,
            );

            _polylines.add(polyline);
          }
        }
      } catch (e) {
        print('❌ Error renderizando ruta guardada ${saved.id}: $e');
      }
    }

    setState(() {});
  }

  // cargar imagen de colectivo en el mapa con coordenadas
  Future<void> _mostrarColectivosEnMapa(int ruta) async {
    // 1️⃣ Obtener colectivos desde la API
    List<Colectivo> colectivos = await ApiService.getColectivosPorRuta(ruta);

    // 2️⃣ Limpiar marcadores de colectivos anteriores, pero mantener user location
    _markers.removeWhere((m) => m.markerId.value.startsWith('colectivo_'));

    // 3️⃣ Agregar marcador de usuario si existe
    if (_userLocationMarker != null) {
      _markers.add(_userLocationMarker!);
    }

    // 4️⃣ Crear marcadores para colectivos
    for (var c in colectivos) {
      final marker = Marker(
        markerId: MarkerId('colectivo_${c.numero_economico}'),
        position: LatLng(c.latitud, c.longitud),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Colectivo ${c.numero_economico}',
          snippet: 'Lugares disponibles: ${c.lugaresDisponibles}',
          onTap: () {
            _mostrarAlertaColectivos(
              context,
              c.numero_economico,
              c.lugaresDisponibles,
            );
          },
        ),
      );

      _markers.add(marker);
    }

    setState(() {});
    print("🚌 Marcadores de colectivos agregados al mapa");
  }

  // alerta del colectivo
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  children: [
                    TextSpan(
                      text: lugaresDisponibles > 0
                          ? "Lugares Disponibles: "
                          : "Lleva Cupo Extra: ",
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
            ],
          ),
        );
      },
    );
  }
}

// convertir el string de un color a un valor color
Color _parseColor(String colorString) {
  colorString = colorString.toLowerCase().trim();

  switch (colorString) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    case 'gray':
    case 'grey':
      return Colors.grey;

    // Si en la BD guardas códigos hexadecimales (#RRGGBB)
    default:
      try {
        if (colorString.startsWith('#')) {
          colorString = colorString.substring(1);
        }
        if (colorString.length == 6) {
          colorString = 'FF$colorString'; // agrega alpha
        }
        return Color(int.parse('0x$colorString'));
      } catch (e) {
        print('⚠️ Color inválido "$colorString", usando gris por defecto.');
        return Colors.grey;
      }
  }
}
