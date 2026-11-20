import '../../domain/models/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../mock/mock_places.dart';

class MockPlaceRepository implements PlaceRepository {
  final List<Place> _places = List.from(initialMockPlaces);

  @override
  Future<List<Place>> getPlaces() async {
    return List.unmodifiable(_places);
  }

  @override
  Future<Place?> getPlaceById(String id) async {
    try {
      return _places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlace(Place place) async {
    final index = _places.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      _places[index] = place;
    } else {
      _places.add(place);
    }
  }

  @override
  Future<void> deletePlace(String id) async {
    _places.removeWhere((p) => p.id == id);
  }
}
