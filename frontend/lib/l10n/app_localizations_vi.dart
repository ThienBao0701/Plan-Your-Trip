// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Plan Your Trip';

  @override
  String get tabExplore => 'Khám phá';

  @override
  String get tabTrips => 'Chuyến đi';

  @override
  String get tabPlanner => 'Lịch trình';

  @override
  String get tabProfile => 'Hồ sơ';

  @override
  String get tabExploreSemantic => 'Tab Khám phá';

  @override
  String get tabTripsSemantic => 'Tab Chuyến đi';

  @override
  String get tabPlannerSemantic => 'Tab Lịch trình';

  @override
  String get tabProfileSemantic => 'Tab Hồ sơ';

  @override
  String get bottomNavigationSemantic => 'Điều hướng chính';

  @override
  String get loadingTitle => 'Đang tải';

  @override
  String get loadingMessage => 'Đang chuẩn bị hành trình của bạn...';

  @override
  String get loadingSemanticLabel => 'Nội dung đang tải';

  @override
  String get emptyTitle => 'Chưa có dữ liệu';

  @override
  String get emptyMessage => 'Nội dung sẽ xuất hiện tại đây khi bạn bắt đầu.';

  @override
  String get emptyAction => 'Khám phá ngay';

  @override
  String get emptyStateSemanticLabel => 'Trạng thái chưa có dữ liệu';

  @override
  String get offlineTitle => 'Bạn đang ngoại tuyến';

  @override
  String get offlineMessage => 'Kiểm tra kết nối mạng rồi thử lại.';

  @override
  String get offlineAction => 'Thử lại';

  @override
  String get offlineStateSemanticLabel => 'Trạng thái ngoại tuyến';

  @override
  String get errorTitle => 'Đã xảy ra lỗi';

  @override
  String get errorMessage => 'Chúng tôi chưa thể tải nội dung này.';

  @override
  String get errorAction => 'Tải lại';

  @override
  String get errorStateSemanticLabel => 'Lỗi có thể khôi phục';

  @override
  String get sessionExpiredTitle => 'Phiên đăng nhập đã hết hạn';

  @override
  String get sessionExpiredMessage =>
      'Đăng nhập lại để tiếp tục. Dữ liệu cục bộ chưa lưu vẫn được giữ.';

  @override
  String get sessionExpiredLoginAction => 'Đăng nhập lại';

  @override
  String get sessionExpiredHomeAction => 'Về trang chủ';

  @override
  String get sessionExpiredSemanticLabel => 'Phiên đăng nhập đã hết hạn';

  @override
  String get searchFieldSemanticLabel => 'Tìm kiếm';

  @override
  String get plannerTitle => 'Lịch trình';

  @override
  String get plannerSubtitle =>
      'Mở dòng thời gian chuyến đi và tiếp tục lên kế hoạch.';

  @override
  String get plannerEmptyTitle => 'Chưa có chuyến đi để lên lịch';

  @override
  String get plannerEmptyMessage =>
      'Tạo một chuyến đi trước khi xây dựng lịch trình.';

  @override
  String get plannerCreateTripAction => 'Tạo chuyến đi';

  @override
  String get plannerOpenTimelineAction => 'Mở lịch trình';

  @override
  String plannerTripMeta(String destination, int days, int travelers) {
    return '$destination · $days ngày · $travelers người';
  }

  @override
  String get plannerTripCardSemantic => 'Thẻ lập lịch chuyến đi';

  @override
  String get demoModeLabel => 'Chế độ demo';
}
