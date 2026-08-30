import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../mock/app_models.dart';
import '../mock/mock_data.dart';
import '../partner/partner_account_models.dart';
import '../partner/partner_analytics_models.dart';
import '../partner/partner_booking_models.dart';
import '../partner/partner_finance_models.dart';
import '../partner/partner_dashboard_models.dart';
import '../partner/partner_models.dart';
import '../partner/partner_inventory_models.dart';
import '../partner/partner_policy_models.dart';
import '../partner/partner_promotion_models.dart';
import '../partner/partner_property_models.dart';
import '../partner/partner_rate_models.dart';
import '../partner/partner_room_models.dart';

/// Machine-readable outcome classification for the typed Saved Collections
/// endpoints — deliberately distinct from the legacy `Map<String, dynamic>`
/// `code` strings used by `login`/`register`, since callers here (`AppState`)
/// need to disambiguate by call-site context, not by parsing server prose.
enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  unprocessable,
  server,
  malformed,
  // Write-only: the request may have reached and been committed by the server
  // (e.g. a timeout or malformed success on a create). Never map this to a
  // clean failure and never blindly retry.
  uncertain,
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
      // The demo account is a traveller account; it never reaches a backend and
      // must never be treated as a partner or admin.
      return {'success': true, 'demo': true, 'token': token, 'role': 'USER'};
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
        // `AuthDtos.AuthResponse` is `(token, UserDto(id, fullName, email, role))`.
        // The role was previously parsed and discarded; it is surfaced here so
        // the client can route by role. Absent/unrecognised values stay null and
        // fail closed in `AppRole.parse`.
        final user = body['user'];
        return {
          'success': true,
          'demo': false,
          'token': token,
          'role': user is Map<String, dynamic> ? user['role'] : null,
        };
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
    if (statusCode == 403) return ApiErrorKind.forbidden;
    if (statusCode == 404) return ApiErrorKind.notFound;
    if (statusCode == 409) return ApiErrorKind.conflict;
    if (statusCode == 422) return ApiErrorKind.unprocessable;
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

  /// Fetches a full place from the public `GET /api/places/{id}` endpoint so a
  /// partial saved record (wishlist / collection) can be hydrated into a
  /// complete [Place]. The endpoint is public (no auth); a missing or
  /// non-`PUBLISHED` place returns 404 → [ApiErrorKind.notFound].
  Future<CollectionApiResult<PlaceDetailRecord>> getPlaceDetail(
    int placeId,
  ) async {
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/places/$placeId'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(PlaceDetailRecord.fromJson(body));
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

  // ── Wishlist (/api/me/wishlist, UI-18) ──────────────────────────────────
  //
  // Reuses the Saved Collections typed-result infrastructure (ApiErrorKind,
  // CollectionApiResult, _jsonHeaders, _errorKindForStatus, _decodeJsonMap,
  // _collectionsTimeout). The backend GET is get-or-create (never 404); add
  // may return 422 when the place is not PUBLISHED.

  Future<CollectionApiResult<WishlistRecord>> getWishlist() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/wishlist'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(WishlistRecord.fromJson(body));
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

  Future<CollectionApiResult<WishlistItemRecord>> addWishlistItem({
    required int placeId,
    String? note,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/wishlist/items'),
            headers: _jsonHeaders,
            body: jsonEncode({'placeId': placeId, 'note': note}),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(WishlistItemRecord.fromJson(body));
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

  Future<CollectionApiVoidResult> removeWishlistItem(int placeId) async {
    try {
      final res = await _client
          .delete(
            Uri.parse('$baseUrl/me/wishlist/items/$placeId'),
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

  // ── Trips (/api/me/trips, UI-20 TripPlan planner) ───────────────────────
  //
  // Reuses the Saved Collections typed-result infrastructure. Every endpoint is
  // JWT-authenticated. Creates return 201; a 403 (collaborator without edit
  // rights) maps to ApiErrorKind.forbidden, kept distinct from 401 so callers
  // show a permission error rather than the session-expired sheet.

  static String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<CollectionApiResult<List<TripSummaryRecord>>> getMyTrips() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => TripSummaryRecord.fromJson(e as Map<String, dynamic>))
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

  Future<CollectionApiResult<TripDetailRecord>> getTripDetail(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(TripDetailRecord.fromJson(body));
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

  Future<CollectionApiResult<TripDetailRecord>> createTrip({
    required String title,
    String? description,
    String? destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/trips'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'title': title,
              'description': description,
              'destination': destination,
              'startDate': _isoDate(startDate),
              'endDate': _isoDate(endDate),
              'isPublic': false,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(TripDetailRecord.fromJson(body));
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

  Future<CollectionApiResult<TripDayRecord>> createTripDay({
    required int tripId,
    required int dayNumber,
    DateTime? date,
    String? title,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/trips/$tripId/days'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'dayNumber': dayNumber,
              'date': date == null ? null : _isoDate(date),
              'title': title,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(TripDayRecord.fromJson(body));
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

  Future<CollectionApiResult<TripItemRecord>> addTripItem({
    required int dayId,
    required int placeId,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/trips/days/$dayId/items'),
            headers: _jsonHeaders,
            body: jsonEncode({'placeId': placeId}),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(TripItemRecord.fromJson(body));
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

  // ── Place search (/api/places/search, UI-21) ────────────────────────────
  //
  // Public, offset-paginated (`PageResponse<PlaceSummaryResponse>`). Only
  // backend-verified params are sent; blanks/nulls are omitted. `size` must be
  // ≤ 100 or the backend returns 400 → ApiErrorKind.validation.
  Future<CollectionApiResult<PlaceSearchPage>> searchPlaces({
    String? q,
    String? categorySlug,
    double? minRating,
    int? maxPriceLevel,
    bool? featured,
    String sort = 'newest',
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (categorySlug != null && categorySlug.isNotEmpty)
        'categorySlug': categorySlug,
      if (minRating != null) 'minRating': minRating.toString(),
      if (maxPriceLevel != null) 'maxPriceLevel': maxPriceLevel.toString(),
      if (featured != null) 'featured': featured.toString(),
      'sort': sort,
      'page': page.toString(),
      'size': size.toString(),
    };
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/places/search')
                .replace(queryParameters: params),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(PlaceSearchPage.fromJson(body));
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

  // ── Hotel availability (/api/places/{placeId}/availability, UI-22) ────────
  //
  // Public endpoint (permitted GET on /api/places/**). Returns real bookable
  // rooms with real prices for a hotel place + date range + guest count. The
  // backend 400s on checkOut<=checkIn / past checkIn / adults<1, and 404s when
  // the place is missing or has no hotel detail.
  Future<CollectionApiResult<HotelAvailabilityResult>> getHotelAvailability({
    required int placeId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 1,
    int children = 0,
  }) async {
    String d(DateTime v) => '${v.year.toString().padLeft(4, '0')}-'
        '${v.month.toString().padLeft(2, '0')}-'
        '${v.day.toString().padLeft(2, '0')}';
    final params = <String, String>{
      'checkIn': d(checkIn),
      'checkOut': d(checkOut),
      'adults': adults.toString(),
      'children': children.toString(),
    };
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/places/$placeId/availability')
                .replace(queryParameters: params),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
            HotelAvailabilityResult.fromJson(body));
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

  /// Lists a room's real sellable rate plans with pricing + eligibility +
  /// cancellation terms for a stay (`GET /api/rooms/{roomId}/rate-plans`). This
  /// is a public, read-only endpoint distinct from the availability search — it
  /// is never a duplicate of [getHotelAvailability]. Returns a JSON array.
  Future<CollectionApiResult<List<HotelRatePlan>>> getRoomRatePlans({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
  }) async {
    String d(DateTime v) => '${v.year.toString().padLeft(4, '0')}-'
        '${v.month.toString().padLeft(2, '0')}-'
        '${v.day.toString().padLeft(2, '0')}';
    final params = <String, String>{
      'checkIn': d(checkIn),
      'checkOut': d(checkOut),
      'adults': adults.toString(),
      'children': children.toString(),
      'extraBeds': extraBeds.toString(),
    };
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/rooms/$roomId/rate-plans')
                .replace(queryParameters: params),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => HotelRatePlan.fromJson(e as Map<String, dynamic>))
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

  /// Fetches the canonical, backend-computed pricing quote for a room + stay
  /// from the public `POST /api/rooms/{roomId}/pricing/quote` endpoint. This is
  /// read-only: it never creates a booking, holds inventory, or applies customer
  /// benefits (the authenticated `/api/me/...` variant does that; deferred). All
  /// prices come straight from the backend — nothing is computed client-side.
  Future<CollectionApiResult<HotelPricingQuote>> getRoomPricingQuote({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
    int? ratePlanId,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/rooms/$roomId/pricing/quote'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'checkIn': _isoDate(checkIn),
              'checkOut': _isoDate(checkOut),
              'adults': adults,
              'children': children,
              'extraBeds': extraBeds,
              if (ratePlanId != null) 'ratePlanId': ratePlanId,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(HotelPricingQuote.fromJson(body));
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

  // A create is a WRITE, so it gets a longer budget than the read-only
  // collections calls (the backend takes pessimistic inventory locks) and a
  // WRITE-safe failure mapping below.
  static const Duration _bookingTimeout = Duration(seconds: 20);

  /// Creates a real backend booking (`POST /api/bookings`, authenticated).
  /// Returns the server's own booking code / status / pricing — nothing is
  /// fabricated. Because the backend has NO idempotency on create, this method
  /// performs exactly one request and never retries: a timeout or a malformed
  /// success is surfaced as [ApiErrorKind.uncertain] (the write may already have
  /// been committed), NOT as a clean failure the caller could safely resubmit.
  Future<CollectionApiResult<BookingCreateRecord>> createBooking(
    BookingCreatePayload payload,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/bookings'),
            headers: _jsonHeaders,
            body: jsonEncode(payload.toJson()),
          )
          .timeout(_bookingTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          // Success status but unreadable body — the booking may exist.
          return const CollectionApiResult.failure(ApiErrorKind.uncertain);
        }
        return CollectionApiResult.success(BookingCreateRecord.fromJson(body));
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The request may have reached the server and committed — uncertain.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      // Thrown parsing a success body → the booking may exist — uncertain.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  /// Loads the authenticated user's real booking history
  /// (`GET /api/me/bookings`, authenticated). The backend returns a bare JSON
  /// array of `BookingSummaryResponse` — ALL of the caller's bookings sorted
  /// createdAt DESC. There is NO pagination / sort / status query param on this
  /// endpoint, so this sends none and fetches the whole list once.
  Future<CollectionApiResult<List<BookingSummaryRecord>>>
      getMyBookings() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/bookings'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  BookingSummaryRecord.fromJson(e as Map<String, dynamic>))
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

  /// Loads one booking's full detail (`GET /api/bookings/{id}`, authenticated,
  /// owner-only — ADMIN may also read). Returns the same `BookingResponse` shape
  /// as create, so it reuses [BookingCreateRecord]. 403 (not your booking) and
  /// 404 (not found) surface as typed error kinds — never fabricated.
  Future<CollectionApiResult<BookingCreateRecord>> getBookingDetail(
    int id,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/bookings/$id'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(BookingCreateRecord.fromJson(body));
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

  // ── Payments (/api/payments, /api/bookings/{id}/payments, UI-28) ─────────────
  // The backend has NO live payment gateway (checkoutUrl is null on the
  // settlement flow — CLAUDE.md), so there is no redirect to launch. A payment is
  // created PENDING and settled offline via the backend's own mock-success /
  // mock-fail endpoints. All calls are authenticated, 8s timeout, no retry.

  /// Creates a real payment for a booking (`POST /api/payments`, 201). The
  /// backend charges `booking.finalPrice`; [method] is the backend `PaymentMethod`
  /// enum name (default sandbox `MOCK`, as no live gateway is wired).
  Future<CollectionApiResult<RealPaymentRecord>> createPayment(
    int bookingId, {
    String method = 'MOCK',
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/payments'),
            headers: _jsonHeaders,
            body: jsonEncode({'bookingId': bookingId, 'paymentMethod': method}),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPaymentRecord.fromJson(body));
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

  /// Lists the payments for a booking (`GET /api/bookings/{id}/payments`,
  /// owner-only) — a bare JSON array sorted createdAt DESC.
  Future<CollectionApiResult<List<RealPaymentRecord>>> getBookingPayments(
    int bookingId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/bookings/$bookingId/payments'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealPaymentRecord.fromJson(e as Map<String, dynamic>))
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

  /// Fetches one payment's current status (`GET /api/payments/{id}`, owner/admin).
  Future<CollectionApiResult<RealPaymentRecord>> getPayment(int id) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/payments/$id'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPaymentRecord.fromJson(body));
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

  /// Settles a PENDING payment via the backend's own sandbox endpoint
  /// ([success]=true → `mock-success` → PAID + booking CONFIRMED; false →
  /// `mock-fail` → FAILED). These are REAL backend endpoints (the only offline
  /// completion path, as no live gateway exists) — not a fabricated result.
  Future<CollectionApiResult<RealPaymentRecord>> settlePaymentSandbox(
    int id, {
    required bool success,
  }) async {
    final suffix = success ? 'mock-success' : 'mock-fail';
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/payments/$id/$suffix'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPaymentRecord.fromJson(body));
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

  // ── Reviews (/api/reviews, /api/me/reviews, /api/places/{id}/reviews, UI-29) ─
  // Reads are bare JSON arrays. A create returns 201 with the full review, which
  // is PENDING (awaiting moderation). All authenticated, 8s timeout, no retry.

  /// Lists a place's PUBLIC (approved-only) reviews (`GET /api/places/{id}/reviews`).
  Future<CollectionApiResult<List<ReviewSummaryRecord>>> getPlaceReviews(
    int placeId,
  ) =>
      _getReviewList('$baseUrl/places/$placeId/reviews');

  /// Lists the authenticated user's own reviews (`GET /api/me/reviews`).
  Future<CollectionApiResult<List<ReviewSummaryRecord>>> getMyReviews() =>
      _getReviewList('$baseUrl/me/reviews');

  Future<CollectionApiResult<List<ReviewSummaryRecord>>> _getReviewList(
    String url,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  ReviewSummaryRecord.fromJson(e as Map<String, dynamic>))
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

  /// Fetches one review in full (`GET /api/reviews/{id}`, owner or admin).
  Future<CollectionApiResult<ReviewDetailRecord>> getReview(int id) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/reviews/$id'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(ReviewDetailRecord.fromJson(body));
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

  /// Creates a review for a COMPLETED booking (`POST /api/reviews`, 201). The
  /// created review is PENDING (awaiting moderation — not publicly visible until
  /// APPROVED). 422 if the booking is not completed, 409 if it was already
  /// reviewed — surfaced honestly, never fabricated.
  Future<CollectionApiResult<ReviewDetailRecord>> createReview(
    ReviewCreatePayload payload,
  ) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/reviews'),
            headers: _jsonHeaders,
            body: jsonEncode(payload.toJson()),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(ReviewDetailRecord.fromJson(body));
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

  // ── Notifications (/api/me/notifications, UI-30) ─────────────────────────────
  // List is a bare JSON array; mark-read returns the updated notification;
  // mark-all-read and unread-count return a bare number; delete returns 204. All
  // authenticated, 8s timeout, no retry.

  /// Lists the authenticated user's notifications (`GET /api/me/notifications`),
  /// newest first (bare array of NotificationSummaryResponse).
  Future<CollectionApiResult<List<RealNotificationRecord>>>
      getNotifications() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/notifications'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  RealNotificationRecord.fromJson(e as Map<String, dynamic>))
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

  /// Counts unread notifications (`GET /api/me/notifications/unread-count`) — the
  /// backend returns a bare number.
  Future<CollectionApiResult<int>> getUnreadNotificationCount() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/notifications/unread-count'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! num) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(decoded.toInt());
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

  /// Marks one notification read (`PATCH /api/me/notifications/{id}/read`,
  /// owner-only) and returns the updated notification.
  Future<CollectionApiResult<RealNotificationRecord>> markNotificationRead(
    int id,
  ) async {
    try {
      final res = await _client
          .patch(Uri.parse('$baseUrl/me/notifications/$id/read'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
            RealNotificationRecord.fromJson(body));
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

  /// Marks all of the user's notifications read
  /// (`PATCH /api/me/notifications/read-all`) — returns the count updated.
  Future<CollectionApiResult<int>> markAllNotificationsRead() async {
    try {
      final res = await _client
          .patch(Uri.parse('$baseUrl/me/notifications/read-all'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final count = decoded is num ? decoded.toInt() : 0;
        return CollectionApiResult.success(count);
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

  /// Deletes one notification (`DELETE /api/me/notifications/{id}`, 204).
  Future<CollectionApiVoidResult> deleteNotification(int id) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/notifications/$id'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  // ── Recently Viewed (/api/me/recently-viewed, UI-31) ─────────────────────────
  // GET returns a WRAPPED object {items:[...]} (not a bare array), server-sorted
  // viewedAt DESC, capped to 50. Record is a POST; clear/remove are DELETEs (204).
  // All authenticated, 8s timeout, no retry.

  /// Lists the user's recently viewed places (`GET /api/me/recently-viewed`).
  Future<CollectionApiResult<List<RecentlyViewedRecord>>>
      getRecentlyViewed() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/recently-viewed'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        final items = body?['items'];
        if (items is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          items
              .map((e) =>
                  RecentlyViewedRecord.fromJson(e as Map<String, dynamic>))
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

  /// Records (or refreshes) a view of a published place
  /// (`POST /api/me/recently-viewed/{placeId}`, 201). 422 if the place is not
  /// published, 404 if it does not exist — surfaced honestly.
  Future<CollectionApiResult<RecentlyViewedRecord>> recordRecentlyView(
    int placeId,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/recently-viewed/$placeId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RecentlyViewedRecord.fromJson(body));
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

  /// Clears the entire recently-viewed list (`DELETE /api/me/recently-viewed`, 204).
  Future<CollectionApiVoidResult> clearRecentlyViewed() =>
      _deleteRecentlyViewed('$baseUrl/me/recently-viewed');

  /// Removes one place from the list
  /// (`DELETE /api/me/recently-viewed/{placeId}`, 204; 404 if not present).
  Future<CollectionApiVoidResult> removeRecentlyViewed(int placeId) =>
      _deleteRecentlyViewed('$baseUrl/me/recently-viewed/$placeId');

  Future<CollectionApiVoidResult> _deleteRecentlyViewed(String url) async {
    try {
      final res = await _client
          .delete(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  // ── Profile (/api/me, /api/me/profile, UI-32) ────────────────────────────────
  // GET /me → read-only signed-in identity (fullName/email/role). GET /me/profile
  // → travel profile (server lazily creates a default row). PUT /me/profile is
  // FULL-REPLACE: the body must carry every field or the omitted ones are wiped;
  // passportNumber is write-only (echoed back only masked). All authenticated,
  // 8s timeout, no retry.

  /// Reads the signed-in user's identity (`GET /api/me`).
  Future<CollectionApiResult<AccountIdentityRecord>>
      getAccountIdentity() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
            AccountIdentityRecord.fromJson(body));
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

  /// Reads the signed-in user's travel profile (`GET /api/me/profile`).
  Future<CollectionApiResult<CustomerProfileRecord>>
      getCustomerProfile() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/profile'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
            CustomerProfileRecord.fromJson(body));
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

  /// Full-replace update of the travel profile (`PUT /api/me/profile`). Returns
  /// the server's updated (masked) profile — never optimistic.
  Future<CollectionApiResult<CustomerProfileRecord>> updateCustomerProfile(
    CustomerProfileUpdate update,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/profile'),
              headers: _jsonHeaders, body: jsonEncode(update.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
            CustomerProfileRecord.fromJson(body));
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

  // ── Gift Cards (/api/me/gift-cards, UI-33) ───────────────────────────────────
  // Prepaid promotional value only. List + transactions are PageResponse
  // {content,page,size,totalElements,totalPages}. Claim/activate return the full
  // GiftCardResponse (masked code only — the raw fullCode is never stored client
  // side). All authenticated + owner-scoped (non-owned card → 404, not 403). 8s
  // timeout, no retry.

  /// Lists the user's gift cards (`GET /api/me/gift-cards`, paged).
  Future<CollectionApiResult<RealGiftCardsPage>> getMyGiftCards({
    int? page,
    int? size,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/me/gift-cards').replace(
        queryParameters: {
          if (page != null) 'page': '$page',
          if (size != null) 'size': '$size',
        },
      );
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealGiftCardsPage.fromJson(body));
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

  /// Gets one of the user's gift cards by id (`GET /api/me/gift-cards/{id}`).
  Future<CollectionApiResult<RealGiftCardDetail>> getGiftCard(int id) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/gift-cards/$id'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealGiftCardDetail.fromJson(body));
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

  /// Lists the immutable ledger for one gift card
  /// (`GET /api/me/gift-cards/{id}/transactions`, paged).
  Future<CollectionApiResult<RealGiftCardTransactionsPage>>
      getGiftCardTransactions(int id, {int? page, int? size}) async {
    try {
      final uri = Uri.parse('$baseUrl/me/gift-cards/$id/transactions').replace(
        queryParameters: {
          if (page != null) 'page': '$page',
          if (size != null) 'size': '$size',
        },
      );
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealGiftCardTransactionsPage.fromJson(body),
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

  /// Claims an email-issued gift card by its code and activates it
  /// (`POST /api/me/gift-cards/claim`, idempotent). Returns the claimed card.
  Future<CollectionApiResult<RealGiftCardDetail>> claimGiftCard(
    String code,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/gift-cards/claim'),
              headers: _jsonHeaders, body: jsonEncode({'code': code}))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealGiftCardDetail.fromJson(body));
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

  /// Activates an ISSUED gift card the user owns
  /// (`POST /api/me/gift-cards/{id}/activate`, idempotent).
  Future<CollectionApiResult<RealGiftCardDetail>> activateGiftCard(
    int id,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/gift-cards/$id/activate'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealGiftCardDetail.fromJson(body));
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

  // ── Loyalty (/api/me/loyalty, UI-34) ─────────────────────────────────────────
  // Customer READ-ONLY: account (balance + lifetime earned, created lazily) and
  // an immutable transaction ledger (PageResponse, createdAt DESC). No customer
  // mutation exists. All authenticated + owner-scoped. 8s timeout, no retry.

  /// Reads the user's loyalty account (`GET /api/me/loyalty`).
  Future<CollectionApiResult<RealLoyaltyAccount>> getLoyaltyAccount() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/loyalty'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealLoyaltyAccount.fromJson(body));
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

  /// Lists the user's loyalty transactions
  /// (`GET /api/me/loyalty/transactions`, paged).
  Future<CollectionApiResult<RealLoyaltyTransactionsPage>>
      getLoyaltyTransactions({int? page, int? size}) async {
    try {
      final uri = Uri.parse('$baseUrl/me/loyalty/transactions').replace(
        queryParameters: {
          if (page != null) 'page': '$page',
          if (size != null) 'size': '$size',
        },
      );
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealLoyaltyTransactionsPage.fromJson(body),
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

  // ── Travel Credits (/api/me/travel-credits, UI-35) ───────────────────────────
  // Customer READ-ONLY: account (balance + currency, created lazily) and an
  // immutable transaction ledger (PageResponse, createdAt DESC). No customer
  // mutation exists. All authenticated + owner-scoped. 8s timeout, no retry.

  /// Reads the user's travel-credit account (`GET /api/me/travel-credits`).
  Future<CollectionApiResult<RealTravelCreditAccount>>
      getTravelCreditAccount() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/travel-credits'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealTravelCreditAccount.fromJson(body),
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

  /// Lists the user's travel-credit transactions
  /// (`GET /api/me/travel-credits/transactions`, paged).
  Future<CollectionApiResult<RealTravelCreditTransactionsPage>>
      getTravelCreditTransactions({int? page, int? size}) async {
    try {
      final uri = Uri.parse('$baseUrl/me/travel-credits/transactions').replace(
        queryParameters: {
          if (page != null) 'page': '$page',
          if (size != null) 'size': '$size',
        },
      );
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealTravelCreditTransactionsPage.fromJson(body),
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

  // ── Membership (/api/me/membership, UI-36) ───────────────────────────────────
  // Customer: idempotent enroll (POST, 201) + read-only membership (404 if never
  // enrolled), live progress preview, benefits (bare array), tier history (bare
  // array, newest first). All authenticated + owner-scoped. 8s timeout, no retry.

  /// Reads my membership (`GET /api/me/membership`; 404 when never enrolled).
  Future<CollectionApiResult<RealMembership>> getMembership() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/membership'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealMembership.fromJson(body));
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

  /// Reads my qualification progress (`GET /api/me/membership/progress`).
  Future<CollectionApiResult<RealMembershipProgress>>
      getMembershipProgress() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/membership/progress'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealMembershipProgress.fromJson(body),
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

  /// Lists benefit metadata for my effective tier
  /// (`GET /api/me/membership/benefits`, a bare array).
  Future<CollectionApiResult<List<RealMembershipBenefit>>>
      getMembershipBenefits() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/membership/benefits'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  RealMembershipBenefit.fromJson(e as Map<String, dynamic>))
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

  /// Lists my immutable tier-change history
  /// (`GET /api/me/membership/history`, a bare array, newest first).
  Future<CollectionApiResult<List<RealMembershipHistoryItem>>>
      getMembershipHistory() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/membership/history'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  RealMembershipHistoryItem.fromJson(e as Map<String, dynamic>))
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

  /// Enrolls me in membership (`POST /api/me/membership/enroll`, 201; idempotent).
  /// 400 when there is no active loyalty account.
  Future<CollectionApiResult<RealMembership>> enrollMembership() async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/membership/enroll'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealMembership.fromJson(body));
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

  // ── Referral (/api/me/referral, UI-37) ───────────────────────────────────────
  // Customer: my code + stats (lazy-created), history (bare array, inviter +
  // invitee), and use-a-code (POST). The customer DTO carries no reward amount —
  // only status. All authenticated + owner-scoped. 8s timeout, no retry.

  /// Reads my referral code + basic stats (`GET /api/me/referral`).
  Future<CollectionApiResult<RealReferralSummary>> getReferral() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/referral'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealReferralSummary.fromJson(body));
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

  /// Lists my referral activity (`GET /api/me/referral/history`, a bare array).
  Future<CollectionApiResult<List<RealReferralReward>>>
      getReferralHistory() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/referral/history'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map(
                  (e) => RealReferralReward.fromJson(e as Map<String, dynamic>))
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

  /// Uses another user's referral code (`POST /api/me/referral/use`). 404 if the
  /// code is unknown, 400 if it is your own, 409 if you already used one.
  Future<CollectionApiResult<RealReferralReward>> useReferralCode(
    String code,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/referral/use'),
              headers: _jsonHeaders, body: jsonEncode({'code': code}))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealReferralReward.fromJson(body));
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

  // ── Coupons (/api/me/coupons, UI-38) ─────────────────────────────────────────
  // Customer: list my claimed coupons (bare array, createdAt DESC), get one, and
  // claim by code. No checkout/apply integration exists (preview/eligibility are
  // deferred — they require order/booking context). All authenticated +
  // owner-scoped. 8s timeout, no retry.

  /// Lists my claimed coupons (`GET /api/me/coupons`, a bare array).
  Future<CollectionApiResult<List<RealCoupon>>> getCoupons() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/coupons'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealCoupon.fromJson(e as Map<String, dynamic>))
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

  /// Gets one of my claimed coupons (`GET /api/me/coupons/{id}`; 404 if not mine).
  Future<CollectionApiResult<RealCoupon>> getCoupon(int id) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/coupons/$id'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealCoupon.fromJson(body));
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

  /// Claims a coupon by code (`POST /api/me/coupons/claim`, 201). 404 unknown,
  /// 400 inactive/expired/not-yet-valid, 409 usage limit reached.
  Future<CollectionApiResult<RealCoupon>> claimCoupon(String code) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/coupons/claim'),
              headers: _jsonHeaders, body: jsonEncode({'code': code}))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealCoupon.fromJson(body));
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

  // ── Recommendations (/api/me/recommendations, UI-39) ─────────────────────────
  // Phase 7.23 personalized feed. GET list → PageResponse (paged, active-only by
  // default). GET /{id} → one snapshot (404 if not mine). POST /generate →
  // regenerate (read-only snapshots; never claims/reserves). PATCH /{id}/dismiss
  // and /{id}/click update engagement (idempotent). All authenticated, 8s
  // timeout, no retry.

  /// Lists the user's active recommendations
  /// (`GET /api/me/recommendations`, paged, score desc).
  Future<CollectionApiResult<RealRecommendationPage>> getRecommendations({
    int? page,
    int? size,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/me/recommendations').replace(
        queryParameters: {
          if (page != null) 'page': '$page',
          if (size != null) 'size': '$size',
        },
      );
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealRecommendationPage.fromJson(body),
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

  /// Gets one of the user's recommendations
  /// (`GET /api/me/recommendations/{id}`, 404 if not mine).
  Future<CollectionApiResult<RealRecommendation>> getRecommendation(
    int id,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/recommendations/$id'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealRecommendation.fromJson(body));
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

  /// Regenerates the user's active recommendations
  /// (`POST /api/me/recommendations/generate`). Read-only snapshots — never
  /// claims/reserves anything. Returns the number newly generated.
  Future<CollectionApiResult<int>> generateRecommendations() async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/recommendations/generate'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          (body['generatedCount'] as num?)?.toInt() ?? 0,
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

  /// Dismisses a recommendation (`PATCH /api/me/recommendations/{id}/dismiss`),
  /// hiding it from the default feed (404 if not mine).
  Future<CollectionApiResult<RealRecommendation>> dismissRecommendation(
    int id,
  ) =>
      _patchRecommendation('$baseUrl/me/recommendations/$id/dismiss');

  /// Tracks a click on a recommendation
  /// (`PATCH /api/me/recommendations/{id}/click`, idempotent).
  Future<CollectionApiResult<RealRecommendation>> clickRecommendation(
    int id,
  ) =>
      _patchRecommendation('$baseUrl/me/recommendations/$id/click');

  Future<CollectionApiResult<RealRecommendation>> _patchRecommendation(
    String url,
  ) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealRecommendation.fromJson(body));
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

  // ── Trip Expenses (/api/me/trips/.../expenses, UI-40) ────────────────────────
  // Phase 7 Trip Budget & Expenses. Expenses hang off a real TripPlan (UI-20).
  // GET list → bare array (newest expenseDate first). POST create (201), PUT
  // update, DELETE (204). GET budget-summary → server-computed totals. Reads need
  // owner/collaborator; mutations need owner/EDITOR (403 for a VIEWER). All
  // authenticated, 8s timeout, no retry.

  /// Lists a trip's expenses (`GET /api/me/trips/{tripId}/expenses`).
  Future<CollectionApiResult<List<RealExpense>>> getTripExpenses(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/expenses'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealExpense.fromJson(e as Map<String, dynamic>))
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

  /// Gets a trip's budget-vs-actual summary
  /// (`GET /api/me/trips/{tripId}/budget-summary`).
  Future<CollectionApiResult<RealExpenseSummary>> getTripBudgetSummary(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/budget-summary'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealExpenseSummary.fromJson(body));
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

  // ── Trip Budget entity (/api/me/trips/.../budget, UI-47) ─────────────────────
  // The single per-trip budget row. GET → 404 when unset; PUT create-or-update
  // (owner-only, 403 for a non-owner collaborator); DELETE (204, owner-only).
  // Spent/remaining/over-budget come from getTripBudgetSummary above. All
  // authenticated, 8s timeout, no retry.

  /// Gets a trip's budget (`GET /api/me/trips/{tripId}/budget`); 404 when unset.
  Future<CollectionApiResult<RealBudget>> getBudget(int tripId) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/budget'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealBudget.fromJson(body));
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

  /// Creates or updates a trip's budget
  /// (`PUT /api/me/trips/{tripId}/budget`, owner-only).
  Future<CollectionApiResult<RealBudget>> upsertBudget(
    int tripId,
    RealBudgetPayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/$tripId/budget'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealBudget.fromJson(body));
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

  /// Deletes a trip's budget
  /// (`DELETE /api/me/trips/{tripId}/budget`, 204, owner-only).
  Future<CollectionApiVoidResult> deleteBudget(int tripId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/$tripId/budget'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Adds an expense to a trip
  /// (`POST /api/me/trips/{tripId}/expenses`, 201).
  Future<CollectionApiResult<RealExpense>> createTripExpense(
    int tripId,
    RealExpensePayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/expenses'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealExpense.fromJson(body));
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

  /// Updates an expense (`PUT /api/me/trips/expenses/{expenseId}`).
  Future<CollectionApiResult<RealExpense>> updateTripExpense(
    int expenseId,
    RealExpensePayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/expenses/$expenseId'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealExpense.fromJson(body));
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

  /// Deletes an expense (`DELETE /api/me/trips/expenses/{expenseId}`, 204).
  Future<CollectionApiVoidResult> deleteTripExpense(int expenseId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/expenses/$expenseId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  // ── Conversations (/api/me/conversations, UI-41) ─────────────────────────────
  // Guest↔partner messaging about a booking. GET list → bare array (lastMessageAt
  // desc). GET /{id} → thread with messages (createdAt asc). POST create (201,
  // reuses an existing thread for the booking). POST /{id}/messages (201). PATCH
  // /{id}/read and /{id}/close → updated conversation. No websocket/realtime; the
  // client refreshes on demand. All authenticated, 8s timeout, no retry.

  /// Lists the user's conversations (`GET /api/me/conversations`).
  Future<CollectionApiResult<List<RealConversationSummary>>>
      getConversations() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/conversations'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) =>
                  RealConversationSummary.fromJson(e as Map<String, dynamic>))
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

  /// Gets one conversation with its messages
  /// (`GET /api/me/conversations/{id}`, 403 if not mine).
  Future<CollectionApiResult<RealConversation>> getConversation(
    int id,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/conversations/$id'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealConversation.fromJson(body));
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

  /// Starts (or reuses) a conversation for one of the user's bookings
  /// (`POST /api/me/conversations`, 201). 404 booking not found, 403 not the
  /// booking owner, 422 the hotel has no partner to message.
  Future<CollectionApiResult<RealConversation>> createConversation(
    int bookingId, {
    String? subject,
  }) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/conversations'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'bookingId': bookingId,
                if (subject != null && subject.isNotEmpty) 'subject': subject,
              }))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealConversation.fromJson(body));
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

  /// Sends a message as the guest
  /// (`POST /api/me/conversations/{id}/messages`, 201). 422 if the thread is
  /// archived, 400 if the body is blank.
  Future<CollectionApiResult<RealMessage>> sendConversationMessage(
    int id,
    String body,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/conversations/$id/messages'),
              headers: _jsonHeaders, body: jsonEncode({'body': body}))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = _decodeJsonMap(res).data;
        if (data == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealMessage.fromJson(data));
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

  /// Marks the user's incoming messages read
  /// (`PATCH /api/me/conversations/{id}/read`).
  Future<CollectionApiResult<RealConversation>> markConversationRead(
    int id,
  ) =>
      _patchConversation('$baseUrl/me/conversations/$id/read');

  /// Closes a conversation (`PATCH /api/me/conversations/{id}/close`).
  Future<CollectionApiResult<RealConversation>> closeConversation(int id) =>
      _patchConversation('$baseUrl/me/conversations/$id/close');

  Future<CollectionApiResult<RealConversation>> _patchConversation(
    String url,
  ) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealConversation.fromJson(body));
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

  // ── AI Context (/api/me/ai/context, UI-42) ───────────────────────────────────
  // A single read-only aggregate snapshot (no persistence, no AI generation).
  // Authenticated, 8s timeout, no retry.

  /// Reads the user's aggregated AI trip context (`GET /api/me/ai/context`).
  Future<CollectionApiResult<RealAiContext>> getAiContext() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/ai/context'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealAiContext.fromJson(body));
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

  // ── Trip Documents (/api/me/trips/.../documents, UI-43) ──────────────────────
  // Documents attach to a real TripPlan (UI-20). GET list → bare array (pinned
  // first, then newest). POST create (201; url registers a new media asset), PUT
  // update (metadata only), DELETE (204), PATCH pin/unpin. Reads need
  // owner/collaborator; mutations need owner/EDITOR (403 for a VIEWER). All
  // authenticated, 8s timeout, no retry.

  /// Lists a trip's documents (`GET /api/me/trips/{tripId}/documents`).
  Future<CollectionApiResult<List<RealTripDocument>>> getTripDocuments(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/documents'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealTripDocument.fromJson(e as Map<String, dynamic>))
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

  /// Attaches a document to a trip
  /// (`POST /api/me/trips/{tripId}/documents`, 201).
  Future<CollectionApiResult<RealTripDocument>> createTripDocument(
    int tripId,
    RealTripDocumentPayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/documents'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripDocument.fromJson(body));
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

  /// Updates a document's metadata
  /// (`PUT /api/me/trips/documents/{id}`).
  Future<CollectionApiResult<RealTripDocument>> updateTripDocument(
    int documentId,
    RealTripDocumentPayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/documents/$documentId'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripDocument.fromJson(body));
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

  /// Deletes a document (`DELETE /api/me/trips/documents/{id}`, 204).
  Future<CollectionApiVoidResult> deleteTripDocument(int documentId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/documents/$documentId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Pins a document (`PATCH /api/me/trips/documents/{id}/pin`).
  Future<CollectionApiResult<RealTripDocument>> pinTripDocument(
    int documentId,
  ) =>
      _patchTripDocument('$baseUrl/me/trips/documents/$documentId/pin');

  /// Unpins a document (`PATCH /api/me/trips/documents/{id}/unpin`).
  Future<CollectionApiResult<RealTripDocument>> unpinTripDocument(
    int documentId,
  ) =>
      _patchTripDocument('$baseUrl/me/trips/documents/$documentId/unpin');

  Future<CollectionApiResult<RealTripDocument>> _patchTripDocument(
    String url,
  ) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripDocument.fromJson(body));
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

  // ── Trip Notes (/api/me/trips/.../notes, UI-44) ──────────────────────────────
  // Notes attach to a real TripPlan (UI-20). GET list → bare array (pinned first,
  // then newest updated). POST create (201), PUT update, DELETE (204), PATCH
  // pin/unpin. Reads need owner/collaborator; mutations need owner/EDITOR (403
  // for a VIEWER). All authenticated, 8s timeout, no retry.

  /// Lists a trip's notes (`GET /api/me/trips/{tripId}/notes`).
  Future<CollectionApiResult<List<RealTripNote>>> getTripNotes(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/notes'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealTripNote.fromJson(e as Map<String, dynamic>))
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

  /// Adds a note to a trip (`POST /api/me/trips/{tripId}/notes`, 201).
  Future<CollectionApiResult<RealTripNote>> createTripNote(
    int tripId,
    RealTripNotePayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/notes'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripNote.fromJson(body));
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

  /// Updates a note (`PUT /api/me/trips/notes/{id}`).
  Future<CollectionApiResult<RealTripNote>> updateTripNote(
    int noteId,
    RealTripNotePayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/notes/$noteId'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripNote.fromJson(body));
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

  /// Deletes a note (`DELETE /api/me/trips/notes/{id}`, 204).
  Future<CollectionApiVoidResult> deleteTripNote(int noteId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/notes/$noteId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Pins a note (`PATCH /api/me/trips/notes/{id}/pin`).
  Future<CollectionApiResult<RealTripNote>> pinTripNote(int noteId) =>
      _patchTripNote('$baseUrl/me/trips/notes/$noteId/pin');

  /// Unpins a note (`PATCH /api/me/trips/notes/{id}/unpin`).
  Future<CollectionApiResult<RealTripNote>> unpinTripNote(int noteId) =>
      _patchTripNote('$baseUrl/me/trips/notes/$noteId/unpin');

  Future<CollectionApiResult<RealTripNote>> _patchTripNote(String url) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripNote.fromJson(body));
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

  // ── Trip Packing (/api/me/trips/.../packing, UI-45) ──────────────────────────
  // Per-trip packing checklist on a real TripPlan (UI-20). GET list → bare array
  // (unchecked first, then sortOrder). POST create (201), PUT update, DELETE
  // (204), PATCH check/uncheck. Reads need owner/collaborator; mutations need
  // owner/EDITOR (403 for a VIEWER). All authenticated, 8s timeout, no retry.

  /// Lists a trip's packing checklist (`GET /api/me/trips/{tripId}/packing`).
  Future<CollectionApiResult<List<RealPackingItem>>> getPackingItems(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/packing'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealPackingItem.fromJson(e as Map<String, dynamic>))
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

  /// Adds a packing item (`POST /api/me/trips/{tripId}/packing`, 201).
  Future<CollectionApiResult<RealPackingItem>> createPackingItem(
    int tripId,
    RealPackingItemPayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/packing'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPackingItem.fromJson(body));
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

  /// Updates a packing item (`PUT /api/me/trips/packing/{id}`).
  Future<CollectionApiResult<RealPackingItem>> updatePackingItem(
    int itemId,
    RealPackingItemPayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/packing/$itemId'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPackingItem.fromJson(body));
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

  /// Deletes a packing item (`DELETE /api/me/trips/packing/{id}`, 204).
  Future<CollectionApiVoidResult> deletePackingItem(int itemId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/packing/$itemId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Marks a packing item checked (`PATCH /api/me/trips/packing/{id}/check`).
  Future<CollectionApiResult<RealPackingItem>> checkPackingItem(int itemId) =>
      _patchPackingItem('$baseUrl/me/trips/packing/$itemId/check');

  /// Marks a packing item unchecked (`PATCH /api/me/trips/packing/{id}/uncheck`).
  Future<CollectionApiResult<RealPackingItem>> uncheckPackingItem(int itemId) =>
      _patchPackingItem('$baseUrl/me/trips/packing/$itemId/uncheck');

  Future<CollectionApiResult<RealPackingItem>> _patchPackingItem(
    String url,
  ) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealPackingItem.fromJson(body));
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

  // ── Trip Reminders (/api/me/trips/.../reminders, UI-46) ──────────────────────
  // Per-trip in-app reminder records on a real TripPlan (UI-20). GET list → bare
  // array (reminderAt ASC, CANCELLED hidden unless includeCancelled=true). POST
  // create (201), PUT update, PATCH complete/cancel (no body), DELETE (204).
  // Reads need owner/collaborator; mutations need owner/EDITOR (403 for a
  // VIEWER). No delivery/scheduler exists — storage + CRUD only. All
  // authenticated, 8s timeout, no retry.

  /// Lists a trip's reminders (`GET /api/me/trips/{tripId}/reminders`), soonest
  /// first. Cancelled reminders are hidden unless [includeCancelled] is true.
  Future<CollectionApiResult<List<RealReminder>>> getReminders(
    int tripId, {
    bool includeCancelled = false,
  }) async {
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/me/trips/$tripId/reminders')
                .replace(queryParameters: {
              'includeCancelled': includeCancelled.toString(),
            }),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealReminder.fromJson(e as Map<String, dynamic>))
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

  /// Adds a reminder (`POST /api/me/trips/{tripId}/reminders`, 201).
  Future<CollectionApiResult<RealReminder>> createReminder(
    int tripId,
    RealReminderPayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/reminders'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealReminder.fromJson(body));
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

  /// Updates a reminder (`PUT /api/me/trips/reminders/{id}`).
  Future<CollectionApiResult<RealReminder>> updateReminder(
    int reminderId,
    RealReminderPayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/trips/reminders/$reminderId'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealReminder.fromJson(body));
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

  /// Deletes a reminder (`DELETE /api/me/trips/reminders/{id}`, 204).
  Future<CollectionApiVoidResult> deleteReminder(int reminderId) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/trips/reminders/$reminderId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Marks a reminder completed (`PATCH /api/me/trips/reminders/{id}/complete`).
  Future<CollectionApiResult<RealReminder>> completeReminder(int reminderId) =>
      _patchReminder('$baseUrl/me/trips/reminders/$reminderId/complete');

  /// Cancels a reminder (`PATCH /api/me/trips/reminders/{id}/cancel`).
  Future<CollectionApiResult<RealReminder>> cancelReminder(int reminderId) =>
      _patchReminder('$baseUrl/me/trips/reminders/$reminderId/cancel');

  Future<CollectionApiResult<RealReminder>> _patchReminder(String url) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealReminder.fromJson(body));
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

  // ── Trip Collaboration (/api/me/trips/.../collaborators, UI-48) ──────────────
  // Owner-only collaborator management + public/private toggle on a real
  // TripPlan (UI-20). GET list → bare array (createdAt ASC). POST invite (201),
  // PATCH role, DELETE (204). PATCH public/private → share state. Every
  // operation here is owner-only (403 for a collaborator, 404 for a stranger).
  // All authenticated, 8s timeout, no retry.

  /// Lists a trip's collaborators
  /// (`GET /api/me/trips/{tripId}/collaborators`, owner-only).
  Future<CollectionApiResult<List<RealCollaborator>>> getCollaborators(
    int tripId,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/$tripId/collaborators'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealCollaborator.fromJson(e as Map<String, dynamic>))
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

  /// Lists trips shared with the authenticated user as an active collaborator
  /// (`GET /api/me/trips/shared`, createdAt DESC).
  Future<CollectionApiResult<List<RealSharedTrip>>> getSharedTrips() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/trips/shared'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealSharedTrip.fromJson(e as Map<String, dynamic>))
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

  // ── Interest Profile (/api/me/interests, UI-52) ──────────────────────────

  /// Fetches the authenticated user's derived interest profile
  /// (`GET /api/me/interests`). Returns an empty snapshot until the first
  /// recalculation; own-scoped (401 unauthenticated).
  Future<CollectionApiResult<RealInterestProfile>> getInterestProfile() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/interests'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! Map<String, dynamic>) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealInterestProfile.fromJson(decoded),
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

  /// Re-derives the authenticated user's interest profile from their current
  /// bookings/wishlist/collections/reviews (`POST /api/me/interests/recalculate`,
  /// no body). Deterministic backend aggregation; returns the refreshed profile.
  Future<CollectionApiResult<RealInterestProfile>>
      recalculateInterestProfile() async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/me/interests/recalculate'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! Map<String, dynamic>) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          RealInterestProfile.fromJson(decoded),
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

  /// Invites a collaborator by email
  /// (`POST /api/me/trips/{tripId}/collaborators`, 201, owner-only).
  Future<CollectionApiResult<RealCollaborator>> inviteCollaborator(
    int tripId,
    RealCollaboratorPayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/trips/$tripId/collaborators'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealCollaborator.fromJson(body));
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

  /// Updates a collaborator's role
  /// (`PATCH /api/me/trips/{tripId}/collaborators/{collaboratorId}`, owner-only).
  Future<CollectionApiResult<RealCollaborator>> updateCollaboratorRole(
    int tripId,
    int collaboratorId,
    RealCollaboratorPayload payload,
  ) async {
    try {
      final res = await _client
          .patch(
              Uri.parse(
                  '$baseUrl/me/trips/$tripId/collaborators/$collaboratorId'),
              headers: _jsonHeaders,
              body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealCollaborator.fromJson(body));
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

  /// Removes a collaborator
  /// (`DELETE /api/me/trips/{tripId}/collaborators/{collaboratorId}`, 204,
  /// owner-only).
  Future<CollectionApiVoidResult> removeCollaborator(
    int tripId,
    int collaboratorId,
  ) async {
    try {
      final res = await _client
          .delete(
              Uri.parse(
                  '$baseUrl/me/trips/$tripId/collaborators/$collaboratorId'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Toggles a trip's public visibility
  /// (`PATCH /api/me/trips/{tripId}/public` or `.../private`, owner-only).
  Future<CollectionApiResult<RealTripShare>> setTripPublic(
    int tripId,
    bool makePublic,
  ) async {
    try {
      final res = await _client
          .patch(
              Uri.parse(
                  '$baseUrl/me/trips/$tripId/${makePublic ? 'public' : 'private'}'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealTripShare.fromJson(body));
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

  // ── Travel Wallet (/api/me/travel-wallet, UI-50) ─────────────────────────────
  // Per-user organizer of documents/vouchers/tickets. GET list → bare array
  // (default sort). POST create (201), PUT update, DELETE (204). PATCH
  // favorite/unfavorite/archive/restore. Every item is strictly owner-only
  // (404 for a non-owner or missing id — never 403). All authenticated, 8s
  // timeout, no retry.

  /// Lists my wallet items (`GET /api/me/travel-wallet`, default sort).
  Future<CollectionApiResult<List<RealWalletItem>>> getWalletItems() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/me/travel-wallet'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          decoded
              .map((e) => RealWalletItem.fromJson(e as Map<String, dynamic>))
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

  /// Creates a wallet item (`POST /api/me/travel-wallet`, 201).
  Future<CollectionApiResult<RealWalletItem>> createWalletItem(
    RealWalletItemPayload payload,
  ) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl/me/travel-wallet'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealWalletItem.fromJson(body));
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

  /// Updates a wallet item's metadata (`PUT /api/me/travel-wallet/{id}`).
  Future<CollectionApiResult<RealWalletItem>> updateWalletItem(
    int id,
    RealWalletItemPayload payload,
  ) async {
    try {
      final res = await _client
          .put(Uri.parse('$baseUrl/me/travel-wallet/$id'),
              headers: _jsonHeaders, body: jsonEncode(payload.toJson()))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(RealWalletItem.fromJson(body));
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

  /// Hard-deletes a wallet item (`DELETE /api/me/travel-wallet/{id}`, 204).
  Future<CollectionApiVoidResult> deleteWalletItem(int id) async {
    try {
      final res = await _client
          .delete(Uri.parse('$baseUrl/me/travel-wallet/$id'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  /// Marks a wallet item favorite (`PATCH /travel-wallet/{id}/favorite`).
  Future<CollectionApiVoidResult> favoriteWalletItem(int id) =>
      _patchWalletItem('$baseUrl/me/travel-wallet/$id/favorite');

  /// Unmarks a wallet item favorite (`PATCH /travel-wallet/{id}/unfavorite`).
  Future<CollectionApiVoidResult> unfavoriteWalletItem(int id) =>
      _patchWalletItem('$baseUrl/me/travel-wallet/$id/unfavorite');

  /// Archives a wallet item (`PATCH /travel-wallet/{id}/archive`).
  Future<CollectionApiVoidResult> archiveWalletItem(int id) =>
      _patchWalletItem('$baseUrl/me/travel-wallet/$id/archive');

  /// Restores an archived wallet item (`PATCH /travel-wallet/{id}/restore`).
  Future<CollectionApiVoidResult> restoreWalletItem(int id) =>
      _patchWalletItem('$baseUrl/me/travel-wallet/$id/restore');

  Future<CollectionApiVoidResult> _patchWalletItem(String url) async {
    try {
      final res = await _client
          .patch(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
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

  // ── Partner Extranet (/api/partner/**, C0 foundation) ───────────────────
  //
  // Read-only endpoints only. Every one of these already exists in the backend
  // (`Partner*Controller`) — nothing here is speculative. Authorization is
  // enforced server-side twice over: `SecurityConfig` gates `/api/partner/**`
  // on `hasAnyRole("PARTNER","ADMIN")`, and each partner service then
  // self-scopes via `partnerProfileRepo.findByUserId(uid)`. The client's role
  // check is UX routing only and grants nothing.
  //
  // Status codes these can return, and what they mean:
  //   401 — no/expired token.
  //   403 — role admitted but the partner profile is not APPROVED
  //         (`requireApproved`), or the caller's PartnerTeamRole is too low.
  //   404 — the caller has no partner profile at all (and, for the extranet
  //         endpoints, also when the caller is only a *team member* rather than
  //         the profile owner — see `PartnerState` for how that is handled).

  /// Fetches the caller's own partner profile (`GET /api/partner/profile`).
  ///
  /// This is the one partner route `SecurityConfig` gates as merely
  /// `authenticated` rather than `hasAnyRole("PARTNER","ADMIN")`, because it is
  /// also the onboarding entry point. A caller with no profile gets 404, which
  /// is a legitimate state, not an error.
  Future<CollectionApiResult<PartnerProfile>> getPartnerProfile() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/partner/profile'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final profile = PartnerProfile.fromJson(body);
        if (profile == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(profile);
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

  /// Fetches the partner workspace overview
  /// (`GET /api/partner/extranet/home`) — profile summary plus the operational
  /// counts the dashboard renders. Requires an APPROVED profile owned by the
  /// caller; `PartnerExtranetService` is owner-only by design.
  Future<CollectionApiResult<PartnerWorkspaceOverview>>
      getPartnerWorkspaceOverview() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/partner/extranet/home'),
              headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(
          PartnerWorkspaceOverview.fromJson(body),
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

  /// Lists the properties the caller is authorized to operate
  /// (`GET /api/partner/hotels`, bare array). This is the workspace's property
  /// scope — the client never widens it, and never asks for a property the
  /// backend did not return here.
  Future<CollectionApiResult<List<PartnerProperty>>>
      getPartnerProperties() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/partner/hotels'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final properties = <PartnerProperty>[];
        for (final entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final property = PartnerProperty.fromJson(entry);
          if (property != null) properties.add(property);
        }
        return CollectionApiResult.success(properties);
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

  /// Lists the caller's partner team (`GET /api/partner/team`, bare array).
  ///
  /// `PartnerSettingsService.resolveAccess` is the only partner resolver that
  /// is team-aware, so this is also the sole way the client can learn a
  /// non-owner's `PartnerTeamRole`. Used for permission-aware UX only.
  Future<CollectionApiResult<List<PartnerTeamMember>>>
      getPartnerTeamMembers() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/partner/team'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final members = <PartnerTeamMember>[];
        for (final entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final member = PartnerTeamMember.fromJson(entry);
          if (member != null) members.add(member);
        }
        return CollectionApiResult.success(members);
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

  // ── Partner Dashboard (C1) ──────────────────────────────────────────────
  //
  // All read-only, all verified present in backend-v1/develop. Scope rules:
  //   * `/partner/dashboard` takes NO parameters — `PartnerBookingService`
  //     computes it over every owned hotel, anchored on today.
  //   * `/partner/analytics/**` and `/partner/finance/overview` accept
  //     `hotelId`, `from` and `to`. `hotelId` must be one the backend already
  //     returned from `/partner/hotels`; an unowned id is a uniform 404.
  //     `from` after `to` is a 400 (`resolveRange`).
  //   * `/partner/extranet/**` take no parameters and are owner-only.
  //
  // Every one of these returns 404 when the caller has no partner profile and
  // 403 when the profile is not APPROVED (`myApprovedProfileOrThrow`).

  /// Builds the `hotelId` / `from` / `to` query the analytics and finance
  /// endpoints accept. Dates are sent as ISO `yyyy-MM-dd`, matching the
  /// controllers' `@DateTimeFormat(iso = DATE)`.
  Map<String, String> _partnerScopeQuery({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      {
        if (hotelId != null) 'hotelId': '$hotelId',
        if (from != null) 'from': _isoDate(from),
        if (to != null) 'to': _isoDate(to),
      };

  Uri _partnerUri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  /// Shared request/decode path for the partner GETs that return a JSON object.
  Future<CollectionApiResult<T>> _partnerGetObject<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(parse(body));
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

  /// Shared request/decode path for the partner GETs that return a bare array.
  Future<CollectionApiResult<List<T>>> _partnerGetList<T>(
    Uri uri,
    T? Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final res = await _client
          .get(uri, headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! List) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final items = <T>[];
        for (final entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final item = parse(entry);
          if (item != null) items.add(item);
        }
        return CollectionApiResult.success(items);
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

  /// `GET /api/partner/dashboard` — today's booking operations across every
  /// owned hotel. Takes no parameters by design (see `PartnerBookingService`).
  Future<CollectionApiResult<PartnerBookingDashboard>>
      getPartnerBookingDashboard() => _partnerGetObject(
          _partnerUri('/partner/dashboard'), PartnerBookingDashboard.fromJson);

  /// `GET /api/partner/analytics/overview` for the given scope.
  Future<CollectionApiResult<PartnerAnalyticsOverview>>
      getPartnerAnalyticsOverview({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/overview',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerAnalyticsOverview.fromJson,
          );

  /// `GET /api/partner/analytics/occupancy` for the given scope.
  Future<CollectionApiResult<PartnerOccupancyAnalytics>>
      getPartnerOccupancyAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/occupancy',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerOccupancyAnalytics.fromJson,
          );

  /// `GET /api/partner/analytics/revenue` for the given scope.
  Future<CollectionApiResult<PartnerRevenueAnalytics>>
      getPartnerRevenueAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/revenue',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerRevenueAnalytics.fromJson,
          );

  /// `GET /api/partner/finance/overview` for the given scope.
  ///
  /// Only called when the dashboard scope differs from the default; at the
  /// default scope the identical record is already embedded in
  /// `/partner/extranet/home` as `financeSummary`.
  Future<CollectionApiResult<PartnerFinanceOverview>>
      getPartnerFinanceOverview({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/finance/overview',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerFinanceOverview.fromJson,
          );

  /// `GET /api/partner/extranet/activity-logs` — the caller's own audit trail,
  /// newest first (`findByPartnerProfileIdOrderByCreatedAtDesc`).
  Future<CollectionApiResult<List<PartnerActivityLogEntry>>>
      getPartnerActivityLogs() => _partnerGetList(
            _partnerUri('/partner/extranet/activity-logs'),
            PartnerActivityLogEntry.fromJson,
          );

  /// `GET /api/partner/extranet/menu` — the backend's own navigation contract:
  /// key, label, route, enabled and a nullable badge count per entry.
  Future<CollectionApiResult<List<PartnerMenuItem>>> getPartnerMenu() async {
    final result = await _partnerGetObject<List<PartnerMenuItem>>(
      _partnerUri('/partner/extranet/menu'),
      (body) {
        final sections = body['sections'];
        if (sections is! List) return const <PartnerMenuItem>[];
        final items = <PartnerMenuItem>[];
        for (final entry in sections) {
          if (entry is! Map<String, dynamic>) continue;
          final item = PartnerMenuItem.fromJson(entry);
          if (item != null) items.add(item);
        }
        return items;
      },
    );
    return result;
  }

  // ── Partner Properties (C2) ─────────────────────────────────────────────
  //
  // `PartnerHotelController` exposes GET list, GET detail, four PUT edit
  // endpoints and PATCH activate/deactivate. There is **no create and no
  // delete** — a partner's properties are assigned to them by an admin
  // (`PartnerPropertyService.assignOwner`), so no client-side create exists.
  //
  // Ownership: every method resolves through
  // `ownedPlaceOrThrow` → `places.findByIdAndOwnerId`, which returns a uniform
  // 404 for an unknown id AND for a real property owned by someone else. That
  // is deliberate — it leaks no existence. Verified against the running
  // backend: place id 2 is publicly readable at /api/places/2 (200) yet
  // /api/partner/hotels/2 returns 404 for a partner who does not own it.

  /// `GET /api/partner/hotels/{id}` — one owned property in full.
  ///
  /// 404 means "not yours or not there" and the two are indistinguishable by
  /// design; the client must not present it as "this property exists but you
  /// lack permission".
  Future<CollectionApiResult<PartnerPropertyDetail>> getPartnerProperty(
          int propertyId) =>
      _partnerGetObject(
        _partnerUri('/partner/hotels/$propertyId'),
        (body) => PartnerPropertyDetail.fromJson(body),
      ).then(_requireDetail);

  /// `PATCH /api/partner/hotels/{id}/activate` — publish the listing to guests.
  ///
  /// Returns the full updated `PartnerHotelResponse`, so state is refreshed
  /// from the server's own answer rather than optimistically guessed.
  Future<CollectionApiResult<PartnerPropertyDetail>> activatePartnerProperty(
          int propertyId) =>
      _partnerPatchDetail('/partner/hotels/$propertyId/activate');

  /// `PATCH /api/partner/hotels/{id}/deactivate` — withdraw the listing.
  Future<CollectionApiResult<PartnerPropertyDetail>> deactivatePartnerProperty(
          int propertyId) =>
      _partnerPatchDetail('/partner/hotels/$propertyId/deactivate');

  Future<CollectionApiResult<PartnerPropertyDetail>> _partnerPatchDetail(
      String path) async {
    try {
      final res = await _client
          .patch(_partnerUri(path), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final detail = PartnerPropertyDetail.fromJson(body);
        if (detail == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(detail);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // A mutation that timed out may still have been committed server-side.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerPropertyDetail> _requireDetail(
          CollectionApiResult<PartnerPropertyDetail?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerPropertyDetail))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Rooms (C3) ──────────────────────────────────────────────────
  //
  // `PartnerRoomController` exposes GET list, GET detail, PUT update and
  // PATCH activate/deactivate. There is **no create and no delete**.
  //
  // The list endpoint takes a **required** `hotelId` query parameter
  // (`@RequestParam Long hotelId`, no `required = false`), so the property
  // context is mandatory — this client never calls it without one. Omitting it
  // produces a 500 from the running backend rather than a 400; see the C3
  // report. Callers are therefore required to pass a property id.
  //
  // Ownership, verified live:
  //   * list  — `ownedPlaceOrThrow(hotelId)` → 404 for an unknown *or* unowned
  //     hotel, then a further 404 if the place has no `HotelDetail` row.
  //   * detail/mutations — `ownedRoomOrThrow` walks
  //     room → hotelDetail → place → owner and returns a uniform 404 when the
  //     owner does not match. Rooms 1–4 resolve for the seeded partner; 5+ are
  //     404, with no way to tell "absent" from "someone else's".

  /// `GET /api/partner/rooms?hotelId={id}` — every room of one owned property,
  /// **including inactive ones** (`getByHotelDetail(detailId, false)`).
  Future<CollectionApiResult<List<PartnerRoom>>> getPartnerRooms(int hotelId) =>
      _partnerGetList(
        _partnerUri('/partner/rooms', {'hotelId': '$hotelId'}),
        PartnerRoom.fromJson,
      );

  /// `GET /api/partner/rooms/{roomId}` — one owned room in full.
  Future<CollectionApiResult<PartnerRoom>> getPartnerRoom(int roomId) =>
      _partnerGetObject(
        _partnerUri('/partner/rooms/$roomId'),
        (body) => PartnerRoom.fromJson(body),
      ).then(_requireRoom);

  /// `PATCH /api/partner/rooms/{roomId}/activate` — list this room type.
  Future<CollectionApiResult<PartnerRoom>> activatePartnerRoom(int roomId) =>
      _partnerPatchRoom('/partner/rooms/$roomId/activate');

  /// `PATCH /api/partner/rooms/{roomId}/deactivate` — stop listing it.
  Future<CollectionApiResult<PartnerRoom>> deactivatePartnerRoom(int roomId) =>
      _partnerPatchRoom('/partner/rooms/$roomId/deactivate');

  Future<CollectionApiResult<PartnerRoom>> _partnerPatchRoom(
      String path) async {
    try {
      final res = await _client
          .patch(_partnerUri(path), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final room = PartnerRoom.fromJson(body);
        if (room == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(room);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The mutation may already have been committed server-side.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerRoom> _requireRoom(
          CollectionApiResult<PartnerRoom?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(result.data as PartnerRoom))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Inventory / Calendar (C4) ───────────────────────────────────
  //
  // Namespace is `/api/partner/calendar/**` — the backend calls this surface
  // "calendar", not "inventory". `PartnerCalendarController` also exposes
  // `/rooms/{roomId}/price` (GET/PUT), which is **rate plans** and belongs to a
  // later phase; it is deliberately absent here.
  //
  // Ownership: `PartnerCalendarService.ownedRoomOrThrow` walks
  // room → hotelDetail → place → owner and returns a uniform 404 for an unknown
  // room and for another partner's room. Verified live: room 5 → 404.
  //
  // Date range: `from`/`to` are **inclusive on both ends** and are only applied
  // when *both* are present — sending one silently returns the room's entire
  // history. An inverted range returns 200 with an empty list rather than 400,
  // so callers must validate it themselves.

  /// `GET /api/partner/calendar/rooms/{roomId}` for an inclusive `[from, to]`.
  ///
  /// Both bounds are required by this client even though the endpoint accepts
  /// neither: a partial range is ignored server-side, which would quietly
  /// return every row the room has ever had.
  Future<CollectionApiResult<PartnerInventoryCalendar>> getPartnerInventory({
    required int roomId,
    required DateTime from,
    required DateTime to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/calendar/rooms/$roomId', {
          'from': _isoDate(from),
          'to': _isoDate(to),
        }),
        (body) => PartnerInventoryCalendar.fromJson(body),
      ).then(_requireCalendar);

  /// Toggles one per-day flag.
  ///
  /// Each flag has its own PATCH endpoint taking `{"value": bool}`
  /// (`PartnerCalendarDto.InventoryFlagRequest`) and returns the full updated
  /// `RoomInventoryResponse`. These touch exactly one boolean and never the
  /// quantities, so they cannot clobber a concurrent booking's decrement.
  ///
  /// A date with no inventory row returns **404** — only the bulk endpoint
  /// creates rows.
  Future<CollectionApiResult<PartnerInventoryDay>> setPartnerInventoryFlag({
    required int roomId,
    required DateTime date,
    required PartnerInventoryFlag flag,
    required bool value,
  }) async {
    final segment = switch (flag) {
      PartnerInventoryFlag.stopSell => 'stop-sell',
      PartnerInventoryFlag.closedArrival => 'closed-arrival',
      PartnerInventoryFlag.closedDeparture => 'closed-departure',
    };
    final uri = _partnerUri(
        '/partner/calendar/rooms/$roomId/${_isoDate(date)}/$segment');
    try {
      final res = await _client
          .patch(uri, headers: _jsonHeaders, body: jsonEncode({'value': value}))
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final day = PartnerInventoryDay.fromJson(body);
        if (day == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(day);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The flag may already have been persisted before the connection dropped.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerInventoryCalendar> _requireCalendar(
          CollectionApiResult<PartnerInventoryCalendar?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerInventoryCalendar))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Rates (C5) ──────────────────────────────────────────────────
  //
  // `PartnerPricingController` spans two paths:
  //   /api/partner/rooms/{roomId}/rate-plans        (list, create)
  //   /api/partner/rate-plans/{id}/**               (update, delete, activate,
  //                                                  deactivate, duplicate,
  //                                                  occupancy prices, preview,
  //                                                  validate)
  //
  // C5 exposes the reads plus activate/deactivate only. Create, `PUT` update,
  // delete, duplicate and occupancy-price writes are deliberately absent:
  //   * `PUT /rate-plans/{id}` is a **full replace** — `applyAndValidate` nulls
  //     `code`, `description`, cancellation fields, stay limits and advance-
  //     booking limits when omitted, so a partial form would erase them.
  //   * `DELETE` is irreversible and 409s when the plan parents derived plans.
  //   * Duplicate is a create.
  // Activate/deactivate take no body, flip one boolean and return the full
  // record, so they cannot corrupt a plan's configuration.
  //
  // Ownership: `PartnerPricingService.ownedRoomOrThrow` / `ownedRatePlanOrThrow`
  // walk to the owning profile and return a uniform 404. Verified live: room 5
  // and rate plan 9999 both 404.

  /// `GET /api/partner/rooms/{roomId}/rate-plans`.
  Future<CollectionApiResult<List<PartnerRatePlan>>> getPartnerRatePlans(
          int roomId) =>
      _partnerGetList(
        _partnerUri('/partner/rooms/$roomId/rate-plans'),
        PartnerRatePlan.fromJson,
      );

  /// `GET /api/partner/rate-plans/{id}/occupancy-prices`.
  Future<CollectionApiResult<List<PartnerOccupancyPrice>>>
      getPartnerOccupancyPrices(int ratePlanId) => _partnerGetList(
            _partnerUri('/partner/rate-plans/$ratePlanId/occupancy-prices'),
            PartnerOccupancyPrice.fromJson,
          );

  /// `GET /api/partner/rate-plans/{id}/preview` — backend-computed pricing and
  /// eligibility for one stay.
  ///
  /// `checkIn`/`checkOut` are a half-open **night** range (nights =
  /// checkOut − checkIn), unlike the rate plan's own inclusive validity window.
  /// The endpoint does not reject `checkOut <= checkIn` (verified live: 200),
  /// so callers validate it first.
  Future<CollectionApiResult<PartnerRatePreview>> getPartnerRatePreview({
    required int ratePlanId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/rate-plans/$ratePlanId/preview', {
          'checkIn': _isoDate(checkIn),
          'checkOut': _isoDate(checkOut),
          'adults': '$adults',
          'children': '$children',
          'extraBeds': '$extraBeds',
        }),
        (body) => PartnerRatePreview.fromJson(body),
      ).then(_requirePreview);

  /// `POST /api/partner/rate-plans/{id}/activate`.
  Future<CollectionApiResult<PartnerRatePlan>> activatePartnerRatePlan(
          int ratePlanId) =>
      _partnerPostRatePlan('/partner/rate-plans/$ratePlanId/activate');

  /// `POST /api/partner/rate-plans/{id}/deactivate`.
  Future<CollectionApiResult<PartnerRatePlan>> deactivatePartnerRatePlan(
          int ratePlanId) =>
      _partnerPostRatePlan('/partner/rate-plans/$ratePlanId/deactivate');

  Future<CollectionApiResult<PartnerRatePlan>> _partnerPostRatePlan(
      String path) async {
    try {
      final res = await _client
          .post(_partnerUri(path), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final plan = PartnerRatePlan.fromJson(body);
        if (plan == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(plan);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // May already have been committed before the connection dropped.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerRatePreview> _requirePreview(
          CollectionApiResult<PartnerRatePreview?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(result.data as PartnerRatePreview))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Policies & Settings (C6) ────────────────────────────────────
  //
  // Two domains with two different authorization rules:
  //   * `PUT /api/partner/hotels/{id}/policies` — `PartnerPropertyService` is
  //     **owner-only** (`partnerProfileRepo.findByUserId`), no team-role check.
  //   * `GET/PUT /api/partner/settings` — `PartnerSettingsService.resolveAccess`
  //     is the one **team-aware** resolver in the partner API; writes require
  //     OWNER or MANAGER (`SETTINGS_WRITE_ROLES`) and 403 otherwise.
  //
  // Both request records carry every field the form shows (5 and 9), so unlike
  // the property and rate-plan PUTs there is no omitted-field erasure.
  //
  // There is deliberately **no asset/media method here**: every media mutation
  // lives under `/api/admin/**` (`hasRole("ADMIN")`), and a PARTNER receives 403
  // — verified live. See the C6 report.

  /// `PUT /api/partner/hotels/{id}/policies`.
  ///
  /// `checkIn`/`checkOut` are `@NotNull`; omitting either is a 400
  /// (`"checkIn: must not be null"`). The three house-rule strings may be null,
  /// and sending null genuinely clears them.
  Future<CollectionApiResult<PartnerPropertyDetail>> updatePartnerPolicies({
    required int propertyId,
    required PartnerPropertyPolicies policies,
  }) async {
    try {
      final res = await _client
          .put(
            _partnerUri('/partner/hotels/$propertyId/policies'),
            headers: _jsonHeaders,
            body: jsonEncode(policies.toRequestJson()),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final detail = PartnerPropertyDetail.fromJson(body);
        if (detail == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(detail);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  /// `GET /api/partner/settings` — created with defaults on first access.
  Future<CollectionApiResult<PartnerWorkspaceSettings>>
      getPartnerWorkspaceSettings() => _partnerGetObject(
            _partnerUri('/partner/settings'),
            (body) => PartnerWorkspaceSettings.fromJson(body),
          ).then(_requireSettings);

  /// `PUT /api/partner/settings` — OWNER or MANAGER only; 403 for any other
  /// team role, with the server's own explanation.
  Future<CollectionApiResult<PartnerWorkspaceSettings>>
      updatePartnerWorkspaceSettings(PartnerWorkspaceSettings settings) async {
    try {
      final res = await _client
          .put(
            _partnerUri('/partner/settings'),
            headers: _jsonHeaders,
            body: jsonEncode(settings.toRequestJson()),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final updated = PartnerWorkspaceSettings.fromJson(body);
        if (updated == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(updated);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerWorkspaceSettings> _requireSettings(
          CollectionApiResult<PartnerWorkspaceSettings?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerWorkspaceSettings))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Promotions & Vouchers (C7) ──────────────────────────────────
  //
  // Promotions: `/api/partner/promotions` — GET list, GET detail, POST, PUT,
  // DELETE. Owner-only (`PartnerPromotionService` is not team-aware).
  // Ownership is by **target**: a promotion is "mine" when its `targetId`
  // resolves to a HotelDetail or HotelRoom I own. An `ALL`-targeted promotion is
  // never mine, and creating one is a 403.
  //
  // C7 exposes the reads plus an activate/deactivate that is implemented as a
  // **lossless full PUT** — there is no command endpoint for activation, and
  // `PromotionService.fill` replaces all sixteen request fields, so the only
  // safe write echoes the entire stored record and changes one flag. Create,
  // free-form edit and delete are deliberately absent; see the C7 report.
  //
  // Vouchers: `POST /api/partner/bookings/voucher/verify` is the *only* partner
  // voucher endpoint, and it is read-only. There is no partner coupon or
  // gift-card API at all — those are admin/customer surfaces.

  /// `GET /api/partner/promotions` — promotions targeting a hotel or room I own.
  Future<CollectionApiResult<List<PartnerPromotion>>> getPartnerPromotions() =>
      _partnerGetList(
        _partnerUri('/partner/promotions'),
        PartnerPromotion.fromJson,
      );

  /// `GET /api/partner/promotions/{id}` — uniform 404 for unknown or unowned.
  Future<CollectionApiResult<PartnerPromotion>> getPartnerPromotion(int id) =>
      _partnerGetObject(
        _partnerUri('/partner/promotions/$id'),
        (body) => PartnerPromotion.fromJson(body),
      ).then(_requirePromotion);

  /// `PUT /api/partner/promotions/{id}` carrying the **complete** record with
  /// only `active` changed.
  ///
  /// [promotion] must be the record just read from the server; the body echoes
  /// all sixteen request fields so the full replace cannot erase anything.
  /// Note `Promotion` has no `@Version`, so a concurrent edit elsewhere would be
  /// overwritten — reported rather than papered over.
  Future<CollectionApiResult<PartnerPromotion>> setPartnerPromotionActive({
    required PartnerPromotion promotion,
    required bool active,
  }) async {
    try {
      final res = await _client
          .put(
            _partnerUri('/partner/promotions/${promotion.id}'),
            headers: _jsonHeaders,
            body: jsonEncode(promotion.toRequestJson(activeOverride: active)),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final updated = PartnerPromotion.fromJson(body);
        if (updated == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(updated);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  /// `GET /api/partner/rooms/{roomId}/pricing-preview` — the engine's own
  /// breakdown for a stay, including which promotions it applied and the
  /// resulting amounts.
  ///
  /// Every figure is backend-computed; the client never recomputes pricing.
  /// `checkIn`/`checkOut` are a half-open night range.
  Future<CollectionApiResult<PartnerPricingPreview>> getPartnerPricingPreview({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/rooms/$roomId/pricing-preview', {
          'checkIn': _isoDate(checkIn),
          'checkOut': _isoDate(checkOut),
        }),
        (body) => PartnerPricingPreview.fromJson(body),
      ).then(_requirePreviewBreakdown);

  /// `POST /api/partner/bookings/voucher/verify` — read-only booking-voucher
  /// verification.
  ///
  /// An invalid signature, an unknown booking and another partner's booking all
  /// collapse to a uniform **404**, so the client must not claim to know which.
  /// A verified-but-ineligible booking returns 200 with `eligible = false` and a
  /// reason.
  Future<CollectionApiResult<PartnerVoucherVerification>> verifyPartnerVoucher(
      String voucherPayload) async {
    try {
      final res = await _client
          .post(
            _partnerUri('/partner/bookings/voucher/verify'),
            headers: _jsonHeaders,
            body: jsonEncode({'voucherPayload': voucherPayload}),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final result = PartnerVoucherVerification.fromJson(body);
        if (result == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(result);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // Verification mutates nothing, so a timeout is a plain failure — there is
      // no uncertain committed state to warn about.
      return const CollectionApiResult.failure(ApiErrorKind.timeout);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerPromotion> _requirePromotion(
          CollectionApiResult<PartnerPromotion?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(result.data as PartnerPromotion))
          : CollectionApiResult.failure(result.errorKind, result.message);

  CollectionApiResult<PartnerPricingPreview> _requirePreviewBreakdown(
          CollectionApiResult<PartnerPricingPreview?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerPricingPreview))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Bookings (C8) ───────────────────────────────────────────────
  //
  // `PartnerBookingController` + `PartnerStayController`. Owner-only:
  // `PartnerBookingService.myApprovedProfileOrThrow` resolves through
  // `partnerProfileRepo.findByUserId` (404 when there is no profile, 403 when it
  // is not APPROVED), then `ownedBookingOrThrow` answers a **uniform 404** for
  // both an unknown booking and one belonging to another partner. No
  // `PartnerTeamRole` check exists on any booking endpoint.
  //
  // Reads:  GET  /partner/bookings          (server-paginated, filtered)
  //         GET  /partner/bookings/{id}     (booking + payments + invoice + timeline)
  //         GET  /partner/stays/{id}        (derived stay state + audit + history)
  // Writes: PATCH /partner/bookings/{id}/{check-in|check-out|no-show|complete}
  //         POST  /partner/bookings/check-in   (voucher payload or booking code)
  //         POST  /partner/bookings/check-out  (voucher payload or booking code)
  //
  // There is deliberately **no cancel and no modify**: `BookingService.cancel`
  // and `.modify` compare the caller against `booking.getUser()` and answer 403
  // for anyone else, the property owner included. Those belong to the customer.

  /// `GET /api/partner/bookings` — one page of the partner's bookings.
  ///
  /// The endpoint accepts no `hotelId`, so the result is partner-wide across
  /// every owned property. Sorting is fixed server-side (`createdAt DESC`) and
  /// is not a request parameter.
  Future<CollectionApiResult<PartnerBookingPage>> getPartnerBookings(
    PartnerBookingQuery query,
  ) =>
      _partnerGetObject(
        _partnerUri('/partner/bookings', query.toQueryParameters()),
        (body) => PartnerBookingPage.fromJson(body),
      ).then(_requireBookingPage);

  /// `GET /api/partner/bookings/{id}` — booking, payments, invoice, timeline.
  Future<CollectionApiResult<PartnerBookingDetail>> getPartnerBookingDetail(
          int bookingId) =>
      _partnerGetObject(
        _partnerUri('/partner/bookings/$bookingId'),
        (body) => PartnerBookingDetail.fromJson(body),
      ).then(_requireBookingDetail);

  /// `GET /api/partner/stays/{bookingId}` — the consolidated read-only stay
  /// projection: derived schedule and state, voucher classification, timeline,
  /// modification history, check-in/out audit rows and operational warnings.
  ///
  /// Strictly read-only (`@Transactional(readOnly = true)`); it mutates nothing.
  Future<CollectionApiResult<PartnerGuestStay>> getPartnerGuestStay(
          int bookingId) =>
      _partnerGetObject(
        _partnerUri('/partner/stays/$bookingId'),
        (body) => PartnerGuestStay.fromJson(body),
      ).then(_requireGuestStay);

  /// `PATCH /api/partner/bookings/{id}/{action}` — advance the booking
  /// lifecycle through `BookingStatusEngineService`.
  ///
  /// Every transition is **one-way**: the engine's table defines no edge back to
  /// the previous state, so the caller must confirm first. An illegal transition
  /// is a **422**, never a 409, and leaves the booking untouched (the backend's
  /// own `rollbackSafety_illegalTransition_noPartialStateChange` test asserts
  /// this). Unlike the POST endpoints below, these are **not idempotent** —
  /// repeating a check-in on an already-CHECKED_IN booking is itself a 422.
  Future<CollectionApiResult<PartnerBooking>> runPartnerBookingAction({
    required int bookingId,
    required PartnerBookingAction action,
  }) async {
    try {
      final res = await _client
          .patch(
            _partnerUri('/partner/bookings/$bookingId/${action.path}'),
            headers: _jsonHeaders,
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final booking = PartnerBooking.fromJson(body);
        if (booking == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(booking);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The transition may have committed before the connection dropped, and
      // it cannot be undone — the caller must re-read rather than retry.
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  /// `POST /api/partner/bookings/check-in` or `.../check-out` — the front-desk
  /// mutations, addressed by a scanned voucher payload **or** a typed booking
  /// code.
  ///
  /// Exactly one of the two must be supplied; both or neither is a **400**
  /// enforced by the backend, and this client refuses to send such a request at
  /// all. An ineligible status or a stay outside the configured window is a
  /// **422**; an invalid signature, an unknown booking and another partner's
  /// booking all collapse to a uniform **404**.
  ///
  /// Both endpoints are **idempotent**: repeating the call on a booking already
  /// in the target state returns 200 with the original timestamp, writing no
  /// second audit row and sending no second notification. A timeout is still
  /// reported as uncertain — the client cannot know whether it landed — but
  /// re-running it is safe because of that idempotency.
  Future<CollectionApiResult<PartnerFrontDeskResult>>
      runPartnerFrontDeskAction({
    required bool checkIn,
    String? voucherPayload,
    String? bookingCode,
  }) async {
    final payload = voucherPayload?.trim();
    final code = bookingCode?.trim();
    final hasPayload = payload != null && payload.isNotEmpty;
    final hasCode = code != null && code.isNotEmpty;
    if (hasPayload == hasCode) {
      // Mirrors the backend's own "exactly one of" rule rather than spending a
      // round trip to be told the same thing.
      return const CollectionApiResult.failure(ApiErrorKind.validation);
    }

    try {
      final res = await _client
          .post(
            _partnerUri(
                '/partner/bookings/${checkIn ? 'check-in' : 'check-out'}'),
            headers: _jsonHeaders,
            body: jsonEncode(
              hasPayload ? {'voucherPayload': payload} : {'bookingCode': code},
            ),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final result = PartnerFrontDeskResult.fromJson(body);
        if (result == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(result);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerBookingPage> _requireBookingPage(
          CollectionApiResult<PartnerBookingPage?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(result.data as PartnerBookingPage))
          : CollectionApiResult.failure(result.errorKind, result.message);

  CollectionApiResult<PartnerBookingDetail> _requireBookingDetail(
          CollectionApiResult<PartnerBookingDetail?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerBookingDetail))
          : CollectionApiResult.failure(result.errorKind, result.message);

  CollectionApiResult<PartnerGuestStay> _requireGuestStay(
          CollectionApiResult<PartnerGuestStay?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(result.data as PartnerGuestStay))
          : CollectionApiResult.failure(result.errorKind, result.message);

  // ── Partner Finance & Analytics (C11) ───────────────────────────────────
  //
  // `PartnerFinanceController` and `PartnerAnalyticsController` are **entirely
  // read-only**: fifteen GETs, no mutation of any kind, and every one takes the
  // same optional `hotelId` / `from` / `to` triple. C1 already consumes four of
  // them (`analytics/overview`, `analytics/revenue`, `analytics/occupancy` and
  // `finance/overview`); the eleven below had no client at all.
  //
  // Shared semantics, identical in `PartnerFinanceService` and
  // `PartnerAnalyticsService` (`resolveRange` / `resolveHotelScope`):
  //   * `to` defaults to today, `from` to `to - 29 days` → an inclusive 30-day
  //     window. A **partial range is honoured**, not ignored — unlike the C4/C9
  //     calendar, where sending one bound silently returns everything.
  //   * `from > to` is a real **400**, not a silent empty result.
  //   * Bookings are bucketed by **`checkInDate`**, inclusive on both ends.
  //   * `hotelId` null → every owned property; an unowned id → uniform **404**.
  //   * `LocalDate.now()` uses the *server's* zone (see the C10 finding).
  //
  // No endpoint paginates, and none accepts a sort. Each loads every matching
  // booking into memory server-side — reported as a scalability concern.

  /// `GET /api/partner/finance/revenue` — revenue by day, month, hotel and room
  /// plus the server's own average and highest booking value.
  Future<CollectionApiResult<PartnerFinanceRevenue>> getPartnerFinanceRevenue({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/revenue',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerFinanceRevenue.fromJson,
      );

  /// `GET /api/partner/finance/commissions` — gross, commission and net at the
  /// platform rate. The rate is a hard-coded constant server-side; the client
  /// neither applies nor re-derives it.
  Future<CollectionApiResult<PartnerCommission>> getPartnerCommissions({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/commissions',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerCommission.fromJson,
      );

  /// `GET /api/partner/finance/settlements` — synthesized calendar-month
  /// periods. There is no settlement ledger behind these.
  Future<CollectionApiResult<PartnerSettlement>> getPartnerSettlements({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/settlements',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerSettlement.fromJson,
      );

  /// `GET /api/partner/finance/payouts` — the same synthesized periods split by
  /// status, plus an assumed next-payout date. No payout record exists.
  Future<CollectionApiResult<PartnerPayouts>> getPartnerPayouts({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/payouts',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerPayouts.fromJson,
      );

  /// `GET /api/partner/finance/invoices` — counts by status and a total.
  /// Aggregates only: no invoice id, no invoice list, no document.
  Future<CollectionApiResult<PartnerInvoiceFinance>> getPartnerInvoiceFinance({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/invoices',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerInvoiceFinance.fromJson,
      );

  /// `GET /api/partner/finance/refunds` — count, amount and the server's own
  /// refund rate. A partner cannot initiate a refund; there is no such endpoint.
  Future<CollectionApiResult<PartnerRefunds>> getPartnerRefunds({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/finance/refunds',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerRefunds.fromJson,
      );

  /// `GET /api/partner/analytics/bookings` — status mix, arrivals, departures
  /// and stay length.
  Future<CollectionApiResult<PartnerBookingAnalytics>>
      getPartnerBookingAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/bookings',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerBookingAnalytics.fromJson,
          );

  /// `GET /api/partner/analytics/rooms` — top rooms by revenue and by bookings,
  /// plus an availability summary.
  Future<CollectionApiResult<PartnerRoomAnalytics>> getPartnerRoomAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
      _partnerGetObject(
        _partnerUri('/partner/analytics/rooms',
            _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
        PartnerRoomAnalytics.fromJson,
      );

  /// `GET /api/partner/analytics/promotions` — structural only. The backend
  /// cannot attribute discounts yet, so `estimatedDiscountedBookings` is often
  /// null and must not be shown as zero.
  Future<CollectionApiResult<PartnerPromotionAnalytics>>
      getPartnerPromotionAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/promotions',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerPromotionAnalytics.fromJson,
          );

  /// `GET /api/partner/analytics/reviews` — rating and moderation aggregates.
  /// The response's `latestReviews` previews are deliberately not parsed; that
  /// is the Reviews domain.
  Future<CollectionApiResult<PartnerReviewAnalytics>>
      getPartnerReviewAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/reviews',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerReviewAnalytics.fromJson,
          );

  /// `GET /api/partner/analytics/messages` — conversation counts and the mean
  /// response time, which is null when nothing could be observed.
  Future<CollectionApiResult<PartnerMessageAnalytics>>
      getPartnerMessageAnalytics({
    int? hotelId,
    DateTime? from,
    DateTime? to,
  }) =>
          _partnerGetObject(
            _partnerUri('/partner/analytics/messages',
                _partnerScopeQuery(hotelId: hotelId, from: from, to: to)),
            PartnerMessageAnalytics.fromJson,
          );

  // ── Partner Reviews, Team & Payout account (C12) ────────────────────────
  //
  // ## Reviews
  //
  // `PartnerReviewController` has exactly **one** endpoint:
  // `PUT /api/partner/reviews/{reviewId}/reply`. There is no partner review
  // list, no review detail and no moderation — so the list below reuses the
  // public `GET /api/places/{placeId}/reviews` that `getPlaceReviews` (UI-29)
  // already implements, and no new read method is added.
  //
  // **A partner cannot read a review's text.** `ReviewService.getReview` runs
  // `checkOwnerOrAdmin` against the review's *author*, so `GET /api/reviews/{id}`
  // answers a partner with **403** (verified live). The only review fields a
  // partner can see are those on `ReviewSummaryResponse`: rating, title, author
  // name, status, date and their own reply. Reported, not worked around.
  //
  // ## Team and payout
  //
  // Both live on `PartnerSettingsController`, whose settings half C6 already
  // consumes. Role rules come straight from `PartnerSettingsService`:
  // team writes call `requireOwner` (**OWNER only**), payout writes require
  // **OWNER or FINANCE**, and settings writes remain OWNER/MANAGER as C6 has it.
  //
  // The payout request carries a full account number, but the backend derives
  // `bankAccountLast4` and **discards the rest immediately** — nothing sensitive
  // is ever stored or returned.

  /// `PUT /api/partner/reviews/{reviewId}/reply` — create or replace the single
  /// partner reply.
  ///
  /// A review has exactly one reply: the first call creates it, later calls
  /// replace it in place. There is **no delete endpoint**, so a published reply
  /// can be edited but never withdrawn. Only an `APPROVED` review may be replied
  /// to (**422** otherwise); an unknown review and one whose place the caller
  /// does not own both give a uniform **404**. The guest is notified only on the
  /// first reply.
  Future<CollectionApiVoidResult> replyToPartnerReview({
    required int reviewId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      // Mirrors the backend's `@NotBlank` rather than spending a round trip.
      return const CollectionApiVoidResult.failure(ApiErrorKind.validation);
    }
    try {
      final res = await _client
          .put(
            _partnerUri('/partner/reviews/$reviewId/reply'),
            headers: _jsonHeaders,
            body: jsonEncode({'content': trimmed}),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) return const CollectionApiVoidResult.success();
      return CollectionApiVoidResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The reply may already be published, and it cannot be withdrawn.
      return const CollectionApiVoidResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    }
  }

  /// `POST /api/partner/team` — invite a member by email with a role.
  /// **OWNER only** (`requireOwner`).
  Future<CollectionApiResult<PartnerTeamMember>> addPartnerTeamMember({
    required String email,
    required PartnerTeamRole role,
  }) =>
      _partnerTeamWrite(
        () => _client.post(
          _partnerUri('/partner/team'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email.trim(),
            'role': partnerTeamRoleWire(role),
          }),
        ),
        role,
      );

  /// `PATCH /api/partner/team/{id}` — change a member's role, or activate and
  /// deactivate them. **OWNER only.**
  ///
  /// Only the fields passed are sent, so a role change never silently toggles
  /// `active` and vice versa.
  Future<CollectionApiResult<PartnerTeamMember>> updatePartnerTeamMember({
    required int memberId,
    PartnerTeamRole? role,
    bool? active,
  }) =>
      _partnerTeamWrite(
        () => _client.patch(
          _partnerUri('/partner/team/$memberId'),
          headers: _jsonHeaders,
          body: jsonEncode({
            if (role != null) 'role': partnerTeamRoleWire(role),
            if (active != null) 'active': active,
          }),
        ),
        role,
      );

  /// `DELETE /api/partner/team/{id}` — remove a member. **OWNER only**, and
  /// irreversible: there is no undo endpoint.
  Future<CollectionApiVoidResult> removePartnerTeamMember(int memberId) async {
    try {
      final res = await _client
          .delete(_partnerUri('/partner/team/$memberId'), headers: _jsonHeaders)
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 204) {
        return const CollectionApiVoidResult.success();
      }
      return CollectionApiVoidResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      // The removal may have committed, and it cannot be undone.
      return const CollectionApiVoidResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiVoidResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiVoidResult.failure(ApiErrorKind.network);
    }
  }

  Future<CollectionApiResult<PartnerTeamMember>> _partnerTeamWrite(
    Future<http.Response> Function() send,
    PartnerTeamRole? role,
  ) async {
    if (role != null && partnerTeamRoleWire(role) == null) {
      // An unrecognised role has no wire value and must never be sent.
      return const CollectionApiResult.failure(ApiErrorKind.validation);
    }
    try {
      final res = await send().timeout(_collectionsTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final member = PartnerTeamMember.fromJson(body);
        if (member == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(member);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  /// `GET /api/partner/payout-account` — the safe projection.
  ///
  /// Only `bankAccountLast4` exists server-side; the full number was discarded
  /// when it was first submitted, so there is nothing sensitive to receive.
  Future<CollectionApiResult<PartnerPayoutAccount>> getPartnerPayoutAccount() =>
      _partnerGetObject(
        _partnerUri('/partner/payout-account'),
        (body) => PartnerPayoutAccount.fromJson(body),
      ).then(_requirePayoutAccount);

  /// `PUT /api/partner/payout-account` — **OWNER or FINANCE**.
  ///
  /// The account number is sent once and never comes back; the response carries
  /// only its last four digits. The client keeps no copy.
  Future<CollectionApiResult<PartnerPayoutAccount>> updatePartnerPayoutAccount({
    required String accountHolderName,
    required String bankName,
    required String bankAccountNumber,
    required PartnerPayoutMethod payoutMethod,
  }) async {
    final wire = payoutMethod.wireValue;
    final holder = accountHolderName.trim();
    final bank = bankName.trim();
    final number = bankAccountNumber.trim();
    // Mirrors `@NotBlank` and `@Size(min = 4)` on `PartnerPayoutAccountRequest`.
    if (wire == null || holder.isEmpty || bank.isEmpty || number.length < 4) {
      return const CollectionApiResult.failure(ApiErrorKind.validation);
    }
    try {
      final res = await _client
          .put(
            _partnerUri('/partner/payout-account'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'accountHolderName': holder,
              'bankName': bank,
              'bankAccountNumber': number,
              'payoutMethod': wire,
            }),
          )
          .timeout(_collectionsTimeout);
      if (res.statusCode == 200) {
        final body = _decodeJsonMap(res).data;
        if (body == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        final account = PartnerPayoutAccount.fromJson(body);
        if (account == null) {
          return const CollectionApiResult.failure(ApiErrorKind.malformed);
        }
        return CollectionApiResult.success(account);
      }
      return CollectionApiResult.failure(
        _errorKindForStatus(res.statusCode),
        _safeServerMessage(_decodeJsonMap(res).data),
      );
    } on TimeoutException {
      return const CollectionApiResult.failure(ApiErrorKind.uncertain);
    } on http.ClientException {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    } on FormatException {
      return const CollectionApiResult.failure(ApiErrorKind.malformed);
    } catch (_) {
      return const CollectionApiResult.failure(ApiErrorKind.network);
    }
  }

  CollectionApiResult<PartnerPayoutAccount> _requirePayoutAccount(
          CollectionApiResult<PartnerPayoutAccount?> result) =>
      result.success
          ? (result.data == null
              ? const CollectionApiResult.failure(ApiErrorKind.malformed)
              : CollectionApiResult.success(
                  result.data as PartnerPayoutAccount))
          : CollectionApiResult.failure(result.errorKind, result.message);

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
