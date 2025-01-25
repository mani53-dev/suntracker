import 'package:flutter/material.dart';

ThemeData getAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xff614A5E),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xff614A5E),
      selectionHandleColor: const Color(0xff614A5E),
      selectionColor: const Color(0xff614A5E).withOpacity(0.25),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xff614A5E), // button text color
      ),
    ),
    // fontFamily: 'Varela',
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xff363535),
        fontSize: 14,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xff484747),
        fontSize: 12,
      ),
    ),
  );
}
