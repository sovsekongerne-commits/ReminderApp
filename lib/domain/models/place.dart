/// Repræsenterer et gemt sted med geokoordinater og geofence-radius.
class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String icon; // Emoji eller ikon-alias (f.eks. '🏠', '💼')
  final double radiusMeters; // Geofence radius i meter, typisk 100-300m
  final int? colorValue; // Valgfri farveaccent
  final DateTime createdAt;

  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.icon,
    this.radiusMeters = 150.0,
    this.colorValue,
    required this.createdAt,
  });

  Place copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? icon,
    double? radiusMeters,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      icon: icon ?? this.icon,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'icon': icon,
      'radiusMeters': radiusMeters,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      icon: json['icon'] as String,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150.0,
      colorValue: json['colorValue'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
