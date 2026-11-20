import '../../domain/models/place.dart';

final List<Place> initialMockPlaces = [
  Place(
    id: 'place_home',
    name: 'Hjem',
    latitude: 55.6761,
    longitude: 12.5683,
    icon: '🏠',
    radiusMeters: 100.0,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  Place(
    id: 'place_work',
    name: 'Arbejde',
    latitude: 55.6800,
    longitude: 12.5850,
    icon: '💼',
    radiusMeters: 150.0,
    createdAt: DateTime.now().subtract(const Duration(days: 28)),
  ),
];
