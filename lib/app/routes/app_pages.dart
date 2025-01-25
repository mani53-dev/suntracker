import 'package:get/get.dart';
import 'package:suntracker/app/SunTrack/bindings/direction_tracker_bindings.dart';
import '../SunTrack/views/direction_tracker_view.dart';
import 'app_routes.dart';

class AppPages {
  static var INITIAL = Routes.DIRECTION_TRACKER_VIEW;

  static final routes = [
    GetPage(
      name: Routes.DIRECTION_TRACKER_VIEW,
      page: () => const DirectionTrackerView(),
      bindings: [
        DirectionTrackerBindings()
      ]
    ),
  ];
}
