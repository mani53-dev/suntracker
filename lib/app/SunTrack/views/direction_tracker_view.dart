/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 12:27:56
 */

import 'dart:io';
import 'dart:math';

import 'package:artools/artools.dart';
import 'package:camera/camera.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:suntracker/app/SunTrack/widgets/dotted_circle.dart';

import '../controllers/direction_tracker_controller.dart';

class DirectionTrackerView extends GetView<DirectionTrackerController> {
  const DirectionTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => controller.isCameraInitialized.value
            ? Stack(
                children: [
                  SizedBox(
                    height: Get.height,
                    child: controller.isPhotoCaptured.value
                        ? Image.file(
                            File(controller.capturedImagePath.value),
                            fit: BoxFit.cover,
                          )
                        : CameraPreview(controller.cameraController),
                  ),
                  DottedCircle(radius: controller.circleRadius)
                      .center()
                      .visibility(!controller.isPhotoCaptured.value),
                  Center(
                    child: Transform.rotate(
                      angle: controller.arrowDirection.value * (pi / 180),
                      // Convert to radians
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 100.0,
                        color: Colors.red,
                      ),
                    ),
                  ).visibility(!controller.isPhotoCaptured.value),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
