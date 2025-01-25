import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class Helper {
  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }
}
