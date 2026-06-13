import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:thpt_exam_prep_app/core/config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  const ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, body: $body)';
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUri = Uri.parse(AppConfig.apiBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final resolvedPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}$normalizedPath'
        : '${baseUri.path}/$normalizedPath';
    return baseUri.replace(
      path: resolvedPath,
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, String> _defaultHeaders({
    Map<String, String>? headers,
    bool hasBody = false,
  }) {
    final merged = <String, String>{
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json; charset=utf-8',
      ...?headers,
    };
    return merged;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send<dynamic>(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send<dynamic>(
      'POST',
      path,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send<dynamic>(
      'PUT',
      path,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send<dynamic>(
      'DELETE',
      path,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<T?> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = _defaultHeaders(
      headers: headers,
      hasBody: body != null,
    );

    try {
      http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: requestHeaders)
              .timeout(Duration(seconds: AppConfig.apiTimeout));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: requestHeaders, body: _encodeBody(body))
              .timeout(Duration(seconds: AppConfig.apiTimeout));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: requestHeaders, body: _encodeBody(body))
              .timeout(Duration(seconds: AppConfig.apiTimeout));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: requestHeaders, body: _encodeBody(body))
              .timeout(Duration(seconds: AppConfig.apiTimeout));
          break;
        default:
          throw const ApiException('Unsupported HTTP method');
      }

      return _handleResponse<T>(response);
    } on TimeoutException {
      throw const ApiException(
        'Kết nối quá thời gian chờ. Vui lòng thử lại sau.',
      );
    } on SocketException {
      throw const ApiException(
        'Không có kết nối mạng hoặc không truy cập được backend.',
      );
    } on HttpException {
      throw const ApiException('Lỗi giao thức HTTP khi gọi API.');
    } on FormatException {
      throw const ApiException('Dữ liệu JSON từ server không hợp lệ.');
    }
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  T? _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body.trim();

    if (statusCode >= 200 && statusCode < 300) {
      if (statusCode == 204 || responseBody.isEmpty) {
        return null;
      }

      try {
        return jsonDecode(responseBody) as T?;
      } on FormatException {
        throw ApiException(
          'Server trả về dữ liệu không phải JSON hợp lệ.',
          statusCode: statusCode,
          body: responseBody,
        );
      }
    }

    dynamic errorBody;
    if (responseBody.isNotEmpty) {
      try {
        errorBody = jsonDecode(responseBody);
      } catch (_) {
        errorBody = responseBody;
      }
    }

    throw ApiException(
      'API trả về lỗi HTTP $statusCode.',
      statusCode: statusCode,
      body: errorBody,
    );
  }

  void dispose() {
    _client.close();
  }
}
