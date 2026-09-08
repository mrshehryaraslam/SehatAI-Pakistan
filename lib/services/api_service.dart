import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final int statusCode;

  const ApiResponse({
    required this.isSuccess,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String? _authToken;
  static String? get authToken => _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
    debugPrint('[ApiService] Auth token updated: ${token != null ? "SET" : "CLEARED"}');
  }

  Map<String, String> _buildHeaders({bool authRequired = true}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (authRequired && _authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse<dynamic>> get(
    String url, {
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _buildHeaders(authRequired: authRequired))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('[ApiService] GET error on $url: $e');
      return ApiResponse(
        isSuccess: false,
        message: 'Network or server error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _buildHeaders(authRequired: authRequired),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('[ApiService] POST error on $url: $e');
      return ApiResponse(
        isSuccess: false,
        message: 'Network or server error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _buildHeaders(authRequired: authRequired),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('[ApiService] PUT error on $url: $e');
      return ApiResponse(
        isSuccess: false,
        message: 'Network or server error: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<dynamic>> delete(
    String url, {
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _buildHeaders(authRequired: authRequired),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('[ApiService] DELETE error on $url: $e');
      return ApiResponse(
        isSuccess: false,
        message: 'Network or server error: $e',
        statusCode: 0,
      );
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final status = decoded['status']?.toString().toLowerCase();
        final message = decoded['message']?.toString() ?? 'Response received';
        final data = decoded['data'];

        final isSuccess = (response.statusCode >= 200 && response.statusCode < 300) &&
            (status == 'success' || status == null);

        return ApiResponse(
          isSuccess: isSuccess,
          message: message,
          data: data,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Invalid response format',
        data: decoded,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        isSuccess: false,
        message: 'Failed to parse server response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
