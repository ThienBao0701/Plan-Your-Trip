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
