import 'package:flutter/material.dart';

class SavedRoute {
  final String id;
  final String name;
  final int color; // valor ARGB (ej. Colors.red.value)
  final String geojson; // representación GeoJSON del recorrido

  SavedRoute({
    required this.id,
    required this.name,
    required this.color,
    required this.geojson,
  });

  /// Convierte a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'geojson': geojson,
      };

  /// Convierte desde JSON al objeto SavedRoute
  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ruta sin nombre',
      color: (json['color'] is int)
          ? json['color']
          : Colors.blue.value, // color por defecto si no viene
      geojson: json['geojson']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'SavedRoute(id: $id, name: $name, color: $color, geojson: $geojson)';
}
