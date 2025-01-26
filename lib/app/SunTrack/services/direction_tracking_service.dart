/* 
 * Author: Affine Sol (PVT LTD) - https://affinesol.com/ 
 * Last Modified: 26/01/2025 at 15:37:58
 */

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:suntracker/app/providers/dio_client.dart';

abstract class AnyDirectionTrackingService {
  Future<dynamic> getSunBrightness({required File sunImage});
}

class DirectionTrackingService implements AnyDirectionTrackingService {
  final DioClient _httpClient = DioClient();

  @override
  Future getSunBrightness({required File sunImage}) async {
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          sunImage.path,
          filename: sunImage.path.split('/').last,
        ),
      });

      var response = await _httpClient.post(
        'brightness',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioError catch (_) {
      rethrow;
    }
  }

}