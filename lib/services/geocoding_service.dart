import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Model for et geocodet søgeresultat
class GeocodingResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => '$name ($address) [$latitude, $longitude]';
}

/// Tjeneste til at søge efter adresser og steder (f.eks. OpenStreetMap Nominatim)
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Søg efter adresser eller steder i Danmark
  Future<List<GeocodingResult>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final encodedQuery = Uri.encodeComponent(trimmed);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&countrycodes=dk&addressdetails=1',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'StedOgPaamindelseApp/1.0 (Danish Location Reminder)');
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return _fallbackDanishPlaces(trimmed);
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final List<dynamic> jsonList = jsonDecode(responseBody);

      final results = <GeocodingResult>[];
      for (final item in jsonList) {
        final latStr = item['lat'] as String?;
        final lonStr = item['lon'] as String?;
        if (latStr == null || lonStr == null) continue;

        final lat = double.tryParse(latStr);
        final lon = double.tryParse(lonStr);
        if (lat == null || lon == null) continue;

        final rawName = item['name'] as String? ?? '';
        final displayName = item['display_name'] as String? ?? '';

        // Skab en kort, pæn adressevisning (f.eks. "Nørregade 10, København")
        final shortAddress = _cleanDisplayName(displayName, rawName);
        final title = rawName.isNotEmpty ? rawName : shortAddress.split(',').first.trim();

        results.add(
          GeocodingResult(
            name: title,
            address: shortAddress,
            latitude: lat,
            longitude: lon,
          ),
        );
      }

      if (results.isEmpty) {
        return _fallbackDanishPlaces(trimmed);
      }

      return results;
    } catch (e) {
      debugPrint('Fejl ved geocoding-søgning: $e');
      return _fallbackDanishPlaces(trimmed);
    }
  }

  /// Fjerner redundante dele fra OpenStreetMaps lange display_name
  String _cleanDisplayName(String full, String name) {
    final parts = full.split(',').map((p) => p.trim()).toList();
    if (parts.length <= 3) return full;

    // Bevar typisk de første 2-3 relevante elementer (vej/navn + by/område)
    final filtered = parts.where((p) {
      final lower = p.toLowerCase();
      return !lower.contains('kommune') &&
          !lower.contains('region') &&
          lower != 'danmark';
    }).toList();

    if (filtered.isEmpty) return parts.take(2).join(', ');
    return filtered.take(3).join(', ');
  }

  /// Enkle, velkendte danske steder som backup ved offline eller netværksproblemer
  List<GeocodingResult> _fallbackDanishPlaces(String query) {
    final q = query.toLowerCase();
    const mockDb = [
      GeocodingResult(
        name: 'København Hovedbanegård',
        address: 'Bernstorffsgade 16, 1577 København V',
        latitude: 55.6726,
        longitude: 12.5648,
      ),
      GeocodingResult(
        name: 'Hillerød Station',
        address: 'Nordre Jernbanevej, 3400 Hillerød',
        latitude: 55.9268,
        longitude: 12.3111,
      ),
      GeocodingResult(
        name: 'Slotsarkaderne',
        address: 'Frederikshave, 3400 Hillerød',
        latitude: 55.9295,
        longitude: 12.2988,
      ),
      GeocodingResult(
        name: 'Strøget',
        address: 'Amagertorv, 1160 København K',
        latitude: 55.6787,
        longitude: 12.5786,
      ),
      GeocodingResult(
        name: 'Aarhus Hovedbanegård',
        address: 'Banegårdspladsen 1, 8000 Aarhus C',
        latitude: 56.1504,
        longitude: 10.2045,
      ),
      GeocodingResult(
        name: 'Odense Banegård Center',
        address: 'Østre Stationsvej 27, 5000 Odense C',
        latitude: 55.4013,
        longitude: 10.3876,
      ),
      GeocodingResult(
        name: 'Bilka Hillerød',
        address: 'Slotsarkaderne 1, 3400 Hillerød',
        latitude: 55.9295,
        longitude: 12.2988,
      ),
    ];

    return mockDb.where((p) =>
      p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q)
    ).toList();
  }
}
