import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_places.dart';
import '../../data/repositories/local_place_repository.dart';
import '../../domain/models/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../../services/geofence_service.dart';
import 'reminder_provider.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return LocalPlaceRepository();
});

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return NativeGeofenceService();
});

final placesProvider = NotifierProvider<PlacesNotifier, List<Place>>(
  PlacesNotifier.new,
);

class PlacesNotifier extends Notifier<List<Place>> {
  late Future<void> _ready;

  @override
  List<Place> build() {
    _ready = _load();
    return initialMockPlaces;
  }

  Future<void> _load() async {
    final places = await ref.read(placeRepositoryProvider).getPlaces();
    state = places;
    await _sync();
  }

  Future<void> _sync() async {
    try {
      await ref
          .read(geofenceServiceProvider)
          .sync(state, ref.read(remindersProvider));
    } catch (_) {}
  }

  /// Tilføjer et nyt sted eller opdaterer et eksisterende (samme id).
  Future<void> savePlace(Place place) async {
    await _ready;
    final exists = state.any((p) => p.id == place.id);
    state = exists
        ? [
            for (final p in state)
              if (p.id == place.id) place else p,
          ]
        : [...state, place];
    await ref.read(placeRepositoryProvider).savePlace(place);
    await _sync();
  }

  /// Sletter stedet. Sedler der kun hører til stedet slettes også;
  /// sedler med flere steder beholdes uden dette sted.
  Future<void> deletePlace(String id) async {
    await _ready;
    state = state.where((p) => p.id != id).toList();
    await ref.read(placeRepositoryProvider).deletePlace(id);
    await ref.read(remindersProvider.notifier).removePlace(id);
    try {
      await ref.read(geofenceServiceProvider).unregisterGeofence(id);
    } catch (_) {}
  }

  Place? getPlaceById(String? id) {
    if (id == null) return null;
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }
}
