/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 24/12/2024 at 20:41:33
 */
import 'package:flutter/material.dart';

enum AppColors with ColorValues {
  red(Color(0xffEC1A1A), "Red"),
  green(Color(0xff29BB2F), "Green");

  final Color color;
  final String name;

  const AppColors(this.color, this.name);

  @override
  int redCode() => color.red;

  @override
  int greenCode() => color.green;

  @override
  int blueCode() => color.blue;

  @override
  String toString() {
    super.toString();
    return "Color name is: $name";
  }

  String hexCode() =>
      "#${color.value.toRadixString(16).substring(2, color.value.toRadixString(16).length)}";
}

mixin ColorValues {
  int redCode() => -1;

  int greenCode() => -1;

  int blueCode() => -1;
}
