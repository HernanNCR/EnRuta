class Colectivo {
  final String id;
  final int numero_economico;
  final String placa;
  final double latitud;
  final double longitud;
  final int lugaresDisponibles;
  final int rute;

  Colectivo({
    required this.id,
    required this.numero_economico,
    required this.placa,
    required this.latitud,
    required this.longitud,
    required this.lugaresDisponibles,
    required this.rute,
  });

  factory Colectivo.fromJson(Map<String, dynamic> json) {
    return Colectivo(
      id: json['_id'] ?? '',
      numero_economico: json['numero_economico'] ?? 0,
      placa: json['placa'] ?? '',
      latitud: _parseDecimal(json['latitud']),
      longitud: _parseDecimal(json['longitud']),
      lugaresDisponibles: json['lugaresDisponibles'] ?? 0,
      rute: json['rute'],
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is Map && value.containsKey(r'$numberDecimal')) {
      return double.tryParse(value[r'$numberDecimal']) ?? 0.0;
    } else if (value is num) {
      return value.toDouble();
    } else {
      return 0.0;
    }
  }
}
