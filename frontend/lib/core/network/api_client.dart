import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../mock/app_models.dart';
import '../mock/mock_data.dart';

/// Machine-readable outcome classification for the typed Saved Collections
/// endpoints — deliberately distinct from the legacy `Map<String, dynamic>`
/// `code` strings used by `login`/`register`, since callers here (`AppState`)
/// need to disambiguate by call-site context, not by parsing server prose.
enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  notFound,
  conflict,
  validation,
  server,
  malformed,
}

class CollectionApiResult<T> {
  final bool success;
  final T? data;
  final ApiErrorKind? errorKind;
  final String? message;

  const CollectionApiResult.success(this.data)
      : success = true,
        errorKind = null,
        message = null;

  const CollectionApiResult.failure(this.errorKind, [this.message])
      : success = false,
        data = null;
}

class CollectionApiVoidResult {
  final bool success;
  final ApiErrorKind? errorKind;
  final String? message;

  const CollectionApiVoidResult.success()
      : success = true,
        errorKind = null,
        message = null;

  const CollectionApiVoidResult.failure(this.errorKind, [this.message])
      : success = false;
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  bool demoMode = true;
  String? token;
  ApiClient({this.baseUrl = AppConfig.apiBaseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email == MockData.demoEmail && password == MockData.demoPassword) {
      demoMode = true;
      token = 'demo-token';
      return {'success': true, 'demo': true, 'token': token};
    }
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/auth/login'),
              headers: _jsonHeaders,
              body: jsonEncode({'email': email, 'password': password}))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = _decodeJsonMap(res);
        final body = decoded.data;
        if (body == null || body['token'] is! String) {
          return _failure('malformed',
              'Login succeeded but the server response was incomplete.');
        }
        token = body['token'] as String;
        demoMode = false;
        return {'success': true, 'demo': false, 'token': token};
      }
      return _failureForStatus(res);
    } on TimeoutException {
      return _failure('network',
          'The backend did not respond in time. Check the server and network.');
    } on http.ClientException {
      return _failure(
          'network', 'Cannot reach the backend. Check the API base URL.');
    } on FormatException {
      return _failure('malformed',
          'The backend returned an unexpected response. Please try again.');
    } catch (_) {
      return _failure('network',
          'Cannot reach the backend. You can still use the demo account.');
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/auth/register'),
              headers: _jsonHeaders,
              body: jsonEncode(
                  {'fullName': name, 'email': email, 'password': password}))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true};
      }
      return _failureForStatus(res);
    } on TimeoutException {
      return _failure('network',
          'The backend did not respond in time. Check the server and network.');
    } on http.ClientException {
      return _failure(
          'network', 'Cannot reach the backend. Check the API base URL.');
    } on FormatException {
      return _failure('malformed',
          'The backend returned an unexpected response. Please try again.');
    } catch (_) {
      return _failure(
          'network', 'Cannot reach the backend. You can still use Demo Mode.');
    }
  }

  // ── Saved Collections (/api/me/collections) ─────────────────────────────

  static const Duration _collectionsTimeout = Duration(seconds: 8);

  ApiErrorKind _errorKindForStatus(int statusCode) {
    if (statusCode == 400) return ApiErrorKind.validation;
    if (statusCode == 401) return ApiErrorKind.unauthorized;
    if (statusCode == 404) return ApiErrorKind.notFound;
    if (statusCode == 409) return ApiErrorKind.conflict;
    if (statusCode >= 500) return ApiErrorKind.server;
    return ApiErrorKind.malformed;
  }

  Future<CollectionApiResult<List<CollectionSummaryRecord>>>
      listCollections() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/collections'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  CollectionSummaryRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiResult<CollectionDetailRecord>> createCollection({
    required String name,
    String? description,
    String? coverImageUrl,
    bool? privateCollection,
    int? sortOrder,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/collections'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'name': name,
              'description': description,
              'coverImageUrl': coverImageUrl,
              'privateCollection': privateCollection,
              'sortOrder': sortOrder,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          CollectionDetailRecord.fromJson(body),
        );
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiResult<CollectionDetailRecord>> getCollectionDetail(
    int collectionId,
  ) async {
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/me/collections/$collectionId'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          CollectionDetailRecord.fromJson(body),
        );
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiResult<CollectionDetailRecord>> updateCollection({
    required int collectionId,
    required String name,
    String? description,
    String? coverImageUrl,
    bool? privateCollection,
    int? sortOrder,
  }) async {
    try {
      final res = await _client
          .put(
            Uri.parse('$baseUrl/me/collections/$collectionId'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'name': name,
              'description': description,
              'coverImageUrl': coverImageUrl,
              'privateCollection': privateCollection,
              'sortOrder': sortOrder,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          CollectionDetailRecord.fromJson(body),
        );
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiVoidResult> deleteCollection(int collectionId) async {
    try {
      final res = await _client
          .delete(
            Uri.parse('$baseUrl/me/collections/$collectionId'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 204) {
        return const CollectionApiVoidResult.success();
      }
      return CollectionApiVoidResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiResult<CollectionPlaceRecord>> addCollectionPlace({
    required int collectionId,
    required int placeId,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/collections/$collectionId/places/$placeId'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          CollectionPlaceRecord.fromJson(body),
        );
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiVoidResult> removeCollectionPlace({
    required int collectionId,
    required int placeId,
  }) async {
    try {
      final res = await _client
          .delete(
            Uri.parse('$baseUrl/me/collections/$collectionId/places/$placeId'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 204) {
        return const CollectionApiVoidResult.success();
      }
      return CollectionApiVoidResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    }
  }

  Map<String, dynamic> _failureForStatus(http.Response res) {
    Map<String, dynamic>? body;
    try {
      body = _decodeJsonMap(res).data;
    } on FormatException {
      body = null;
    }
    final serverMessage = _safeServerMessage(body);
    if (res.statusCode == 400) {
      return _failure('validation',
          serverMessage ?? 'Please check the submitted information.');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      return _failure(
          'invalid_credentials', serverMessage ?? 'Invalid email or password.');
    }
    if (res.statusCode >= 500) {
      return _failure('server',
          'The backend is temporarily unavailable. Please try again later.');
    }
    return _failure(
        'unexpected', serverMessage ?? 'Unexpected backend response.');
  }

  ({Map<String, dynamic>? data}) _decodeJsonMap(http.Response res) {
    if (res.bodyBytes.isEmpty) return (data: null);
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is Map<String, dynamic>) return (data: decoded);
    return (data: null);
  }

  String? _safeServerMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    final raw = body['message'] ?? body['error'] ?? body['detail'];
    if (raw is! String) return null;
    final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (cleaned.isEmpty || cleaned.length > 180) return null;
    return cleaned;
  }

  Map<String, dynamic> _failure(String code, String message) => {
        'success': false,
        'code': code,
        'message': message,
      };
}
