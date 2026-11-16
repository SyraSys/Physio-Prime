import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final locationAutofillServiceProvider = Provider<LocationAutofillService>((ref) {
  return const LocationAutofillService();
});

enum LocationFailure { serviceDisabled, permissionDenied, permissionDeniedForever, timeout, noAddressFound, unknown }

class LocationAutofillException implements Exception {
  final LocationFailure reason;
  const LocationAutofillException(this.reason);

  String get message {
    switch (reason) {
      case LocationFailure.serviceDisabled:
        return 'Location services are turned off. Enable them in Settings to use GPS auto-fill.';
      case LocationFailure.permissionDenied:
        return 'Location permission was denied. You can enter your address manually.';
      case LocationFailure.permissionDeniedForever:
        return 'Location access is blocked for PhysioPrime. Allow it in Settings to use GPS auto-fill.';
      case LocationFailure.timeout:
        return 'Could not get a GPS fix in time. Move to an open area or enter the address manually.';
      case LocationFailure.noAddressFound:
        return 'We could not find an address for your location. Please enter it manually.';
      case LocationFailure.unknown:
        return 'Unable to read your location right now. Please enter your address manually.';
    }
  }

  bool get canOpenSettings =>
      reason == LocationFailure.permissionDeniedForever || reason == LocationFailure.serviceDisabled;
}

/// Address components resolved from the device's GPS + platform geocoder.
/// Fields are null when the geocoder did not supply them – nothing is invented.
class ResolvedAddress {
  final String? street;
  final String? area;
  final String? city;
  final String? postalCode;
  final double latitude;
  final double longitude;

  const ResolvedAddress({
    required this.latitude,
    required this.longitude,
    this.street,
    this.area,
    this.city,
    this.postalCode,
  });
}

/// GPS auto-fill using Geolocator for position and the platform geocoder
/// (CLGeocoder on iOS, Geocoder on Android) via `geocoding` for addresses.
class LocationAutofillService {
  const LocationAutofillService();

  Future<ResolvedAddress> resolveCurrentAddress() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAutofillException(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAutofillException(LocationFailure.permissionDeniedForever);
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      throw const LocationAutofillException(LocationFailure.permissionDenied);
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
    } on TimeoutException {
      throw const LocationAutofillException(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      throw const LocationAutofillException(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      throw const LocationAutofillException(LocationFailure.permissionDenied);
    } catch (_) {
      throw const LocationAutofillException(LocationFailure.unknown);
    }

    List<Placemark> placemarks;
    try {
      placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationAutofillException(LocationFailure.noAddressFound);
    }
    if (placemarks.isEmpty) {
      throw const LocationAutofillException(LocationFailure.noAddressFound);
    }

    final p = placemarks.first;
    String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

    final streetParts = <String>[];
    for (final part in [clean(p.subThoroughfare), clean(p.thoroughfare)]) {
      if (part != null && !streetParts.contains(part)) streetParts.add(part);
    }
    final name = clean(p.name);
    if (streetParts.isEmpty && name != null && name != clean(p.subLocality)) {
      streetParts.add(name);
    }

    final resolved = ResolvedAddress(
      latitude: position.latitude,
      longitude: position.longitude,
      street: streetParts.isEmpty ? null : streetParts.join(' '),
      area: clean(p.subLocality),
      city: clean(p.locality) ?? clean(p.subAdministrativeArea),
      postalCode: clean(p.postalCode),
    );

    if (resolved.street == null && resolved.area == null && resolved.city == null) {
      throw const LocationAutofillException(LocationFailure.noAddressFound);
    }
    return resolved;
  }

  Future<bool> openSettings(LocationFailure reason) {
    return reason == LocationFailure.serviceDisabled ? Geolocator.openLocationSettings() : Geolocator.openAppSettings();
  }
}
