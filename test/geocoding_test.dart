import 'package:flutter_test/flutter_test.dart';
import 'package:location_reminder/services/geocoding_service.dart';

void main() {
  group('GeocodingService tests', () {
    test('searchPlaces returns fallback results when offline or query matches', () async {
      final service = GeocodingService();
      final results = await service.searchPlaces('Hillerød');
      expect(results.isNotEmpty, true);
      expect(results.any((r) => r.name.contains('Hillerød') || r.address.contains('Hillerød')), true);
    });

    test('searchPlaces returns empty list for very short queries', () async {
      final service = GeocodingService();
      final results = await service.searchPlaces('a');
      expect(results.isEmpty, true);
    });
  });
}
