import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Excecao de chamadas a API Forrageira (servidor UFSJ).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;

  const ApiException(this.message, {this.statusCode, this.isRetryable = false});

  @override
  String toString() => message;
}

/// Cliente HTTP da API REST (https://capim.ufsj.edu.br/api).
///
/// Anexa automaticamente o ID token do Firebase em `Authorization: Bearer`.
/// As respostas seguem o formato `{status, message, data}`; este cliente
/// retorna o conteudo de `data` em caso de sucesso e lanca [ApiException]
/// caso contrario.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    FirebaseAuth? auth,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl,
        _auth = auth ?? FirebaseAuth.instance;

  /// Base configuravel em build: --dart-define=API_BASE_URL=...
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://capim.ufsj.edu.br/api',
  );

  final http.Client _http;
  final String _baseUrl;
  final FirebaseAuth _auth;

  static const Duration _timeout = Duration(seconds: 30);

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers();

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _http.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on SocketException {
      throw const ApiException(
        'Falha de conexao. Verifique sua internet.',
        isRetryable: true,
      );
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou demais para responder.',
        isRetryable: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'Falha de comunicacao com o servidor.',
        isRetryable: true,
      );
    }

    return _parse(response);
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final qp = <String, String>{};
    query?.forEach((key, value) {
      if (value != null) qp[key] = value.toString();
    });
    return Uri.parse('$_baseUrl$normalized')
        .replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final token = await _idToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String?> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  dynamic _parse(http.Response response) {
    Map<String, dynamic>? json;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        json = null;
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && (json == null || json['status'] == 'success')) {
      return json?['data'];
    }

    final message = (json?['message'] as String?) ??
        'Erro HTTP ${response.statusCode}.';
    throw ApiException(
      message,
      statusCode: response.statusCode,
      isRetryable: response.statusCode >= 500,
    );
  }
}
