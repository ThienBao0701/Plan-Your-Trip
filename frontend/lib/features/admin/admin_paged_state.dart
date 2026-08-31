import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'widgets/admin_widgets.dart';

/// Shared behaviour for every paginated Admin CMS grid.
///
/// The five grids differ only in which endpoint they call and which filters
/// they carry; page navigation, sort handling, stale-response protection and
/// error mapping are identical. Putting that here means one implementation to
/// reason about rather than five that can drift — the same reasoning that gave
/// the partner modules their `_loadToken` convention.
///
/// Subclasses implement [fetch] and nothing else about paging.
abstract class AdminPagedState<T> extends ChangeNotifier {
  final ApiClient api;

  AdminPagedState({required this.api, required String defaultSortField})
      : _sortField = defaultSortField;

  /// Backend default. Kept in sync with `AdminPaging.DEFAULT_SIZE`; the client
  /// sends it explicitly so the displayed page size is never a guess.
  static const int defaultPageSize = 20;

  /// `AdminPaging.MAX_SIZE`. The client will not ask for more, because the
  /// backend clamps anyway and silently receiving fewer rows than requested is
  /// worse than not asking.
  static const int maxPageSize = 200;

  AdminLoadStatus _status = AdminLoadStatus.idle;
  String? _errorMessage;
  AdminPage<T> _page = AdminPage.empty<T>();

  int _pageIndex = 0;
  int _pageSize = defaultPageSize;
  String _sortField;
  bool _sortDescending = true;

  /// Guards against a slow earlier request overwriting a newer one — the same
  /// stale-response protection the partner modules use.
  int _loadToken = 0;

  AdminLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AdminPage<T> get page => _page;
  List<T> get rows => _page.content;

  int get pageIndex => _pageIndex;
  int get pageSize => _pageSize;
  String get sortField => _sortField;
  bool get sortDescending => _sortDescending;

  bool get isLoading => _status == AdminLoadStatus.loading;
  bool get isReady => _status == AdminLoadStatus.ready;

  /// True only when the load succeeded and the server genuinely has no rows —
  /// distinct from a failure, so the UI never shows "no results" for an error.
  bool get isEmpty => isReady && _page.isEmpty;

  /// `field,dir` exactly as `AdminPaging.safeSort` parses it. Never free text:
  /// [_sortField] can only hold a value the screen offered.
  String get sortParameter => '$_sortField,${_sortDescending ? 'desc' : 'asc'}';

  /// Performs the endpoint call. Subclasses add their own filters.
  Future<CollectionApiResult<AdminPage<T>>> fetch({
    required int page,
    required int size,
    required String sort,
  });

  /// Loads the current page. [resetToFirstPage] is used whenever a filter or
  /// sort changes, because page 4 of the previous result set is meaningless
  /// against a new one.
  Future<void> load({bool resetToFirstPage = false}) async {
    if (resetToFirstPage) _pageIndex = 0;
    final token = ++_loadToken;
    _status = AdminLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result =
        await fetch(page: _pageIndex, size: _pageSize, sort: sortParameter);
    if (token != _loadToken) return;

    if (!result.success || result.data == null) {
      _status = adminStatusFor(result.errorKind);
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _page = result.data!;
    // Trust the server's own page index rather than the one we asked for: if it
    // clamped the request, the UI must reflect where we actually are.
    _pageIndex = _page.page;
    _status = AdminLoadStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> goToPage(int page) {
    if (page < 0 || page == _pageIndex) return Future.value();
    _pageIndex = page;
    return load();
  }

  Future<void> setPageSize(int size) {
    final clamped =
        size < 1 ? defaultPageSize : (size > maxPageSize ? maxPageSize : size);
    if (clamped == _pageSize) return Future.value();
    _pageSize = clamped;
    return load(resetToFirstPage: true);
  }

  Future<void> setSort(String field, bool descending) {
    if (field == _sortField && descending == _sortDescending) {
      return Future.value();
    }
    _sortField = field;
    _sortDescending = descending;
    return load(resetToFirstPage: true);
  }

  /// Drops all rows and paging context. Called when the admin session ends.
  void reset() {
    _loadToken++;
    _status = AdminLoadStatus.idle;
    _errorMessage = null;
    _page = AdminPage.empty<T>();
    _pageIndex = 0;
    _pageSize = defaultPageSize;
    notifyListeners();
  }
}
