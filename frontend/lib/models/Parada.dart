class Parada {
  final String id;
  final String nombre;
  final double latitud;
  final double longitud;
   final List<int> rute;

  Parada({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.rute,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      latitud: _parseDecimal(json['ubicacion']['lat']),
      longitud: _parseDecimal(json['ubicacion']['lng']),
      rute: List<int>.from(json['rutas'] ?? []),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is Map && value.containsKey(r'$numberDecimal')) {
      return double.tryParse(value[r'$numberDecimal']) ?? 0.0;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}
