import 'dart:io';
import 'dart:math';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:artools/artools.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
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
  static const double azimuthThreshold = 5.0;
  static const double altitudeThreshold = 5.0;
  static const double minPitchForSky = 15.0;
  var isCameraPointingUpward = false.obs; // Z-axis detection

  var targetAzimuth = 0.0.obs;
  var targetElevation = 0.0.obs;
  var heading = 0.0.obs;
  var arrowDirection = 0.0.obs;
  var circleRadius = minRadius.obs;
  var isCameraInitialized = false.obs;
  var isPhotoCaptured = false.obs;
  var capturedImagePath = "".obs;
  var isGettingBrightness = false.obs;
  var brightnessPercentage = 0.0.obs;
  var isSunDetected = false.obs;
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
    motionService.startTrackingMotion((data) {
      if (isPhotoCaptured.value) return;
      isCameraPointingUpward.value = data['z']! < -0.2;

      arrowDirection.value = smoothRotation(
        arrowDirection.value,
        calculateArrowDirection(heading.value, targetAzimuth.value),
        0.2,
      );

      updateCircleRadius();
      checkAndCapturePhoto();
    });

    locationService.startTrackingMagneticHeading((magneticHeading) {
      heading.value = normalizeAngle(magneticHeading);
    });

    ever(heading, (_) => updateCircleRadius());
  }

  /// **Track Sun Position**
  void startTrackingSun() {
    locationService.startTrackingCurrentLocation((location) {
      if (isPhotoCaptured.value) return;

      final now = DateTime.now();

      final sunPosition = SunCalc.getSunPosition(
        now,
        location.latitude as num,
        location.longitude as num,
      );

      double sunAzimuth = normalizeAngle((sunPosition["azimuth"]! * 180 / pi) + 180);
      double sunAltitude = sunPosition["altitude"]! * 180 / pi;

      if ((targetAzimuth.value - sunAzimuth).abs() > 0.1 || (targetElevation.value - sunAltitude).abs() > 0.1) {
        targetAzimuth.value = sunAzimuth;
        targetElevation.value = sunAltitude;
      }
    });
  }

  /// **Dynamically Adjust Sun Circle Radius**
  void updateCircleRadius() {
    double elevationFactor = (targetElevation.value + 90) / 180;
    double azimuthDifference =
        calculateArrowDirection(heading.value, targetAzimuth.value).abs();
    double alignmentFactor = (1 - azimuthDifference / 90).clamp(0.0, 1.0);

    double adjustedRadius = minRadius +
        (alignmentFactor * (maxRadius - minRadius) * elevationFactor);
    circleRadius.value = adjustedRadius.clamp(minRadius, maxRadius);
  }

  /// **Calculate Arrow Direction**
  double calculateArrowDirection(double currentHeading, double targetAzimuth) {
    double delta = normalizeAngle(targetAzimuth - currentHeading);
    return (delta > 180)
        ? delta - 360
        : (delta < -180)
            ? delta + 360
            : delta;
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
    if (isPhotoCaptured.value) return; // Prevent multiple captures

    if ((arrowDirection.value.abs() <= 10.0) &&
        isCameraPointingUpward.value) {
      if (!cameraController.value.isTakingPicture) {
        cameraController.takePicture().then((picture) async {
          capturedImagePath.value = picture.path;
          showDefaultDialog(picture);
          isPhotoCaptured.value = true;
          stopTracking();
          try {
            isGettingBrightness.value = true;
            var response = await directionTrackingService.getSunBrightness(
                sunImage: File(picture.path));
            brightnessPercentage.value = response['brightness_percentage'];
            isSunDetected.value = response['sun_detected'];
          } on DioError catch (e) {
            Get.snackbar("Error", "There was an error getting results! - $e");
          } finally {
            isGettingBrightness.value = false;
          }
        }).catchError((e) {
          Get.snackbar("Error", "Failed to capture photo: $e");
          printD(e);
        });
      }
    }
  }

  /// **Capture Photo**
  Future<void> capturePhoto() async {
    if (!cameraController.value.isTakingPicture) {
      try {
        final picture = await cameraController.takePicture();
        capturedImagePath.value = picture.path;
        isPhotoCaptured.value = true;
        stopTracking();
      } catch (e) {
        Get.snackbar("Error", "Failed to capture photo: $e");
      }
    }
  }

  void showDefaultDialog(picture) {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: const Text("Success"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Photo captured: ${picture.path}").marginOnly(bottom: 20),
            Obx(() => isGettingBrightness.value
                ? const CircularProgressIndicator()
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sun Brightness: ${brightnessPercentage.value}")
                    .marginOnly(bottom: 12),
                Text("Sun Detected? ${isSunDetected.value}"),
              ],
            ))
          ],
        ),
        actions: [
          Obx(
                () => TextButton(
              onPressed: isGettingBrightness.value ? null : () => Get.back(),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
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
