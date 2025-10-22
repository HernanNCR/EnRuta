import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'dart:async';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:geolocator/geolocator.dart';

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
  // late PolylineAnnotationManager _lineManager;
  late final List<Widget> _paginas;

  //final List<mb.Point> _rutaManual = [];

  @override
  void initState() {
    super.initState();
    _paginas = [
      _buildMapPage(), // 🗺️ el mapa como primer tab
      const PaginaBoton(),
    ];
  }

  /*Future<void> _dibujarRutaManual() async {
    if (mapboxMap == null || _rutaManual.length < 2) return;
    await _lineManager!.deleteAll();

    // Crear el GeoJSON manualmente
    final lineOptions = PolylineAnnotationOptions(
      geometry: _rutaManual,
      lineColor: Colors.red.value,
      lineWidth: 4.5,
      lineOpacity: 0.8,
    );
    _lineManager!.create(lineOptions);
  }*/

  /* void _limpiarRuta() {
    _rutaManual.clear();
    //_lineManager?.deleteAll();
    setState(() {});
  }*/

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
          /*onTapListener: OnTapListener(
            callback: (screenCoord) async {
              if (mapboxMap == null) return;
              final point = await mapboxMap!.coordinateForPixel(screenCoord);
              if (point != null) {
                setState(() {
                  _rutaManual.add(point.coordinates);
                });
                _dibujarRutaManual();
              }
            },
          ),*/
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
            onPressed: _ColectivoPageState()._addColectivo,
            child: const Icon(Icons.change_circle, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 225, // justo arriba de la barra de navegación
          right: 16,
          child: FloatingActionButton(
            heroTag: "btnEmergencia",
            backgroundColor: Colors.deepPurple,
            onPressed: _ColectivoPageState()._addColectivo,
            child: const Icon(Icons.emergency, color: Colors.white),
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
  void _onMapCreated(MapboxMap controller) async {
    mapboxMap = controller;
    // 🔹 Opcional: centrar inmediatamente en Tuxtla
    await mapboxMap?.setCamera(
      CameraOptions(
        center: mb.Point(coordinates: mb.Position(-93.1162, 16.7503)),
        zoom: 12.0,
      ),
    );
    await _centrarUsuario();
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
      await mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: mb.Position(-93.1162, 16.7503)),
          zoom: 14.5,
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
