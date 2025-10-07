import 'package:flutter/material.dart';
import 'package:frontend/models/Colectivo.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD con node',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
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

  final List<Widget> _paginas = [ColectivoPage(), PaginaBoton()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual], // muestra la página actual
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
