import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location/location.dart';

abstract class AnyLocationService {
  void startTrackingMagneticHeading(Function(double)? completion);
  void startTrackingCurrentLocation(Function(LocationData)? completion);
  void stopTrackingMagneticHeading();
  void stopTrackingCurrentLocation();
}

class LocationService implements AnyLocationService {
  final Location _location = Location();
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  LocationService() {
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    if (permission != PermissionStatus.granted) return;
  }

  @override
  void startTrackingMagneticHeading(Function(double)? completion) {
    _compassSubscription = FlutterCompass.events?.listen((compassEvent) {
      double magneticHeading = (compassEvent.heading ?? 0) % 360;
      if (magneticHeading < 0) magneticHeading += 360;

      completion?.call(magneticHeading);
    });
  }

  @override
  void startTrackingCurrentLocation(Function(LocationData)? completion) async {
    bool serviceEnabled = await _location.serviceEnabled();
    PermissionStatus permissionGranted = await _location.hasPermission();

    if (!serviceEnabled || permissionGranted != PermissionStatus.granted) {
      return;
    }

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      completion?.call(currentLocation);
    });
  }

  @override
  void stopTrackingMagneticHeading() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  @override
  void stopTrackingCurrentLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  String _getCardinalDirection(double heading) {
    if ((heading >= 0 && heading < 22.5) || (heading >= 337.5)) return "North";
    if (heading >= 22.5 && heading < 67.5) return "Northeast";
    if (heading >= 67.5 && heading < 112.5) return "East";
    if (heading >= 112.5 && heading < 157.5) return "Southeast";
    if (heading >= 157.5 && heading < 202.5) return "South";
    if (heading >= 202.5 && heading < 247.5) return "Southwest";
    if (heading >= 247.5 && heading < 292.5) return "West";
    if (heading >= 292.5 && heading < 337.5) return "Northwest";
    return "Unknown";
  }
}
