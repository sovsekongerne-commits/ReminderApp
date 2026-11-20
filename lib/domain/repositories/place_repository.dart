import '../models/place.dart';

/// Abstrakt snitflade for håndtering af gemte steder.
abstract class PlaceRepository {
  Future<List<Place>> getPlaces();
  Future<Place?> getPlaceById(String id);
  Future<void> savePlace(Place place);
  Future<void> deletePlace(String id);
}
