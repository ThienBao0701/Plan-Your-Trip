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
