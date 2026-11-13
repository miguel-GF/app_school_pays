import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(String baseUrl, {http.Client? client})
      : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _http = client ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'school_access_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'school_access_token');
  }

  Future<String?> readToken() async {
    _token ??= await _storage.read(key: 'school_access_token');
    return _token;
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null || !base.hasAuthority || !base.scheme.startsWith('http')) {
      throw const ApiException(0, 'La URL del API de esta escuela no está configurada.');
    }

    final uri = Uri.parse('$baseUrl/api/v1/mobile$path');
    final token = await readToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _http.send(request).timeout(const Duration(seconds: 25));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        data['message']?.toString() ?? 'Error al conectar con el API escolar.',
      );
    }
    return data;
  }
}
