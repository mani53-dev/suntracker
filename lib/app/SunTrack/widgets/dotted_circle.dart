/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 23:47:08
 */

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DottedCircle extends StatelessWidget {
  final RxDouble radius;

  const DottedCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: radius.value * 2,
        height: radius.value * 2,
        decoration: DottedDecoration(
          shape: Shape.circle,
          color: Colors.red,
          strokeWidth: 2,
          dash: [4, 8],
        ),
      ),
    );
  }
}
