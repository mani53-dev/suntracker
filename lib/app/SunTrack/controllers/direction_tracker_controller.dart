import 'dart:math';

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suntracker/app/SunTrack/services/motion_service.dart';
import '../services/location_service.dart';


class DirectionTrackerController extends GetxController {
  final AnyMotionService motionService;
  final AnyLocationService locationService;

  DirectionTrackerController({
    required this.motionService,
    required this.locationService,
  });

  var targetAngle = 170.0.obs; // Sun azimuth (angle in degrees)
  var targetElevation = 0.0.obs; // Sun altitude (in degrees)
  var heading = 0.0.obs; // Device's magnetic heading (in degrees)
  var isCameraPointingUpward = false.obs; // Z-axis detection
  var arrowDirection = 0.0.obs; // Angle for arrow UI
  var circleRadius = 100.0.obs; // Circle radius for UI
  var isCameraInitialized = false.obs;

  late CameraController cameraController;

  // Flag to track if photo has already been taken
  var isPhotoCaptured = false.obs;
  var capturedImagePath = "".obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    startTrackingMotion();
    startTrackingSunDirection();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No cameras available");

      final camera = cameras.first;
      cameraController = CameraController(camera, ResolutionPreset.high);
      await cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar("Camera Error", e.toString());
      isCameraInitialized.value = false;
    }
  }

  void startTrackingMotion() {
    motionService.startTrackingMotion((data) {
      if (isPhotoCaptured.value) return; // Stop tracking if photo is already taken

      // Update Z-axis detection with a threshold for precision
      isCameraPointingUpward.value = data['z']! < -0.2;

      // Update arrow direction with smoothing
      arrowDirection.value = smoothRotation(
        arrowDirection.value,
        calculateArrowDirection(
          currentHeading: heading.value,
          targetAzimuth: targetAngle.value,
        ) + 180,
        0.1, // Smoothing factor (adjust as needed)
      );

      // Check and capture photo if aligned with sun
      checkAndCapturePhoto();
    });

    // Update heading continuously
    locationService.startTrackingMagneticHeading((magneticHeading) {
      heading.value = normalizeAngle(magneticHeading);
    });
  }

  void startTrackingSunDirection() {
    DateTime? lastUpdate;

    locationService.startTrackingCurrentLocation((location) {
      if (isPhotoCaptured.value) return; // Stop tracking if photo is already taken

      final now = DateTime.now();
      if (lastUpdate != null && now.difference(lastUpdate!) < const Duration(seconds: 5)) {
        return; // Skip if less than 5 seconds have passed
      }
      lastUpdate = now;

      final sunPosition = SunCalc.getSunPosition(
        now,
        location.latitude as num,
        location.longitude as num,
      );

      // Update sun azimuth and elevation
      targetAngle.value = normalizeAngle(sunPosition["azimuth"]! * 180 / pi); // Convert radians to degrees
      targetElevation.value = sunPosition["altitude"]! * 180 / pi; // Convert radians to degrees

      // Update circle radius based on the sun's elevation
      updateCircleRadius(targetElevation.value);
    });
  }

  void updateCircleRadius(double elevation) {
    // Map the elevation range (-90 to 90 degrees) to a radius range (100 to 200)
    const double minRadius = 100.0;
    const double maxRadius = 200.0;

    // Normalize elevation to a value between 0 and 1 (from -90 to 90 degrees)
    double normalizedElevation = (elevation + 90) / 180;

    // Calculate the angular difference between the camera's heading and the sun's azimuth
    double alignmentThreshold = 10.0; // Degrees tolerance for "close to the sun"
    double delta = calculateArrowDirection(
      currentHeading: heading.value,
      targetAzimuth: targetAngle.value,
    ).abs();

    // Check if the camera is within 10% of alignment with the sun
    double alignmentPercentage = (1 - delta / 180).clamp(0.0, 1.0); // Normalize to a value between 0 and 1

    // If the camera is within 10% alignment (alignmentPercentage > 0.9), increase the radius
    if (alignmentPercentage > 0.9) {
      circleRadius.value = minRadius + (normalizedElevation * (maxRadius - minRadius));
    } else {
      // Optionally, reset the radius to the minimum when not aligned
      circleRadius.value = minRadius;
    }

    // Print for debugging purposes
    print('Circle radius: ${circleRadius.value}, Alignment percentage: $alignmentPercentage');
  }

  double calculateArrowDirection({
    required double currentHeading,
    required double targetAzimuth,
  }) {
    currentHeading = normalizeAngle(currentHeading);
    targetAzimuth = normalizeAngle(targetAzimuth);

    double delta = targetAzimuth - currentHeading;

    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    return delta;
  }

  double normalizeAngle(double angle) {
    return (angle % 360 + 360) % 360;
  }

  double smoothRotation(double current, double target, double alpha) {
    return current + alpha * (target - current);
  }

  void checkAndCapturePhoto() {
    if (isPhotoCaptured.value) return; // Prevent multiple captures

    const alignmentThreshold = 10.0; // Degrees of tolerance

    if ((arrowDirection.value.abs() <= alignmentThreshold) && isCameraPointingUpward.value) {
      if (!cameraController.value.isTakingPicture) {
        cameraController.takePicture().then((picture) {
          capturedImagePath.value = picture.path;
          showDefaultDialog(picture);
          isPhotoCaptured.value = true; // Mark photo as captured
          stopTracking(); // Stop all tracking after capturing photo
        }).catchError((e) {
          Get.snackbar("Error", "Failed to capture photo: $e");
        });
      }
    }
  }

  void stopTracking() {
    motionService.invalidateMotionTracking(); // Assuming stopTracking exists
    locationService.stopTrackingMagneticHeading();
    locationService.stopTrackingCurrentLocation();
  }

  void showDefaultDialog(picture) {
    Get.dialog(
      AlertDialog(
        title: const Text("Success"),
        content: Text("Photo captured: ${picture.path}"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Dismiss the dialog
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    if (cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.onClose();
  }
}