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
      'Danh sách yêu thích (địa điểm lưu nhanh) chưa được kết nối với backend cho tài khoản thật. Bộ sưu tập đã lưu được đồng bộ với tài khoản của bạn bên dưới.';

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
  String get savedPlacesSubtitle =>
      'Danh sách địa điểm du lịch bạn lưu, được lấy từ dữ liệu địa điểm công khai hiện tại.';

  @override
  String get savedPlacesDemoBoundary =>
      'Mục lưu trong Chế độ demo là dữ liệu trình diễn cục bộ. Chúng chưa được đồng bộ với API wishlist.';

  @override
  String get savedPlacesEmptyTitle => 'Chưa có địa điểm đã lưu';

  @override
  String get savedPlacesEmptyMessage =>
      'Lưu một địa điểm công khai từ Khám phá, tìm kiếm, khám phá danh mục hoặc trang chi tiết địa điểm.';

  @override
  String savedPlacesCountSemantic(int count) {
    return '$count địa điểm đã lưu';
  }

  @override
  String get savedPlacesFilterSemantic => 'Bộ lọc địa điểm đã lưu';

  @override
  String get savedPlacesSortNewest => 'Mới lưu';

  @override
  String get savedPlacesSortName => 'Tên';

  @override
  String savedPlacesCollectionCount(int count) {
    return '$count bộ sưu tập';
  }

  @override
  String savedPlacesCollectionCountSemantic(int count) {
    return '$count bộ sưu tập đã lưu';
  }

  @override
  String savedPlacesAllSavedTab(int count) {
    return 'Tất cả đã lưu ($count)';
  }

  @override
  String savedPlacesCollectionsTab(int count) {
    return 'Bộ sưu tập ($count)';
  }

  @override
  String get savedPlacesSectionTabsSemantic => 'Các mục địa điểm đã lưu';

  @override
  String get savedPlacesWishlistBoundaryTitle => 'Wishlist và ghi chú';

  @override
  String get savedPlacesWishlistBoundaryMessage =>
      'Wishlist và ghi chú riêng tư là dữ liệu cục bộ trong Chế độ demo cho đến khi kết nối lưu trữ backend.';

  @override
  String get savedPlacesCollectionsTitle => 'Bộ sưu tập';

  @override
  String get savedPlacesCollectionsBoundaryMessage =>
      'Bộ sưu tập đồng bộ với /api/me/collections cho tài khoản thật; Chế độ demo chỉ dùng dữ liệu cục bộ. Thêm địa điểm vào bộ sưu tập không bao giờ thay đổi wishlist.';

  @override
  String get savedPlacesCollectionNetworkErrorMessage =>
      'Không thể kết nối với backend. Kiểm tra kết nối mạng và thử lại.';

  @override
  String get savedPlacesCollectionServerErrorMessage =>
      'Backend gặp sự cố khi hoàn tất thao tác này. Vui lòng thử lại.';

  @override
  String get savedPlacesCollectionUnauthenticatedMessage =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để tiếp tục.';

  @override
  String get savedPlacesCollectionPlaceHydrationMessage =>
      'Thông tin đầy đủ về địa điểm chưa được đồng bộ cho bộ sưu tập thật. Xem chi tiết và Thêm vào chuyến đi sẽ có ở giai đoạn sau.';

  @override
  String get savedPlacesCollectionAddPlaceDeferredTitle =>
      'Thêm địa điểm sẽ có sau';

  @override
  String get savedPlacesCollectionAddPlaceDeferredMessage =>
      'Chọn địa điểm đã lưu để thêm vào bộ sưu tập thật chưa khả dụng. Tính năng này sẽ được kết nối ở giai đoạn sau.';

  @override
  String get savedPlacesCollectionCreateAction => 'Tạo bộ sưu tập';

  @override
  String get savedPlacesCollectionCreateSemantic => 'Tạo bộ sưu tập đã lưu';

  @override
  String get savedPlacesCollectionsEmptyTitle => 'Chưa có bộ sưu tập';

  @override
  String get savedPlacesCollectionsEmptyMessage =>
      'Tạo bộ sưu tập riêng tư cho một điểm đến, ý tưởng cuối tuần hoặc danh sách rút gọn.';

  @override
  String savedPlacesCollectionItemCount(int count) {
    return '$count địa điểm';
  }

  @override
  String savedPlacesCollectionItemCountSemantic(int count) {
    return '$count địa điểm trong bộ sưu tập';
  }

  @override
  String savedPlacesCollectionCardSemantic(String collection, int count) {
    return '$collection, $count địa điểm';
  }

  @override
  String get savedPlacesCollectionPrivateLabel => 'Riêng tư';

  @override
  String get savedPlacesCollectionVisibleLabel => 'Hiển thị';

  @override
  String savedPlacesCollectionUpdated(String date) {
    return 'Cập nhật $date';
  }

  @override
  String get savedPlacesCollectionOpenAction => 'Mở';

  @override
  String savedPlacesCollectionOpenSemantic(String collection) {
    return 'Mở bộ sưu tập $collection';
  }

  @override
  String get savedPlacesCollectionEditAction => 'Sửa';

  @override
  String savedPlacesCollectionEditSemantic(String collection) {
    return 'Sửa bộ sưu tập $collection';
  }

  @override
  String savedPlacesCollectionDeleteSemantic(String collection) {
    return 'Xóa bộ sưu tập $collection';
  }

  @override
  String savedPlacesCollectionDetailSemantic(String collection, int count) {
    return '$collection, $count địa điểm';
  }

  @override
  String get savedPlacesCollectionBackAction => 'Bộ sưu tập';

  @override
  String get savedPlacesCollectionBackSemantic => 'Quay lại bộ sưu tập đã lưu';

  @override
  String get savedPlacesCollectionAddSavedAction => 'Thêm địa điểm đã lưu';

  @override
  String savedPlacesCollectionAddSavedSemantic(String collection) {
    return 'Thêm địa điểm đã lưu vào $collection';
  }

  @override
  String get savedPlacesCollectionEmptyTitle => 'Bộ sưu tập trống';

  @override
  String get savedPlacesCollectionEmptyMessage =>
      'Thêm một địa điểm công khai đã lưu. Việc này không thay đổi wishlist.';

  @override
  String savedPlacesCollectionPlaceSemantic(String place, String date) {
    return '$place, đã thêm $date';
  }

  @override
  String savedPlacesCollectionAddedOn(String date) {
    return 'Đã thêm $date';
  }

  @override
  String get savedPlacesCollectionRemovePlaceAction => 'Xóa';

  @override
  String savedPlacesCollectionRemovePlaceSemantic(String place) {
    return 'Xóa $place khỏi bộ sưu tập này';
  }

  @override
  String get savedPlacesCollectionStaleItemTitle =>
      'Mục bộ sưu tập không khả dụng';

  @override
  String savedPlacesCollectionStaleItemMessage(int placeId) {
    return 'Tham chiếu địa điểm $placeId không còn khớp với dữ liệu địa điểm công khai.';
  }

  @override
  String get savedPlacesCollectionRemoveStaleSemantic =>
      'Xóa địa điểm không khả dụng khỏi bộ sưu tập';

  @override
  String savedPlacesCollectionMembershipIn(String collection) {
    return 'Có trong $collection';
  }

  @override
  String savedPlacesCollectionMembershipOut(String collection) {
    return 'Chưa có trong $collection';
  }

  @override
  String savedPlacesCollectionRemoveMembershipSemantic(
      String place, String collection) {
    return 'Xóa $place khỏi $collection';
  }

  @override
  String savedPlacesCollectionAddMembershipSemantic(
      String place, String collection) {
    return 'Thêm $place vào $collection';
  }

  @override
  String get savedPlacesCollectionInAction => 'Đã thêm';

  @override
  String get savedPlacesCollectionAddAction => 'Thêm';

  @override
  String get savedPlacesCollectionEditTitle => 'Sửa bộ sưu tập';

  @override
  String get savedPlacesCollectionCreateTitle => 'Tạo bộ sưu tập';

  @override
  String get savedPlacesCollectionNameLabel => 'Tên bộ sưu tập';

  @override
  String savedPlacesCollectionNameHelper(int maxLength) {
    return 'Bắt buộc, tối đa $maxLength ký tự.';
  }

  @override
  String get savedPlacesCollectionDescriptionLabel => 'Mô tả';

  @override
  String savedPlacesCollectionDescriptionHelper(int maxLength) {
    return 'Không bắt buộc, tối đa $maxLength ký tự.';
  }

  @override
  String get savedPlacesCollectionCoverLabel => 'URL ảnh bìa';

  @override
  String savedPlacesCollectionCoverHelper(int maxLength) {
    return 'Văn bản URL không bắt buộc, tối đa $maxLength ký tự.';
  }

  @override
  String get savedPlacesCollectionPrivateHelper =>
      'Mọi endpoint bộ sưu tập đều giới hạn theo chủ sở hữu trong giai đoạn này.';

  @override
  String get savedPlacesCollectionSaveAction => 'Lưu bộ sưu tập';

  @override
  String savedPlacesCollectionCreatedMessage(String collection) {
    return 'Đã tạo bộ sưu tập $collection.';
  }

  @override
  String savedPlacesCollectionUpdatedMessage(String collection) {
    return 'Đã cập nhật bộ sưu tập $collection.';
  }

  @override
  String savedPlacesCollectionDeleteTitle(String collection) {
    return 'Xóa $collection?';
  }

  @override
  String savedPlacesCollectionDeleteMessage(String collection) {
    return 'Xóa $collection? Chỉ thành viên bộ sưu tập bị xóa. Địa điểm, ghi chú wishlist, chuyến đi, booking, đánh giá và tài liệu được giữ nguyên.';
  }

  @override
  String get savedPlacesCollectionDeleteAction => 'Xóa bộ sưu tập';

  @override
  String savedPlacesCollectionDeletedMessage(String collection) {
    return 'Đã xóa bộ sưu tập $collection.';
  }

  @override
  String savedPlacesCollectionAddSavedTitle(String collection) {
    return 'Thêm địa điểm đã lưu vào $collection';
  }

  @override
  String get savedPlacesCollectionAddSavedMessage =>
      'Chỉ liệt kê các địa điểm đang được lưu. Thành viên bộ sưu tập tách biệt với wishlist.';

  @override
  String savedPlacesManageCollectionsTitle(String place) {
    return 'Bộ sưu tập cho $place';
  }

  @override
  String get savedPlacesManageCollectionsMessage =>
      'Thêm hoặc xóa địa điểm đã lưu này khỏi bộ sưu tập riêng tư trong Chế độ demo.';

  @override
  String get savedPlacesCollectionSavedMessage => 'Đã cập nhật bộ sưu tập.';

  @override
  String get savedPlacesCollectionsRealUnavailableMessage =>
      'Bộ sưu tập đã lưu chưa được kết nối với backend cho tài khoản thật.';

  @override
  String savedPlacesCollectionInvalidNameMessage(int maxLength) {
    return 'Tên bộ sưu tập là bắt buộc và tối đa $maxLength ký tự.';
  }

  @override
  String savedPlacesCollectionInvalidDescriptionMessage(int maxLength) {
    return 'Mô tả bộ sưu tập tối đa $maxLength ký tự.';
  }

  @override
  String savedPlacesCollectionInvalidCoverMessage(int maxLength) {
    return 'URL ảnh bìa bộ sưu tập tối đa $maxLength ký tự.';
  }

  @override
  String savedPlacesCollectionLimitMessage(int maxCount) {
    return 'Bạn đã đạt giới hạn cục bộ $maxCount bộ sưu tập.';
  }

  @override
  String get savedPlacesCollectionNotFoundMessage =>
      'Bộ sưu tập này không khả dụng.';

  @override
  String get savedPlacesCollectionPlaceNotFoundMessage =>
      'Không thể thêm địa điểm này vì nó không còn khớp với dữ liệu địa điểm công khai.';

  @override
  String savedPlacesCollectionDuplicatePlaceMessage(
      String place, String collection) {
    return '$place đã có trong $collection.';
  }

  @override
  String get savedPlacesCollectionItemNotFoundMessage =>
      'Địa điểm này không nằm trong bộ sưu tập đã chọn.';

  @override
  String savedPlacesCollectionItemLimitMessage(int maxCount) {
    return 'Bộ sưu tập này đã đạt giới hạn cục bộ $maxCount địa điểm.';
  }

  @override
  String savedPlacesCollectionAddedPlaceMessage(
      String place, String collection) {
    return 'Đã thêm $place vào $collection.';
  }

  @override
  String savedPlacesCollectionRemovedPlaceMessage(
      String place, String collection) {
    return 'Đã xóa $place khỏi $collection.';
  }

  @override
  String get savedPlacesAddToCollectionAction => 'Bộ sưu tập';

  @override
  String savedPlacesManageCollectionsSemantic(String place) {
    return 'Quản lý bộ sưu tập cho $place';
  }

  @override
  String savedPlacesSavedOn(String date) {
    return 'Đã lưu $date';
  }

  @override
  String savedPlacesNote(String note) {
    return 'Ghi chú: $note';
  }

  @override
  String get savedPlacesEditNoteAction => 'Sửa ghi chú';

  @override
  String savedPlacesEditNoteSemantic(String place) {
    return 'Sửa ghi chú riêng tư cho $place';
  }

  @override
  String savedPlacesEditNoteTitle(String place) {
    return 'Ghi chú riêng tư cho $place';
  }

  @override
  String get savedPlacesNoteFieldLabel => 'Ghi chú riêng tư';

  @override
  String savedPlacesNoteFieldHelper(int maxLength) {
    return 'Tối đa $maxLength ký tự. Để trống để xóa ghi chú.';
  }

  @override
  String get savedPlacesNoteSaveAction => 'Lưu ghi chú';

  @override
  String savedPlacesNoteSavedMessage(String place) {
    return 'Đã cập nhật ghi chú riêng tư cho $place.';
  }

  @override
  String get savedPlacesNoteTooLongMessage =>
      'Ghi chú riêng tư tối đa 500 ký tự.';

  @override
  String savedPlacesSaveSemantic(String place) {
    return 'Lưu $place';
  }

  @override
  String savedPlacesRemoveSemantic(String place) {
    return 'Xóa địa điểm đã lưu $place';
  }

  @override
  String savedPlacesSavedMessage(String place) {
    return 'Đã lưu cục bộ $place.';
  }

  @override
  String savedPlacesAlreadySavedMessage(String place) {
    return '$place đã được lưu.';
  }

  @override
  String savedPlacesRemovedPlace(String place) {
    return 'Đã xóa $place khỏi danh sách đã lưu cục bộ.';
  }

  @override
  String get savedPlacesActionForbiddenMessage =>
      'Địa điểm đã lưu này thuộc về khách du lịch khác.';

  @override
  String get savedPlacesMissingTitle => 'Địa điểm đã lưu không khả dụng';

  @override
  String get savedPlacesMissingMessage =>
      'Địa điểm đã lưu này không còn khớp với dữ liệu địa điểm công khai.';

  @override
  String savedPlacesMissingRecordMessage(int placeId) {
    return 'Tham chiếu địa điểm đã lưu $placeId không còn khớp với dữ liệu địa điểm công khai.';
  }

  @override
  String get savedPlacesRemoveAction => 'Xóa';

  @override
  String get savedPlacesRemoveConfirmTitle => 'Xóa địa điểm đã lưu?';

  @override
  String savedPlacesRemoveConfirmMessage(String place) {
    return 'Xóa $place khỏi danh sách đã lưu cục bộ? Địa điểm, chuyến đi, đặt phòng, đánh giá và ví du lịch sẽ không bị xóa.';
  }

  @override
  String get savedPlacesRemoveConfirmAction => 'Xóa địa điểm đã lưu';

  @override
  String get savedPlacesViewDetailsAction => 'Chi tiết';

  @override
  String savedPlacesOpenDetailSemantic(String place) {
    return 'Mở chi tiết cho $place';
  }

  @override
  String get savedPlacesHotelAction => 'Xem phòng';

  @override
  String savedPlacesCardSemantic(String place, String date) {
    return '$place, đã lưu $date';
  }

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
  String get notificationCenterSubtitle =>
      'Luồng hoạt động trong ứng dụng cục bộ cho booking, thanh toán, chuyến đi, đánh giá, ưu đãi, ví du lịch, tài liệu và thông báo tài khoản.';

  @override
  String get notificationCenterSemantic => 'Trung tâm thông báo và hoạt động';

  @override
  String get notificationRealBoundary =>
      'Tài khoản thật sẽ dùng API thông báo trong ứng dụng đã commit khi lớp repository frontend được kết nối. Push, token thiết bị và quyền thông báo ngoài hệ thống chưa được kết nối trong giai đoạn UI này.';

  @override
  String get notificationDemoModeLabel => 'Demo cục bộ';

  @override
  String get notificationPreferenceBoundary =>
      'Các công tắc thông báo chỉ là tùy chọn cục bộ trên thiết bị. Chúng không đăng ký token push hoặc đồng bộ tùy chọn máy chủ.';

  @override
  String notificationUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chưa đọc',
      one: '1 chưa đọc',
      zero: '0 chưa đọc',
    );
    return '$_temp0';
  }

  @override
  String notificationUnreadCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo chưa đọc',
      one: '1 thông báo chưa đọc',
      zero: 'Không có thông báo chưa đọc',
    );
    return '$_temp0';
  }

  @override
  String notificationTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo',
      one: '1 thông báo',
      zero: '0 thông báo',
    );
    return '$_temp0';
  }

  @override
  String get notificationMarkAllReadSemantic =>
      'Đánh dấu tất cả thông báo demo là đã đọc';

  @override
  String notificationMarkAllReadResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đánh dấu $count thông báo là đã đọc.',
      one: 'Đã đánh dấu 1 thông báo là đã đọc.',
      zero: 'Không có thông báo chưa đọc nào thay đổi.',
    );
    return '$_temp0';
  }

  @override
  String get notificationFilterSemantic => 'Bộ lọc thông báo';

  @override
  String get notificationFilterAll => 'Tất cả';

  @override
  String get notificationFilterUnread => 'Chưa đọc';

  @override
  String get notificationFilterBookings => 'Booking';

  @override
  String get notificationFilterPayments => 'Thanh toán';

  @override
  String get notificationFilterTrips => 'Chuyến đi';

  @override
  String get notificationFilterReviews => 'Đánh giá';

  @override
  String get notificationFilterRewards => 'Ưu đãi';

  @override
  String get notificationFilterWallet => 'Ví';

  @override
  String get notificationFilterSystem => 'Hệ thống';

  @override
  String get notificationFilterEmptyMessage =>
      'Không có thông báo phù hợp bộ lọc này.';

  @override
  String get notificationReadLabel => 'Đã đọc';

  @override
  String get notificationUnreadLabel => 'Chưa đọc';

  @override
  String notificationCardSemantic(
      String readState, String type, String title, String time) {
    return '$readState. Thông báo $type. $title. $time.';
  }

  @override
  String get notificationMissingTitle => 'Thông báo không khả dụng';

  @override
  String get notificationMissingMessage =>
      'Thông báo cục bộ này không còn khả dụng.';

  @override
  String get notificationCreatedAtLabel => 'Tạo lúc';

  @override
  String get notificationReadAtLabel => 'Đọc lúc';

  @override
  String get notificationPrivacyNote =>
      'Mã booking và tham chiếu thanh toán riêng tư được che bớt hoặc bỏ qua trong chế độ xem hoạt động này.';

  @override
  String get notificationOpenTargetSemantic =>
      'Mở mục được liên kết với thông báo';

  @override
  String get notificationDeleteAction => 'Xóa thông báo';

  @override
  String get notificationDeleteSemantic => 'Xóa thông báo demo này';

  @override
  String get notificationDeleteConfirmTitle => 'Xóa thông báo?';

  @override
  String get notificationDeleteConfirmMessage =>
      'Xóa thông báo demo cục bộ này? Booking, thanh toán, chuyến đi, đánh giá, ưu đãi hoặc mục ví được liên kết sẽ không bị xóa.';

  @override
  String get notificationDeleteConfirmAction => 'Xóa thông báo';

  @override
  String get notificationDeletedMessage =>
      'Đã xóa thông báo khỏi dữ liệu demo cục bộ.';

  @override
  String get notificationTargetUnavailable =>
      'Thông báo này không có màn hình liên kết.';

  @override
  String get notificationTargetMissing =>
      'Mục liên kết không còn trong dữ liệu demo cục bộ.';

  @override
  String get notificationNoTargetAction => 'Không có màn hình liên kết';

  @override
  String get notificationOpenBooking => 'Xem booking';

  @override
  String get notificationOpenPayment => 'Xem trạng thái thanh toán';

  @override
  String get notificationOpenTrip => 'Xem chuyến đi';

  @override
  String get notificationOpenTripCompanion => 'Xem người đồng hành';

  @override
  String get notificationOpenTripDocuments => 'Xem tài liệu chuyến đi';

  @override
  String get notificationOpenReview => 'Xem đánh giá';

  @override
  String get notificationOpenRewards => 'Xem ưu đãi';

  @override
  String get notificationOpenWallet => 'Xem ví du lịch';

  @override
  String get notificationTypeBooking => 'Booking';

  @override
  String get notificationTypePayment => 'Thanh toán';

  @override
  String get notificationTypeReservation => 'Giữ chỗ';

  @override
  String get notificationTypeSystem => 'Hệ thống';

  @override
  String get notificationTypePromotion => 'Khuyến mãi';

  @override
  String get notificationTypeReview => 'Đánh giá';

  @override
  String get notificationTypePartner => 'Đối tác';

  @override
  String get notificationTypeAdmin => 'Quản trị';

  @override
  String get notificationTypeMessage => 'Tin nhắn';

  @override
  String get notificationTypeTrip => 'Chuyến đi';

  @override
  String get notificationPriorityLow => 'Thấp';

  @override
  String get notificationPriorityNormal => 'Bình thường';

  @override
  String get notificationPriorityHigh => 'Cao';

  @override
  String get notificationPriorityUrgent => 'Khẩn cấp';

  @override
  String get notificationDemoBookingModifiedTitle => 'Đã lưu thay đổi booking';

  @override
  String get notificationDemoBookingModifiedMessage =>
      'Chỗ ở Đà Lạt đang chờ xác nhận vẫn giữ nguyên mã booking trong khi bản xem trước sửa đổi cục bộ cập nhật snapshot lưu trú.';

  @override
  String get notificationDemoPaymentSuccessTitle => 'Thanh toán demo hoàn tất';

  @override
  String get notificationDemoPaymentSuccessMessage =>
      'Bản xem trước checkout cục bộ đã ghi nhận thanh toán MOCK đã trả. Không có khoản phí thật nào được thực hiện.';

  @override
  String get notificationDemoPaymentFailedTitle =>
      'Thanh toán demo cần xem lại';

  @override
  String get notificationDemoPaymentFailedMessage =>
      'Một bản xem trước thanh toán cục bộ chưa hoàn tất. Hãy xem lại booking trước khi thử hành động checkout demo khác.';

  @override
  String get notificationDemoTripCollaborationTitle =>
      'Cập nhật cộng tác chuyến đi';

  @override
  String get notificationDemoTripCollaborationMessage =>
      'Danh sách người đồng hành chuyến Đà Lạt có cập nhật cộng tác cục bộ để bạn xem.';

  @override
  String get notificationDemoItineraryReminderTitle => 'Đã gửi nhắc lịch trình';

  @override
  String get notificationDemoItineraryReminderMessage =>
      'Nhắc lịch UI-9 vẫn là bản ghi nhắc chuyến đi; đây chỉ là bản sao thông báo trong ứng dụng đã gửi.';

  @override
  String get notificationDemoReviewReplyTitle =>
      'Khách sạn đã phản hồi đánh giá';

  @override
  String get notificationDemoReviewReplyMessage =>
      'Phản hồi của chủ villa đã có trong chi tiết đánh giá mà không lộ dữ liệu kiểm duyệt nội bộ.';

  @override
  String get notificationDemoRewardTitle => 'Có cập nhật quyền lợi';

  @override
  String get notificationDemoRewardMessage =>
      'Thông báo ưu đãi và quyền lợi cục bộ đã sẵn sàng trong trung tâm ưu đãi.';

  @override
  String get notificationDemoWalletTitle => 'Thông báo tài liệu ví';

  @override
  String get notificationDemoWalletMessage =>
      'Ghi chú tài liệu du lịch đã che bớt đang có trong Ví du lịch.';

  @override
  String get notificationDemoSystemTitle => 'Thông báo tài khoản';

  @override
  String get notificationDemoSystemMessage =>
      'Hoạt động tài khoản demo cục bộ được hiển thị tại đây mà không đăng ký push hoặc lưu token thiết bị.';

  @override
  String profileNotificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo chưa đọc',
      one: '1 thông báo chưa đọc',
      zero: 'Không có thông báo chưa đọc',
    );
    return '$_temp0';
  }

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
  String get cancellationFreeDeadlinePassed => 'Đã qua thời hạn hủy miễn phí';

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
      'Tôi hiểu bước thanh toán không thu thông tin thẻ và không giữ phòng thật trong UI này.';

  @override
  String get bookingConfirmAction => 'Xác nhận đặt phòng demo';

  @override
  String get bookingConfirmSemantic => 'Tiếp tục đến thanh toán an toàn';

  @override
  String get bookingDuplicatePrevented => 'Đã chặn tạo đặt phòng trùng.';

  @override
  String get checkoutTitle => 'Thanh toán an toàn';

  @override
  String get checkoutContinueAction => 'Tiếp tục đến thanh toán an toàn';

  @override
  String get checkoutSecureTitle => 'Thanh toán an toàn';

  @override
  String get checkoutSemantic => 'Thanh toán đặt phòng an toàn';

  @override
  String get checkoutRealModeLabel => 'Tài khoản thật';

  @override
  String get checkoutSecureBoundaryPill => 'Không nhập thẻ';

  @override
  String get checkoutWholeStayTotal => 'Tổng toàn bộ kỳ lưu trú';

  @override
  String get checkoutStaySnapshotTitle => 'Ảnh chụp lưu trú';

  @override
  String get checkoutProviderTitle => 'Nhà cung cấp thanh toán';

  @override
  String get checkoutProviderHelper =>
      'Backend có hợp đồng phiên thanh toán qua nhà cung cấp. UI-13 không mở cổng ngoài và không thu thông tin đăng nhập/thẻ.';

  @override
  String get checkoutMockProviderSubtitle =>
      'Nhà cung cấp demo cục bộ chỉ để trình bày.';

  @override
  String get checkoutHostedProviderSubtitle =>
      'Backend đã chứng minh luồng chuyển sang nhà cung cấp, nhưng UI này chưa mở cổng ngoài.';

  @override
  String get checkoutSecurityTitle => 'Bảo mật thanh toán';

  @override
  String get checkoutDemoSecurityBoundary =>
      'Chế độ Demo có thể tạo lượt thanh toán cục bộ để trình bày. Không trừ tiền và không gửi callback đến cổng thanh toán.';

  @override
  String get checkoutRealUnavailableMessage =>
      'Thanh toán thật cần tích hợp API/repository và luồng chuyển sang nhà cung cấp. UI này không mô phỏng thành công.';

  @override
  String get checkoutNoSensitiveFields =>
      'Ứng dụng không yêu cầu số thẻ, ngày hết hạn, CVV, PIN, mật khẩu ngân hàng, OTP, token thanh toán hoặc bí mật cổng thanh toán.';

  @override
  String get checkoutBenefitsBoundaryTitle => 'Ưu đãi và ví';

  @override
  String get checkoutBenefitsReadOnlyDemo =>
      'Travel credit, điểm, mã giảm giá, thẻ quà tặng và ví chỉ để xem tại đây trừ khi backend có hợp đồng checkout áp dụng chúng.';

  @override
  String get checkoutBenefitsReadOnlyReal =>
      'Ưu đãi và số dư ví chưa được kết nối với thanh toán thật trong UI này.';

  @override
  String get checkoutCreateDemoPaymentAction =>
      'Tạo đặt phòng và thanh toán demo';

  @override
  String get checkoutRealUnavailableAction => 'Chưa có thanh toán thật';

  @override
  String get checkoutSubmitSemantic =>
      'Tạo đặt phòng và lượt thanh toán demo cục bộ';

  @override
  String get paymentStatusTitle => 'Trạng thái thanh toán';

  @override
  String get paymentRealUnavailableTitle => 'Chưa kết nối thanh toán';

  @override
  String get paymentRealUnavailableMessage =>
      'Trạng thái thanh toán thật cần tích hợp API/repository backend. Tài khoản thật không được mô phỏng thành công cục bộ.';

  @override
  String get paymentMissingTitle => 'Không có thanh toán';

  @override
  String get paymentMissingMessage =>
      'Lượt thanh toán cục bộ này không còn khả dụng.';

  @override
  String get paymentDemoFailureReason =>
      'Nhà cung cấp demo từ chối thanh toán.';

  @override
  String get paymentStatusSemantic => 'Chi tiết trạng thái thanh toán';

  @override
  String get paymentDemoLocalOnly =>
      'Trạng thái thanh toán này là dữ liệu trình bày Demo cục bộ và không phải giao dịch thật.';

  @override
  String get paymentDetailsTitle => 'Chi tiết thanh toán';

  @override
  String get paymentProviderLabel => 'Nhà cung cấp';

  @override
  String get paymentSessionStatusLabel => 'Phiên cổng thanh toán';

  @override
  String get paymentAmountLabel => 'Số tiền';

  @override
  String get paymentCreatedLabel => 'Đã tạo thanh toán';

  @override
  String get paymentHoldExpiresLabel => 'Giữ phòng hết hạn';

  @override
  String get paymentPaidAtLabel => 'Đã thanh toán lúc';

  @override
  String get paymentFailedAtLabel => 'Thất bại lúc';

  @override
  String get paymentCancelledAtLabel => 'Đã hủy lúc';

  @override
  String get paymentRefundedAtLabel => 'Đã hoàn lúc';

  @override
  String get paymentReferenceLabel => 'Tham chiếu nhà cung cấp';

  @override
  String get paymentMaskedReferenceSemantic => 'Tham chiếu nhà cung cấp đã che';

  @override
  String get paymentFailureReasonLabel => 'Lý do thất bại';

  @override
  String get paymentNoRefundInference =>
      'Trạng thái hủy đặt phòng và thanh toán tách biệt. Đặt phòng đã hủy không được xem là đã hoàn tiền nếu không có trạng thái hoàn tiền.';

  @override
  String get paymentActionsTitle => 'Hành động thanh toán';

  @override
  String get paymentCompleteDemoAction => 'Hoàn tất thanh toán demo';

  @override
  String get paymentCompleteDemoSemantic =>
      'Hoàn tất thanh toán demo cục bộ này';

  @override
  String get paymentFailDemoAction => 'Cho thanh toán demo thất bại';

  @override
  String get paymentCancelDemoAction => 'Hủy phiên thanh toán';

  @override
  String get paymentRetryAction => 'Thử thanh toán lại';

  @override
  String get paymentContinueAction => 'Tiếp tục thanh toán';

  @override
  String get paymentStatusAction => 'Trạng thái thanh toán';

  @override
  String get paymentContinueConfirmationAction => 'Tiếp tục đến xác nhận';

  @override
  String get paymentPendingBoundary =>
      'Thanh toán demo đang chờ có thể hoàn tất, thất bại hoặc hủy cục bộ. Callback nhà cung cấp thật không được mô phỏng.';

  @override
  String get paymentTerminalBoundary =>
      'Trạng thái thanh toán cuối được hiển thị như ảnh chụp bất biến. Chỉ được thử lại khi quy tắc backend cho phép lượt mới.';

  @override
  String get paymentProviderMock => 'Nhà cung cấp Mock';

  @override
  String get paymentProviderVnpay => 'VNPay';

  @override
  String get paymentProviderPayos => 'PayOS';

  @override
  String get paymentProviderMomo => 'MoMo';

  @override
  String get paymentProviderStripe => 'Stripe';

  @override
  String get paymentProviderApplePay => 'Apple Pay';

  @override
  String get paymentProviderGooglePay => 'Google Pay';

  @override
  String get paymentProviderManual => 'Thủ công';

  @override
  String get paymentSessionStatusNew => 'Mới';

  @override
  String get paymentSessionStatusPending => 'Đang chờ';

  @override
  String get paymentSessionStatusAuthorized => 'Đã ủy quyền';

  @override
  String get paymentSessionStatusCaptured => 'Đã thu tiền';

  @override
  String get paymentSessionStatusFailed => 'Thất bại';

  @override
  String get paymentSessionStatusCancelled => 'Đã hủy';

  @override
  String get paymentSessionStatusExpired => 'Hết hạn';

  @override
  String get paymentResultSuccessTitle => 'Đã hoàn tất thanh toán';

  @override
  String get paymentResultPendingTitle => 'Đang chờ thanh toán';

  @override
  String get paymentResultFailedTitle => 'Thanh toán thất bại';

  @override
  String get paymentResultCancelledTitle => 'Đã hủy thanh toán';

  @override
  String get paymentResultExpiredTitle => 'Thanh toán hết hạn';

  @override
  String get paymentActionSuccess => 'Đã cập nhật trạng thái thanh toán.';

  @override
  String get paymentActionUnavailable =>
      'Hành động thanh toán không khả dụng cho tài khoản này.';

  @override
  String get paymentDuplicatePrevented => 'Đã chặn gửi checkout trùng.';

  @override
  String get paymentActionInvalidState =>
      'Trạng thái thanh toán này không thể thực hiện hành động đó.';

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
      'Đặt phòng này là dữ liệu trình bày demo cục bộ. Dữ liệu không đồng bộ với backend và không giữ phòng.';

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
      'Chỉ đặt phòng demo cục bộ xuất hiện tại đây. Quản lý đặt phòng thật chưa được kết nối.';

  @override
  String get myBookingsRealEmptyTitle => 'Chưa kết nối đặt phòng';

  @override
  String get myBookingsRealEmptyMessage =>
      'Đặt phòng tài khoản thật sẽ xuất hiện sau khi tích hợp backend.';

  @override
  String get myBookingsEmptyTitle => 'Chưa có đặt phòng';

  @override
  String get myBookingsEmptyMessage =>
      'Đặt phòng demo xuất hiện sau khi xác nhận hoặc từ ví dụ lưu trú cục bộ đã gieo sẵn.';

  @override
  String get myBookingCardSemantic => 'Thẻ đặt phòng';

  @override
  String get bookingDetailsTitle => 'Chi tiết đặt phòng';

  @override
  String get bookingDetailMissingTitle => 'Không có đặt phòng';

  @override
  String get bookingDetailMissingMessage =>
      'Đặt phòng cục bộ này không còn khả dụng.';

  @override
  String get bookingDetailSemantic => 'Chi tiết đặt phòng';

  @override
  String get bookingPaymentUnavailableAction => 'Chưa có thanh toán';

  @override
  String get bookingPaymentUnavailable =>
      'Hành động thanh toán chưa được kết nối trong UI này.';

  @override
  String get bookingStayOverviewTitle => 'Tóm tắt lưu trú';

  @override
  String get bookingSnapshotTitle => 'Ảnh chụp phòng và gói giá';

  @override
  String get bookingPolicyTitle => 'Chính sách hủy';

  @override
  String get bookingTimelineTitle => 'Dòng thời gian trạng thái';

  @override
  String get bookingActionsTitle => 'Hành động đặt phòng';

  @override
  String get bookingCodeLabel => 'Mã đặt phòng';

  @override
  String get bookingCodeSemantic => 'Tham chiếu đặt phòng cục bộ';

  @override
  String get bookingDatesLabel => 'Ngày lưu trú';

  @override
  String get bookingNightsLabel => 'Số đêm';

  @override
  String get bookingGuestsLabel => 'Khách';

  @override
  String get bookingRoomsLabel => 'Phòng';

  @override
  String bookingRoomsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phòng',
      one: '1 phòng',
    );
    return '$_temp0';
  }

  @override
  String get bookingCreatedLabel => 'Đã tạo';

  @override
  String get bookingConfirmedLabel => 'Đã xác nhận';

  @override
  String get bookingCancelledAtLabel => 'Đã hủy';

  @override
  String get bookingCancellationReasonLabel => 'Lý do hủy';

  @override
  String get bookingHotelLabel => 'Khách sạn';

  @override
  String get bookingRoomLabel => 'Phòng';

  @override
  String get bookingRoomCodeLabel => 'Mã phòng';

  @override
  String get bookingRatePlanLabel => 'Gói giá';

  @override
  String get bookingMealPlanLabel => 'Gói bữa ăn';

  @override
  String get bookingTotalLabel => 'Tổng';

  @override
  String get bookingPaymentStatusLabel => 'Trạng thái thanh toán';

  @override
  String get bookingPaymentStatusPending => 'Đang chờ thanh toán';

  @override
  String get bookingPaymentStatusPaid => 'Đã thanh toán';

  @override
  String get bookingPaymentStatusFailed => 'Thanh toán thất bại';

  @override
  String get bookingPaymentStatusCancelled => 'Đã hủy thanh toán';

  @override
  String get bookingPaymentStatusRefunded => 'Đã hoàn tiền';

  @override
  String get bookingCancellationPolicyLabel => 'Loại chính sách';

  @override
  String get bookingPolicySummaryLabel => 'Tóm tắt chính sách';

  @override
  String get bookingCancellationDeadlineLabel => 'Hạn hủy';

  @override
  String bookingCancellationDeadlineValue(String date) {
    return 'Hạn hủy: $date';
  }

  @override
  String get bookingRefundableLabel => 'Khả năng hoàn tiền';

  @override
  String get bookingRefundableYes => 'Có thể hoàn tiền';

  @override
  String get bookingRefundableNo => 'Không hoàn tiền';

  @override
  String get bookingCancellationDeadlinePassedPolicy =>
      'Thời hạn hủy miễn phí đã qua. Bạn vẫn có thể yêu cầu hủy với các trạng thái đặt phòng đủ điều kiện, nhưng bản xem trước chính sách backend xem đây là hủy với phí phạt toàn phần.';

  @override
  String get bookingRefundBoundary =>
      'Tính toán và chi trả hoàn tiền không được mô phỏng trong Chế độ Demo cục bộ.';

  @override
  String get bookingViewReviewAction => 'Xem đánh giá';

  @override
  String get bookingViewPlaceAction => 'Xem khách sạn';

  @override
  String get bookingUnsupportedMessage =>
      'Thay đổi đặt phòng đã ổn định, đổi lịch, tải hóa đơn, hoàn tiền và nhắn tin với chỗ ở cần tích hợp backend và không được mô phỏng cục bộ.';

  @override
  String get bookingModifyAction => 'Sửa đặt phòng';

  @override
  String get bookingModifyTitle => 'Sửa đặt phòng';

  @override
  String get bookingModifySemantic => 'Sửa đặt phòng demo đang chờ này';

  @override
  String get bookingModifyIntro =>
      'Chỉ đặt phòng demo đang chờ mới có thể đổi cục bộ. Đặt phòng đã xác nhận, đã thanh toán, đã nhận phòng, hoàn tất, hủy, hoàn tiền, lưu trữ và vắng mặt sẽ bị khóa.';

  @override
  String get bookingModifyAvailableLabel => 'Có thể đổi khi đang chờ';

  @override
  String get bookingModifyUnavailableLabel => 'Không thể đổi';

  @override
  String get bookingModifyDemoLabel => 'Chế độ Demo cục bộ';

  @override
  String get bookingModifyDemoBoundary =>
      'Thao tác này chỉ cập nhật dữ liệu trình bày cục bộ xác định và không khẳng định tình trạng phòng trực tiếp.';

  @override
  String get bookingModifyEditTitle => 'Sửa trường được hỗ trợ';

  @override
  String get bookingModifyEditableFields =>
      'Các trường backend hỗ trợ trong UI này là ngày nhận phòng, ngày trả phòng, người lớn, trẻ em, giường phụ và gói giá. Khách sạn, phòng, số phòng và ưu đãi giữ nguyên.';

  @override
  String get bookingModifyReviewTitle => 'Xem lại thay đổi';

  @override
  String get bookingModifyReviewInstruction =>
      'Xem lại giá trị hiện tại và đề xuất trước khi xác nhận. Đặt phòng gốc không đổi cho đến khi xác nhận thành công.';

  @override
  String get bookingModifyCurrentLabel => 'Hiện tại';

  @override
  String get bookingModifyProposedLabel => 'Đề xuất';

  @override
  String get bookingModifyUnchangedLabel => 'Không đổi';

  @override
  String get bookingModifyChangedLabel => 'Đã đổi';

  @override
  String get bookingModifyCheckInLabel => 'Ngày nhận phòng';

  @override
  String get bookingModifyCheckOutLabel => 'Ngày trả phòng';

  @override
  String get bookingModifyAdultsLabel => 'Người lớn';

  @override
  String get bookingModifyChildrenLabel => 'Trẻ em';

  @override
  String get bookingModifyExtraBedsLabel => 'Giường phụ';

  @override
  String get bookingModifyRatePlanLabel => 'Gói giá';

  @override
  String get bookingModifyRatePlanHelper =>
      'Chỉ có thể chọn gói giá đủ điều kiện trong cùng phòng.';

  @override
  String get bookingModifyDateHelp => 'Dùng YYYY-MM-DD.';

  @override
  String get bookingModifyRequiredField => 'Trường này là bắt buộc.';

  @override
  String get bookingModifyRoomUnchanged => 'Cùng phòng';

  @override
  String get bookingModifyRoomCountUnchanged =>
      'Phòng và số phòng không thể sửa trong hợp đồng chỉnh sửa backend.';

  @override
  String get bookingModifyContinueReviewAction => 'Xem lại thay đổi';

  @override
  String get bookingModifyConfirmAction => 'Xác nhận thay đổi';

  @override
  String get bookingModifyBackToEditAction => 'Quay lại sửa';

  @override
  String get bookingModifySuccessMessage => 'Đã sửa đặt phòng demo cục bộ.';

  @override
  String get bookingModifyUnavailableReal =>
      'Sửa đặt phòng thật cần tích hợp API backend.';

  @override
  String get bookingModifyUnavailableNotFound =>
      'Đặt phòng này không còn khả dụng.';

  @override
  String get bookingModifyUnavailableForbidden =>
      'Đặt phòng này thuộc về khách khác.';

  @override
  String get bookingModifyUnavailableOnlyPending =>
      'Chỉ đặt phòng đang chờ mới có thể đổi.';

  @override
  String get bookingModifyUnavailablePaymentStarted =>
      'Đặt phòng cục bộ này đã có lượt thanh toán nên ảnh chụp lưu trú bị khóa để an toàn cho UI.';

  @override
  String get bookingModifyUnavailableRoomRate =>
      'Ảnh chụp phòng hoặc gói giá không còn khả dụng.';

  @override
  String get bookingModifyUnavailableStarted => 'Kỳ lưu trú này đã bắt đầu.';

  @override
  String get bookingModifyInvalidDates =>
      'Chọn ngày nhận phòng trong tương lai và ngày trả phòng sau ngày nhận phòng.';

  @override
  String get bookingModifyInvalidGuests =>
      'Số lượng khách phải hợp lệ và không âm.';

  @override
  String get bookingModifyCapacityExceeded =>
      'Số lượng khách vượt quá sức chứa của phòng.';

  @override
  String get bookingModifyQuoteUnavailable =>
      'Không có báo giá sửa đổi cục bộ an toàn cho các giá trị này.';

  @override
  String get bookingModifyNoChanges =>
      'Hãy thay đổi ít nhất một trường được hỗ trợ trước khi xem lại.';

  @override
  String get bookingModifyStale =>
      'Đặt phòng này đã thay đổi trong lúc bạn chỉnh sửa. Mở lại biểu mẫu và xem giá trị mới nhất.';

  @override
  String get bookingModifyBoundariesTitle => 'Ranh giới chỉnh sửa';

  @override
  String get bookingModifyPriceBoundaryLabel => 'Ảnh hưởng giá';

  @override
  String get bookingModifyPriceBoundary =>
      'Tổng mới là ước tính demo cục bộ xác định theo cấu trúc tổng toàn kỳ lưu trú chuẩn của backend. Đây không phải báo giá backend trực tiếp.';

  @override
  String get bookingModifyAvailabilityBoundaryLabel => 'Tình trạng phòng';

  @override
  String get bookingModifyAvailabilityBoundary =>
      'Chế độ Demo cục bộ không trừ tồn kho hoặc tạo giữ phòng mới. Tình trạng phòng trực tiếp vẫn do backend xử lý.';

  @override
  String get bookingModifyPaymentBoundaryLabel => 'Thanh toán';

  @override
  String get bookingModifyPaymentBoundary =>
      'Chỉnh sửa không đánh dấu thanh toán đã trả, thất bại, hủy hoặc hoàn tiền và không tạo lượt thanh toán.';

  @override
  String get bookingModifySnapshotBoundary =>
      'Không có tóm tắt chính sách an toàn cho khách ở ảnh chụp gói giá này.';

  @override
  String get bookingModifyLiveRepricingTitle => 'Báo giá backend trực tiếp';

  @override
  String get bookingModifyLiveRepricingUnavailable =>
      'Định giá lại trực tiếp và kiểm tra tồn kho có điều chỉnh trùng ngày được hiển thị như ranh giới tích hợp trung thực cho đến khi kết nối mạng được nối.';

  @override
  String get bookingCancelAction => 'Hủy đặt phòng';

  @override
  String get bookingCancelSemantic => 'Hủy đặt phòng demo này';

  @override
  String get bookingCancelConfirmTitle => 'Hủy đặt phòng demo?';

  @override
  String bookingCancelConfirmMessage(String code) {
    return 'Hủy đặt phòng cục bộ $code? Kỳ lưu trú vẫn nằm trong lịch sử và không gửi yêu cầu backend.';
  }

  @override
  String get bookingCancelReasonLabel => 'Lý do hủy';

  @override
  String get bookingCancelReasonHelper =>
      'Ghi chú cục bộ tùy chọn. Hợp đồng backend không bắt buộc lý do.';

  @override
  String get bookingCancellationLocalWarning =>
      'Thao tác này chỉ thay đổi dữ liệu trình bày Chế độ Demo cục bộ.';

  @override
  String get bookingCancelledMessage => 'Đã hủy đặt phòng demo cục bộ.';

  @override
  String get bookingCancellationUnavailableReal =>
      'Hủy đặt phòng thật cần tích hợp backend.';

  @override
  String get bookingCancellationUnavailableForbidden =>
      'Đặt phòng này thuộc về khách khác.';

  @override
  String get bookingCancellationUnavailableAlready =>
      'Đặt phòng này đã bị hủy.';

  @override
  String get bookingCancellationUnavailableCompleted =>
      'Kỳ lưu trú đã hoàn tất hoặc thuộc lịch sử không thể hủy.';

  @override
  String get bookingCancellationUnavailableStarted =>
      'Quá trình nhận phòng đã bắt đầu nên khách không thể hủy.';

  @override
  String get bookingCancellationUnavailableGeneric =>
      'Không thể hủy với trạng thái đặt phòng này.';

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
  String get bookingTimelineCreated => 'Đã tạo đặt phòng';

  @override
  String get bookingTimelinePaid => 'Đã hoàn tất thanh toán';

  @override
  String get bookingTimelineConfirmed => 'Đã xác nhận đặt phòng';

  @override
  String get bookingTimelineModified => 'Đã sửa đặt phòng';

  @override
  String get bookingTimelineCheckedIn => 'Khách đã nhận phòng';

  @override
  String get bookingTimelineCheckedOut => 'Khách đã trả phòng';

  @override
  String get bookingTimelineCompleted => 'Kỳ lưu trú hoàn tất';

  @override
  String get bookingTimelineCancelled => 'Đã hủy đặt phòng';

  @override
  String get bookingTimelineArchived => 'Đã lưu trữ đặt phòng';

  @override
  String get bookingTimelineRefunded => 'Đã hoàn tiền thanh toán';

  @override
  String get bookingTimelineUnknown => 'Đã cập nhật trạng thái';

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

  @override
  String get tripCompanionAction => 'Công cụ chuyến đi';

  @override
  String get tripCompanionTitle => 'Đồng hành chuyến đi';

  @override
  String tripCompanionSubtitle(String trip) {
    return 'Công cụ demo cục bộ cho $trip: chia sẻ, ghi chú, hành lý, nhắc việc và tài liệu.';
  }

  @override
  String get tripCompanionRealEmptyTitle => 'Công cụ chuyến đi chưa kết nối';

  @override
  String get tripCompanionRealEmptyMessage =>
      'Cộng tác, ghi chú, hành lý và nhắc việc của tài khoản thật sẽ hiển thị sau khi kết nối backend. Dữ liệu demo không hiển thị cho phiên thật.';

  @override
  String tripCompanionPermissionLabel(String role) {
    return 'Quyền: $role';
  }

  @override
  String get tripCompanionReadOnlyNotice =>
      'Chuyến đi này chỉ đọc với vai trò cục bộ hiện tại của bạn.';

  @override
  String get tripCompanionNoAccessRole => 'Không có quyền';

  @override
  String get tripCompanionCountCollaborators => 'Cộng tác viên';

  @override
  String get tripCompanionCountNotes => 'Ghi chú';

  @override
  String get tripCompanionCountPacking => 'Cần mang';

  @override
  String get tripCompanionCountReminders => 'Nhắc việc chờ xử lý';

  @override
  String get tripCompanionCountDocuments => 'Tài liệu';

  @override
  String get tripCompanionCollaborationTitle => 'Cộng tác';

  @override
  String get tripCompanionCollaborationSubtitle =>
      'Quản lý cộng tác viên demo cục bộ, vai trò và trạng thái riêng tư.';

  @override
  String get tripCompanionNotesTitle => 'Ghi chú & Nhật ký';

  @override
  String get tripCompanionNotesSubtitle =>
      'Lưu ghi chú ghim, ý tưởng, kỷ niệm và nhật ký.';

  @override
  String get tripCompanionPackingTitle => 'Danh sách hành lý';

  @override
  String get tripCompanionPackingSubtitle =>
      'Theo dõi món đã đóng gói, người phụ trách và việc còn lại.';

  @override
  String get tripCompanionRemindersTitle => 'Nhắc việc';

  @override
  String get tripCompanionRemindersSubtitle =>
      'Quản lý bản ghi nhắc việc trong ứng dụng, không lập lịch gửi.';

  @override
  String get tripCompanionDocumentsSubtitle =>
      'Mở màn hình tài liệu chuyến đi hiện có.';

  @override
  String tripCompanionOpenSemantic(String module) {
    return 'Mở $module';
  }

  @override
  String get sharedWithMeTitle => 'Được chia sẻ với tôi';

  @override
  String get sharedWithMeSubtitle =>
      'Các chuyến đi demo cục bộ đang hoạt động do người khác sở hữu.';

  @override
  String get sharedWithMeRealEmptyTitle =>
      'Chuyến đi được chia sẻ chưa kết nối';

  @override
  String get sharedWithMeRealEmptyMessage =>
      'Chuyến đi được chia sẻ của tài khoản thật sẽ hiển thị sau khi kết nối backend. Dữ liệu demo không hiển thị cho phiên thật.';

  @override
  String get sharedWithMeEmptyTitle => 'Chưa có chuyến đi được chia sẻ';

  @override
  String get sharedWithMeEmptyMessage =>
      'Chuyến đi được chia sẻ với bạn sẽ hiển thị tại đây trong Demo Mode.';

  @override
  String get sharedWithMeSummaryReadOnlyNotice =>
      'Tóm tắt này chỉ là phần trình bày demo cục bộ. Công cụ chuyến đi được chia sẻ đầy đủ sẽ mở khi backend cung cấp bản ghi chuyến đi hoàn chỉnh.';

  @override
  String sharedWithMeOwnerLabel(String owner) {
    return 'Chủ sở hữu: $owner';
  }

  @override
  String sharedWithMeRoleLabel(String role) {
    return 'Vai trò: $role';
  }

  @override
  String sharedWithMeCount(int count) {
    return '$count chuyến đi được chia sẻ';
  }

  @override
  String get collaborationPrivacyPrivate => 'Chuyến đi demo riêng tư';

  @override
  String get collaborationPrivacyPublic => 'Hiển thị công khai demo';

  @override
  String get collaborationPrivacyNotice =>
      'Chỉ chủ sở hữu mới được quản lý cộng tác viên và trạng thái công khai/riêng tư. Hiển thị demo không tạo liên kết chia sẻ thật.';

  @override
  String get collaborationInviteTitle => 'Mời cộng tác viên';

  @override
  String get collaborationInviteEmailLabel => 'Email người dùng demo';

  @override
  String get collaborationInviteAction => 'Mời';

  @override
  String get collaborationRoleViewer => 'Người xem';

  @override
  String get collaborationRoleEditor => 'Người sửa';

  @override
  String get collaborationOwnerRole => 'Chủ sở hữu';

  @override
  String get collaborationActiveLabel => 'Đang hoạt động';

  @override
  String get collaborationInactiveLabel => 'Không hoạt động';

  @override
  String get collaborationChangeRoleAction => 'Vai trò';

  @override
  String get collaborationRemoveAction => 'Xóa';

  @override
  String get collaborationRemoveConfirmTitle => 'Xóa cộng tác viên?';

  @override
  String collaborationRemoveConfirmMessage(String name) {
    return 'Xóa $name khỏi chuyến đi demo cục bộ này? Ghi chú đã viết vẫn được giữ trong lịch sử.';
  }

  @override
  String get collaborationPublicToggleLabel => 'Hiển thị công khai demo';

  @override
  String get collaborationNoShareUrlNotice =>
      'UI phase này không tạo URL công khai, mã QR hay kết quả gửi chia sẻ bên ngoài.';

  @override
  String get tripToolSavedMessage =>
      'Thay đổi công cụ chuyến đi đã lưu cục bộ.';

  @override
  String get tripToolUnavailableMessage =>
      'Tác vụ công cụ chuyến đi chưa kết nối cho tài khoản thật trong UI phase này.';

  @override
  String get tripToolForbiddenMessage =>
      'Vai trò hiện tại không được thực hiện tác vụ này.';

  @override
  String get tripToolBlankMessage => 'Nội dung bắt buộc không được để trống.';

  @override
  String get tripToolInvalidEmailMessage => 'Nhập địa chỉ email hợp lệ.';

  @override
  String get tripToolDuplicateMessage => 'Bản ghi cục bộ này đã tồn tại.';

  @override
  String get tripToolRejectedMessage =>
      'Tác vụ này không thể hoàn tất với dữ liệu chuyến đi hiện tại.';

  @override
  String get tripToolUnsafeUrlMessage =>
      'Dùng URL http hoặc https hợp lệ, có host và không có thông tin đăng nhập.';

  @override
  String get tripToolNotFoundMessage => 'Bản ghi đã chọn không còn khả dụng.';

  @override
  String get tripToolInvalidQuantityMessage =>
      'Số lượng phải là số nguyên tối thiểu 1.';

  @override
  String get tripToolInvalidReorderMessage =>
      'Sắp xếp hành lý phải gồm mỗi item hiện tại đúng một lần.';

  @override
  String get tripToolInvalidDateMessage => 'Dùng ngày giờ cục bộ hợp lệ.';

  @override
  String get notesSearchHint => 'Tìm ghi chú, tác giả hoặc nội dung nhật ký';

  @override
  String get notesAddAction => 'Thêm ghi chú';

  @override
  String get notesEditAction => 'Sửa ghi chú';

  @override
  String get notesContentLabel => 'Nội dung';

  @override
  String get notesTitleLabel => 'Tiêu đề';

  @override
  String get notesTypeLabel => 'Loại ghi chú';

  @override
  String get notesMoodLabel => 'Tâm trạng';

  @override
  String get notesPhotoUrlLabel => 'URL ảnh an toàn';

  @override
  String get notesPhotoMetadataLabel => 'Siêu dữ liệu URL ảnh';

  @override
  String get notesLinkedDayLabel => 'Ngày liên kết';

  @override
  String get notesLinkedItemLabel => 'Hoạt động liên kết';

  @override
  String get notesEmptyTitle => 'Không có ghi chú phù hợp';

  @override
  String get notesEmptyMessage =>
      'Thêm ghi chú demo cục bộ hoặc điều chỉnh tìm kiếm và bộ lọc.';

  @override
  String get notesPinAction => 'Ghim';

  @override
  String get notesUnpinAction => 'Bỏ ghim';

  @override
  String get notesDeleteAction => 'Xóa ghi chú';

  @override
  String get notesDeleteConfirmTitle => 'Xóa ghi chú?';

  @override
  String notesDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi nhật ký demo cục bộ?';
  }

  @override
  String get noteTypeNote => 'Ghi chú';

  @override
  String get noteTypeJournal => 'Nhật ký';

  @override
  String get noteTypeReminder => 'Ghi chú nhắc việc';

  @override
  String get noteTypeIdea => 'Ý tưởng';

  @override
  String get noteTypeMemory => 'Kỷ niệm';

  @override
  String get moodHappy => 'Vui';

  @override
  String get moodExcited => 'Hào hứng';

  @override
  String get moodCalm => 'Bình tĩnh';

  @override
  String get moodTired => 'Mệt';

  @override
  String get moodStressed => 'Căng thẳng';

  @override
  String get moodNeutral => 'Trung lập';

  @override
  String get packingSearchHint => 'Tìm hành lý, ghi chú hoặc người phụ trách';

  @override
  String get packingAddAction => 'Thêm món hành lý';

  @override
  String get packingEditAction => 'Sửa món';

  @override
  String get packingLabelField => 'Tên món';

  @override
  String get packingQuantityField => 'Số lượng';

  @override
  String get packingCategoryLabel => 'Nhóm hành lý';

  @override
  String get packingAssigneeLabel => 'Giao cho';

  @override
  String get packingNotesField => 'Ghi chú';

  @override
  String get packingEmptyTitle => 'Không có món hành lý phù hợp';

  @override
  String get packingEmptyMessage =>
      'Thêm món hành lý demo cục bộ hoặc điều chỉnh bộ lọc.';

  @override
  String packingProgressValue(int checked, int total, int percent) {
    return '$checked / $total đã đóng gói ($percent%)';
  }

  @override
  String packingUncheckedCount(int count) {
    return '$count món chưa đóng gói';
  }

  @override
  String get packingDeleteAction => 'Xóa món';

  @override
  String get packingDeleteConfirmTitle => 'Xóa món hành lý?';

  @override
  String packingDeleteConfirmMessage(String label) {
    return 'Xóa $label khỏi danh sách demo cục bộ này?';
  }

  @override
  String get packingMoveUpAction => 'Chuyển lên';

  @override
  String get packingMoveDownAction => 'Chuyển xuống';

  @override
  String get packingUnassignedLabel => 'Chưa giao';

  @override
  String get packingCategoryDocuments => 'Tài liệu';

  @override
  String get packingCategoryClothes => 'Quần áo';

  @override
  String get packingCategoryToiletries => 'Đồ cá nhân';

  @override
  String get packingCategoryElectronics => 'Điện tử';

  @override
  String get packingCategoryMedicine => 'Thuốc';

  @override
  String get packingCategoryMoney => 'Tiền';

  @override
  String get packingCategoryFood => 'Đồ ăn';

  @override
  String get packingCategoryBaby => 'Em bé';

  @override
  String get packingCategoryPet => 'Thú cưng';

  @override
  String get packingCategoryOther => 'Khác';

  @override
  String get remindersIncludeCancelled => 'Gồm mục đã hủy';

  @override
  String get remindersAddAction => 'Thêm nhắc việc';

  @override
  String get remindersEditAction => 'Sửa nhắc việc';

  @override
  String get reminderTitleField => 'Tiêu đề nhắc việc';

  @override
  String get reminderMessageField => 'Thông điệp';

  @override
  String get reminderAtField => 'Ngày giờ cục bộ';

  @override
  String get reminderTypeLabel => 'Loại nhắc việc';

  @override
  String get reminderStatusPending => 'Chờ xử lý';

  @override
  String get reminderStatusCompleted => 'Đã hoàn tất';

  @override
  String get reminderStatusCancelled => 'Đã hủy';

  @override
  String get reminderOverdue => 'Quá hạn';

  @override
  String get reminderEmptyTitle => 'Không có nhắc việc phù hợp';

  @override
  String get reminderEmptyMessage =>
      'Thêm bản ghi nhắc việc cục bộ hoặc bật hiển thị mục đã hủy.';

  @override
  String get reminderCompleteAction => 'Hoàn tất';

  @override
  String get reminderCancelAction => 'Hủy nhắc việc';

  @override
  String get reminderDeleteAction => 'Xóa nhắc việc';

  @override
  String get reminderDeleteConfirmTitle => 'Xóa nhắc việc?';

  @override
  String reminderDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi chuyến đi demo cục bộ này?';
  }

  @override
  String get reminderTypeCustom => 'Tùy chỉnh';

  @override
  String get reminderTypeDocument => 'Tài liệu';

  @override
  String get reminderTypeCheckIn => 'Nhận phòng';

  @override
  String get reminderTypeFlight => 'Chuyến bay';

  @override
  String get reminderTypeActivity => 'Hoạt động';

  @override
  String get reminderTypePayment => 'Thanh toán';

  @override
  String get reminderTypePacking => 'Hành lý';

  @override
  String get reminderTypeOther => 'Khác';

  @override
  String get reminderLocalTimeHelper =>
      'Định dạng: yyyy-MM-dd HH:mm. Sẽ lưu theo UTC để phù hợp API sau này.';

  @override
  String get reminderNoDeliveryNotice =>
      'Đây chỉ là bản ghi nhắc việc trong ứng dụng. UI-9 không lập lịch push, email, SMS hay thông báo hệ điều hành.';

  @override
  String get reviewsTitle => 'Đánh giá';

  @override
  String get reviewsSubtitle =>
      'Duyệt tóm tắt đánh giá demo cục bộ theo hợp đồng đánh giá khách hàng đã commit.';

  @override
  String get reviewsRealUnavailableTitle => 'Đánh giá chưa được kết nối';

  @override
  String get reviewsRealUnavailableMessage =>
      'API đánh giá chưa được nối trong giai đoạn UI này. Phiên thật không hiển thị dữ liệu đánh giá cục bộ.';

  @override
  String get reviewSummaryTitle => 'Niềm tin du khách';

  @override
  String reviewSummarySemantic(String place) {
    return 'Tóm tắt đánh giá cho $place';
  }

  @override
  String get reviewPublicVisibilityNotice =>
      'Danh sách công khai chỉ dùng tóm tắt đánh giá đã duyệt và đã được lọc an toàn.';

  @override
  String get reviewNoReviewsTitle => 'Chưa có đánh giá đã duyệt';

  @override
  String get reviewNoReviewsMessage =>
      'Đánh giá demo cục bộ đã duyệt sẽ xuất hiện ở đây mà không lộ chi tiết đặt phòng.';

  @override
  String get reviewSeeAllAction => 'Xem tất cả đánh giá';

  @override
  String get reviewWriteAction => 'Viết đánh giá';

  @override
  String reviewWriteSemantic(String place) {
    return 'Viết đánh giá cho $place';
  }

  @override
  String reviewAggregateAverage(String average) {
    return 'Trung bình $average';
  }

  @override
  String reviewRatingSemantic(String rating) {
    return 'Điểm trung bình $rating trên 5';
  }

  @override
  String reviewRatingOutOfFive(int rating) {
    return '$rating trên 5';
  }

  @override
  String reviewCountExact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đánh giá đã duyệt',
      one: '1 đánh giá đã duyệt',
    );
    return '$_temp0';
  }

  @override
  String reviewVerifiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kỳ lưu trú xác thực',
      one: '1 kỳ lưu trú xác thực',
    );
    return '$_temp0';
  }

  @override
  String get reviewDistributionSemantic => 'Phân bố điểm đánh giá';

  @override
  String reviewStars(int rating) {
    return 'Điểm $rating';
  }

  @override
  String reviewCategoryAverage(String category, String average) {
    return '$category: $average';
  }

  @override
  String get reviewCategoryCleanliness => 'Sạch sẽ';

  @override
  String get reviewCategoryService => 'Dịch vụ';

  @override
  String get reviewCategoryLocation => 'Vị trí';

  @override
  String get reviewCategoryValue => 'Giá trị';

  @override
  String get reviewCategoryFacilities => 'Tiện nghi';

  @override
  String get reviewFiltersTitle => 'Bộ điều khiển đánh giá';

  @override
  String get reviewSortLabel => 'Sắp xếp';

  @override
  String get reviewSortNewest => 'Mới nhất';

  @override
  String get reviewSortOldest => 'Cũ nhất';

  @override
  String get reviewSortHighest => 'Điểm cao nhất';

  @override
  String get reviewSortLowest => 'Điểm thấp nhất';

  @override
  String get reviewSortHelpful => 'Hữu ích nhất';

  @override
  String get reviewFilterRating => 'Điểm';

  @override
  String get reviewFilterVerifiedOnly => 'Chỉ kỳ lưu trú xác thực';

  @override
  String get reviewFilteredEmptyTitle => 'Không có đánh giá phù hợp';

  @override
  String get reviewFilteredEmptyMessage =>
      'Điều chỉnh bộ lọc cục bộ để xem tóm tắt đánh giá demo đã duyệt.';

  @override
  String get reviewDetailTitle => 'Chi tiết đánh giá';

  @override
  String get reviewNotFoundTitle => 'Không có đánh giá';

  @override
  String get reviewNotFoundMessage =>
      'Đánh giá này không còn trong trạng thái demo cục bộ.';

  @override
  String reviewCardSemantic(String place, int rating) {
    return 'Đánh giá cho $place, $rating trên 5';
  }

  @override
  String get reviewVerifiedStay => 'Lưu trú xác thực';

  @override
  String get reviewUntitled => 'Đánh giá chưa có tiêu đề';

  @override
  String reviewAuthorLine(String author) {
    return 'Bởi $author';
  }

  @override
  String get reviewPublicSummaryOnly =>
      'Hợp đồng backend công khai chỉ trả tóm tắt đã lọc an toàn. Nội dung đầy đủ chỉ hiển thị trong phần đánh giá của tác giả.';

  @override
  String get reviewUnsupportedActionsNotice =>
      'Giai đoạn ứng dụng người dùng cục bộ này chưa có sửa/xóa phía khách hàng, bình chọn hữu ích, báo cáo, tải lên/xóa media hoặc chỉnh sửa phản hồi từ đối tác.';

  @override
  String get reviewMediaTitle => 'Media đánh giá';

  @override
  String reviewMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục media',
      one: '1 mục media',
    );
    return '$_temp0';
  }

  @override
  String reviewMediaCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count media đánh giá',
      one: '1 media đánh giá',
    );
    return '$_temp0';
  }

  @override
  String reviewMoreMediaCount(int count) {
    return '+$count mục nữa';
  }

  @override
  String reviewMediaGallerySemantic(int count) {
    return 'Thư viện media đánh giá có $count mục';
  }

  @override
  String reviewMediaItemSemantic(
      int index, int total, String type, String description) {
    return 'Media đánh giá $index trên $total, $type, $description';
  }

  @override
  String reviewMediaIndex(int index, int total) {
    return '$index trên $total';
  }

  @override
  String get reviewMediaTypePhoto => 'Ảnh';

  @override
  String get reviewMediaTypeVideo => 'Video';

  @override
  String get reviewMediaTypeDocument => 'Tài liệu';

  @override
  String get reviewCoverMedia => 'Ảnh bìa';

  @override
  String get reviewMediaUnavailable => 'Media không khả dụng';

  @override
  String get reviewImageUnavailable => 'Ảnh không khả dụng';

  @override
  String get reviewVideoPreviewUnavailable => 'Chưa có xem trước video';

  @override
  String get reviewUnsupportedMedia => 'Media chưa hỗ trợ';

  @override
  String get reviewPartnerResponseTitle => 'Phản hồi từ nơi lưu trú';

  @override
  String get reviewPropertyResponseIndicator => 'Có phản hồi';

  @override
  String reviewPartnerResponseSemantic(String review) {
    return 'Phản hồi của nơi lưu trú cho $review';
  }

  @override
  String reviewRespondedOn(String date) {
    return 'Đã phản hồi vào $date';
  }

  @override
  String get reviewMediaAttachmentTitle => 'Media đánh giá';

  @override
  String get reviewMediaAttachmentUnavailable =>
      'Đính kèm ảnh và video sẽ có khi API media đánh giá được kết nối.';

  @override
  String get reviewUploadRequiresBackend =>
      'Demo cục bộ này chỉ gửi đánh giá dạng văn bản; không tải tệp lên hoặc nhận URL media nhập tay.';

  @override
  String get reviewDetailMetadataTitle => 'Siêu dữ liệu đánh giá';

  @override
  String get reviewLinkedBookingLabel => 'Đặt phòng liên kết';

  @override
  String get reviewCreatedAtLabel => 'Đã gửi';

  @override
  String get reviewApprovedAtLabel => 'Đã duyệt';

  @override
  String get reviewRejectedAtLabel => 'Đã từ chối';

  @override
  String get reviewRejectReasonLabel => 'Lý do từ chối an toàn';

  @override
  String get reviewHelpfulCountLabel => 'Lượt hữu ích';

  @override
  String get reviewReportedCountLabel => 'Lượt báo cáo';

  @override
  String get reviewWriteTitle => 'Viết đánh giá';

  @override
  String get reviewIneligibleTitle => 'Chưa thể đánh giá';

  @override
  String get reviewBackendCreateNotice =>
      'Đánh giá demo cục bộ ánh xạ tới tuyến đánh giá khách hàng theo đặt phòng và bắt đầu ở trạng thái Chờ duyệt. Đánh giá không được gửi lên backend.';

  @override
  String get reviewOverallRatingLabel => 'Điểm tổng thể';

  @override
  String get reviewTitleLabel => 'Tiêu đề';

  @override
  String get reviewTitleHelper => 'Không bắt buộc. Tối đa 200 ký tự.';

  @override
  String get reviewContentLabel => 'Nội dung đánh giá';

  @override
  String get reviewContentHelper => 'Không bắt buộc. Tối đa 5000 ký tự.';

  @override
  String get reviewCategoryRatingsTitle => 'Điểm hạng mục tùy chọn';

  @override
  String get reviewCategorySkipped => 'Không chấm';

  @override
  String get reviewSubmitAction => 'Gửi đánh giá demo cục bộ';

  @override
  String get reviewSubmittedMessage =>
      'Đã gửi đánh giá demo cục bộ ở trạng thái Chờ duyệt.';

  @override
  String get reviewUnavailableMessage =>
      'Tích hợp đánh giá chưa bật cho phiên thật trong giai đoạn UI này.';

  @override
  String get reviewIneligibleCompletedOnly =>
      'Chỉ có đặt phòng demo cục bộ đã hoàn tất và thuộc về bạn mới có thể đánh giá.';

  @override
  String get reviewDuplicateMessage => 'Đặt phòng này đã có đánh giá.';

  @override
  String get reviewInvalidRatingMessage => 'Điểm đánh giá phải từ 1 đến 5.';

  @override
  String get reviewTitleTooLongMessage => 'Tiêu đề đánh giá tối đa 200 ký tự.';

  @override
  String get reviewContentTooLongMessage =>
      'Nội dung đánh giá tối đa 5000 ký tự.';

  @override
  String get myReviewsTitle => 'Đánh giá của tôi';

  @override
  String get myReviewsSubtitle =>
      'Lịch sử đánh giá demo cục bộ của bạn. Trạng thái bám theo trạng thái đánh giá backend đã commit.';

  @override
  String get myReviewsRealEmptyTitle => 'Đánh giá của tôi chưa được kết nối';

  @override
  String get myReviewsRealEmptyMessage =>
      'Phiên thật không hiển thị lịch sử đánh giá seed cho đến khi API đánh giá khách hàng được nối.';

  @override
  String get myReviewsEmptyTitle => 'Chưa có đánh giá cục bộ';

  @override
  String get myReviewsEmptyMessage =>
      'Mỗi đặt phòng demo đã hoàn tất có thể tạo một đánh giá cục bộ ở trạng thái chờ duyệt.';

  @override
  String reviewSectionHeader(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get reviewStatusPending => 'Chờ duyệt';

  @override
  String get reviewStatusApproved => 'Đã duyệt';

  @override
  String get reviewStatusRejected => 'Đã từ chối';

  @override
  String get reviewStatusHidden => 'Đã ẩn';

  @override
  String get reviewStatusReported => 'Đã báo cáo';

  @override
  String wishlistBookmarkAddedMessage(String place) {
    return 'Đã lưu $place vào danh sách yêu thích.';
  }

  @override
  String wishlistBookmarkRemovedMessage(String place) {
    return 'Đã xóa $place khỏi danh sách yêu thích.';
  }

  @override
  String wishlistBookmarkNotPublishedMessage(String place) {
    return '$place chưa được xuất bản nên chưa thể lưu.';
  }

  @override
  String get wishlistBookmarkNetworkMessage =>
      'Không thể kết nối máy chủ. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get wishlistBookmarkServerErrorMessage =>
      'Đã xảy ra lỗi phía máy chủ. Vui lòng thử lại.';

  @override
  String get wishlistBookmarkUnavailableMessage => 'Hiện chưa thể lưu.';

  @override
  String wishlistBookmarkSavingSemantic(String place) {
    return 'Đang cập nhật trạng thái lưu cho $place';
  }

  @override
  String get wishlistRealLoadingTitle => 'Đang tải danh sách yêu thích';

  @override
  String get wishlistRealLoadingMessage => 'Đang lấy các địa điểm đã lưu…';

  @override
  String get wishlistRealEmptyTitle => 'Danh sách yêu thích trống';

  @override
  String get wishlistRealEmptyMessage =>
      'Chạm vào biểu tượng dấu trang ở bất kỳ địa điểm nào để lưu vào đây.';

  @override
  String get wishlistRealErrorMessage =>
      'Không thể tải danh sách yêu thích. Vui lòng thử lại.';

  @override
  String get wishlistRealPartialDetailsNote =>
      'Chỉ có thông tin hạn chế cho địa điểm đã lưu này.';
}
