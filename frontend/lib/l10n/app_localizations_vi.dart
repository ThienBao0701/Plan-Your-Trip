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
  String get plannerTripSelectorLabel => 'Chọn chuyến đi';

  @override
  String get plannerTripSelectorSemantic => 'Bộ chọn chuyến đi';

  @override
  String get plannerModeSemantic => 'Chế độ hiển thị lịch trình';

  @override
  String get plannerTimelineMode => 'Dòng thời gian';

  @override
  String get plannerRouteMode => 'Tuyến đường';

  @override
  String get plannerDaySelectorSemantic => 'Bộ chọn ngày';

  @override
  String plannerDaySemantic(int day) {
    return 'Chọn ngày $day';
  }

  @override
  String get plannerQuickAddAction => 'Thêm nhanh';

  @override
  String get plannerQuickAddSemantic => 'Thêm nhanh hoạt động hoặc địa điểm';

  @override
  String get plannerAddActivityAction => 'Thêm hoạt động';

  @override
  String get plannerAddActivitySemantic => 'Thêm hoạt động thủ công';

  @override
  String get plannerEmptyDayTitle => 'Ngày này chưa có hoạt động';

  @override
  String get plannerEmptyDayMessage =>
      'Thêm địa điểm hoặc hoạt động thủ công để xây dựng ngày này.';

  @override
  String plannerActivityCardSemantic(String title, String time) {
    return '$title, $time';
  }

  @override
  String get plannerInvalidTimeLabel => 'Thời gian không hợp lệ';

  @override
  String get plannerRouteFallbackSemantic =>
      'Trạng thái tuyến đường chưa kết nối';

  @override
  String get plannerRouteUnavailableMessage =>
      'Bản đồ trực tiếp, tuyến đường, giao thông, khoảng cách và thời gian di chuyển chưa được kết nối. Dữ liệu lịch trình vẫn là cục bộ.';

  @override
  String get plannerRoutePreviewTitle => 'Điểm dừng trong ngày';

  @override
  String get plannerBackToTimelineAction => 'Quay lại dòng thời gian';

  @override
  String get plannerLocalOnlyMessage =>
      'Thay đổi lịch trình là cục bộ trong trạng thái ứng dụng này và không đồng bộ với backend.';

  @override
  String get activityAddTitle => 'Thêm hoạt động';

  @override
  String get activityEditTitle => 'Sửa hoạt động';

  @override
  String get activityCloseAction => 'Đóng';

  @override
  String get activityTitleLabel => 'Tên hoạt động';

  @override
  String get activityNotesLabel => 'Ghi chú';

  @override
  String get activityDayLabel => 'Ngày';

  @override
  String get activityStartTimeLabel => 'Giờ bắt đầu';

  @override
  String get activityEndTimeLabel => 'Giờ kết thúc';

  @override
  String get activityTimeHint => 'Dùng HH:mm';

  @override
  String get activityCategoryLabel => 'Danh mục';

  @override
  String get activityAddAction => 'Thêm hoạt động';

  @override
  String get activitySaveAction => 'Lưu thay đổi';

  @override
  String get activityAddSemantic => 'Thêm hoạt động này';

  @override
  String get activitySaveSemantic => 'Lưu hoạt động này';

  @override
  String get activityTitleRequired => 'Nhập tên hoạt động.';

  @override
  String get activityInvalidTimeRange =>
      'Nhập khoảng thời gian hợp lệ, giờ kết thúc phải sau giờ bắt đầu.';

  @override
  String get activityOutOfRangeDay => 'Chọn một ngày nằm trong chuyến đi này.';

  @override
  String get activitySaveFailed =>
      'Không thể lưu hoạt động này vào ngày đã chọn.';

  @override
  String get activityAddedMessage => 'Đã thêm hoạt động cục bộ.';

  @override
  String get activitySavedMessage => 'Đã cập nhật hoạt động cục bộ.';

  @override
  String get activityDetailTitle => 'Chi tiết hoạt động';

  @override
  String get activityEditAction => 'Chỉnh sửa';

  @override
  String activityEditSemantic(String title) {
    return 'Sửa $title';
  }

  @override
  String get activityViewPlaceAction => 'Xem địa điểm';

  @override
  String get activityEstimatedCostLabel => 'Chi phí dự kiến';

  @override
  String get activityDeleteAction => 'Xóa hoạt động';

  @override
  String activityDeleteSemantic(String title) {
    return 'Xóa $title';
  }

  @override
  String get activityDeleteConfirmTitle => 'Xóa hoạt động?';

  @override
  String activityDeleteConfirmMessage(String title) {
    return 'Xóa \"$title\" khỏi ngày này?';
  }

  @override
  String get activityDeletedMessage => 'Đã xóa hoạt động.';

  @override
  String get activityConflictTitle => 'Xung đột lịch trình';

  @override
  String activityConflictMessage(String title, String time) {
    return '\"$title\" trùng với $time. Hãy đổi giờ hoặc chủ động giữ cả hai hoạt động.';
  }

  @override
  String get activityConflictChangeTime => 'Đổi giờ';

  @override
  String get activityConflictAddAnyway => 'Vẫn thêm';

  @override
  String get activityConflictSaveAnyway => 'Vẫn lưu';

  @override
  String get activityConflictKeepBothTitle => 'Giữ cả hai hoạt động?';

  @override
  String get activityConflictKeepBothMessage =>
      'Thao tác này giữ cả hai hoạt động bị trùng giờ. Không có hoạt động nào bị di chuyển hoặc ghi đè.';

  @override
  String get activityConflictKeepBothAction => 'Giữ cả hai';

  @override
  String get quickAddTitle => 'Thêm nhanh';

  @override
  String get quickAddSearchHint => 'Tìm địa điểm hoặc hoạt động';

  @override
  String quickAddSuggestionsTitle(String day) {
    return 'Gợi ý cho $day';
  }

  @override
  String quickAddPlaceSubtitle(String place) {
    return 'Thêm $place vào một ngày thực tế của chuyến đi.';
  }

  @override
  String get quickAddNoTripTitle => 'Chưa có chuyến đi';

  @override
  String get quickAddNoTripMessage =>
      'Tạo chuyến đi trước khi thêm địa điểm này vào lịch trình.';

  @override
  String get quickAddNoPlacesTitle => 'Không tìm thấy địa điểm';

  @override
  String get quickAddNoPlacesMessage => 'Thử từ khóa cục bộ khác.';

  @override
  String get quickAddSelectTripLabel => 'Chọn chuyến đi';

  @override
  String get quickAddSelectDayLabel => 'Chọn ngày';

  @override
  String quickAddSubmitAction(int day) {
    return 'Thêm vào Ngày $day';
  }

  @override
  String quickAddAddedMessage(String place, String trip, int day) {
    return 'Đã thêm $place vào $trip · Ngày $day';
  }

  @override
  String get authLoginHero => 'Mỗi ngày đi, một hành trình đáng nhớ.';

  @override
  String get authLoginTitle => 'Chào mừng trở lại';

  @override
  String get authLoginSubtitle => 'Đăng nhập để tiếp tục hành trình của bạn.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authFullNameLabel => 'Họ và tên';

  @override
  String get authConfirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get authLoginAction => 'Đăng nhập';

  @override
  String get authDemoAction => 'Dùng Chế độ demo';

  @override
  String get authCreateAccountAction => 'Tạo tài khoản';

  @override
  String get authAlreadyHaveAccount => 'Đã có tài khoản?';

  @override
  String get authNeedAccount => 'Chưa có tài khoản?';

  @override
  String get authForgotPasswordAction => 'Quên mật khẩu?';

  @override
  String get authVerifyEmailAction => 'Xác minh email';

  @override
  String get authDemoHint =>
      'Tài khoản demo dùng dữ liệu mẫu cục bộ và không gọi backend.';

  @override
  String get authBackendHint => 'Đăng nhập backend chỉ dùng /auth/login.';

  @override
  String get authRegisterTitle => 'Tạo tài khoản';

  @override
  String get authRegisterSubtitle =>
      'Bắt đầu không gian lập kế hoạch của riêng bạn.';

  @override
  String get authRegisterAction => 'Đăng ký';

  @override
  String get authRegistrationComplete =>
      'Đăng ký hoàn tất. Vui lòng đăng nhập.';

  @override
  String get authPasswordRequirement => 'Mật khẩu cần ít nhất 8 ký tự.';

  @override
  String get authTermsNote =>
      'Khi tiếp tục, bạn đồng ý với điều khoản và thông tin quyền riêng tư hiện có trong ứng dụng.';

  @override
  String get authShowPassword => 'Hiện mật khẩu';

  @override
  String get authHidePassword => 'Ẩn mật khẩu';

  @override
  String get authShowConfirmPassword => 'Hiện mật khẩu xác nhận';

  @override
  String get authHideConfirmPassword => 'Ẩn mật khẩu xác nhận';

  @override
  String get authValidationName => 'Nhập họ và tên của bạn.';

  @override
  String get authValidationEmail => 'Nhập địa chỉ email hợp lệ.';

  @override
  String get authValidationPasswordRequired => 'Nhập mật khẩu của bạn.';

  @override
  String get authValidationPasswordMin => 'Mật khẩu cần ít nhất 8 ký tự.';

  @override
  String get authValidationConfirmPassword => 'Xác nhận mật khẩu của bạn.';

  @override
  String get authValidationPasswordMismatch => 'Mật khẩu không khớp.';

  @override
  String get authLoginFailed => 'Đăng nhập thất bại.';

  @override
  String get authRegistrationFailed => 'Đăng ký thất bại.';

  @override
  String get authUnsupportedForgotPassword =>
      'Đặt lại mật khẩu chưa được kết nối với backend.';

  @override
  String get authUnsupportedVerification =>
      'Xác minh email chưa được kết nối với backend.';

  @override
  String get authUnsupportedResend => 'Gửi lại mã xác minh chưa được kết nối.';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordSubtitle =>
      'Nhập email tài khoản của bạn. Màn hình này đã sẵn sàng cho endpoint đặt lại mật khẩu sau này.';

  @override
  String get forgotPasswordSendAction => 'Gửi liên kết đặt lại';

  @override
  String get forgotPasswordReturnAction => 'Quay lại đăng nhập';

  @override
  String get forgotPasswordInfo =>
      'Chưa thể gửi liên kết đặt lại cho đến khi backend được kết nối.';

  @override
  String get emailVerificationTitle => 'Xác minh email';

  @override
  String emailVerificationSubtitle(String email) {
    return 'Nhập mã gồm 6 chữ số cho $email.';
  }

  @override
  String emailVerificationDigitSemantic(int position) {
    return 'Chữ số xác minh $position';
  }

  @override
  String get emailVerificationAction => 'Xác minh';

  @override
  String emailVerificationResendIn(int seconds) {
    return 'Gửi lại mã sau 00:$seconds';
  }

  @override
  String get emailVerificationResendAction => 'Gửi lại mã';

  @override
  String get emailVerificationChangeEmail => 'Đổi địa chỉ email';

  @override
  String get emailVerificationIncomplete => 'Nhập đủ 6 chữ số.';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileSettingsSemantic => 'Mở cài đặt';

  @override
  String get profileDemoName => 'Khách du lịch demo';

  @override
  String get profileRealAccountTitle => 'Tài khoản đã đăng nhập';

  @override
  String get profileEmailMissing => 'Chưa có email';

  @override
  String get profileDemoStatus => 'Dữ liệu demo đang hoạt động';

  @override
  String get profileRealStatus => 'Tài khoản backend';

  @override
  String get profileBackendProfileUnavailable =>
      'Chi tiết hồ sơ chưa được kết nối với endpoint backend.';

  @override
  String get profileTripsStat => 'Chuyến đi';

  @override
  String get profileSavedPlacesStat => 'Đã lưu';

  @override
  String get profileNotificationsStat => 'Thông báo';

  @override
  String get profileTravelPreferences => 'Sở thích du lịch';

  @override
  String get profileDemoPreferences => 'Ẩm thực, Văn hóa, Thiên nhiên';

  @override
  String get profileAccountSection => 'Tài khoản';

  @override
  String get profileLegalSection => 'Pháp lý';

  @override
  String get profileSettings => 'Cài đặt';

  @override
  String get profileSavedPlaces => 'Địa điểm đã lưu';

  @override
  String get profileNotifications => 'Thông báo';

  @override
  String get profilePrivacyPolicy => 'Chính sách bảo mật';

  @override
  String get profileTerms => 'Điều khoản dịch vụ';

  @override
  String get profileAboutApp => 'Về ứng dụng';

  @override
  String get profileLogout => 'Đăng xuất';

  @override
  String get profileLogoutSemantic => 'Đăng xuất khỏi tài khoản này';

  @override
  String get profileLogoutConfirmTitle => 'Đăng xuất?';

  @override
  String get profileLogoutConfirmMessage =>
      'Thao tác này xóa phiên đã lưu và loại bỏ token Authorization khỏi các yêu cầu sau.';

  @override
  String get profileCancel => 'Hủy';

  @override
  String get profileConfirmLogout => 'Đăng xuất';

  @override
  String get profileVersion => 'Plan Your Trip v1.0.0';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLanguageRegion => 'Ngôn ngữ & khu vực';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageDevice => 'Theo thiết bị';

  @override
  String get settingsLanguageEnglish => 'Tiếng Anh';

  @override
  String get settingsLanguageVietnamese => 'Tiếng Việt';

  @override
  String get settingsCurrency => 'Tiền tệ';

  @override
  String get settingsTimeFormat => 'Định dạng thời gian';

  @override
  String get settingsNotifications => 'Thông báo';

  @override
  String get settingsTripReminders => 'Nhắc lịch trình';

  @override
  String get settingsBookingUpdates => 'Cập nhật booking';

  @override
  String get settingsTravelTips => 'Gợi ý chuyến đi';

  @override
  String get settingsLocalOnly =>
      'Chỉ là tùy chọn cục bộ. Đăng ký push chưa được kết nối.';

  @override
  String get settingsStoredOnDevice => 'Chỉ lưu trên thiết bị này.';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsReduceMotion => 'Giảm chuyển động';

  @override
  String get settingsAccountSecurity => 'Tài khoản & bảo mật';

  @override
  String get settingsPasswordReset => 'Đặt lại mật khẩu';

  @override
  String get settingsPasswordResetSubtitle =>
      'Chỉ là luồng giao diện cho đến khi backend có endpoint.';

  @override
  String get settingsPrivacy => 'Quyền riêng tư';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsDemoData => 'Dữ liệu demo';

  @override
  String get settingsResetDemoData => 'Đặt lại dữ liệu demo';

  @override
  String get settingsResetDemoSubtitle =>
      'Khôi phục chuyến đi, địa điểm và chi phí mẫu ban đầu.';

  @override
  String get settingsResetDemoConfirmTitle => 'Đặt lại dữ liệu demo?';

  @override
  String get settingsResetDemoConfirmMessage =>
      'Thao tác này đăng nhập lại Chế độ demo và khôi phục dữ liệu du lịch mẫu.';

  @override
  String get settingsReset => 'Đặt lại';

  @override
  String get settingsDemoRestored => 'Đã khôi phục dữ liệu demo.';

  @override
  String get settingsConnectedReal => 'Đã kết nối backend';

  @override
  String get savedPlacesTitle => 'Địa điểm đã lưu';

  @override
  String get savedPlacesSearchHint => 'Tìm địa điểm đã lưu';

  @override
  String get savedPlacesAllFilter => 'Tất cả';

  @override
  String savedPlacesCount(int count) {
    return '$count địa điểm';
  }

  @override
  String get savedPlacesRealEmptyTitle => 'Chưa có địa điểm đã lưu';

  @override
  String get savedPlacesRealEmptyMessage =>
      'Địa điểm đã lưu chưa được kết nối với backend cho tài khoản thật.';

  @override
  String get savedPlacesDemoEmptyTitle => 'Không có địa điểm phù hợp';

  @override
  String get savedPlacesDemoEmptyMessage => 'Thử bộ lọc hoặc từ khóa khác.';

  @override
  String savedPlacesBookmarkSemantic(String place) {
    return 'Dấu trang đã lưu cho $place';
  }

  @override
  String get savedPlacesRemoved => 'Đã xóa khỏi danh sách đã lưu cục bộ.';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsMarkAllRead => 'Đánh dấu đã đọc';

  @override
  String get notificationsToday => 'Hôm nay';

  @override
  String get notificationsEarlier => 'Trước đó';

  @override
  String get notificationsRealEmptyTitle => 'Chưa có thông báo';

  @override
  String get notificationsRealEmptyMessage =>
      'Thông báo máy chủ chưa được kết nối cho tài khoản thật.';

  @override
  String get notificationsDemoEmptyTitle => 'Chưa có thông báo demo';

  @override
  String get notificationsDemoEmptyMessage =>
      'Nhắc lịch trình và cập nhật sẽ xuất hiện tại đây.';

  @override
  String get notificationUnreadSemantic => 'Thông báo chưa đọc';

  @override
  String get notificationReadSemantic => 'Thông báo đã đọc';

  @override
  String get notificationsSettingsSemantic => 'Mở cài đặt thông báo';

  @override
  String get notificationScheduleTitle => 'Lịch trình sắp bắt đầu';

  @override
  String get notificationScheduleMessage =>
      'Chuyến đi Đà Lạt của bạn bắt đầu sau 2 ngày.';

  @override
  String get notificationBookingTitle => 'Cập nhật booking';

  @override
  String get notificationBookingMessage =>
      'Chỗ ở demo của bạn đã sẵn sàng cho chuyến đi.';

  @override
  String get notificationTipsTitle => 'Gợi ý dành cho bạn';

  @override
  String get notificationTipsMessage =>
      'Khám phá 5 điểm ăn uống được yêu thích gần nơi đã lưu.';

  @override
  String get notificationBudgetTitle => 'Ngân sách chuyến đi';

  @override
  String get notificationBudgetMessage =>
      'Bạn đã dùng 62% ngân sách demo dự kiến.';

  @override
  String get notificationYesterday => 'Hôm qua';

  @override
  String get notificationBudgetDate => '12 Th7';

  @override
  String get exploreHeroTitle => 'Bạn muốn đi đâu?';

  @override
  String get exploreHeroSubtitle =>
      'Địa điểm gợi ý là dữ liệu xem trước cục bộ. Chuyến đi cá nhân vẫn ở cục bộ cho đến khi có backend.';

  @override
  String get exploreSearchHint =>
      'Tìm thành phố, địa điểm, quán cà phê, khách sạn...';

  @override
  String get exploreSearchActionSemantic => 'Mở kết quả tìm kiếm';

  @override
  String get exploreFiltersSemantic => 'Mở bộ lọc tìm kiếm';

  @override
  String get exploreNoUpcomingTitle => 'Chưa có chuyến đi sắp tới';

  @override
  String get exploreNoUpcomingMessage =>
      'Tạo chuyến đi demo cục bộ khi bạn sẵn sàng lên kế hoạch.';

  @override
  String get exploreCategoriesTitle => 'Khám phá theo danh mục';

  @override
  String get exploreRecommendedTitle => 'Địa điểm gợi ý';

  @override
  String get exploreSeeAll => 'Xem tất cả';

  @override
  String get exploreNoPlacesTitle => 'Chưa có địa điểm';

  @override
  String get exploreNoPlacesMessage =>
      'Nội dung Khám phá sẽ xuất hiện khi có dữ liệu cục bộ.';

  @override
  String get exploreUpcomingTripSemantic => 'Tóm tắt chuyến đi sắp tới';

  @override
  String explorePlanningProgress(int count) {
    return '$count hoạt động đã lên kế hoạch';
  }

  @override
  String get searchTitle => 'Khám phá địa điểm';

  @override
  String get searchHint => 'Tìm khách sạn, món ăn, cà phê, điểm tham quan...';

  @override
  String get searchClearSemantic => 'Xóa tìm kiếm';

  @override
  String get searchModeSemantic => 'Chế độ hiển thị tìm kiếm';

  @override
  String get searchListMode => 'Danh sách';

  @override
  String get searchMapMode => 'Bản đồ';

  @override
  String searchResultCount(int count) {
    return '$count địa điểm';
  }

  @override
  String get searchClearFilters => 'Xóa bộ lọc';

  @override
  String get searchEmptyTitle => 'Không tìm thấy địa điểm';

  @override
  String get searchEmptyMessage => 'Thử từ khóa, danh mục hoặc thẻ khác.';

  @override
  String get searchFiltersTitle => 'Bộ lọc';

  @override
  String get searchSortTitle => 'Sắp xếp';

  @override
  String get searchSortRelevance => 'Phù hợp';

  @override
  String get searchSortRating => 'Đánh giá';

  @override
  String get searchSortDuration => 'Thời lượng';

  @override
  String get searchTagsTitle => 'Thẻ';

  @override
  String get searchApplyFilters => 'Áp dụng bộ lọc';

  @override
  String get searchBackToList => 'Quay lại danh sách';

  @override
  String get mapFallbackSemantic => 'Bản đồ minh họa không trực tiếp';

  @override
  String get mapUnavailableTitle => 'Chưa kết nối nhà cung cấp bản đồ';

  @override
  String get mapUnavailableMessage =>
      'Bản đồ trực tiếp, tuyến đường, giao thông và tọa độ chính xác chưa được kết nối. Bản xem trước này chỉ là sơ đồ minh họa.';

  @override
  String placeReviewCount(int count) {
    return '$count đánh giá';
  }

  @override
  String get placeAddToTrip => 'Thêm vào chuyến đi';

  @override
  String placeAddToTripSemantic(String place) {
    return 'Thêm $place vào chuyến đi';
  }

  @override
  String get placeHighlightsTitle => 'Điểm nổi bật';

  @override
  String get placeUsefulInfoTitle => 'Thông tin hữu ích';

  @override
  String placeDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String placeDurationHours(int hours) {
    return '$hours giờ';
  }

  @override
  String placeDurationHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String get savedPlacesDemoLocalOnly =>
      'Địa điểm đã lưu chỉ nằm trong phiên demo cục bộ này.';

  @override
  String get tripsTitle => 'My trips';

  @override
  String get tripsSubtitle =>
      'Các mục thông minh được suy ra từ ngày chuyến đi.';

  @override
  String get tripsCreateAction => 'Tạo chuyến đi';

  @override
  String get tripsCreateSemantic => 'Tạo chuyến đi mới';

  @override
  String get tripsEmptyTitle => 'Chưa có chuyến đi';

  @override
  String get tripsEmptyMessage => 'Tạo chuyến đi cục bộ đầu tiên để bắt đầu.';

  @override
  String get tripsRealUnavailableMessage =>
      'Lịch sử chuyến đi cá nhân chưa được kết nối với kho backend.';

  @override
  String get tripsOngoing => 'Đang diễn ra';

  @override
  String get tripsUpcoming => 'Sắp tới';

  @override
  String get tripsPast => 'Đã kết thúc';

  @override
  String get tripsOngoingEmpty => 'Không có chuyến đi nào diễn ra hôm nay.';

  @override
  String get tripsUpcomingEmpty => 'Chưa có chuyến đi sắp tới.';

  @override
  String get tripsPastEmpty => 'Chưa có chuyến đi đã hoàn thành.';

  @override
  String tripCardSemantic(String trip) {
    return 'Thẻ chuyến đi $trip';
  }

  @override
  String tripActionsSemantic(String trip) {
    return 'Hành động cho $trip';
  }

  @override
  String get tripEditAction => 'Sửa chuyến đi';

  @override
  String get tripDeleteAction => 'Xóa chuyến đi';

  @override
  String get tripDeleteConfirmTitle => 'Xóa chuyến đi?';

  @override
  String tripDeleteConfirmMessage(String trip) {
    return 'Xóa \"$trip\"? Thao tác này cũng xóa lịch trình và chi phí của chuyến đi.';
  }

  @override
  String get tripDeletedMessage => 'Đã xóa chuyến đi.';

  @override
  String get tripCreatedMessage => 'Đã tạo chuyến đi cục bộ.';

  @override
  String tripDayCount(int days) {
    return '$days ngày';
  }

  @override
  String tripTravelerCount(int travelers) {
    return '$travelers người';
  }

  @override
  String tripDateTravelerMeta(String start, String end, int travelers) {
    return '$start - $end · $travelers người';
  }

  @override
  String tripDaysAway(int days) {
    return 'Bắt đầu sau $days ngày';
  }

  @override
  String get createTripTitle => 'New trip';

  @override
  String get createBackStep => 'Quay lại bước trước';

  @override
  String get createCloseSemantic => 'Đóng luồng tạo chuyến đi';

  @override
  String createStepLabel(int step) {
    return 'Bước $step/3';
  }

  @override
  String get createContinueAction => 'Tiếp tục';

  @override
  String get createContinueSemantic =>
      'Chuyển sang bước tạo chuyến đi tiếp theo';

  @override
  String get createSubmitAction => 'Tạo chuyến đi';

  @override
  String get createSubmitSemantic => 'Tạo chuyến đi này';

  @override
  String get createDestinationRequired => 'Vui lòng nhập điểm đến.';

  @override
  String get createDatesRequired =>
      'Nhập ngày bắt đầu và kết thúc theo định dạng dd/mm/yyyy.';

  @override
  String get createInvalidDateRange =>
      'Ngày kết thúc không được trước ngày bắt đầu.';

  @override
  String get createInvalidTravelers => 'Số người phải từ 1 đến 20.';

  @override
  String get createDiscardTitle => 'Bỏ bản nháp chuyến đi?';

  @override
  String get createDiscardMessage => 'Chi tiết chuyến đi đã nhập sẽ bị mất.';

  @override
  String get createDiscardAction => 'Bỏ';

  @override
  String get createDestinationTitle => 'Bạn muốn đi đâu?';

  @override
  String get createDestinationSubtitle =>
      'Chọn điểm đến từ dữ liệu cục bộ hoặc tự nhập.';

  @override
  String get createDestinationLabel => 'Điểm đến';

  @override
  String get createTripNameLabel => 'Tên chuyến đi';

  @override
  String get createDestinationSuggestions => 'Điểm đến gợi ý';

  @override
  String get createDatesTitle => 'Khi nào bạn sẽ đi?';

  @override
  String get createDatesSubtitle =>
      'Nhập ngày và số người cho chuyến đi cục bộ này.';

  @override
  String get createStartDateLabel => 'Ngày bắt đầu';

  @override
  String get createEndDateLabel => 'Ngày kết thúc';

  @override
  String get createDateFormatHint => 'Dùng dd/mm/yyyy';

  @override
  String get createTravelersLabel => 'Số người';

  @override
  String get createDecreaseTravelers => 'Giảm số người';

  @override
  String get createIncreaseTravelers => 'Tăng số người';

  @override
  String get createBudgetLabel => 'Ngân sách (VND)';

  @override
  String get createPersonalizationTitle =>
      'Thiết kế chuyến đi theo cách của bạn';

  @override
  String get createPersonalizationSubtitle =>
      'Các tùy chọn này chỉ là bản nháp cục bộ.';

  @override
  String get createPreferencesTitle => 'Sở thích';

  @override
  String get createPreferenceFood => 'Ẩm thực';

  @override
  String get createPreferenceCulture => 'Văn hóa';

  @override
  String get createPreferenceNature => 'Thiên nhiên';

  @override
  String get createPreferenceRelax => 'Thư giãn';

  @override
  String get createPreferenceAdventure => 'Phiêu lưu';

  @override
  String get createPreferenceShopping => 'Mua sắm';

  @override
  String get createPaceTitle => 'Nhịp độ';

  @override
  String get createPaceSlow => 'Thư thả';

  @override
  String get createPaceBalanced => 'Cân bằng';

  @override
  String get createPacePacked => 'Dày đặc';

  @override
  String get createBudgetStyleTitle => 'Kiểu ngân sách';

  @override
  String get createBudgetSaving => 'Tiết kiệm';

  @override
  String get createBudgetComfort => 'Thoải mái';

  @override
  String get createBudgetPremium => 'Cao cấp';

  @override
  String get createNotesLabel => 'Ghi chú';

  @override
  String get createPersonalizationLocalOnly =>
      'Sở thích chỉ được giữ trong bản nháp này và không gửi tới backend.';

  @override
  String get createReviewTitle => 'Xem lại';

  @override
  String createReviewSummary(String title, String destination, String start,
      String end, int travelers) {
    return '$title · $destination · $start đến $end · $travelers người';
  }

  @override
  String get createConfirmAction => 'Xác nhận';

  @override
  String editTripTitle(String trip) {
    return 'Sửa $trip';
  }

  @override
  String get editTripHeading => 'Cập nhật chuyến đi';

  @override
  String get editTripSaveAction => 'Cập nhật chuyến đi';

  @override
  String get editTripUpdatedMessage => 'Đã cập nhật chuyến đi.';

  @override
  String get editMoveActivitiesTitle => 'Di chuyển hoạt động?';

  @override
  String editMoveActivitiesMessage(int days) {
    return 'Chuyến đi ngắn hơn này có $days ngày. Hoạt động ở các ngày bị xóa sẽ chuyển về ngày cuối mới.';
  }

  @override
  String get editMoveActivitiesAction => 'Chuyển về ngày cuối';

  @override
  String get tripOverviewProgressTitle => 'Tiến độ chuyến đi';

  @override
  String tripOverviewProgressValue(int percent) {
    return 'Hoàn thành $percent%';
  }

  @override
  String get tripOverviewTimelineAction => 'Lịch trình';

  @override
  String get tripOverviewExpensesAction => 'Ngân sách';

  @override
  String get tripOverviewActivitiesMetric => 'Hoạt động';

  @override
  String get tripOverviewSpentMetric => 'Đã chi';

  @override
  String get tripOverviewBudgetMetric => 'Ngân sách';

  @override
  String get tripOverviewNextTitle => 'Tiếp theo';

  @override
  String get tripOverviewNoActivitiesTitle => 'Chưa có hoạt động';

  @override
  String get tripOverviewNoActivitiesMessage =>
      'Mở lịch trình hiện có để thêm hoạt động.';

  @override
  String tripOverviewDayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String get categoryFoodTitle => 'Ẩm thực & cà phê';

  @override
  String get categoryFoodSubtitle =>
      'Duyệt địa điểm ăn uống và cà phê theo các danh mục được hỗ trợ.';

  @override
  String get categoryFoodSearchHint => 'Tìm món ăn, quán cà phê hoặc đặc sản';

  @override
  String get categoryThingsTitle => 'Hoạt động vui chơi';

  @override
  String get categoryThingsSubtitle =>
      'Điểm tham quan và giải trí được tách riêng để khớp backend sau này.';

  @override
  String get categoryThingsSearchHint => 'Tìm điểm tham quan hoặc giải trí';

  @override
  String get categoryTransportTitle => 'Di chuyển';

  @override
  String get categoryTransportSubtitle =>
      'Duyệt địa điểm di chuyển mà không giả lập tuyến, giá vé hoặc lịch chạy.';

  @override
  String get categoryTransportSearchHint => 'Tìm nhà cung cấp di chuyển';

  @override
  String get categoryRootAll => 'Tất cả';

  @override
  String get categoryRootFood => 'Ẩm thực';

  @override
  String get categoryRootCafe => 'Cà phê';

  @override
  String get categoryRootAttraction => 'Tham quan';

  @override
  String get categoryRootEntertainment => 'Giải trí';

  @override
  String get categoryRootTransportation => 'Di chuyển';

  @override
  String get categoryFiltersSemantic => 'Mở bộ lọc danh mục';

  @override
  String get categoryFiltersTitle => 'Bộ lọc danh mục';

  @override
  String get categoryFilterRating => 'Đánh giá';

  @override
  String get categoryFilterRating45 => 'Đánh giá 4,5+';

  @override
  String get categoryFilterPrice => 'Mức giá';

  @override
  String get categoryFilterPriceAny => 'Mọi mức giá';

  @override
  String get categoryFilterApply => 'Áp dụng bộ lọc';

  @override
  String get categoryEmptyTitle => 'Không có kết quả danh mục';

  @override
  String get categoryEmptyMessage =>
      'Thử từ khóa, danh mục gốc, đánh giá hoặc mức giá khác.';

  @override
  String get categoryLocalPreviewMessage =>
      'Kết quả danh mục công khai này là nội dung xem trước cục bộ và không phải dữ liệu cá nhân từ máy chủ.';

  @override
  String get categoryTransportUnavailableTitle => 'Chưa kết nối tuyến đường';

  @override
  String get categoryTransportUnavailableMessage =>
      'Tuyến trực tiếp, giá vé, lịch chạy, thời gian di chuyển, định vị và đặt vé chưa được kết nối.';

  @override
  String get budgetTitle => 'Ngân sách chuyến đi';

  @override
  String get budgetHeading => 'Tổng quan ngân sách';

  @override
  String get budgetTripSelectorLabel => 'Chuyến đi';

  @override
  String get budgetNoTripTitle => 'Chưa có ngân sách chuyến đi';

  @override
  String get budgetNoTripMessage =>
      'Tạo chuyến đi trước khi theo dõi ngân sách theo chuyến.';

  @override
  String get budgetOverviewSemantic => 'Tổng quan ngân sách';

  @override
  String get budgetTotalBudget => 'Tổng ngân sách';

  @override
  String get budgetSetAction => 'Đặt ngân sách';

  @override
  String get budgetSetTitle => 'Đặt ngân sách chuyến đi';

  @override
  String get budgetAmountLabel => 'Số tiền ngân sách';

  @override
  String get budgetNotSet => 'Chưa đặt';

  @override
  String get budgetSpent => 'Đã chi';

  @override
  String get budgetLeft => 'Còn lại';

  @override
  String get budgetOverBy => 'Vượt';

  @override
  String budgetProgressSemantic(int percent) {
    return 'Tiến độ ngân sách đã dùng $percent phần trăm';
  }

  @override
  String get budgetProgressMissingSemantic =>
      'Chưa có tiến độ ngân sách vì chưa đặt ngân sách';

  @override
  String budgetProgressLabel(int percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String budgetOverMessage(String amount) {
    return 'Vượt ngân sách $amount';
  }

  @override
  String get budgetMissingBudgetTitle => 'Chưa cấu hình ngân sách';

  @override
  String get budgetMissingBudgetMessage =>
      'Bạn vẫn có thể theo dõi chi phí trước khi đặt tổng ngân sách.';

  @override
  String get budgetNoExpensesTitle => 'Chưa có chi phí';

  @override
  String get budgetNoExpensesMessage =>
      'Thêm chi phí để tạo lịch sử chi tiêu cục bộ cho chuyến đi.';

  @override
  String get budgetByCategoryTitle => 'Theo danh mục';

  @override
  String get budgetHistoryTitle => 'Lịch sử chi phí';

  @override
  String budgetMixedCurrencyWarning(String currency) {
    return 'Chuyến đi có chi phí ngoài $currency. Tổng chỉ hiển thị $currency để tránh cộng lẫn tiền tệ.';
  }

  @override
  String get budgetSavedMessage => 'Đã cập nhật ngân sách cục bộ.';

  @override
  String get budgetSaveFailed => 'Không thể lưu ngân sách này.';

  @override
  String get expenseAddSemantic => 'Thêm chi phí';

  @override
  String get expenseAddAction => 'Thêm chi phí';

  @override
  String get expenseAddTitle => 'Thêm chi phí';

  @override
  String get expenseEditTitle => 'Sửa chi phí';

  @override
  String get expenseSaveAction => 'Lưu chi phí';

  @override
  String get expenseSaveSemantic => 'Lưu chi phí này';

  @override
  String get expenseTitleLabel => 'Tên khoản chi';

  @override
  String get expenseTitleRequired => 'Nhập tên khoản chi.';

  @override
  String get expenseAmountLabel => 'Số tiền';

  @override
  String get expenseAmountInvalid => 'Nhập số tiền hữu hạn lớn hơn 0.';

  @override
  String get expenseCurrencyLabel => 'Tiền tệ';

  @override
  String get expenseCategoryLabel => 'Danh mục';

  @override
  String get expenseDateLabel => 'Ngày chi';

  @override
  String get expenseLinkedDayLabel => 'Ngày liên kết';

  @override
  String get expenseNoLinkedDay => 'Không liên kết ngày';

  @override
  String get expenseLinkedDayInvalid =>
      'Ngày liên kết phải thuộc chuyến đi đã chọn.';

  @override
  String get expenseLinkedItemLabel => 'Hoạt động liên kết';

  @override
  String get expenseNoLinkedItem => 'Không liên kết hoạt động';

  @override
  String get expenseLinkedItemInvalid =>
      'Hoạt động liên kết phải thuộc chuyến đi đã chọn.';

  @override
  String get expenseNotesLabel => 'Ghi chú';

  @override
  String get expenseTripRequired => 'Chọn chuyến đi hợp lệ.';

  @override
  String get expenseDateOutOfRange =>
      'Ngày chi phải nằm trong khoảng ngày của chuyến đi đã chọn.';

  @override
  String get expenseSaveFailed =>
      'Không thể lưu chi phí này cho chuyến đi đã chọn.';

  @override
  String get expenseAddedMessage => 'Đã thêm chi phí cục bộ.';

  @override
  String get expenseSavedMessage => 'Đã cập nhật chi phí cục bộ.';

  @override
  String expenseTileSemantic(String title) {
    return 'Chi phí $title';
  }

  @override
  String expenseActionsSemantic(String title) {
    return 'Hành động cho chi phí $title';
  }

  @override
  String get expenseEditAction => 'Sửa';

  @override
  String get expenseDeleteAction => 'Xóa';

  @override
  String get expenseDeleteConfirmTitle => 'Xóa chi phí?';

  @override
  String expenseDeleteConfirmMessage(String title) {
    return 'Xóa \"$title\" khỏi ngân sách chuyến đi này?';
  }

  @override
  String get expenseDeletedMessage => 'Đã xóa chi phí.';

  @override
  String get expenseCategoryAccommodation => 'Chỗ ở';

  @override
  String get expenseCategoryFood => 'Ăn uống';

  @override
  String get expenseCategoryTransport => 'Di chuyển';

  @override
  String get expenseCategoryAttraction => 'Tham quan';

  @override
  String get expenseCategoryShopping => 'Mua sắm';

  @override
  String get expenseCategoryHealth => 'Sức khỏe';

  @override
  String get expenseCategoryVisa => 'Visa';

  @override
  String get expenseCategoryInsurance => 'Bảo hiểm';

  @override
  String get expenseCategoryOther => 'Khác';

  @override
  String get hotelsTitle => 'Khách sạn';

  @override
  String get hotelsSubtitle =>
      'Tìm chỗ ở từ dữ liệu địa điểm công khai, rồi xem một phòng và một báo giá cục bộ.';

  @override
  String get hotelsDestinationLabel => 'Điểm đến';

  @override
  String get hotelsDestinationHint => 'Thành phố, khách sạn hoặc khu vực';

  @override
  String get hotelsCheckInLabel => 'Nhận phòng';

  @override
  String get hotelsCheckOutLabel => 'Trả phòng';

  @override
  String get hotelsAdultsLabel => 'Người lớn';

  @override
  String get hotelsChildrenLabel => 'Trẻ em';

  @override
  String get hotelsSearchAction => 'Tìm chỗ ở';

  @override
  String get hotelsSearchSemantic => 'Tìm chỗ ở khách sạn';

  @override
  String hotelsTripPrefillLabel(String trip) {
    return 'Điền từ $trip';
  }

  @override
  String get hotelsLocalPreviewMessage =>
      'Khám phá khách sạn dùng dữ liệu địa điểm chỗ ở cục bộ. Tình trạng phòng, báo giá và đặt phòng chỉ là giao diện trong giai đoạn này.';

  @override
  String hotelsResultCount(int count) {
    return '$count khách sạn';
  }

  @override
  String get hotelsEmptyTitle => 'Không tìm thấy chỗ ở';

  @override
  String get hotelsEmptyMessage => 'Thử điểm đến hoặc số khách khác.';

  @override
  String get hotelsValidationPastCheckIn =>
      'Ngày nhận phòng không được trước hôm nay.';

  @override
  String get hotelsValidationCheckout =>
      'Ngày trả phòng phải sau ngày nhận phòng.';

  @override
  String get hotelsValidationAdults => 'Cần ít nhất một người lớn.';

  @override
  String get hotelsValidationChildren => 'Số trẻ em không được âm.';

  @override
  String get hotelsValidationExtraBeds => 'Số giường phụ không được âm.';

  @override
  String get hotelDetailTitle => 'Chi tiết khách sạn';

  @override
  String hotelStars(int stars) {
    return '$stars sao';
  }

  @override
  String hotelCheckInOutMeta(String checkIn, String checkOut) {
    return 'Nhận phòng $checkIn · Trả phòng $checkOut';
  }

  @override
  String hotelAvailableRooms(int count) {
    return '$count phòng phù hợp';
  }

  @override
  String get hotelBreakfastIncluded => 'Bữa sáng';

  @override
  String get hotelAirportShuttle => 'Đưa đón sân bay';

  @override
  String hotelDistanceBeach(int meters) {
    return '$meters m tới biển';
  }

  @override
  String hotelDistanceCenter(int meters) {
    return '$meters m tới trung tâm';
  }

  @override
  String hotelLanguages(String languages) {
    return 'Ngôn ngữ: $languages';
  }

  @override
  String hotelPaymentMethods(String methods) {
    return 'Phương thức thanh toán: $methods';
  }

  @override
  String get hotelFacilitiesTitle => 'Tiện nghi';

  @override
  String get hotelServicesTitle => 'Dịch vụ';

  @override
  String get hotelRoomPreviewTitle => 'Xem trước phòng';

  @override
  String get hotelCheckAvailabilityAction => 'Kiểm tra phòng';

  @override
  String hotelCheckAvailabilitySemantic(String hotel) {
    return 'Kiểm tra phòng cho $hotel';
  }

  @override
  String get hotelViewRoomsAction => 'Xem phòng';

  @override
  String hotelCardSemantic(String hotel) {
    return 'Thẻ khách sạn $hotel';
  }

  @override
  String hotelFromPrice(String price) {
    return 'Từ $price';
  }

  @override
  String get hotelRoomsTitle => 'Phòng và giá';

  @override
  String get hotelAvailableRoomsTitle => 'Phòng khả dụng';

  @override
  String get hotelNoAvailabilityTitle => 'Không có phòng phù hợp';

  @override
  String get hotelNoAvailabilityMessage =>
      'Không có phòng cục bộ phù hợp với số khách đã chọn. Hãy đổi ngày hoặc số khách.';

  @override
  String get hotelRatePlansTitle => 'Chọn gói giá';

  @override
  String get hotelContinueReviewAction => 'Xem lại đặt phòng';

  @override
  String get hotelContinueReviewSemantic =>
      'Tiếp tục đến bước xem lại đặt phòng';

  @override
  String hotelNights(int nights) {
    return '$nights đêm';
  }

  @override
  String hotelGuestSummary(int adults, int children) {
    return '$adults người lớn · $children trẻ em';
  }

  @override
  String get hotelOneRoomOnly => '1 phòng';

  @override
  String get hotelAddAdultAction => 'Thêm người lớn';

  @override
  String get hotelExtendStayAction => 'Thêm đêm';

  @override
  String hotelRoomCardSemantic(String room) {
    return 'Thẻ phòng $room';
  }

  @override
  String hotelMaxGuests(int guests) {
    return 'Tối đa $guests khách';
  }

  @override
  String hotelRoomSize(int size) {
    return '$size m²';
  }

  @override
  String hotelBedCount(int count, String label) {
    return '$count × $label';
  }

  @override
  String hotelRatePlanSemantic(String plan) {
    return 'Gói giá $plan';
  }

  @override
  String get roomTypeStandard => 'Standard';

  @override
  String get roomTypeSuperior => 'Superior';

  @override
  String get roomTypeDeluxe => 'Deluxe';

  @override
  String get roomTypePremier => 'Premier';

  @override
  String get roomTypeExecutive => 'Executive';

  @override
  String get roomTypeSuite => 'Suite';

  @override
  String get roomTypeFamily => 'Gia đình';

  @override
  String get roomTypeVilla => 'Villa';

  @override
  String get roomTypeBungalow => 'Bungalow';

  @override
  String get bedTypeSingle => 'Giường đơn';

  @override
  String get bedTypeDouble => 'Giường đôi';

  @override
  String get bedTypeTwin => 'Hai giường đơn';

  @override
  String get bedTypeQueen => 'Giường queen';

  @override
  String get bedTypeKing => 'Giường king';

  @override
  String get bedTypeSofaBed => 'Giường sofa';

  @override
  String get bedTypeBunk => 'Giường tầng';

  @override
  String get mealPlanRoomOnly => 'Chỉ phòng';

  @override
  String get mealPlanBreakfast => 'Bữa sáng';

  @override
  String get mealPlanHalfBoard => 'Nửa gói ăn';

  @override
  String get mealPlanFullBoard => 'Trọn gói ăn';

  @override
  String get mealPlanAllInclusive => 'Bao gồm tất cả';

  @override
  String get cancellationFree => 'Hủy miễn phí';

  @override
  String get cancellationPartial => 'Hoàn tiền một phần';

  @override
  String get cancellationNonRefundable => 'Không hoàn tiền';

  @override
  String get cancellationCustom => 'Chính sách riêng';

  @override
  String get bookingReviewTitle => 'Xem lại đặt phòng';

  @override
  String get bookingSelectedPlanTitle => 'Gói giá đã chọn';

  @override
  String bookingQuoteExpiry(String time) {
    return 'Báo giá hết hạn lúc $time';
  }

  @override
  String get bookingAccountTitle => 'Tài khoản';

  @override
  String get bookingAccountReadOnly =>
      'Danh tính này chỉ để xem tại đây và không gửi kèm trường hồ sơ khách chưa hỗ trợ.';

  @override
  String get bookingSpecialRequestLabel => 'Yêu cầu đặc biệt';

  @override
  String get bookingSpecialRequestHelper =>
      'Ghi chú tùy chọn. Không thu thập thanh toán hoặc hồ sơ khách.';

  @override
  String get bookingPriceTitle => 'Báo giá';

  @override
  String get bookingPriceSemantic => 'Báo giá đặt phòng';

  @override
  String get bookingFinalNightlyRate => 'Giá cuối mỗi đêm';

  @override
  String get bookingStaySubtotal => 'Tạm tính kỳ lưu trú';

  @override
  String get bookingPromotionDiscount => 'Giảm giá khuyến mãi';

  @override
  String get bookingFinalQuotedPrice => 'Tổng báo giá cuối';

  @override
  String get bookingCustomerBenefitsExcluded =>
      'Mã giảm giá, điểm thành viên, travel credit và thẻ quà tặng nằm ngoài UI này.';

  @override
  String get bookingQuoteNoReservation =>
      'Báo giá không tạo đặt phòng và không giữ phòng.';

  @override
  String get bookingQuoteUnavailable => 'Chưa có báo giá';

  @override
  String get bookingInventoryUnavailable => 'Không còn phòng cho báo giá này.';

  @override
  String get bookingQuoteExpired =>
      'Báo giá đã hết hạn. Làm mới tiêu chí trước khi xác nhận.';

  @override
  String get bookingDemoBoundaryMessage =>
      'Chế độ demo có thể tạo đặt phòng cục bộ rõ ràng. Dữ liệu này không đồng bộ với backend.';

  @override
  String get bookingRealUnavailableMessage =>
      'Đặt phòng online chưa được kết nối cho tài khoản thật.';

  @override
  String get bookingTermsAcknowledgement =>
      'Tôi hiểu UI này không thu thanh toán hoặc giữ phòng.';

  @override
  String get bookingConfirmAction => 'Xác nhận đặt phòng demo';

  @override
  String get bookingConfirmSemantic => 'Xác nhận đặt phòng demo này';

  @override
  String get bookingDuplicatePrevented => 'Đã chặn tạo đặt phòng trùng.';

  @override
  String get bookingConfirmationTitle => 'Đã xác nhận đặt phòng demo';

  @override
  String get bookingDemoStatus => 'Đặt phòng demo cục bộ';

  @override
  String bookingLocalCode(String code) {
    return 'Mã cục bộ $code';
  }

  @override
  String get bookingConfirmationLocalOnly =>
      'Đặt phòng này chỉ tồn tại trong trạng thái demo cục bộ. Chưa thanh toán, chưa đồng bộ và không giữ phòng.';

  @override
  String get bookingAddItineraryAction => 'Thêm vào lịch trình';

  @override
  String get bookingAddItinerarySemantic =>
      'Thêm đặt phòng này vào lịch trình chuyến đi';

  @override
  String get bookingItineraryAdded => 'Đã thêm vào lịch trình';

  @override
  String get bookingItineraryAlreadyAdded =>
      'Chỗ ở này đã có trong lịch trình.';

  @override
  String get bookingItineraryAddedMessage => 'Đã thêm chỗ ở vào lịch trình.';

  @override
  String bookingItineraryNote(String code) {
    return 'Đặt phòng demo cục bộ $code.';
  }

  @override
  String get bookingViewBookingAction => 'Xem đặt phòng';

  @override
  String get bookingReturnHomeAction => 'Về trang chủ';

  @override
  String get myBookingsTitle => 'Đặt phòng của tôi';

  @override
  String get myBookingsDemoLocalOnly =>
      'Chỉ đặt phòng demo cục bộ xuất hiện tại đây. Endpoint đặt phòng thật chưa được kết nối trong UI-6.';

  @override
  String get myBookingsRealEmptyTitle => 'Chưa kết nối đặt phòng';

  @override
  String get myBookingsRealEmptyMessage =>
      'Đặt phòng tài khoản thật sẽ xuất hiện sau khi tích hợp backend.';

  @override
  String get myBookingsEmptyTitle => 'Chưa có đặt phòng';

  @override
  String get myBookingsEmptyMessage =>
      'Đặt phòng demo sẽ xuất hiện sau khi xác nhận.';

  @override
  String myBookingCardSemantic(String code) {
    return 'Thẻ đặt phòng $code';
  }

  @override
  String get bookingDetailsTitle => 'Chi tiết đặt phòng';

  @override
  String get bookingPaymentUnavailableAction => 'Chưa có thanh toán';

  @override
  String get bookingPaymentUnavailable =>
      'Hành động thanh toán chưa được kết nối trong UI này.';

  @override
  String get bookingCancelAction => 'Hủy đặt phòng';

  @override
  String get bookingCancelSemantic => 'Hủy đặt phòng demo này';

  @override
  String get bookingCancelConfirmTitle => 'Hủy đặt phòng demo?';

  @override
  String get bookingCancelReasonLabel => 'Lý do hủy';

  @override
  String get bookingCancelledMessage => 'Đã hủy đặt phòng demo cục bộ.';

  @override
  String get bookingSectionAll => 'Tất cả';

  @override
  String get bookingSectionUpcoming => 'Sắp tới';

  @override
  String get bookingSectionActive => 'Đang ở';

  @override
  String get bookingSectionHistory => 'Lịch sử';

  @override
  String get bookingSectionCancelled => 'Đã hủy';

  @override
  String get bookingStatusPending => 'Đang chờ';

  @override
  String get bookingStatusConfirmed => 'Đã xác nhận';

  @override
  String get bookingStatusCheckInReady => 'Sẵn sàng nhận phòng';

  @override
  String get bookingStatusCheckedIn => 'Đã nhận phòng';

  @override
  String get bookingStatusCheckedOut => 'Đã trả phòng';

  @override
  String get bookingStatusCompleted => 'Hoàn tất';

  @override
  String get bookingStatusCancelled => 'Đã hủy';

  @override
  String get bookingStatusRefunded => 'Đã hoàn tiền';

  @override
  String get bookingStatusArchived => 'Đã lưu trữ';

  @override
  String get bookingStatusNoShow => 'Không đến';

  @override
  String get rewardsTitle => 'Ưu đãi & quyền lợi';

  @override
  String get rewardsDemoSubtitle =>
      'Ưu đãi demo cục bộ để xem trước tín dụng, điểm, mã giảm giá, giới thiệu và thẻ quà tặng.';

  @override
  String get rewardsRealUnavailableMessage =>
      'Endpoint ưu đãi chưa được kết nối cho tài khoản thật.';

  @override
  String get rewardsRealEmptyTitle => 'Chưa kết nối ưu đãi';

  @override
  String get rewardsNotConnected => 'Chưa kết nối';

  @override
  String rewardsCountValue(int count) {
    return '$count mục';
  }

  @override
  String get rewardsHistoryEmptyTitle => 'Chưa có lịch sử';

  @override
  String get rewardsHistoryEmptyMessage =>
      'Lịch sử ưu đãi sẽ xuất hiện khi có dữ liệu.';

  @override
  String get rewardsActionUnavailable =>
      'Hành động ưu đãi này chưa được kết nối cho tài khoản thật.';

  @override
  String get rewardsCodeBlank => 'Hãy nhập mã trước.';

  @override
  String get rewardsCodeDuplicate => 'Mã này đã được dùng hoặc đã được nhận.';

  @override
  String get rewardsCodeRejected => 'Mã demo này không đủ điều kiện.';

  @override
  String rewardsExpiresOn(String date) {
    return 'Hết hạn $date';
  }

  @override
  String get travelCreditsTitle => 'Tín dụng du lịch';

  @override
  String get travelCreditsSubtitle =>
      'Tín dụng khuyến mãi dạng tiền, tách biệt với ví giấy tờ du lịch.';

  @override
  String get travelCreditsSemantic => 'Mở Tín dụng du lịch';

  @override
  String get travelCreditsBalance => 'Tín dụng khả dụng';

  @override
  String get travelCreditsBalanceSemantic => 'Số dư tín dụng du lịch';

  @override
  String get travelCreditsLocalOnly =>
      'Tín dụng demo là dữ liệu xem trước cục bộ và không đồng bộ.';

  @override
  String get travelCreditsNoCashOut =>
      'Rút tiền, chuyển khoản và chuyển nhượng được cố ý tắt.';

  @override
  String get travelCreditsTransactions => 'Giao dịch tín dụng';

  @override
  String get creditTxnGrant => 'Cấp tín dụng';

  @override
  String get creditTxnPromotion => 'Khuyến mãi';

  @override
  String get creditTxnRefund => 'Hoàn bằng tín dụng';

  @override
  String get creditTxnAdjustment => 'Điều chỉnh';

  @override
  String get creditTxnRedemption => 'Sử dụng';

  @override
  String get creditTxnExpiration => 'Hết hạn';

  @override
  String get creditTxnReversal => 'Hoàn tác';

  @override
  String get loyaltyTitle => 'Điểm thành viên';

  @override
  String get loyaltySubtitle =>
      'Số dư điểm nguyên và lịch sử giao dịch bất biến.';

  @override
  String get loyaltySemantic => 'Mở Điểm thành viên';

  @override
  String get loyaltyBalanceSemantic => 'Số dư điểm thành viên';

  @override
  String get loyaltyCurrentBalance => 'Số dư hiện tại';

  @override
  String get loyaltyLifetimeEarned => 'Tổng điểm đã kiếm';

  @override
  String loyaltyPointsValue(int points) {
    return '$points điểm';
  }

  @override
  String get pointsUnit => 'điểm';

  @override
  String get loyaltyNoDirectRedeem =>
      'Điểm không phải tiền và đổi điểm trực tiếp chưa được kết nối trong UI-7.';

  @override
  String get loyaltyTransactions => 'Giao dịch điểm';

  @override
  String get loyaltyTxnEarnBooking => 'Kiếm từ đặt phòng';

  @override
  String get loyaltyTxnEarnReview => 'Kiếm từ đánh giá';

  @override
  String get loyaltyTxnGrant => 'Cấp điểm';

  @override
  String get loyaltyTxnAdjustment => 'Điều chỉnh';

  @override
  String get loyaltyTxnReversal => 'Hoàn tác';

  @override
  String get loyaltyTxnRedemptionDebit => 'Trừ điểm đổi thưởng';

  @override
  String get loyaltyTxnRedemptionRelease => 'Giải phóng điểm';

  @override
  String get loyaltyTxnRedemptionRefund => 'Hoàn điểm';

  @override
  String get membershipTitle => 'Hạng thành viên';

  @override
  String get membershipSubtitle =>
      'Tiến độ hạng, metadata quyền lợi và lịch sử hạng.';

  @override
  String get membershipSemantic => 'Mở Hạng thành viên';

  @override
  String get membershipRealUnavailable =>
      'Đăng ký thành viên chưa được kết nối cho tài khoản thật.';

  @override
  String get membershipTierSemantic => 'Hạng và tiến độ thành viên';

  @override
  String get membershipActiveStatus => 'Đang hoạt động';

  @override
  String get membershipPreviewStatus => 'Xem trước';

  @override
  String get membershipExpiredStatus => 'Hết hạn';

  @override
  String get membershipActiveMessage =>
      'Hạng thành viên demo này đang hoạt động cục bộ.';

  @override
  String get membershipPreviewMessage =>
      'Xem trước quyền lợi trước khi đăng ký demo.';

  @override
  String membershipProgressSemantic(int percent) {
    return 'Tiến độ hạng thành viên $percent phần trăm';
  }

  @override
  String get membershipHighestTier =>
      'Đã đạt hạng cao nhất. Không hiển thị hạng kế tiếp giả.';

  @override
  String membershipNextTier(String tier) {
    return 'Hạng tiếp theo: $tier';
  }

  @override
  String get membershipEnrollAction => 'Đăng ký cục bộ';

  @override
  String get membershipEnrolledAction => 'Đã đăng ký cục bộ';

  @override
  String get membershipEnrollSemantic => 'Đăng ký hạng thành viên demo cục bộ';

  @override
  String get membershipEnrollSuccess => 'Đã đăng ký thành viên demo cục bộ.';

  @override
  String get membershipBenefitsTitle => 'Metadata quyền lợi';

  @override
  String get membershipHistoryTitle => 'Lịch sử hạng';

  @override
  String get membershipTierBronze => 'Đồng';

  @override
  String get membershipTierSilver => 'Bạc';

  @override
  String get membershipTierGold => 'Vàng';

  @override
  String get membershipTierPlatinum => 'Bạch kim';

  @override
  String get membershipTierDiamond => 'Kim cương';

  @override
  String get benefitPointsMultiplier => 'Hệ số điểm';

  @override
  String get benefitMemberCoupons => 'Mã chỉ dành cho thành viên';

  @override
  String get benefitPrioritySupport => 'Hỗ trợ ưu tiên';

  @override
  String get benefitEarlyAccess => 'Truy cập sớm';

  @override
  String get benefitLateCheckout => 'Trả phòng muộn';

  @override
  String get benefitEarlyCheckin => 'Nhận phòng sớm';

  @override
  String get benefitRoomUpgrade => 'Nâng hạng phòng';

  @override
  String get benefitFreeBreakfast => 'Bữa sáng miễn phí';

  @override
  String get benefitAirportTransfer => 'Đưa đón sân bay';

  @override
  String get benefitCustom => 'Quyền lợi tùy chỉnh';

  @override
  String get couponsTitle => 'Mã giảm giá';

  @override
  String get couponsSubtitle =>
      'Mã đã nhận và xem trước điều kiện dạng chỉ đọc.';

  @override
  String get couponsSemantic => 'Mở Mã giảm giá';

  @override
  String get couponsRealUnavailable =>
      'Nhận mã giảm giá chưa được kết nối cho tài khoản thật.';

  @override
  String get couponClaimTitle => 'Nhận mã demo';

  @override
  String get couponCodeLabel => 'Mã giảm giá';

  @override
  String get couponClaimHelper =>
      'Dùng LOCAL300 để nhận demo cục bộ. Mã không được áp vào đặt phòng.';

  @override
  String get couponClaimAction => 'Nhận mã';

  @override
  String get couponClaimSemantic => 'Nhận mã giảm giá demo cục bộ';

  @override
  String get couponClaimSuccess => 'Đã nhận mã demo cục bộ.';

  @override
  String get couponsEmptyTitle => 'Chưa có mã';

  @override
  String get couponsEmptyMessage =>
      'Mã giảm giá sẽ xuất hiện sau khi nhận hoặc kết nối.';

  @override
  String couponCardSemantic(String code) {
    return 'Mã giảm giá $code';
  }

  @override
  String get couponPreviewReadOnly =>
      'Xem trước chỉ đọc và không đánh dấu mã là đã dùng.';

  @override
  String couponPercentageValue(int percent) {
    return 'Giảm $percent%';
  }

  @override
  String couponFixedValue(String amount) {
    return 'Giảm $amount';
  }

  @override
  String get couponAmountUnavailable => 'Chưa có số tiền';

  @override
  String get couponTargetAll => 'Tất cả';

  @override
  String get couponTargetHotel => 'Khách sạn';

  @override
  String get couponTargetRoom => 'Phòng';

  @override
  String get couponTargetPlaceType => 'Loại địa điểm';

  @override
  String get referralTitle => 'Giới thiệu';

  @override
  String get referralSubtitle =>
      'Mã giới thiệu, thống kê và dùng mã demo cục bộ.';

  @override
  String get referralSemantic => 'Mở Giới thiệu';

  @override
  String get referralRealUnavailable =>
      'Hành động giới thiệu chưa được kết nối cho tài khoản thật.';

  @override
  String get referralCodeSemantic => 'Mã giới thiệu';

  @override
  String get referralYourCode => 'Mã giới thiệu của bạn';

  @override
  String referralStats(int successful, int pending) {
    return '$successful thành công · $pending đang chờ';
  }

  @override
  String get referralCopyAction => 'Sao chép mã';

  @override
  String get referralCopiedAction => 'Đã sao chép';

  @override
  String get referralCopySemantic => 'Sao chép mã giới thiệu';

  @override
  String get referralUseCodeTitle => 'Dùng mã giới thiệu';

  @override
  String get referralCodeLabel => 'Mã giới thiệu';

  @override
  String get referralUseCodeHelper =>
      'Dùng mã chỉ tạo giới thiệu cục bộ đang chờ. Không cấp thưởng ngay.';

  @override
  String get referralUseCodeAction => 'Dùng mã';

  @override
  String get referralUseCodeSemantic => 'Dùng mã giới thiệu demo cục bộ';

  @override
  String get referralUseSuccess =>
      'Đã ghi nhận mã giới thiệu cục bộ ở trạng thái chờ.';

  @override
  String get referralOwnCodeRejected =>
      'Bạn không thể dùng mã giới thiệu của chính mình.';

  @override
  String get referralHistoryTitle => 'Lịch sử giới thiệu';

  @override
  String get referralUsedNoReward =>
      'USED nghĩa là đang chờ đủ điều kiện; chưa cấp thưởng.';

  @override
  String get referralRoleInviter => 'Người mời';

  @override
  String get referralRoleInvitee => 'Người được mời';

  @override
  String get referralStatusUsed => 'Đã dùng';

  @override
  String get referralStatusRewarded => 'Đã thưởng';

  @override
  String get giftCardsTitle => 'Thẻ quà tặng';

  @override
  String get giftCardsSubtitle =>
      'Thẻ đã che mã, số dư, chi tiết và xem trước chỉ đọc.';

  @override
  String get giftCardsSemantic => 'Mở Thẻ quà tặng';

  @override
  String get giftCardsRealUnavailable =>
      'Hành động thẻ quà tặng chưa được kết nối cho tài khoản thật.';

  @override
  String get giftCardClaimTitle => 'Nhận thẻ quà tặng demo';

  @override
  String get giftCardCodeLabel => 'Mã thẻ quà tặng';

  @override
  String get giftCardClaimHelper =>
      'Dùng GIFTDEMO để nhận demo cục bộ. Không có luồng mua hoặc thanh toán.';

  @override
  String get giftCardClaimAction => 'Nhận thẻ';

  @override
  String get giftCardClaimSemantic => 'Nhận thẻ quà tặng demo cục bộ';

  @override
  String get giftCardClaimSuccess => 'Đã nhận thẻ quà tặng demo cục bộ.';

  @override
  String get giftCardsEmptyTitle => 'Chưa có thẻ quà tặng';

  @override
  String get giftCardsEmptyMessage =>
      'Thẻ quà tặng sẽ xuất hiện sau khi nhận hoặc kết nối.';

  @override
  String giftCardCardSemantic(String code) {
    return 'Thẻ quà tặng $code';
  }

  @override
  String get giftCardBalance => 'Số dư thẻ';

  @override
  String get giftCardTransactionsTitle => 'Giao dịch thẻ quà tặng';

  @override
  String get giftCardPreviewAction => 'Chỉ xem trước';

  @override
  String get giftCardPreviewSemantic =>
      'Xem trước thẻ quà tặng mà không đổi số dư';

  @override
  String get giftCardPreviewReadOnly =>
      'Xem trước thẻ quà tặng chỉ đọc và không đổi số dư.';

  @override
  String get giftCardActivateAction => 'Kích hoạt cục bộ';

  @override
  String get giftCardActivateSuccess =>
      'Đã kích hoạt thẻ quà tặng demo cục bộ.';

  @override
  String get giftCardStatusIssued => 'Đã phát hành';

  @override
  String get giftCardStatusActive => 'Đang hoạt động';

  @override
  String get giftCardStatusPartiallyRedeemed => 'Đã dùng một phần';

  @override
  String get giftCardStatusFullyRedeemed => 'Đã dùng hết';

  @override
  String get giftCardStatusExpired => 'Hết hạn';

  @override
  String get giftCardStatusCancelled => 'Đã hủy';

  @override
  String get giftCardTxnIssue => 'Phát hành';

  @override
  String get giftCardTxnActivation => 'Kích hoạt';

  @override
  String get giftCardTxnRedemption => 'Sử dụng';

  @override
  String get giftCardTxnRefund => 'Hoàn lại';

  @override
  String get giftCardTxnExpiry => 'Hết hạn';

  @override
  String get commonBackSemantic => 'Quay lại';

  @override
  String get demoModeLabel => 'Chế độ demo';

  @override
  String get travelWalletTitle => 'Ví du lịch';

  @override
  String get walletDemoSubtitle =>
      'Trình sắp xếp demo cục bộ cho hộ chiếu, thị thực, vé, voucher, biên lai và xác nhận đặt chỗ.';

  @override
  String get walletPrivacyNotice =>
      'Số giấy tờ nhạy cảm được che trước khi lưu. UI-8 không tải tệp lên, quét giấy tờ hoặc đồng bộ dữ liệu ví.';

  @override
  String get walletRealEmptyTitle => 'Ví du lịch chưa được kết nối';

  @override
  String get walletRealEmptyMessage =>
      'Tài khoản thật sẽ hiển thị giấy tờ trong ví sau khi tích hợp backend. Dữ liệu ví demo không hiển thị trong phiên thật.';

  @override
  String get walletSummaryTotal => 'Tổng';

  @override
  String get walletSummaryActive => 'Đang hiệu lực';

  @override
  String get walletSummaryUpcoming => 'Sắp tới';

  @override
  String get walletSummaryExpiringSoon => 'Sắp hết hạn';

  @override
  String get walletSummaryExpired => 'Đã hết hạn';

  @override
  String get walletSummaryFavorites => 'Yêu thích';

  @override
  String get walletSummaryArchived => 'Lưu trữ';

  @override
  String get walletSummaryUnlinked => 'Chưa liên kết';

  @override
  String walletSummarySemantic(String label, int count) {
    return '$label: $count';
  }

  @override
  String get walletSearchHint =>
      'Tìm tiêu đề, đơn vị cấp, mã đã che hoặc chuyến đi';

  @override
  String get walletFilterCategory => 'Nhóm';

  @override
  String get walletFilterType => 'Loại mục';

  @override
  String get walletFilterStatus => 'Trạng thái';

  @override
  String get walletFilterLinkedTrip => 'Chuyến đi liên kết';

  @override
  String get walletFilterAll => 'Tất cả';

  @override
  String get walletFavoritesOnly => 'Chỉ yêu thích';

  @override
  String get walletArchivedOnly => 'Chỉ lưu trữ';

  @override
  String get walletCreateItemAction => 'Thêm mục ví';

  @override
  String get walletImportBookingAction => 'Nhập đặt chỗ';

  @override
  String get walletNoBookingsToImport =>
      'Không có đặt chỗ demo cục bộ để nhập.';

  @override
  String get walletEmptyTitle => 'Không có mục ví phù hợp';

  @override
  String get walletEmptyMessage =>
      'Điều chỉnh tìm kiếm hoặc bộ lọc, hoặc thêm metadata demo cục bộ.';

  @override
  String get walletSectionFavorites => 'Yêu thích';

  @override
  String get walletSectionExpiringSoon => 'Sắp hết hạn';

  @override
  String get walletSectionUpcoming => 'Sắp tới';

  @override
  String get walletSectionActive => 'Đang hiệu lực';

  @override
  String get walletSectionExpired => 'Đã hết hạn';

  @override
  String get walletSectionArchived => 'Lưu trữ';

  @override
  String get walletSectionByCategory => 'Theo nhóm';

  @override
  String get walletSectionByTrip => 'Theo chuyến đi';

  @override
  String walletItemSemantic(String title) {
    return 'Mục ví $title';
  }

  @override
  String get walletSourceMetadata => 'Chỉ metadata';

  @override
  String get walletSourceTripDocument => 'Giấy tờ chuyến đi';

  @override
  String get walletSourceBooking => 'Đặt chỗ';

  @override
  String get walletSourceInvoice => 'Hóa đơn';

  @override
  String get walletReferenceLabel => 'Mã tham chiếu đã che';

  @override
  String walletMaskedReference(String reference) {
    return 'Mã tham chiếu đã che $reference';
  }

  @override
  String get walletValidityLabel => 'Hiệu lực';

  @override
  String get walletNoValidity => 'Chưa có ngày hiệu lực';

  @override
  String walletValidUntil(String date) {
    return 'Hiệu lực đến $date';
  }

  @override
  String walletValidFrom(String date) {
    return 'Hiệu lực từ $date';
  }

  @override
  String walletValidPeriod(String from, String until) {
    return '$from - $until';
  }

  @override
  String get walletLinkedTripLabel => 'Chuyến đi liên kết';

  @override
  String get walletReminderLabel => 'Nhắc hết hạn';

  @override
  String get walletReminderEnabled => 'Đã bật tùy chọn nhắc cục bộ';

  @override
  String get walletReminderDisabled => 'Đã tắt tùy chọn nhắc cục bộ';

  @override
  String get walletReminderEnableAction => 'Bật nhắc';

  @override
  String get walletReminderDisableAction => 'Tắt nhắc';

  @override
  String get walletFavoriteAction => 'Yêu thích';

  @override
  String get walletUnfavoriteAction => 'Bỏ yêu thích';

  @override
  String get walletArchiveAction => 'Lưu trữ';

  @override
  String get walletRestoreAction => 'Khôi phục';

  @override
  String get walletDeleteAction => 'Xóa';

  @override
  String get walletEditAction => 'Sửa';

  @override
  String get walletSaveAction => 'Lưu';

  @override
  String get walletCreateTitle => 'Thêm metadata ví';

  @override
  String get walletEditTitle => 'Sửa metadata ví';

  @override
  String get walletTitleLabel => 'Tiêu đề';

  @override
  String get walletIssuerLabel => 'Đơn vị cấp';

  @override
  String get walletReferenceInputLabel => 'Số tham chiếu';

  @override
  String get walletReferencePrivacyHelper =>
      'Mã tham chiếu được che ngay và giá trị gốc không được giữ lại.';

  @override
  String get walletTypeLabel => 'Loại mục ví';

  @override
  String get walletStatusLabel => 'Trạng thái đã lưu';

  @override
  String get walletNoValue => 'Chưa cung cấp';

  @override
  String get walletUpdatedLabel => 'Cập nhật';

  @override
  String get walletDeleteConfirmTitle => 'Xóa mục ví?';

  @override
  String walletDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi ví demo cục bộ? Chuyến đi, đặt chỗ hoặc giấy tờ liên kết sẽ không bị xóa.';
  }

  @override
  String get walletSavedMessage => 'Đã lưu mục ví cục bộ.';

  @override
  String get walletDeletedMessage => 'Đã xóa mục ví cục bộ.';

  @override
  String get walletDuplicateMessage => 'Mục cục bộ đó đã tồn tại.';

  @override
  String get walletActionRejectedMessage =>
      'Không thể hoàn tất thao tác ví với dữ liệu hiện tại.';

  @override
  String get walletInvalidDateMessage =>
      'Ngày hết hiệu lực không được trước ngày bắt đầu hiệu lực.';

  @override
  String get walletNotFoundMessage => 'Mục ví đã chọn không còn tồn tại.';

  @override
  String get walletActionUnavailable =>
      'Thao tác Ví du lịch chưa được kết nối cho tài khoản thật trong giai đoạn UI này.';

  @override
  String get walletTitleRequiredMessage => 'Nhập tiêu đề trước khi lưu.';

  @override
  String get walletBookingImportedMessage =>
      'Đã lưu xác nhận đặt chỗ vào ví demo cục bộ.';

  @override
  String get walletBookingAlreadyImportedMessage =>
      'Đặt chỗ đó đã có trong ví demo cục bộ.';

  @override
  String get walletSaveBookingAction => 'Lưu vào Ví du lịch';

  @override
  String get walletSaveBookingSemantic =>
      'Lưu đặt chỗ demo cục bộ này vào Ví du lịch';

  @override
  String get walletTypePassport => 'Hộ chiếu';

  @override
  String get walletTypeVisa => 'Thị thực';

  @override
  String get walletTypeBoardingPass => 'Thẻ lên máy bay';

  @override
  String get walletTypeFlightTicket => 'Vé máy bay';

  @override
  String get walletTypeTrainTicket => 'Vé tàu';

  @override
  String get walletTypeBusTicket => 'Vé xe buýt';

  @override
  String get walletTypeHotelVoucher => 'Voucher khách sạn';

  @override
  String get walletTypeTourVoucher => 'Voucher tour';

  @override
  String get walletTypeInsurance => 'Bảo hiểm';

  @override
  String get walletTypeBookingConfirmation => 'Xác nhận đặt chỗ';

  @override
  String get walletTypeInvoice => 'Hóa đơn';

  @override
  String get walletTypeReceipt => 'Biên lai';

  @override
  String get walletTypeItinerary => 'Lịch trình';

  @override
  String get walletTypeOther => 'Khác';

  @override
  String get walletCategoryIdentity => 'Định danh';

  @override
  String get walletCategoryTransport => 'Di chuyển';

  @override
  String get walletCategoryAccommodation => 'Lưu trú';

  @override
  String get walletCategoryActivity => 'Hoạt động';

  @override
  String get walletCategoryInsurance => 'Bảo hiểm';

  @override
  String get walletCategoryFinancial => 'Tài chính';

  @override
  String get walletCategoryOther => 'Khác';

  @override
  String get walletStatusActive => 'Đang hiệu lực';

  @override
  String get walletStatusUpcoming => 'Sắp tới';

  @override
  String get walletStatusExpired => 'Đã hết hạn';

  @override
  String get walletStatusCancelled => 'Đã hủy';

  @override
  String get walletStatusArchived => 'Đã lưu trữ';

  @override
  String get tripDocumentsAction => 'Giấy tờ';

  @override
  String get tripDocumentsTitle => 'Giấy tờ chuyến đi';

  @override
  String tripDocumentsDemoSubtitle(String trip) {
    return 'Metadata demo cục bộ cho $trip. Không thực hiện tải tệp lên.';
  }

  @override
  String get tripDocumentsRealEmptyTitle =>
      'Giấy tờ chuyến đi chưa được kết nối';

  @override
  String get tripDocumentsRealEmptyMessage =>
      'Giấy tờ chuyến đi thật sẽ xuất hiện sau khi tích hợp backend. Dữ liệu demo không hiển thị trong phiên thật.';

  @override
  String get tripDocumentsEmptyTitle => 'Chưa có giấy tờ';

  @override
  String get tripDocumentsEmptyMessage =>
      'Thêm metadata demo cục bộ cho vé, đặt chỗ, biên lai hoặc giấy tờ.';

  @override
  String get tripDocumentsTripDeletedMessage =>
      'Chuyến đi này không còn khả dụng.';

  @override
  String get tripDocumentAddAction => 'Thêm giấy tờ';

  @override
  String get tripDocumentCreateTitle => 'Thêm giấy tờ chuyến đi';

  @override
  String get tripDocumentEditTitle => 'Sửa giấy tờ chuyến đi';

  @override
  String get tripDocumentTitleLabel => 'Tiêu đề giấy tờ';

  @override
  String get tripDocumentNotesLabel => 'Ghi chú';

  @override
  String get tripDocumentTypeLabel => 'Loại giấy tờ';

  @override
  String get tripDocumentMediaLabel => 'Nhãn media';

  @override
  String get tripDocumentMediaUrlLabel => 'URL tham chiếu an toàn';

  @override
  String get tripDocumentMediaHelper =>
      'Chỉ chấp nhận tham chiếu http hoặc https có host. UI-8 không tải tệp lên.';

  @override
  String get tripDocumentUploaderLabel => 'Người tải';

  @override
  String get tripDocumentNoUploadNotice =>
      'Giai đoạn này chỉ lưu metadata demo cục bộ. Không tải tệp, phân tích PDF, quét ảnh hoặc chia sẻ giấy tờ.';

  @override
  String get tripDocumentPinned => 'Đã ghim';

  @override
  String get tripDocumentUnpinned => 'Chưa ghim';

  @override
  String get tripDocumentPinAction => 'Ghim';

  @override
  String get tripDocumentUnpinAction => 'Bỏ ghim';

  @override
  String get tripDocumentDeleteAction => 'Xóa giấy tờ';

  @override
  String get tripDocumentSaveToWalletAction => 'Lưu vào ví';

  @override
  String get tripDocumentUnsafeUrlMessage =>
      'Dùng URL http hoặc https hợp lệ có host.';

  @override
  String get tripDocumentSafeLinkLabel => 'Liên kết an toàn';

  @override
  String get tripDocumentSavedMessage => 'Đã lưu giấy tờ chuyến đi cục bộ.';

  @override
  String get tripDocumentDeletedMessage => 'Đã xóa giấy tờ chuyến đi cục bộ.';

  @override
  String get tripDocumentWalletImportedMessage =>
      'Đã lưu giấy tờ chuyến đi vào ví demo cục bộ.';

  @override
  String get tripDocumentWalletDuplicateMessage =>
      'Giấy tờ chuyến đi đó đã có trong ví demo cục bộ.';

  @override
  String get tripDocumentDeleteConfirmTitle => 'Xóa giấy tờ chuyến đi?';

  @override
  String tripDocumentDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi chuyến đi demo cục bộ này? Mục ví liên kết sẽ bị gỡ, nhưng chuyến đi không đổi.';
  }

  @override
  String tripDocumentCardSemantic(String title) {
    return 'Giấy tờ chuyến đi $title';
  }

  @override
  String get docTypeFlightTicket => 'Vé máy bay';

  @override
  String get docTypeHotelBooking => 'Đặt phòng khách sạn';

  @override
  String get docTypeTrainTicket => 'Vé tàu';

  @override
  String get docTypeBusTicket => 'Vé xe buýt';

  @override
  String get docTypePassport => 'Hộ chiếu';

  @override
  String get docTypeVisa => 'Thị thực';

  @override
  String get docTypeInsurance => 'Bảo hiểm';

  @override
  String get docTypeTour => 'Tour';

  @override
  String get docTypeReceipt => 'Biên lai';

  @override
  String get docTypePdf => 'PDF';

  @override
  String get docTypeImage => 'Hình ảnh';

  @override
  String get docTypeOther => 'Khác';
}
