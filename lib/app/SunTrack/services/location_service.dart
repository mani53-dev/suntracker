/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 12:27:40
 */

import 'dart:async';
import 'dart:math';

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

  LocationService() {
    _initializeLocationService();
  }

  void _initializeLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return;
      }
    }
  }

  @override
  void startTrackingMagneticHeading(Function(double)? completion) {
    // Subscribe to the compass events and store the subscription
    _compassSubscription = FlutterCompass.events?.listen((compassEvent) {
      double magneticHeading = compassEvent.heading ?? 0.0;

      // Normalize the heading
      if (magneticHeading < 0) {
        magneticHeading = (magneticHeading + 360) % 360;
      }

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

    _location.onLocationChanged.listen((LocationData currentLocation) {
      completion?.call(currentLocation);
    });
  }

  // Stop tracking the compass events
  void stopTrackingMagneticHeading() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  // Stop tracking the location updates
  void stopTrackingCurrentLocation() {
    _location.onLocationChanged.drain();
  }

  String _getCardinalDirection(double heading) {
    String direction;
    if (heading >= 0 && heading < 22.5 || heading >= 337.5) {
      direction = "North";
    } else if (heading >= 22.5 && heading < 67.5) {
      direction = "Northeast";
    } else if (heading >= 67.5 && heading < 112.5) {
      direction = "East";
    } else if (heading >= 112.5 && heading < 157.5) {
      direction = "Southeast";
    } else if (heading >= 157.5 && heading < 202.5) {
      direction = "South";
    } else if (heading >= 202.5 && heading < 247.5) {
      direction = "Southwest";
    } else if (heading >= 247.5 && heading < 292.5) {
      direction = "West";
    } else {
      direction = "unknown";
    }
    return direction;
  }
}