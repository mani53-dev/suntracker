import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

abstract class AnyMotionService {
  void startTrackingMotion(Function(Map<String, double>)? completion);
  void invalidateMotionTracking();
  double getPitch();
}

class MotionService implements AnyMotionService {
  bool _isTracking = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _currentPitch = 0.0;

  @override
  void startTrackingMotion(Function(Map<String, double>)? completion) {
    if (_isTracking) return;
    _isTracking = true;

    _accelerometerSubscription = accelerometerEvents.listen((accel) {
      _currentPitch = atan2(-accel.x, sqrt(accel.y * accel.y + accel.z * accel.z)) * (180 / pi);

      var data = {
        'z': accel.z,
        'pitch': _currentPitch,
      };

      completion?.call(data);
    });
  }

  @override
  void invalidateMotionTracking() {
    _isTracking = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  @override
  double getPitch() => _currentPitch;
}
