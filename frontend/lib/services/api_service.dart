import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Colectivo.dart';
import '../models/saved_route_model.dart';


class ApiService {
  static const String baseUrl =
      "http://10.0.2.2:3000/api/ColectivosRutas"; // Para emulador Android

  // Obtener todos los colectivos
  static Future<List<Colectivo>> getColectivo() async {
    final response = await http.get(Uri.parse(baseUrl));
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((item) => Colectivo.fromJson(item)).toList();
    } else {
      throw Exception("Error al cargar colectivos");
    }
  }

  // obtener lista de rutas
  static Future<List<String>> getRutas() async {
    final response = await http.get(Uri.parse("$baseUrl/rutas"));
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map<String>((item) => item.toString()).toList();
    } else {
      throw Exception("Error al cargar rutas");
    }
  }

  // obtener los colectivos por ruta
  static Future<List<Colectivo>> getColectivosPorRuta(int rute) async {
    final response = await http.get(Uri.parse("$baseUrl/ruta/$rute"));
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((item) => Colectivo.fromJson(item)).toList();
    } else {
      throw Exception("Error al cargar colectivos de la ruta $rute");
    }
  }

  // Crear un nuevo colectivo
  static Future<Colectivo> createColectivo(Colectivo colectivo) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(colectivo),
    );

    if (response.statusCode == 201) {
      return Colectivo.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al crear colectivo");
    }
  }

  // actualizar tarea
  static Future<Colectivo> updateColectivo(
    String id,
    Colectivo colectivo,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type ": "application/json"},
      body: json.encode(colectivo),
    );
    if (response.statusCode == 200) {
      return Colectivo.fromJson(json.decode(response.body));
    } else {
      throw Exception("error al actualizar colectivo");
    }
  }

  static Future<void> deleteColectivo(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200) {
      throw Exception("error al eliminar colectivo");
    }
  }

  // actualizar colectivo
  static Future<Colectivo> updateUbicacion(
    String id,
    int numero1,
    int numero2,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"), // Asegúrate que el backend tenga PUT /:id
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "latitud": numero1, // o el campo que corresponda
        "longitud": numero2,
      }),
    );

    if (response.statusCode == 200) {
      return Colectivo.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al actualizar la ubicación");
    }
  }

  static Future<Colectivo> updatePassenger(
    String id,
    int numero1,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"), // Asegúrate que el backend tenga PUT /:id
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "lugaresDisponibles": numero1,
      }),
    );

    if (response.statusCode == 200) {
      return Colectivo.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al actualizar la ubicación");
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
  static Future<void> enviarRutaGeoJson(Map<String, dynamic> geojson) async {
    final url = Uri.parse('$baseUrl/guardar-ruta');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'geojson': geojson}),
      );

      if (response.statusCode == 200) {
        print('✅ GeoJSON enviado correctamente');
        print('📦 Respuesta del backend: ${response.body}');
      } else {
        print('❌ Error al enviar GeoJSON: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error de conexión: $e');
    }
  }

  // recibir datos del backend de cordenadas 
  // Devuelve los datos tal cual del backend
static Future<List<Map<String, dynamic>>> getRutasCoordenadas() async {
  final response = await http.get(Uri.parse("$baseUrl/rutas_coordenadas"));

  if (response.statusCode == 200) {
    final List jsonData = json.decode(response.body);
    return List<Map<String, dynamic>>.from(jsonData);
  } else {
    throw Exception("Error al cargar rutas");
  }
}


  
}


