import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/utils/app_toast.dart';
import '../session/session_manager.dart';
import 'api_endpoint.dart';

class ApiClient {
  ApiClient(this._sessionManager, {http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final SessionManager _sessionManager;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool requiresAuth = false,
    bool showSuccessToast = true,
    Map<String, String>? headers,
  }) async {
    final resolvedHeaders = await _headers(
      requiresAuth: requiresAuth,
      headers: headers,
    );
    final uri = _uriFor(path);
    _logRequest(method: 'GET', uri: uri, headers: resolvedHeaders);

    final response = await _client.get(uri, headers: resolvedHeaders);
    _logResponse(method: 'GET', uri: uri, response: response);
    return _decodeResponse(response, showSuccessToast: showSuccessToast);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool showSuccessToast = true,
    Map<String, String>? headers,
  }) async {
    final resolvedHeaders = await _headers(
      requiresAuth: requiresAuth,
      headers: headers,
    );
    final uri = _uriFor(path);
    final requestBody = jsonEncode(body ?? const <String, dynamic>{});
    _logRequest(
      method: 'POST',
      uri: uri,
      headers: resolvedHeaders,
      body: requestBody,
    );

    final response = await _client.post(
      uri,
      headers: resolvedHeaders,
      body: requestBody,
    );
    _logResponse(method: 'POST', uri: uri, response: response);
    return _decodeResponse(response, showSuccessToast: showSuccessToast);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool showSuccessToast = true,
    Map<String, String>? headers,
  }) async {
    final resolvedHeaders = await _headers(
      requiresAuth: requiresAuth,
      headers: headers,
    );
    final uri = _uriFor(path);
    final requestBody = jsonEncode(body ?? const <String, dynamic>{});
    _logRequest(
      method: 'PUT',
      uri: uri,
      headers: resolvedHeaders,
      body: requestBody,
    );

    final response = await _client.put(
      uri,
      headers: resolvedHeaders,
      body: requestBody,
    );
    _logResponse(method: 'PUT', uri: uri, response: response);
    return _decodeResponse(response, showSuccessToast: showSuccessToast);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    bool showSuccessToast = true,
    Map<String, String>? headers,
  }) async {
    final resolvedHeaders = await _headers(
      requiresAuth: requiresAuth,
      headers: headers,
    );
    final uri = _uriFor(path);
    final requestBody = body == null ? null : jsonEncode(body);
    _logRequest(
      method: 'DELETE',
      uri: uri,
      headers: resolvedHeaders,
      body: requestBody,
    );

    final response = await _client.delete(
      uri,
      headers: resolvedHeaders,
      body: requestBody,
    );
    _logResponse(method: 'DELETE', uri: uri, response: response);
    return _decodeResponse(response, showSuccessToast: showSuccessToast);
  }

  Uri _uriFor(String path) {
    return Uri.parse(ApiEndpoint.baseUrl).resolve(path);
  }

  Future<Map<String, String>> _headers({
    required bool requiresAuth,
    Map<String, String>? headers,
  }) async {
    final resolvedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    if (requiresAuth) {
      final token = await _sessionManager.accessToken;
      if (token != null && token.isNotEmpty) {
        resolvedHeaders['Authorization'] = 'Bearer $token';
      }
    }

    return resolvedHeaders;
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required bool showSuccessToast,
  }) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = response.body;
      }
    }

    decoded ??= const <String, dynamic>{};

    final message = _extractMessage(decoded);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (showSuccessToast && message != null && message.trim().isNotEmpty) {
        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          AppToast.error(message);
        } else {
          AppToast.success(message);
        }
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'data': decoded};
    }

    if (message != null && message.trim().isNotEmpty) {
      AppToast.error(message);
    }

    throw ApiException(
      message: message ?? 'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  String? _extractMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['message']?.toString();
    }
    if (decoded is String) {
      return decoded;
    }
    return null;
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    final buffer = StringBuffer()
      ..writeln('[API][REQUEST] $method $uri')
      ..writeln('[API][REQUEST][HEADERS] $headers');

    if (body != null) {
      buffer.writeln('[API][REQUEST][BODY] $body');
    }

    print(buffer.toString());
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required http.Response response,
  }) {
    final buffer = StringBuffer()
      ..writeln('[API][RESPONSE] $method $uri')
      ..writeln('[API][RESPONSE][STATUS] ${response.statusCode}')
      ..writeln('[API][RESPONSE][BODY] ${response.body}');

    print(buffer.toString());
  }
}

class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.responseBody});

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => message;
}
