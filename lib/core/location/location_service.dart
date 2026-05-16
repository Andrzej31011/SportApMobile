import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailureType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationResult {
  const LocationResult._({
    this.latitude,
    this.longitude,
    this.message,
    this.failureType,
  });

  const LocationResult.success({
    required double latitude,
    required double longitude,
  }) : this._(latitude: latitude, longitude: longitude);

  const LocationResult.failure({
    required String message,
    required LocationFailureType failureType,
  }) : this._(message: message, failureType: failureType);

  final double? latitude;
  final double? longitude;
  final String? message;
  final LocationFailureType? failureType;

  bool get isSuccess => latitude != null && longitude != null;

  bool get canOpenLocationSettings =>
      failureType == LocationFailureType.servicesDisabled;

  bool get canOpenAppSettings =>
      failureType == LocationFailureType.permissionDeniedForever;
}

class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation({
    bool requestPermission = true,
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return const LocationResult.failure(
        message: 'Wlacz lokalizacje w ustawieniach telefonu.',
        failureType: LocationFailureType.servicesDisabled,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult.failure(
        message: 'Aplikacja nie ma zgody na uzycie lokalizacji.',
        failureType: LocationFailureType.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        message:
            'Aplikacja nie ma zgody na uzycie lokalizacji. Zmien to w ustawieniach aplikacji.',
        failureType: LocationFailureType.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      ).timeout(timeout);

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      return const LocationResult.failure(
        message: 'Nie udalo sie pobrac lokalizacji.',
        failureType: LocationFailureType.timeout,
      );
    } catch (_) {
      return const LocationResult.failure(
        message: 'Nie udalo sie pobrac lokalizacji.',
        failureType: LocationFailureType.unknown,
      );
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
