import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstrakt snitflade for lokationstjenesten på telefonen.
abstract class LocationService {
  Future<bool> checkPermission();
  Future<bool> requestForegroundPermission();
  Future<bool> requestBackgroundPermission();
  Future<({double latitude, double longitude})?> getCurrentLocation();
}

/// Produktions-klar LocationService med geolocator og permission_handler.
class NativeLocationService implements LocationService {
  static final NativeLocationService _instance =
      NativeLocationService._internal();
  factory NativeLocationService() => _instance;
  NativeLocationService._internal();

  @override
  Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestForegroundPermission() async {
    if (kIsWeb) return true;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    if (kIsWeb) return true;

    // Først forgrunds-tilladelse hvis den ikke findes
    final hasForeground = await requestForegroundPermission();
    if (!hasForeground) return false;

    // Derefter baggrunds-tilladelse (nødvendig for iOS region monitoring og Android Geofencing)
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  @override
  Future<({double latitude, double longitude})?> getCurrentLocation() async {
    try {
      final hasPerm = await requestForegroundPermission();
      if (!hasPerm) {
        // Fallback til København K hvis tilladelse afvises
        return (latitude: 55.6761, longitude: 12.5683);
      }

      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        return (latitude: 55.6761, longitude: 12.5683);
      }

      // Hent hurtig placering med medium præcision for at spare batteri
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
      return (latitude: pos.latitude, longitude: pos.longitude);
    } catch (e) {
      debugPrint('Fejl ved hentning af placering: $e');
      return (latitude: 55.6761, longitude: 12.5683);
    }
  }
}
