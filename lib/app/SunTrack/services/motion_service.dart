/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 12:27:48
 */

import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

abstract class AnyMotionService {
  void startTrackingMotion(Function(Map<String, double>)? completion);
  void invalidateMotionTracking();
}

class MotionService implements AnyMotionService {
  bool _isTracking = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void startTrackingMotion(Function(Map<String, double>)? completion) {
    if (_isTracking) return; // Prevent duplicate tracking
    _isTracking = true;

    // Start listening to accelerometer events
    _accelerometerSubscription = accelerometerEvents.listen((accel) {
      double pitch = atan2(-accel.x, sqrt(accel.y * accel.y + accel.z * accel.z)) * (180 / pi);

      var data = {
        'z': accel.z,
        'pitch': pitch,
      };

      completion?.call(data);
    });
  }

  @override
  void invalidateMotionTracking() {
    _isTracking = false;

    // Stop tracking the accelerometer events
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}