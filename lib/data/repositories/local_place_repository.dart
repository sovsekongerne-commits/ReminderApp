import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../mock/mock_places.dart';

class LocalPlaceRepository implements PlaceRepository {
  static const String _key = 'saved_places_v1';

  @override
  Future<List<Place>> getPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      // Første gang appen åbnes: Gem standardsteder (Hjem og Arbejde)
      await _saveAll(initialMockPlaces);
      return initialMockPlaces;
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => Place.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return initialMockPlaces;
    }
  }

  @override
  Future<Place?> getPlaceById(String id) async {
    final places = await getPlaces();
    try {
      return places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlace(Place place) async {
    final places = await getPlaces();
    final index = places.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      places[index] = place;
    } else {
      places.add(place);
    }
    await _saveAll(places);
  }

  @override
  Future<void> deletePlace(String id) async {
    final places = await getPlaces();
    places.removeWhere((p) => p.id == id);
    await _saveAll(places);
  }

  Future<void> _saveAll(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(places.map((p) => p.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
