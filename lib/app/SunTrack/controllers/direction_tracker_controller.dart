import 'dart:math';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/direction_tracking_service.dart';
import '../services/motion_service.dart';
import '../services/location_service.dart';

class DirectionTrackerController extends GetxController {
  final AnyMotionService motionService;
  final AnyLocationService locationService;
  final AnyDirectionTrackingService directionTrackingService;

  DirectionTrackerController({
    required this.motionService,
    required this.locationService,
    required this.directionTrackingService,
  });

  static const double minRadius = 70.0;
  static const double maxRadius = 180.0;
  static const double azimuthThreshold = 5.0; // Require closer alignment
  static const double altitudeThreshold = 5.0; // Require closer vertical alignment
  static const double minPitchForSky = 15.0; // Prevents horizon captures

  var targetAzimuth = 0.0.obs;
  var targetElevation = 0.0.obs;
  var heading = 0.0.obs;
  var arrowDirection = 0.0.obs;
  var circleRadius = minRadius.obs;
  var isCameraInitialized = false.obs;
  var isPhotoCaptured = false.obs;
  var capturedImagePath = "".obs;
  late CameraController cameraController;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    startTrackingMotion();
    startTrackingSun();
  }

  /// **Initialize Camera**
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No cameras available");

      cameraController = CameraController(cameras.first, ResolutionPreset.high);
      await cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar("Camera Error", e.toString());
      isCameraInitialized.value = false;
    }
  }

  /// **Track Motion & Adjust Arrow**
  void startTrackingMotion() {
    motionService.startTrackingMotion((_) {
      if (isPhotoCaptured.value) return;

      // Continuously update heading and arrow direction
      arrowDirection.value = smoothRotation(
        arrowDirection.value,
        calculateArrowDirection(heading.value, targetAzimuth.value),
        0.2, // Smooth transition
      );

      updateCircleRadius(); // Ensure real-time radius changes
      checkAndCapturePhoto();
    });

    locationService.startTrackingMagneticHeading((magneticHeading) {
      heading.value = normalizeAngle(magneticHeading);
    });

    ever(heading, (_) => updateCircleRadius()); // Ensure radius updates with heading changes
  }

  /// **Track Sun Position**
  void startTrackingSun() {
    locationService.startTrackingCurrentLocation((location) {
      if (isPhotoCaptured.value) return;

      final now = DateTime.now();

      // Get sun position
      final sunPosition = SunCalc.getSunPosition(
        now,
        location.latitude as num,
        location.longitude as num,
      );

      // Azimuth: Convert from radians to degrees and normalize to 0-360
      double sunAzimuth = normalizeAngle(sunPosition["azimuth"]! * 180 / pi);

      // Altitude: Convert from radians to degrees
      double sunAltitude = sunPosition["altitude"]! * 180 / pi;

      // Update target azimuth and elevation if they change significantly
      if ((targetAzimuth.value - sunAzimuth).abs() > 0.1 ||
          (targetElevation.value - sunAltitude).abs() > 0.1) {
        targetAzimuth.value = sunAzimuth;
        targetElevation.value = sunAltitude;

        updateCircleRadius();
        checkAndCapturePhoto(); // Ensure photo capture logic runs immediately
      }
    });
  }

  /// **Dynamically Adjust Sun Circle Radius**
  void updateCircleRadius() {
    double elevationFactor = (targetElevation.value + 90) / 180;
    double azimuthDifference = calculateArrowDirection(heading.value, targetAzimuth.value).abs();
    double alignmentFactor = (1 - azimuthDifference / 90).clamp(0.0, 1.0);

    double adjustedRadius = minRadius + (alignmentFactor * (maxRadius - minRadius) * elevationFactor);
    circleRadius.value = adjustedRadius.clamp(minRadius, maxRadius);
  }

  /// **Calculate Arrow Direction**
  double calculateArrowDirection(double currentHeading, double targetAzimuth) {
    double delta = normalizeAngle(targetAzimuth - currentHeading);
    return (delta > 180) ? delta - 360 : (delta < -180) ? delta + 360 : delta;
  }

  /// **Ensure Angle is Between 0-360**
  double normalizeAngle(double angle) {
    return (angle % 360 + 360) % 360;
  }

  /// **Smooth Arrow Rotation**
  double smoothRotation(double current, double target, double alpha) {
    return current + alpha * (target - current);
  }

  /// **Check Alignment & Capture Photo**
  void checkAndCapturePhoto() {
    if (isPhotoCaptured.value || !isCameraInitialized.value) return;

    double azimuthError = (calculateArrowDirection(heading.value, targetAzimuth.value)).abs();
    double altitudeError = (targetElevation.value - motionService.getPitch()).abs();
    double pitch = motionService.getPitch();

    // Debugging: Print values to verify accuracy
    print("Azimuth Error: $azimuthError, Altitude Error: $altitudeError, Pitch: $pitch");

    if (azimuthError <= azimuthThreshold &&
        altitudeError <= altitudeThreshold &&
        pitch > minPitchForSky) {
      capturePhoto();
    }
  }


  /// **Capture Photo**
  void capturePhoto() {
    if (!cameraController.value.isTakingPicture) {
      cameraController.takePicture().then((picture) {
        capturedImagePath.value = picture.path;
        isPhotoCaptured.value = true;
        stopTracking();
      }).catchError((e) {
        Get.snackbar("Error", "Failed to capture photo: $e");
      });
    }
  }

  /// **Stop Tracking After Capture**
  void stopTracking() {
    motionService.invalidateMotionTracking();
    locationService.stopTrackingMagneticHeading();
    locationService.stopTrackingCurrentLocation();
  }

  @override
  void onClose() {
    if (cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.onClose();
  }
}