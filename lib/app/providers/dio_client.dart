import 'dart:io';

import 'package:artools/artools.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

const _defaultConnectTimeout = Duration.millisecondsPerMinute;
const _defaultReceiveTimeout = Duration.millisecondsPerMinute;

class DioClient {
  static DioClient? _instance;

  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  static const String _baseURL = "https://affine.affinesol.com/";
  late Dio _dio;

  DioClient._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: _baseURL,
      connectTimeout: _defaultConnectTimeout,
      receiveTimeout: _defaultReceiveTimeout,
      headers: {},
      contentType: 'application/json; charset=utf-8',
      responseType: ResponseType.json,
    );


    _dio = Dio(options);

    // ✅ Bypass SSL Certificate Validation (For Both Dev & Production)
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioError e, handler) {
          if (e.response?.statusCode == 401) {}
          handler.reject(DioError(
            requestOptions: e.requestOptions,
            error: e,
            type: e.type,
            response: e.response,
          ));
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
          request: false,
          requestBody: false));
    }
  }

  Future post(
      String url, {
        data,
        JsonMap? queryParameters,
        Options? options,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      var response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
      return response.data;
    } on DioError catch (e) {
      debugPrint("Dio Error: $e");
      rethrow;
    }
  }

  Future get(
    String url, {
    JsonMap? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    var response = await _dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
      onReceiveProgress: onReceiveProgress,
    );
    return response.data;
  }

  Future delete(
    String url, {
    data,
    JsonMap? queryParameters,
    Options? options,
  }) async {
    var response = await _dio.delete(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data;
  }
}
