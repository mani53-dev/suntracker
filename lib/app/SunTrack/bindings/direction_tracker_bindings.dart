/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 12:28:39
 */

import 'package:get/get.dart';

import '../controllers/direction_tracker_controller.dart';
import '../services/location_service.dart';
import '../services/motion_service.dart';

class DirectionTrackerBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MotionService());
    Get.lazyPut(() => LocationService());

    Get.lazyPut(
      () => DirectionTrackerController(
        motionService: Get.find<MotionService>(),
        locationService: Get.find<LocationService>(),
      ),
    );
  }
}
