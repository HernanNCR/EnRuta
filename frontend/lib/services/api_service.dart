import 'dart:convert'; // Librería para codificar/decodificar JSON. Conectada a todas las peticiones HTTP que envían/reciben datos JSON.
import 'package:http/http.dart' as http; // Paquete para hacer peticiones HTTP. Conectado a la comunicación con el backend.
import '../models/Colectivo.dart'; // Modelo de datos para Colectivo. Conectado a la conversión de JSON a objetos Dart.

class ApiService { // Clase estática para servicios de API. Conectada al backend para operaciones CRUD de colectivos y rutas.
  static const String baseUrl = "http://10.0.2.2:3000/api/ColectivosRutas"; // URL base del backend. Conectada al servidor local para emulador Android.

  // Obtener todos los colectivos
  static Future<List<Colectivo>> getColectivo() async { // Método para obtener lista de colectivos. Conectado al endpoint GET / del backend.
    final response = await http.get(Uri.parse(baseUrl)); // Petición GET a la URL base. Conectada al servidor.
    print("STATUS CODE: ${response.statusCode}"); // Log del código de estado. Conectado al debugging.
    print("BODY: ${response.body}"); // Log del cuerpo de respuesta. Conectado al debugging.
    if (response.statusCode == 200) { // Verificación de éxito. Conectada al manejo de respuestas.
      final List jsonData = json.decode(response.body); // Decodificación JSON. Conectada a la conversión de datos.
      return jsonData.map((item) => Colectivo.fromJson(item)).toList(); // Mapeo a objetos Colectivo. Conectado al modelo.
    } else {
      throw Exception("Error al cargar colectivos"); // Excepción en caso de error. Conectada al manejo de errores en UI.
    }
  }

  // obtener lista de rutas
  static Future<List<String>> getRutas() async { // Método para obtener lista de rutas. Conectado al endpoint GET /rutas.
    final response = await http.get(Uri.parse("$baseUrl/rutas")); // Petición GET a rutas. Conectada al backend.
    if (response.statusCode == 200) { // Verificación de éxito.
      final List jsonData = json.decode(response.body); // Decodificación JSON.
      return jsonData.map<String>((item) => item.toString()).toList(); // Conversión a lista de strings. Conectada a la UI de selección de rutas.
    } else {
      throw Exception("Error al cargar rutas"); // Excepción en error.
    }
  }

  // obtener los colectivos por ruta
  static Future<List<Colectivo>> getColectivosPorRuta(int rute) async { // Método para obtener colectivos por ruta. Conectado al endpoint GET /ruta/:rute.
    final response = await http.get(Uri.parse("$baseUrl/ruta/$rute")); // Petición GET con parámetro de ruta.
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((item) => Colectivo.fromJson(item)).toList(); // Mapeo a Colectivos.
    } else {
      throw Exception("Error al cargar colectivos de la ruta $rute"); // Excepción con detalle.
    }
  }

  // obtener ruta por colectivo
  static Future<List<Map<String, dynamic>>> getRutaPorColectivo( // Método para obtener coordenadas de ruta por colectivo. Conectado al endpoint GET /ruta_coordenadas/:rute.
    int rute,
  ) async {
    final response = await http.get( // Petición GET.
      Uri.parse("$baseUrl/ruta_coordenadas/$rute"),
    );
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      print(jsonData); // Log de datos. Conectado al debugging.
      return List<Map<String, dynamic>>.from(jsonData); // Retorno de mapas dinámicos. Conectado al procesamiento de GeoJSON.
    } else {
      throw Exception("Error al cargar rutas"); // Excepción.
    }
  }

  // Crear un nuevo colectivo
  static Future<Colectivo> createColectivo(Colectivo colectivo) async { // Método para crear colectivo. Conectado al endpoint POST /.
    final response = await http.post( // Petición POST.
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"}, // Headers para JSON. Conectado al envío de datos.
      body: json.encode(colectivo), // Cuerpo con colectivo codificado. Conectado al modelo.
    );

    if (response.statusCode == 201) { // Verificación de creación exitosa.
      return Colectivo.fromJson(json.decode(response.body)); // Retorno del colectivo creado.
    } else {
      throw Exception("Error al crear colectivo"); // Excepción.
    }
  }

  // actualizar tarea
  static Future<Colectivo> updateColectivo( // Método para actualizar colectivo. Conectado al endpoint PUT /:id.
    String id, // ID del colectivo a actualizar. Conectado a la base de datos.
    Colectivo colectivo, // Datos actualizados. Conectado al modelo.
  ) async {
    final response = await http.put( // Petición PUT.
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type ": "application/json"}, // Headers.
      body: json.encode(colectivo), // Cuerpo.
    );
    if (response.statusCode == 200) { // Verificación de éxito.
      return Colectivo.fromJson(json.decode(response.body)); // Retorno actualizado.
    } else {
      throw Exception("error al actualizar colectivo"); // Excepción.
    }
  }

  static Future<void> deleteColectivo(String id) async { // Método para eliminar colectivo. Conectado al endpoint DELETE /:id.
    final response = await http.delete(Uri.parse("$baseUrl/$id")); // Petición DELETE.
    if (response.statusCode != 200) { // Verificación de error.
      throw Exception("error al eliminar colectivo"); // Excepción.
    }
  }

  // actualizar colectivo
  static Future<Colectivo> updateUbicacion( // Método para actualizar ubicación. Conectado al endpoint PUT /:id.
    String id, // ID del colectivo.
    int numero1, // Latitud. Conectado al GPS.
    int numero2, // Longitud. Conectado al GPS.
  ) async {
    final response = await http.put( // Petición PUT.
      Uri.parse("$baseUrl/$id"), // URL con ID.
      headers: {"Content-Type": "application/json"}, // Headers.
      body: json.encode({ // Cuerpo con coordenadas.
        "latitud": numero1, // Campo latitud.
        "longitud": numero2, // Campo longitud.
      }),
    );

    if (response.statusCode == 200) { // Verificación.
      return Colectivo.fromJson(json.decode(response.body)); // Retorno.
    } else {
      throw Exception("Error al actualizar la ubicación"); // Excepción.
    }
  }

  static Future<Colectivo> updatePassenger(String id, int numero1) async { // Método para actualizar pasajeros. Conectado al endpoint PUT /:id.
    final response = await http.put( // Petición PUT.
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"}, // Headers.
      body: json.encode({"lugaresDisponibles": numero1}), // Cuerpo con lugares disponibles. Conectado a la disponibilidad.
    );

    if (response.statusCode == 200) { // Verificación.
      return Colectivo.fromJson(json.decode(response.body)); // Retorno.
    } else {
      throw Exception("Error al actualizar la ubicación"); // Excepción (nota: mensaje incorrecto, debería ser "pasajeros").
    }
  }

  // // eliminar colectivo
  // static Future<void> deleteColectivo(String id) async {
  //   final response = await http.delete(Uri.parse("$baseUrl/$id"));

  //   if (response.statusCode != 200 && response.statusCode != 204) {
  //     throw Exception("Error al eliminar colectivo");
  //   }
  // }

  // mandar informacion de coordenadas al backend
  static Future<void> enviarRutaGeoJson(Map<String, dynamic> geojson) async { // Método para enviar ruta en GeoJSON. Conectado al endpoint POST /guardar-ruta.
    final url = Uri.parse('$baseUrl/guardar-ruta'); // URL del endpoint. Conectada al backend. 
 
    try {
      final response = await http.post( // Petición POST.
        url,
        headers: {'Content-Type': 'application/json'}, // Headers.
        body: jsonEncode({'geojson': geojson}), // Cuerpo con GeoJSON. Conectado al formato de rutas.
      );

      if (response.statusCode == 200) { // Verificación de éxito.
        print('✅ GeoJSON enviado correctamente'); // Log de éxito.
        print('📦 Respuesta del backend: ${response.body}'); // Log de respuesta.
      } else {
        print('❌ Error al enviar GeoJSON: ${response.statusCode}'); // Log de error.
      }
    } catch (e) { // Manejo de excepciones.
      print('⚠️ Error de conexión: $e'); // Log de error de conexión.
    }
  }

  static Future<void> guardarParada( // Método para guardar parada. Conectado al endpoint POST /guardar-parada.
    double lat, // Latitud de la parada. Conectada al mapa.
    double lng, // Longitud de la parada. Conectada al mapa.
    String nombre, // Nombre de la parada. Conectada a la UI.
    List<int> rutas, // Lista de rutas asociadas. Conectada al modelo de rutas.
  ) async {
    final url = Uri.parse('$baseUrl/guardar-parada'); // URL del endpoint.

    try {
      final response = await http.post( // Petición POST.
        url,
        headers: {'Content-Type': 'application/json'}, // Headers.
        body: jsonEncode({ // Cuerpo con datos de parada.
          'lat': lat, // Latitud.
          'lng': lng, // Longitud.
          'nombre': nombre, // Nombre.
          'rutas': rutas, // Rutas.
        }),
      );

      if (response.statusCode == 200) { // Verificación.
        print('✅ Parada guardada correctamente'); // Log.
        print('📦 Respuesta del backend: ${response.body}'); // Log.
      } else {
        print('❌ Error al guardar parada: ${response.statusCode}'); // Log de error.
      }
    } catch (e) { // Manejo de excepciones.
      print('⚠️ Error de conexión: $e'); // Log.
      rethrow; // Relanzar excepción.
    }
  }

  // recibir datos del backend de cordenadas
  // Devuelve los datos tal cual del backend
  static Future<List<Map<String, dynamic>>> getRutasCoordenadas() async { // Método para obtener coordenadas de rutas. Conectado al endpoint GET /rutas_coordenadas.
    final response = await http.get(Uri.parse("$baseUrl/rutas_coordenadas")); // Petición GET.

    if (response.statusCode == 200) { // Verificación.
      final List jsonData = json.decode(response.body); // Decodificación.
      return List<Map<String, dynamic>>.from(jsonData); // Retorno de mapas. Conectado al procesamiento de rutas.
    } else {
      throw Exception("Error al cargar rutas"); // Excepción.
    }
  }
}
