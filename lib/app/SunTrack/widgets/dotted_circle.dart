/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 18/01/2025 at 23:47:08
 */

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DottedCircle extends StatelessWidget {
  final double radius;

  const DottedCircle({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: DottedDecoration(
        shape: Shape.circle,
        color: Colors.red,
        strokeWidth: 3,
        dash: const [4, 10],
      ),
    );
  }
}
