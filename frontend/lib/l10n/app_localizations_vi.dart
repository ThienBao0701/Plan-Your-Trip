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
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordSubtitle =>
      'Nhập email của tài khoản. Nếu tài khoản tồn tại, liên kết đặt lại mật khẩu sẽ được gửi.';

  @override
  String get forgotPasswordSendAction => 'Gửi liên kết đặt lại';

  @override
  String get forgotPasswordReturnAction => 'Quay lại đăng nhập';

  @override
  String get forgotPasswordInfo =>
      'Vì lý do bảo mật, phản hồi là như nhau dù địa chỉ có tài khoản hay không.';

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
  String get bookingContinueAction => 'Tiếp tục đặt phòng';

  @override
  String get bookingContinueSemantic => 'Tiếp tục đặt phòng với phòng đã chọn';

  @override
  String bookingStepLabel(int current, int total) {
    return 'Bước $current/$total';
  }

  @override
  String get bookingSummaryTitle => 'Tóm tắt đặt phòng';

  @override
  String get bookingSummaryStayTitle => 'Kỳ nghỉ của bạn';

  @override
  String get bookingQuoteLoadingMessage => 'Đang lấy giá mới nhất…';

  @override
  String get bookingQuoteErrorMessage =>
      'Không tải được giá. Vui lòng thử lại.';

  @override
  String get bookingQuoteInvalidDatesMessage =>
      'Ngày trả phòng phải sau ngày nhận phòng.';

  @override
  String get bookingTripLinkedLabel => 'Đã liên kết với chuyến đi của bạn';

  @override
  String get bookingGuestInfoContinueAction => 'Tiếp tục nhập thông tin khách';

  @override
  String get bookingGuestInfoTitle => 'Thông tin khách';

  @override
  String get bookingGuestSectionTitle => 'Khách chính';

  @override
  String get bookingGuestNameLabel => 'Họ và tên';

  @override
  String get bookingGuestEmailLabel => 'Email';

  @override
  String get bookingGuestPhoneLabel => 'Số điện thoại (tùy chọn)';

  @override
  String get bookingGuestCountryLabel => 'Quốc gia hoặc khu vực (tùy chọn)';

  @override
  String get bookingArrivalTimeLabel => 'Giờ đến dự kiến (tùy chọn)';

  @override
  String get bookingArrivalTimeHint => 'ví dụ 15:00';

  @override
  String get bookingGuestLocalOnlyNote =>
      'Họ tên, số điện thoại, quốc gia và giờ đến hiện chỉ được lưu trên thiết bị này — API đặt phòng chưa lưu các thông tin này.';

  @override
  String get bookingSpecialRequestsTitle => 'Yêu cầu đặc biệt';

  @override
  String get specialRequestLateCheckIn => 'Nhận phòng muộn';

  @override
  String get specialRequestHighFloor => 'Tầng cao';

  @override
  String get specialRequestQuietRoom => 'Phòng yên tĩnh';

  @override
  String get specialRequestTwinBed => 'Giường đôi tách';

  @override
  String get specialRequestLargeBed => 'Giường lớn';

  @override
  String get bookingSpecialRequestNoteLabel => 'Yêu cầu khác';

  @override
  String get bookingSpecialRequestNoteHelper =>
      'Tùy chọn. Yêu cầu được ghi nhận nhưng không đảm bảo.';

  @override
  String get bookingValidationNameRequired => 'Vui lòng nhập họ tên của khách.';

  @override
  String get bookingValidationEmailRequired => 'Vui lòng nhập email liên hệ.';

  @override
  String get bookingValidationEmailInvalid => 'Nhập địa chỉ email hợp lệ.';

  @override
  String get bookingValidationPhoneInvalid => 'Nhập số điện thoại hợp lệ.';

  @override
  String get bookingValidationTooLong => 'Giá trị này quá dài.';

  @override
  String get bookingReviewContinueAction => 'Tiếp tục đến xem lại';

  @override
  String get bookingReviewGuestTitle => 'Thông tin khách';

  @override
  String get bookingNoSpecialRequests => 'Không có yêu cầu đặc biệt';

  @override
  String get bookingDraftTermsAcknowledgement =>
      'Tôi hiểu bước này chỉ chuẩn bị bản nháp đặt phòng — chưa tạo đặt phòng, chưa thanh toán và chưa có xác nhận.';

  @override
  String get bookingDraftNoReservationNote =>
      'Việc chuẩn bị bản nháp không tạo đặt phòng hay thu tiền.';

  @override
  String get bookingPrepareAction => 'Chuẩn bị đặt phòng';

  @override
  String get bookingPrepareSemantic => 'Chuẩn bị bản nháp đặt phòng của bạn';

  @override
  String get bookingDraftInvalidMessage =>
      'Vui lòng hoàn tất thông tin khách trước.';

  @override
  String get bookingDraftQuoteMissingMessage =>
      'Giá vẫn đang tải. Vui lòng đợi một chút.';

  @override
  String get bookingReadyTitle => 'Đặt phòng đã sẵn sàng';

  @override
  String get bookingReadyHeadline =>
      'Đặt phòng của bạn đã sẵn sàng để xác nhận';

  @override
  String get bookingReadyBody =>
      'Chúng tôi đã chuẩn bị thông tin đặt phòng của bạn. Đây là bản nháp — chưa tạo đặt phòng, chưa thu tiền và chưa cấp mã xác nhận. Việc kết nối bước đặt phòng và thanh toán sẽ có ở giai đoạn tiếp theo.';

  @override
  String get bookingReadySemantic =>
      'Đặt phòng đã được chuẩn bị và sẵn sàng để xác nhận';

  @override
  String get bookingReadyDoneAction => 'Quay lại khám phá';

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

  @override
  String placeHydrationLoadingSemantic(String place) {
    return 'Đang tải chi tiết cho $place';
  }

  @override
  String get placeHydrationUnavailableMessage =>
      'Địa điểm này không còn khả dụng.';

  @override
  String get placeHydrationErrorMessage =>
      'Không thể tải chi tiết địa điểm. Vui lòng thử lại.';

  @override
  String get tripsRealLoadingMessage => 'Đang tải chuyến đi của bạn…';

  @override
  String get tripsRealErrorMessage =>
      'Không thể tải chuyến đi của bạn. Vui lòng thử lại.';

  @override
  String get tripsRealEmptyMessage =>
      'Bạn chưa tạo chuyến đi nào. Hãy bắt đầu lên kế hoạch cho hành trình tiếp theo.';

  @override
  String get tripsRealSessionExpiredTitle => 'Phiên đăng nhập đã hết hạn';

  @override
  String get tripsRealSessionExpiredMessage =>
      'Vui lòng đăng nhập lại để xem chuyến đi của bạn.';

  @override
  String get tripsRealSignInAction => 'Đăng nhập';

  @override
  String get tripRealPermissionDeniedMessage =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get tripStatusPlanning => 'Đang lên kế hoạch';

  @override
  String get tripStatusActive => 'Đang diễn ra';

  @override
  String get tripStatusCompleted => 'Đã hoàn thành';

  @override
  String get tripStatusCancelled => 'Đã hủy';

  @override
  String get tripStatusUnknown => 'Chuyến đi';

  @override
  String tripDayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String get tripDetailRealTitle => 'Chuyến đi';

  @override
  String get tripDetailRealLoadingMessage => 'Đang tải chi tiết chuyến đi…';

  @override
  String get tripDetailRealUnavailableTitle => 'Chuyến đi không khả dụng';

  @override
  String get tripDetailRealUnavailableMessage =>
      'Chuyến đi này không còn khả dụng.';

  @override
  String get tripDetailRealErrorMessage =>
      'Không thể tải chuyến đi này. Vui lòng thử lại.';

  @override
  String get tripDetailRealEditDisabledNote =>
      'Chưa thể chỉnh sửa lịch trình này.';

  @override
  String get tripDetailRealNoDaysMessage => 'Chuyến đi này chưa có ngày nào.';

  @override
  String get tripDetailRealNoItemsMessage =>
      'Chưa có hoạt động nào cho ngày này.';

  @override
  String get addToTripRealLoadingTrips => 'Đang tải chuyến đi của bạn…';

  @override
  String get addToTripRealNoTripsMessage =>
      'Bạn chưa có chuyến đi nào. Hãy tạo một chuyến để bắt đầu thêm địa điểm.';

  @override
  String get addToTripRealSelectTripLabel => 'Chọn chuyến đi';

  @override
  String get addToTripRealSelectDayLabel => 'Chọn ngày';

  @override
  String addToTripRealNewDayOption(int day) {
    return 'Ngày mới (Ngày $day)';
  }

  @override
  String get addToTripRealPlanningNote =>
      'Thao tác này thêm địa điểm vào kế hoạch chuyến đi. Đây không phải là đặt chỗ.';

  @override
  String get addToTripRealAddingMessage => 'Đang thêm vào chuyến đi…';

  @override
  String addToTripRealAddedMessage(String place) {
    return 'Đã thêm $place vào chuyến đi của bạn.';
  }

  @override
  String get addToTripRealErrorMessage =>
      'Không thể thêm địa điểm này. Vui lòng thử lại.';

  @override
  String get addToTripRealUnpublishedMessage =>
      'Hiện chưa thể thêm địa điểm này vào chuyến đi.';

  @override
  String get addToTripRealTripUnavailableMessage =>
      'Chuyến đi hoặc địa điểm đó không còn khả dụng.';

  @override
  String get createTripRealErrorMessage =>
      'Không thể tạo chuyến đi của bạn. Vui lòng thử lại.';

  @override
  String get searchRealLoadingMessage => 'Đang tìm địa điểm…';

  @override
  String get searchRealErrorMessage =>
      'Không thể tải địa điểm. Vui lòng thử lại.';

  @override
  String get searchRealNoResultsMessage =>
      'Không có địa điểm nào phù hợp. Hãy thử từ khóa hoặc bộ lọc khác.';

  @override
  String get searchRealEndOfResults => 'Bạn đã xem hết kết quả.';

  @override
  String get searchRealSortLabel => 'Sắp xếp theo';

  @override
  String get searchRealRatingLabel => 'Đánh giá tối thiểu';

  @override
  String get searchRealPriceLabel => 'Giá tối đa';

  @override
  String get searchRealSortNewest => 'Mới nhất';

  @override
  String get searchRealSortTopRated => 'Đánh giá cao nhất';

  @override
  String get searchRealSortPriceLow => 'Giá: thấp đến cao';

  @override
  String get searchRealSortPriceHigh => 'Giá: cao đến thấp';

  @override
  String get searchRealSortName => 'Tên A–Z';

  @override
  String get searchRealRatingAny => 'Bất kỳ';

  @override
  String get searchRealRating3plus => '3.0+';

  @override
  String get searchRealRating4plus => '4.0+';

  @override
  String get searchRealRating45plus => '4.5+';

  @override
  String get searchRealPriceAny => 'Bất kỳ';

  @override
  String get availabilityRealLoadingMessage =>
      'Đang kiểm tra phòng trống thực tế…';

  @override
  String get availabilityRealErrorMessage =>
      'Không tải được phòng trống. Vui lòng thử lại.';

  @override
  String get availabilityRealInvalidDatesMessage =>
      'Chọn ngày trả phòng sau ngày nhận phòng để xem phòng.';

  @override
  String availabilityRealRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count phòng',
      one: 'Còn 1 phòng',
    );
    return '$_temp0';
  }

  @override
  String availabilityRealPerNight(String price) {
    return '$price / đêm';
  }

  @override
  String availabilityRealOriginalPrice(String price) {
    return '$price';
  }

  @override
  String availabilityRealTotalForNights(String price, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights đêm',
      one: '1 đêm',
    );
    return '$price tổng · $_temp0';
  }

  @override
  String get availabilityRealFreeCancellation => 'Miễn phí hủy';

  @override
  String get availabilityRealInstantConfirmation => 'Xác nhận tức thì';

  @override
  String get placeDetailRealLoadingMessage => 'Đang tải thông tin địa điểm…';

  @override
  String get placeDetailRealErrorMessage =>
      'Không thể tải địa điểm này. Vui lòng thử lại.';

  @override
  String get placeDetailRealNotFoundMessage =>
      'Địa điểm này không còn khả dụng.';

  @override
  String placeGallerySemantic(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
    );
    return 'Thư viện ảnh của $name, $_temp0';
  }

  @override
  String get placeGalleryClose => 'Đóng ảnh';

  @override
  String get placeOpenNow => 'Đang mở cửa';

  @override
  String get placeClosedNow => 'Đang đóng cửa';

  @override
  String get placeOpeningHoursTitle => 'Giờ mở cửa';

  @override
  String get placeOpeningHoursClosed => 'Đóng cửa';

  @override
  String get placeCoordinatesTitle => 'Vị trí';

  @override
  String placeCoordinatesValue(String lat, String long) {
    return '$lat, $long';
  }

  @override
  String get placeAmenitiesTitle => 'Tiện ích';

  @override
  String get placeMetadataTitle => 'Thông tin hữu ích';

  @override
  String get metadataVisitDurationTitle => 'Thời gian tham quan gợi ý';

  @override
  String get metadataTravelStylesTitle => 'Phong cách du lịch';

  @override
  String get metadataBestSeasonsTitle => 'Mùa đẹp nhất';

  @override
  String get metadataBestVisitTimesTitle => 'Thời điểm trong ngày';

  @override
  String get metadataWeatherTitle => 'Thời tiết';

  @override
  String get metadataBudgetTitle => 'Ngân sách';

  @override
  String get metadataDifficultyTitle => 'Độ khó';

  @override
  String get metadataAccessibilityTitle => 'Khả năng tiếp cận';

  @override
  String get metadataCrowdTitle => 'Mức độ đông đúc';

  @override
  String get metadataHighlightsTitle => 'Điểm nổi bật';

  @override
  String get metadataNotesTitle => 'Ghi chú';

  @override
  String get travelStyleSolo => 'Một mình';

  @override
  String get travelStyleCouple => 'Cặp đôi';

  @override
  String get travelStyleFamily => 'Gia đình';

  @override
  String get travelStyleFriends => 'Bạn bè';

  @override
  String get travelStyleBusiness => 'Công tác';

  @override
  String get travelStyleBackpacker => 'Phượt';

  @override
  String get travelStyleLuxury => 'Sang trọng';

  @override
  String get bestVisitTimeEarlyMorning => 'Sáng sớm';

  @override
  String get bestVisitTimeMorning => 'Buổi sáng';

  @override
  String get bestVisitTimeAfternoon => 'Buổi chiều';

  @override
  String get bestVisitTimeSunset => 'Hoàng hôn';

  @override
  String get bestVisitTimeEvening => 'Buổi tối';

  @override
  String get bestVisitTimeNight => 'Ban đêm';

  @override
  String get bestSeasonSpring => 'Mùa xuân';

  @override
  String get bestSeasonSummer => 'Mùa hè';

  @override
  String get bestSeasonAutumn => 'Mùa thu';

  @override
  String get bestSeasonWinter => 'Mùa đông';

  @override
  String get bestSeasonAllYear => 'Quanh năm';

  @override
  String get weatherSunny => 'Nắng';

  @override
  String get weatherCloudy => 'Nhiều mây';

  @override
  String get weatherRainy => 'Mưa';

  @override
  String get weatherCool => 'Mát mẻ';

  @override
  String get weatherAny => 'Mọi thời tiết';

  @override
  String get budgetFree => 'Miễn phí';

  @override
  String get budgetLow => 'Tiết kiệm';

  @override
  String get budgetMedium => 'Tầm trung';

  @override
  String get budgetHigh => 'Cao cấp';

  @override
  String get budgetLuxury => 'Xa xỉ';

  @override
  String get difficultyEasy => 'Dễ';

  @override
  String get difficultyModerate => 'Vừa phải';

  @override
  String get difficultyHard => 'Khó';

  @override
  String get accessibilityLow => 'Hạn chế tiếp cận';

  @override
  String get accessibilityMedium => 'Tiếp cận vừa phải';

  @override
  String get accessibilityHigh => 'Dễ tiếp cận';

  @override
  String get crowdLow => 'Yên tĩnh';

  @override
  String get crowdMedium => 'Vừa phải';

  @override
  String get crowdHigh => 'Đông đúc';

  @override
  String get flagRomantic => 'Lãng mạn';

  @override
  String get flagFamilyFriendly => 'Phù hợp gia đình';

  @override
  String get flagKidFriendly => 'Phù hợp trẻ em';

  @override
  String get flagPetFriendly => 'Cho phép thú cưng';

  @override
  String get flagWheelchairFriendly => 'Thân thiện xe lăn';

  @override
  String get flagPhotographySpot => 'Điểm chụp ảnh';

  @override
  String get flagSunsetSpot => 'Ngắm hoàng hôn';

  @override
  String get flagSunriseSpot => 'Ngắm bình minh';

  @override
  String get flagIndoor => 'Trong nhà';

  @override
  String get flagOutdoor => 'Ngoài trời';

  @override
  String get flagRainyDaySuitable => 'Hợp ngày mưa';

  @override
  String get facilityGroupGeneral => 'Chung';

  @override
  String get facilityGroupWellness => 'Chăm sóc sức khỏe';

  @override
  String get facilityGroupBusiness => 'Công vụ';

  @override
  String get facilityGroupFood => 'Ẩm thực';

  @override
  String get facilityGroupOutdoor => 'Ngoài trời';

  @override
  String get facilityGroupFamily => 'Gia đình';

  @override
  String get facilityGroupAccessibility => 'Tiếp cận';

  @override
  String get hotelPoliciesTitle => 'Chính sách';

  @override
  String get hotelPolicyCancellation => 'Hủy phòng';

  @override
  String get hotelPolicyPayment => 'Thanh toán';

  @override
  String get hotelPolicyChildren => 'Trẻ em';

  @override
  String get hotelPolicyPet => 'Thú cưng';

  @override
  String get hotelPolicySmoking => 'Hút thuốc';

  @override
  String get hotelParkingFree => 'Đỗ xe miễn phí';

  @override
  String get hotelParkingPaid => 'Đỗ xe có phí';

  @override
  String get hotelParkingUnavailable => 'Không có chỗ đỗ xe';

  @override
  String get hotelWifiFree => 'Wi-Fi miễn phí';

  @override
  String get hotelWifiPaid => 'Wi-Fi có phí';

  @override
  String get hotelWifiUnavailable => 'Không có Wi-Fi';

  @override
  String hotelServiceUnavailable(String service) {
    return '$service (không khả dụng)';
  }

  @override
  String get roomSelectAction => 'Chọn phòng này';

  @override
  String roomSelectSemantic(String name) {
    return 'Chọn $name';
  }

  @override
  String get roomSelectedBadge => 'Đã chọn';

  @override
  String roomDetailImageSemantic(String name) {
    return 'Ảnh của $name';
  }

  @override
  String roomCodeLabel(String code) {
    return 'Mã phòng $code';
  }

  @override
  String roomBedConfig(int count, String bed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $bed',
    );
    return '$_temp0';
  }

  @override
  String get roomOccupancyTitle => 'Sức chứa';

  @override
  String roomOccupancyAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người lớn',
    );
    return '$_temp0';
  }

  @override
  String roomOccupancyChildren(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trẻ em',
    );
    return '$_temp0';
  }

  @override
  String get roomPriceTitle => 'Giá';

  @override
  String hotelRoomCardSelectedSemantic(String name) {
    return '$name, đã chọn';
  }

  @override
  String get roomRatePlansTitle => 'Gói giá';

  @override
  String get roomRatePlansLoadingMessage => 'Đang tải gói giá…';

  @override
  String get roomRatePlansErrorMessage =>
      'Không thể tải gói giá. Vui lòng thử lại.';

  @override
  String get roomRatePlansInvalidDatesMessage =>
      'Chọn ngày trả phòng sau ngày nhận phòng để xem gói giá.';

  @override
  String get roomRatePlansEmptyTitle => 'Không có gói giá';

  @override
  String get roomRatePlansEmptyMessage =>
      'Phòng này không có gói giá khả dụng cho kỳ lưu trú đã chọn.';

  @override
  String roomRatePlanSemantic(String name) {
    return 'Gói giá $name';
  }

  @override
  String roomRatePlanSelectedSemantic(String name) {
    return 'Gói giá $name, đã chọn';
  }

  @override
  String get roomRatePlanIneligible => 'Không khả dụng cho kỳ lưu trú đã chọn.';

  @override
  String get ratePlanRefundable => 'Được hoàn tiền';

  @override
  String get ratePlanNonRefundable => 'Không hoàn tiền';

  @override
  String ratePlanFinalNightly(String price) {
    return '$price / đêm';
  }

  @override
  String ratePlanBaseNightly(String price) {
    return 'Giá gốc $price / đêm';
  }

  @override
  String ratePlanStaySubtotal(String price, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights đêm',
    );
    return '$price cho $_temp0';
  }

  @override
  String get bookingCreateAction => 'Tạo đặt phòng';

  @override
  String get bookingCreateSemantic => 'Tạo đặt phòng của bạn';

  @override
  String get bookingCreatingLabel => 'Đang tạo đặt phòng…';

  @override
  String get bookingResultTitle => 'Đặt phòng của bạn';

  @override
  String get bookingResultCodeLabel => 'Mã đặt phòng';

  @override
  String get bookingResultStatusLabel => 'Trạng thái';

  @override
  String get bookingResultDoneAction => 'Xong';

  @override
  String get bookingResultBaseLabel => 'Giá phòng';

  @override
  String get bookingResultPaymentNextNote =>
      'Đặt phòng của bạn đã được tạo và đang ở trạng thái chờ. Hoàn tất thanh toán để xác nhận.';

  @override
  String get bookingPriceChangedNote =>
      'Giá cuối cùng do máy chủ xác nhận khác với báo giá trước đó. Số tiền hiển thị ở trên là số tiền áp dụng cho đặt phòng của bạn.';

  @override
  String get bookingStatusPendingLabel => 'Đang chờ';

  @override
  String get bookingStatusConfirmedLabel => 'Đã xác nhận';

  @override
  String get bookingStatusUnknownLabel => 'Không xác định';

  @override
  String get bookingStatusPendingHeadline => 'Đặt phòng đang chờ';

  @override
  String get bookingStatusPendingBody =>
      'Chúng tôi đã tạo đặt phòng và đang giữ phòng cho bạn. Đặt phòng vẫn ở trạng thái đang chờ cho đến khi thanh toán và cơ sở lưu trú xác nhận — đây chưa phải là kỳ nghỉ đã được xác nhận.';

  @override
  String get bookingStatusConfirmedHeadline => 'Đặt phòng đã xác nhận';

  @override
  String get bookingStatusConfirmedBody =>
      'Đặt phòng của bạn đã được cơ sở lưu trú xác nhận.';

  @override
  String bookingStatusGenericHeadline(String status) {
    return 'Trạng thái đặt phòng: $status';
  }

  @override
  String get bookingSubmitValidationMessage =>
      'Một số thông tin đặt phòng không hợp lệ. Vui lòng kiểm tra lại ngày và số khách rồi thử lại.';

  @override
  String get bookingSubmitForbiddenMessage =>
      'Bạn không có quyền tạo đặt phòng này.';

  @override
  String get bookingSubmitRoomUnavailableMessage =>
      'Phòng hoặc gói giá này không còn khả dụng. Vui lòng quay lại và chọn lại.';

  @override
  String get bookingSubmitConflictMessage =>
      'Phòng này vừa được đặt cho ngày của bạn. Vui lòng quay lại và thử phòng hoặc ngày khác.';

  @override
  String get bookingSubmitUnprocessableMessage =>
      'Không thể đặt phòng này cho ngày đã chọn. Vui lòng quay lại và điều chỉnh kỳ nghỉ.';

  @override
  String get bookingSubmitServerErrorMessage =>
      'Đã xảy ra lỗi khi tạo đặt phòng. Chưa có đặt phòng nào được tạo — vui lòng thử lại.';

  @override
  String get bookingSubmitNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get bookingSubmitUncertainTitle => 'Chưa xác nhận đặt phòng';

  @override
  String get bookingSubmitUncertainBody =>
      'Chúng tôi không thể xác nhận đặt phòng đã được tạo hay chưa. Vui lòng đừng gửi lại — hãy kiểm tra danh sách đặt phòng sau để xem đã thành công chưa.';

  @override
  String get bookingSubmitUncertainAcknowledge =>
      'Tôi hiểu điều này có thể tạo ra một đặt phòng trùng lặp';

  @override
  String get bookingsRealLoadingMessage => 'Đang tải đặt phòng của bạn…';

  @override
  String get bookingsRealErrorMessage =>
      'Không thể tải danh sách đặt phòng. Vui lòng thử lại.';

  @override
  String get bookingDetailLoadingMessage => 'Đang tải chi tiết đặt phòng…';

  @override
  String get bookingDetailErrorMessage =>
      'Không thể tải đặt phòng này. Vui lòng thử lại.';

  @override
  String get bookingDetailSpecialRequestLabel => 'Yêu cầu đặc biệt';

  @override
  String get bookingHistoryUncertainTitle =>
      'Một đặt phòng có thể chưa thành công';

  @override
  String get bookingHistoryUncertainBody =>
      'Đặt phòng gần nhất của bạn chưa được xác nhận. Hãy kiểm tra danh sách bên dưới để xem nó đã được tạo hay chưa trước khi thử lại.';

  @override
  String get bookingHistoryUncertainDismiss => 'Bỏ qua';

  @override
  String get paymentTitle => 'Thanh toán';

  @override
  String get paymentPayNowAction => 'Thanh toán ngay';

  @override
  String get paymentLoadingMessage => 'Đang tải thanh toán…';

  @override
  String get paymentErrorMessage =>
      'Không thể tải thanh toán. Vui lòng thử lại.';

  @override
  String get paymentSandboxNotice =>
      'Chưa có cổng thanh toán trực tiếp nào được kết nối. Thanh toán được tạo thật trên máy chủ và xử lý trong môi trường thử nghiệm — không có thẻ nào bị trừ tiền và không có trang thanh toán bên ngoài nào mở ra.';

  @override
  String get paymentAmountToPayLabel => 'Số tiền cần thanh toán';

  @override
  String get paymentNoneTitle => 'Chưa có thanh toán';

  @override
  String get paymentNoneMessage =>
      'Tạo một khoản thanh toán cho đặt phòng này để tiếp tục.';

  @override
  String get paymentCreateAction => 'Tạo thanh toán';

  @override
  String get paymentCreatingLabel => 'Đang tạo thanh toán…';

  @override
  String get paymentCodeLabel => 'Mã thanh toán';

  @override
  String get paymentMethodLabel => 'Phương thức';

  @override
  String get paymentProcessingLabel => 'Đang xử lý…';

  @override
  String get paymentSuccessHeadline => 'Thanh toán thành công';

  @override
  String get paymentSuccessBody =>
      'Thanh toán đã hoàn tất và đặt phòng của bạn đã được xác nhận.';

  @override
  String get paymentPendingHeadline => 'Thanh toán đang chờ';

  @override
  String get paymentPendingBody =>
      'Khoản thanh toán đã được tạo và đang chờ hoàn tất.';

  @override
  String get paymentFailedHeadline => 'Thanh toán thất bại';

  @override
  String get paymentFailedBody =>
      'Khoản thanh toán này chưa thành công. Bạn có thể tạo một khoản thanh toán mới.';

  @override
  String get paymentCompleteSandboxAction => 'Hoàn tất thanh toán (thử nghiệm)';

  @override
  String get paymentFailSandboxAction =>
      'Mô phỏng thanh toán thất bại (thử nghiệm)';

  @override
  String get paymentRefreshAction => 'Làm mới trạng thái';

  @override
  String get paymentRetryNewAction => 'Bắt đầu thanh toán mới';

  @override
  String get paymentConfirmTitle => 'Hoàn tất thanh toán này?';

  @override
  String get paymentConfirmMessage =>
      'Thao tác này xử lý thanh toán trên máy chủ (thử nghiệm) và xác nhận đặt phòng của bạn. Không có thẻ nào bị trừ tiền.';

  @override
  String get paymentConfirmAction => 'Hoàn tất thanh toán';

  @override
  String get paymentStatusUnknownLabel => 'Không xác định';

  @override
  String get paymentActionValidationMessage =>
      'Yêu cầu thanh toán không hợp lệ. Vui lòng thử lại.';

  @override
  String get paymentActionForbiddenMessage =>
      'Bạn không có quyền thanh toán cho đặt phòng này.';

  @override
  String get paymentActionNotPayableMessage =>
      'Đặt phòng này hiện không thể thanh toán. Có thể nó đã bị hủy, đã thanh toán, hoặc không còn ở trạng thái chờ.';

  @override
  String get paymentActionConflictMessage =>
      'Khoản thanh toán đã thay đổi trên máy chủ. Hãy làm mới và thử lại.';

  @override
  String get paymentActionServerErrorMessage =>
      'Đã xảy ra lỗi với thanh toán. Vui lòng thử lại.';

  @override
  String get paymentActionNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get reviewStatusUnknown => 'Không xác định';

  @override
  String get reviewsListLoadingMessage => 'Đang tải đánh giá…';

  @override
  String get reviewsListErrorMessage =>
      'Không thể tải đánh giá. Vui lòng thử lại.';

  @override
  String get placeReviewsTitle => 'Đánh giá';

  @override
  String get placeReviewsEmptyTitle => 'Chưa có đánh giá';

  @override
  String get placeReviewsEmptyMessage =>
      'Địa điểm này chưa có đánh giá nào được đăng.';

  @override
  String get reviewsMineTitle => 'Đánh giá của tôi';

  @override
  String get reviewsMineEmptyTitle => 'Chưa có đánh giá';

  @override
  String get reviewsMineEmptyMessage =>
      'Đánh giá bạn viết cho các kỳ nghỉ đã hoàn tất sẽ xuất hiện ở đây.';

  @override
  String reviewStarsSemantic(int rating) {
    return '$rating trên 5';
  }

  @override
  String writeReviewRateStarSemantic(int rating) {
    return 'Chấm $rating trên 5';
  }

  @override
  String get reviewPartnerReplyTitle => 'Phản hồi từ cơ sở lưu trú';

  @override
  String get reviewUnknownPlace => 'Địa điểm';

  @override
  String get reviewAnonymousReviewer => 'Khách';

  @override
  String get reviewRatingCleanliness => 'Sạch sẽ';

  @override
  String get reviewRatingService => 'Dịch vụ';

  @override
  String get reviewRatingLocation => 'Vị trí';

  @override
  String get reviewRatingValue => 'Đáng giá';

  @override
  String get reviewRatingFacilities => 'Tiện nghi';

  @override
  String get writeReviewTitle => 'Viết đánh giá';

  @override
  String get writeReviewOverallLabel => 'Đánh giá tổng thể';

  @override
  String get writeReviewSubRatingsTitle => 'Chấm chi tiết (tùy chọn)';

  @override
  String get writeReviewTitleLabel => 'Tiêu đề (tùy chọn)';

  @override
  String get writeReviewContentLabel => 'Nội dung đánh giá (tùy chọn)';

  @override
  String get writeReviewSubmitAction => 'Gửi đánh giá';

  @override
  String get writeReviewSubmittingLabel => 'Đang gửi đánh giá…';

  @override
  String get writeReviewModerationNote =>
      'Đánh giá của bạn được gửi để kiểm duyệt và sẽ hiển thị công khai sau khi được duyệt.';

  @override
  String get writeReviewPendingHeadline => 'Đã gửi đánh giá';

  @override
  String get writeReviewPendingBody =>
      'Cảm ơn bạn! Đánh giá của bạn đang chờ kiểm duyệt và sẽ được đăng sau khi được duyệt.';

  @override
  String get writeReviewOverallRequiredHint =>
      'Chạm vào ngôi sao để đặt đánh giá tổng thể của bạn.';

  @override
  String get bookingDetailSeeReviewsAction => 'Xem đánh giá khách sạn';

  @override
  String get reviewSubmitValidationMessage =>
      'Vui lòng kiểm tra lại đánh giá và thử lại.';

  @override
  String get reviewSubmitForbiddenMessage =>
      'Bạn chỉ có thể đánh giá đặt phòng của chính mình.';

  @override
  String get reviewSubmitAlreadyMessage => 'Bạn đã đánh giá đặt phòng này rồi.';

  @override
  String get reviewSubmitNotCompletedMessage =>
      'Bạn chỉ có thể đánh giá kỳ nghỉ sau khi nó đã hoàn tất.';

  @override
  String get reviewSubmitServerErrorMessage =>
      'Đã xảy ra lỗi khi gửi đánh giá. Vui lòng thử lại.';

  @override
  String get reviewSubmitNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get notificationsRealLoadingMessage => 'Đang tải thông báo…';

  @override
  String get notificationsRealErrorMessage =>
      'Không thể tải thông báo của bạn. Vui lòng thử lại.';

  @override
  String get notificationsRealSubtitle =>
      'Cập nhật từ đặt phòng, thanh toán và đánh giá của bạn.';

  @override
  String get notificationActionForbiddenMessage =>
      'Bạn không có quyền thay đổi thông báo này.';

  @override
  String get notificationActionServerErrorMessage =>
      'Đã xảy ra lỗi khi cập nhật thông báo của bạn. Vui lòng thử lại.';

  @override
  String get notificationActionNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get recentlyViewedTitle => 'Đã xem gần đây';

  @override
  String get recentlyViewedLoadingMessage => 'Đang tải mục đã xem gần đây…';

  @override
  String get recentlyViewedErrorMessage =>
      'Không thể tải các địa điểm đã xem gần đây. Vui lòng thử lại.';

  @override
  String get recentlyViewedEmptyTitle => 'Chưa có gì ở đây';

  @override
  String get recentlyViewedEmptyMessage =>
      'Các địa điểm bạn xem sẽ xuất hiện ở đây.';

  @override
  String get recentlyViewedUnknownPlace => 'Địa điểm';

  @override
  String recentlyViewedCardSemantic(String name) {
    return 'Mở $name';
  }

  @override
  String recentlyViewedRatingSemantic(String rating, int count) {
    return 'Đánh giá $rating từ $count nhận xét';
  }

  @override
  String recentlyViewedRemoveSemantic(String name) {
    return 'Xóa $name khỏi mục đã xem gần đây';
  }

  @override
  String get recentlyViewedClearSemantic => 'Xóa mục đã xem gần đây';

  @override
  String get recentlyViewedClearConfirmTitle => 'Xóa mục đã xem gần đây?';

  @override
  String get recentlyViewedClearConfirmMessage =>
      'Thao tác này sẽ xóa mọi địa điểm khỏi danh sách đã xem gần đây của bạn.';

  @override
  String get recentlyViewedClearConfirmAction => 'Xóa tất cả';

  @override
  String get recentlyViewedRemoveConfirmTitle => 'Xóa khỏi mục đã xem gần đây?';

  @override
  String recentlyViewedRemoveConfirmMessage(String name) {
    return 'Xóa $name khỏi danh sách đã xem gần đây của bạn?';
  }

  @override
  String get recentlyViewedRemoveConfirmAction => 'Xóa';

  @override
  String get recentlyViewedClearedMessage => 'Đã xóa mục đã xem gần đây.';

  @override
  String get recentlyViewedRemovedMessage => 'Đã xóa khỏi mục đã xem gần đây.';

  @override
  String get recentlyViewedOpenErrorMessage =>
      'Không thể mở địa điểm này. Vui lòng thử lại.';

  @override
  String get recentlyViewedGoneMessage => 'Địa điểm này không còn khả dụng.';

  @override
  String get recentlyViewedForbiddenMessage =>
      'Bạn không có quyền thực hiện điều đó.';

  @override
  String get recentlyViewedActionErrorMessage =>
      'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get recentlyViewedNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get profileEditTitle => 'Hồ sơ & tùy chọn';

  @override
  String get profileEditLoadingMessage => 'Đang tải hồ sơ của bạn…';

  @override
  String get profileEditErrorMessage =>
      'Không thể tải hồ sơ. Vui lòng thử lại.';

  @override
  String get profileEditMissingMessage => 'Hồ sơ của bạn không khả dụng.';

  @override
  String get profileEditSaveAction => 'Lưu thay đổi';

  @override
  String get profileEditSavedMessage => 'Đã cập nhật hồ sơ.';

  @override
  String get profileEditSaveErrorMessage =>
      'Không thể lưu thay đổi. Vui lòng thử lại.';

  @override
  String get profileEditForbiddenMessage =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get profileEditNetworkMessage =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get profileEditIdentitySection => 'Tài khoản';

  @override
  String get profileEditPreferencesSection => 'Tùy chọn du lịch';

  @override
  String get profileEditContactSection => 'Liên hệ & giấy tờ';

  @override
  String get profileFieldAvatar => 'Liên kết ảnh đại diện';

  @override
  String get profileFieldLanguage => 'Ngôn ngữ ưu tiên';

  @override
  String get profileFieldCurrency => 'Tiền tệ ưu tiên';

  @override
  String get profileFieldPaymentMethod => 'Phương thức thanh toán ưu tiên';

  @override
  String get profileFieldNationality => 'Quốc tịch';

  @override
  String get profileFieldEmergencyName => 'Tên người liên hệ khẩn cấp';

  @override
  String get profileFieldEmergencyPhone => 'Số điện thoại liên hệ khẩn cấp';

  @override
  String get profileFieldAccessibility => 'Nhu cầu hỗ trợ tiếp cận';

  @override
  String get profileFieldDietaryPreference => 'Chế độ ăn uống';

  @override
  String get profileFieldTravelStyle => 'Phong cách du lịch';

  @override
  String get profileEditPassportLabel => 'Số hộ chiếu';

  @override
  String profileEditPassportWarning(String masked) {
    return 'Đang lưu: $masked. Nhập lại để giữ nguyên — để trống sẽ xóa hộ chiếu đã lưu khi bạn lưu.';
  }

  @override
  String get profileEditPassportHint => 'Không bắt buộc. Được che khi đã lưu.';

  @override
  String get profileEditMarketingLabel => 'Nhận thông tin tiếp thị';

  @override
  String get profileEditOptionalHint => 'Không bắt buộc';

  @override
  String profileCompletionSemantic(int percent) {
    return 'Hồ sơ hoàn thành $percent%';
  }

  @override
  String profileRoleSemantic(String role) {
    return 'Vai trò tài khoản: $role';
  }

  @override
  String get profileEditEmptyPreferences =>
      'Thêm tùy chọn du lịch để cá nhân hóa chuyến đi của bạn.';

  @override
  String get giftCardsRealClaimTitle => 'Đổi thẻ quà tặng';

  @override
  String get giftCardsRealClaimHelper =>
      'Nhập mã thẻ quà tặng bạn nhận được để thêm vào tài khoản.';

  @override
  String get giftCardsRealClaimSuccess => 'Đã đổi thẻ quà tặng.';

  @override
  String get giftCardsRealLoadingMessage => 'Đang tải thẻ quà tặng của bạn…';

  @override
  String get giftCardsRealErrorMessage =>
      'Không thể tải thẻ quà tặng. Vui lòng thử lại.';

  @override
  String get giftCardsRealEmptyMessage =>
      'Thẻ quà tặng bạn mua hoặc nhận sẽ hiển thị ở đây.';

  @override
  String get giftCardsRealLoadMore => 'Tải thêm';

  @override
  String get giftCardsRealActivateAction => 'Kích hoạt thẻ quà tặng';

  @override
  String get giftCardsRealActivateSuccess => 'Đã kích hoạt thẻ quà tặng.';

  @override
  String get giftCardsRealActionError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get giftCardsRealNotFound => 'Không tìm thấy thẻ quà tặng đó.';

  @override
  String get giftCardsRealConflict =>
      'Không thể sử dụng thẻ quà tặng này ở trạng thái hiện tại.';

  @override
  String get giftCardsRealNetwork =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get giftCardsRealValidation =>
      'Vui lòng kiểm tra mã thẻ quà tặng và thử lại.';

  @override
  String get giftCardStatusUnknown => 'Không xác định';

  @override
  String giftCardsRealBalanceSemantic(String balance) {
    return 'Số dư hiện tại $balance';
  }

  @override
  String get loyaltyRealLoadingMessage => 'Đang tải điểm thưởng của bạn…';

  @override
  String get loyaltyRealErrorMessage =>
      'Không thể tải điểm thưởng. Vui lòng thử lại.';

  @override
  String get loyaltyRealLoadMore => 'Tải thêm';

  @override
  String get loyaltyRealEarnNote =>
      'Điểm được tích lũy tự động từ các đặt phòng và đánh giá đã hoàn tất. Không thể quy đổi trực tiếp tại đây.';

  @override
  String get travelCreditRealLoadingMessage =>
      'Đang tải tín dụng du lịch của bạn…';

  @override
  String get travelCreditRealErrorMessage =>
      'Không thể tải tín dụng du lịch. Vui lòng thử lại.';

  @override
  String get travelCreditRealLoadMore => 'Tải thêm';

  @override
  String get membershipRealLoadingMessage =>
      'Đang tải hạng thành viên của bạn…';

  @override
  String get membershipRealErrorMessage =>
      'Không thể tải hạng thành viên. Vui lòng thử lại.';

  @override
  String get membershipRealActiveMessage =>
      'Hạng thành viên của bạn đang hoạt động.';

  @override
  String get membershipRealPreviewMessage =>
      'Đây là bản xem trước hạng bạn đủ điều kiện. Đăng ký để kích hoạt.';

  @override
  String get membershipRealEnrollAction => 'Đăng ký ngay';

  @override
  String get membershipRealEnrolledAction => 'Đã đăng ký';

  @override
  String get membershipRealEnrollSemantic => 'Đăng ký hạng thành viên';

  @override
  String get membershipRealEnrollSuccess => 'Bạn đã đăng ký hạng thành viên.';

  @override
  String get membershipRealEnrollError =>
      'Không thể đăng ký. Vui lòng thử lại.';

  @override
  String get membershipRealEnrollNeedsLoyalty =>
      'Cần có tài khoản điểm thưởng đang hoạt động để đăng ký hạng thành viên.';

  @override
  String get membershipRealNoBenefits => 'Chưa có quyền lợi nào cho hạng này.';

  @override
  String membershipRealPointsToNext(int points) {
    return 'Cần thêm $points điểm để lên hạng tiếp theo';
  }

  @override
  String membershipRealBookingsToNext(int bookings) {
    return 'Cần thêm $bookings lượt đặt hoàn tất để lên hạng tiếp theo';
  }

  @override
  String get referralRealLoadingMessage => 'Đang tải thông tin giới thiệu…';

  @override
  String get referralRealErrorMessage =>
      'Không thể tải thông tin giới thiệu. Vui lòng thử lại.';

  @override
  String get referralRealUseHelper =>
      'Nhập mã giới thiệu của bạn bè. Phần thưởng được trao sau một lượt đặt đủ điều kiện.';

  @override
  String get referralRealUseSuccess =>
      'Đã áp dụng mã giới thiệu. Phần thưởng được trao sau một lượt đặt đủ điều kiện.';

  @override
  String get referralRealUseError =>
      'Không thể áp dụng mã đó. Vui lòng thử lại.';

  @override
  String get referralRealAlreadyUsed =>
      'Bạn đã sử dụng một mã giới thiệu và không thể dùng thêm.';

  @override
  String get referralRealCodeNotFound => 'Không tìm thấy mã giới thiệu đó.';

  @override
  String get referralRealNoHistory =>
      'Chưa có hoạt động giới thiệu. Chia sẻ mã của bạn để bắt đầu.';

  @override
  String get couponsRealLoadingMessage => 'Đang tải phiếu giảm giá của bạn…';

  @override
  String get couponsRealErrorMessage =>
      'Không thể tải phiếu giảm giá. Vui lòng thử lại.';

  @override
  String get couponsRealClaimHelper =>
      'Nhập mã phiếu giảm giá để thêm vào tài khoản của bạn.';

  @override
  String get couponsRealClaimSuccess => 'Đã nhận phiếu giảm giá.';

  @override
  String get couponsRealClaimError =>
      'Không thể nhận phiếu giảm giá đó. Vui lòng thử lại.';

  @override
  String get couponsRealNotFound => 'Không tìm thấy mã phiếu giảm giá đó.';

  @override
  String get couponsRealInvalidCode =>
      'Phiếu giảm giá đã ngừng hoạt động, hết hạn hoặc chưa có hiệu lực.';

  @override
  String get couponsRealLimitReached =>
      'Bạn đã đạt giới hạn sử dụng cho phiếu giảm giá này.';

  @override
  String get couponStatusAvailable => 'Có thể dùng';

  @override
  String get couponStatusUsed => 'Đã dùng';

  @override
  String get couponStatusExpired => 'Hết hạn';

  @override
  String get couponStatusRevoked => 'Đã thu hồi';

  @override
  String get couponStatusUnknown => 'Không xác định';

  @override
  String couponDetailMinimumSpend(String amount) {
    return 'Chi tiêu tối thiểu $amount';
  }

  @override
  String couponDetailValidUntil(String date) {
    return 'Có hiệu lực đến $date';
  }

  @override
  String couponDetailUsagePerUser(int count) {
    return 'Tối đa $count lượt dùng mỗi khách hàng';
  }

  @override
  String get recommendationsTitle => 'Gợi ý cho bạn';

  @override
  String get recommendationsLoadingMessage => 'Đang tải gợi ý của bạn…';

  @override
  String get recommendationsErrorMessage =>
      'Không thể tải gợi ý của bạn. Vui lòng thử lại.';

  @override
  String get recommendationsEmptyTitle => 'Chưa có gợi ý nào';

  @override
  String get recommendationsEmptyMessage =>
      'Hãy lưu địa điểm, xem khách sạn và đặt chuyến đi — sau đó tạo lại để nhận gợi ý dành riêng cho bạn.';

  @override
  String get recommendationsGenerateSemantic => 'Tạo lại gợi ý';

  @override
  String get recommendationsGeneratedMessage =>
      'Gợi ý của bạn đã được cập nhật.';

  @override
  String get recommendationsGenerateErrorMessage =>
      'Không thể làm mới gợi ý của bạn. Vui lòng thử lại.';

  @override
  String get recommendationsLoadMore => 'Tải thêm';

  @override
  String get recommendationsDismissedMessage => 'Đã bỏ qua gợi ý.';

  @override
  String get recommendationsActionErrorMessage =>
      'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get recommendationsNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get recommendationsGoneMessage => 'Gợi ý này không còn khả dụng.';

  @override
  String get recommendationUntitled => 'Gợi ý';

  @override
  String recommendationsDismissSemantic(String name) {
    return 'Bỏ qua $name';
  }

  @override
  String recommendationCardSemantic(String name) {
    return 'Gợi ý: $name';
  }

  @override
  String recommendationScoreSemantic(int score) {
    return 'Điểm phù hợp $score trên 100';
  }

  @override
  String get recommendationTypePlace => 'Địa điểm';

  @override
  String get recommendationTypeHotel => 'Khách sạn';

  @override
  String get recommendationTypeRoom => 'Phòng';

  @override
  String get recommendationTypePromotion => 'Khuyến mãi';

  @override
  String get recommendationTypeCoupon => 'Mã giảm giá';

  @override
  String get recommendationTypeTripIdea => 'Ý tưởng chuyến đi';

  @override
  String get recommendationTypeOther => 'Đề xuất';

  @override
  String get recommendationStateClicked => 'Đã xem';

  @override
  String get recommendationStateConverted => 'Đã đặt';

  @override
  String get recommendationDetailReason => 'Vì sao chúng tôi chọn mục này';

  @override
  String recommendationDetailGenerated(String date) {
    return 'Gợi ý ngày $date';
  }

  @override
  String recommendationDetailExpires(String date) {
    return 'Khả dụng đến $date';
  }

  @override
  String get expensesTitle => 'Chi phí';

  @override
  String get expensesLoadingMessage => 'Đang tải chi phí…';

  @override
  String get expensesErrorMessage =>
      'Không thể tải chi phí của chuyến đi này. Vui lòng thử lại.';

  @override
  String get expensesGoneMessage =>
      'Chuyến đi hoặc khoản chi này không còn khả dụng.';

  @override
  String get expensesForbiddenMessage =>
      'Bạn không có quyền quản lý chi phí cho chuyến đi này.';

  @override
  String get expensesInvalidMessage =>
      'Vui lòng kiểm tra số tiền, đơn vị tiền tệ, tiêu đề và ngày.';

  @override
  String get expensesNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get expensesActionErrorMessage => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get expensesEmptyTitle => 'Chưa có chi phí nào';

  @override
  String get expensesEmptyMessage =>
      'Theo dõi những gì bạn chi cho chuyến đi này — thêm khoản chi đầu tiên.';

  @override
  String get expensesAddAction => 'Thêm chi phí';

  @override
  String get expensesSaveAction => 'Lưu thay đổi';

  @override
  String get expensesAddTitle => 'Thêm chi phí';

  @override
  String get expensesEditTitle => 'Sửa chi phí';

  @override
  String get expensesAddSemantic => 'Thêm một khoản chi';

  @override
  String get expensesCreatedMessage => 'Đã thêm chi phí.';

  @override
  String get expensesUpdatedMessage => 'Đã cập nhật chi phí.';

  @override
  String get expensesDeletedMessage => 'Đã xóa chi phí.';

  @override
  String get expensesDeleteConfirmTitle => 'Xóa chi phí?';

  @override
  String get expensesDeleteConfirmAction => 'Xóa';

  @override
  String get expensesSummarySpent => 'Tổng chi';

  @override
  String get expensesSummaryOverBudget => 'Vượt ngân sách';

  @override
  String get expenseUntitled => 'Chi phí';

  @override
  String get expenseFieldTitle => 'Tiêu đề';

  @override
  String get expenseFieldAmount => 'Số tiền';

  @override
  String get expenseFieldCurrency => 'Tiền tệ';

  @override
  String get expenseFieldCategory => 'Danh mục';

  @override
  String get expenseFieldDate => 'Ngày';

  @override
  String get expenseFieldNotes => 'Ghi chú (tùy chọn)';

  @override
  String expensesDeleteConfirmMessage(String title) {
    return 'Xóa \"$title\"? Không thể hoàn tác.';
  }

  @override
  String expensesDeleteSemantic(String title) {
    return 'Xóa $title';
  }

  @override
  String expenseCardSemantic(String title) {
    return 'Chi phí: $title';
  }

  @override
  String expensesSummaryBudget(String amount) {
    return 'Ngân sách $amount';
  }

  @override
  String expensesSummaryRemaining(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String get conversationsTitle => 'Tin nhắn';

  @override
  String get conversationsLoadingMessage => 'Đang tải tin nhắn của bạn…';

  @override
  String get conversationsErrorMessage =>
      'Không thể tải tin nhắn của bạn. Vui lòng thử lại.';

  @override
  String get conversationsEmptyTitle => 'Chưa có tin nhắn nào';

  @override
  String get conversationsEmptyMessage =>
      'Mở một đặt phòng và chạm biểu tượng tin nhắn để trò chuyện với chủ nhà.';

  @override
  String get conversationStatusOpen => 'Đang mở';

  @override
  String get conversationStatusClosed => 'Đã đóng';

  @override
  String get conversationStatusArchived => 'Đã lưu trữ';

  @override
  String get conversationUntitled => 'Cuộc trò chuyện';

  @override
  String get conversationLoadingMessage => 'Đang tải cuộc trò chuyện…';

  @override
  String get conversationErrorMessage =>
      'Không thể tải cuộc trò chuyện này. Vui lòng thử lại.';

  @override
  String get conversationForbiddenMessage =>
      'Cuộc trò chuyện này không khả dụng với bạn.';

  @override
  String get conversationGoneMessage =>
      'Cuộc trò chuyện này không còn khả dụng.';

  @override
  String get conversationArchivedMessage =>
      'Cuộc trò chuyện này đã được lưu trữ và không thể nhận tin nhắn mới.';

  @override
  String get conversationEmptyBodyMessage => 'Nhập một tin nhắn để gửi.';

  @override
  String get conversationNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get conversationActionErrorMessage =>
      'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get conversationNoPartnerMessage =>
      'Chủ nhà của đặt phòng này chưa thể nhận tin nhắn.';

  @override
  String get conversationCloseConfirmTitle => 'Đóng cuộc trò chuyện?';

  @override
  String get conversationCloseConfirmMessage =>
      'Bạn có thể mở lại sau bằng cách gửi một tin nhắn mới.';

  @override
  String get conversationCloseAction => 'Đóng';

  @override
  String get conversationClosedMessage => 'Đã đóng cuộc trò chuyện.';

  @override
  String get conversationArchivedNote => 'Cuộc trò chuyện này đã được lưu trữ.';

  @override
  String get conversationNoMessagesTitle => 'Chưa có tin nhắn nào';

  @override
  String get conversationNoMessagesMessage =>
      'Chào một câu để bắt đầu cuộc trò chuyện.';

  @override
  String get conversationSenderYou => 'Bạn';

  @override
  String get conversationSenderHost => 'Chủ nhà';

  @override
  String get conversationSenderSupport => 'Hỗ trợ';

  @override
  String get conversationSenderSystem => 'Hệ thống';

  @override
  String get conversationSeen => 'Đã xem';

  @override
  String get conversationComposerHint => 'Viết một tin nhắn…';

  @override
  String get conversationSendSemantic => 'Gửi tin nhắn';

  @override
  String get conversationMessageHostAction => 'Nhắn cho chủ nhà';

  @override
  String conversationBookingLabel(String code) {
    return 'Đặt phòng $code';
  }

  @override
  String conversationUnreadBadge(int count) {
    return '$count chưa đọc';
  }

  @override
  String conversationTileSemantic(String title, int count) {
    return 'Cuộc trò chuyện $title, $count chưa đọc';
  }

  @override
  String conversationMessageSemantic(String sender, String body) {
    return '$sender đã nói: $body';
  }

  @override
  String get aiContextTitle => 'Bối cảnh chuyến đi AI';

  @override
  String get aiContextLoadingMessage => 'Đang tải bối cảnh chuyến đi của bạn…';

  @override
  String get aiContextErrorMessage =>
      'Không thể tải bối cảnh chuyến đi của bạn. Vui lòng thử lại.';

  @override
  String get aiContextExplainer =>
      'Ảnh chụp chỉ đọc dữ liệu du lịch của bạn mà một trợ lý AI sẽ sử dụng. Không có tin nhắn nào được tạo ở đây.';

  @override
  String get aiContextActivityTitle => 'Hoạt động của bạn';

  @override
  String get aiContextCurrentTripTitle => 'Chuyến đi hiện tại';

  @override
  String get aiContextBudgetTitle => 'Ngân sách chuyến đi hiện tại';

  @override
  String get aiContextUpcomingTripsTitle => 'Chuyến đi sắp tới';

  @override
  String get aiContextUntitledTrip => 'Chuyến đi chưa đặt tên';

  @override
  String get aiContextOverBudget => 'Vượt ngân sách';

  @override
  String get aiContextStatTrips => 'Chuyến đi';

  @override
  String get aiContextStatActiveTrips => 'Đang diễn ra';

  @override
  String get aiContextStatUpcomingTrips => 'Sắp tới';

  @override
  String get aiContextStatCompletedTrips => 'Đã hoàn thành';

  @override
  String get aiContextStatPlannedDays => 'Ngày đã lên kế hoạch';

  @override
  String get aiContextStatBookings => 'Đặt chỗ';

  @override
  String get aiContextStatCollections => 'Bộ sưu tập';

  @override
  String get aiContextStatWishlist => 'Yêu thích';

  @override
  String get aiContextStatReviews => 'Đánh giá';

  @override
  String get aiContextStatRecommendations => 'Gợi ý';

  @override
  String aiContextGeneratedAt(String date) {
    return 'Ảnh chụp lúc $date';
  }

  @override
  String aiContextTripDays(int count) {
    return '$count ngày';
  }

  @override
  String aiContextStatSemantic(String label, int value) {
    return '$label: $value';
  }

  @override
  String aiContextSpent(String amount) {
    return 'Đã chi $amount';
  }

  @override
  String aiContextBudget(String amount) {
    return 'Ngân sách $amount';
  }

  @override
  String aiContextRemaining(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String get documentsRealLoadingMessage => 'Đang tải tài liệu…';

  @override
  String get documentsRealErrorMessage =>
      'Không thể tải tài liệu của chuyến đi này. Vui lòng thử lại.';

  @override
  String get documentsRealForbiddenMessage =>
      'Bạn không có quyền quản lý tài liệu cho chuyến đi này.';

  @override
  String get documentsRealGoneMessage =>
      'Chuyến đi hoặc tài liệu này không còn khả dụng.';

  @override
  String get documentsRealNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get documentsRealActionErrorMessage =>
      'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get documentsRealCreatedMessage => 'Đã đính kèm tài liệu.';

  @override
  String get documentsRealUpdatedMessage => 'Đã cập nhật tài liệu.';

  @override
  String get documentsRealPinnedMessage => 'Đã ghim tài liệu.';

  @override
  String get documentsRealUnpinnedMessage => 'Đã bỏ ghim tài liệu.';

  @override
  String get documentsRealUrlRequiredMessage => 'Nhập liên kết đến tài liệu.';

  @override
  String get documentsRealAddSemantic => 'Đính kèm tài liệu';

  @override
  String get documentsRealTypeUnknown => 'Tài liệu';

  @override
  String get notesRealTitle => 'Ghi chú';

  @override
  String get notesRealLoadingMessage => 'Đang tải ghi chú…';

  @override
  String get notesRealErrorMessage =>
      'Không thể tải ghi chú của chuyến đi này. Vui lòng thử lại.';

  @override
  String get notesRealForbiddenMessage =>
      'Bạn không có quyền quản lý ghi chú cho chuyến đi này.';

  @override
  String get notesRealGoneMessage =>
      'Chuyến đi hoặc ghi chú này không còn khả dụng.';

  @override
  String get notesRealNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get notesRealActionErrorMessage => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get notesRealCreatedMessage => 'Đã thêm ghi chú.';

  @override
  String get notesRealUpdatedMessage => 'Đã cập nhật ghi chú.';

  @override
  String get notesRealDeletedMessage => 'Đã xóa ghi chú.';

  @override
  String get notesRealPinnedMessage => 'Đã ghim ghi chú.';

  @override
  String get notesRealUnpinnedMessage => 'Đã bỏ ghim ghi chú.';

  @override
  String get notesRealContentRequiredMessage =>
      'Nhập nội dung cho ghi chú này.';

  @override
  String get notesRealAddSemantic => 'Thêm ghi chú';

  @override
  String get notesRealMoodNone => 'Không có tâm trạng';

  @override
  String get notesRealCreateTitle => 'Ghi chú mới';

  @override
  String get notesRealEditTitle => 'Sửa ghi chú';

  @override
  String get packingRealTitle => 'Hành lý';

  @override
  String get packingRealLoadingMessage => 'Đang tải danh sách hành lý…';

  @override
  String get packingRealErrorMessage =>
      'Không thể tải danh sách hành lý của chuyến đi này. Vui lòng thử lại.';

  @override
  String get packingRealForbiddenMessage =>
      'Bạn không có quyền quản lý danh sách hành lý cho chuyến đi này.';

  @override
  String get packingRealGoneMessage =>
      'Chuyến đi hoặc mục hành lý này không còn khả dụng.';

  @override
  String get packingRealNetworkMessage =>
      'Bạn dường như đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get packingRealActionErrorMessage =>
      'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get packingRealCreatedMessage => 'Đã thêm mục hành lý.';

  @override
  String get packingRealUpdatedMessage => 'Đã cập nhật mục hành lý.';

  @override
  String get packingRealDeletedMessage => 'Đã xóa mục hành lý.';

  @override
  String get packingRealLabelRequiredMessage => 'Nhập tên cho mục này.';

  @override
  String get packingRealQuantityInvalidMessage => 'Số lượng phải từ 1 trở lên.';

  @override
  String get packingRealAddSemantic => 'Thêm mục hành lý';

  @override
  String get packingRealCreateTitle => 'Mục hành lý mới';

  @override
  String get packingRealEditTitle => 'Sửa mục hành lý';

  @override
  String get packingRealEmptyTitle => 'Chưa có gì để đóng gói';

  @override
  String get packingRealEmptyMessage =>
      'Thêm những thứ bạn cần mang theo trong chuyến đi này.';

  @override
  String packingRealDeleteConfirmMessage(String label) {
    return 'Xóa $label khỏi danh sách này?';
  }

  @override
  String packingRealCheckSemantic(String label) {
    return 'Đánh dấu $label đã đóng gói';
  }

  @override
  String packingRealUncheckSemantic(String label) {
    return 'Đánh dấu $label chưa đóng gói';
  }

  @override
  String get remindersRealTitle => 'Nhắc nhở chuyến đi';

  @override
  String get remindersRealLoadingMessage => 'Đang tải nhắc nhở…';

  @override
  String get remindersRealErrorMessage =>
      'Không thể tải các nhắc nhở này. Kéo để làm mới hoặc thử lại.';

  @override
  String get remindersRealForbiddenMessage =>
      'Bạn có thể xem các nhắc nhở này nhưng chỉ chủ chuyến đi hoặc người chỉnh sửa mới có thể thay đổi.';

  @override
  String get remindersRealGoneMessage =>
      'Nhắc nhở hoặc chuyến đi này không còn khả dụng.';

  @override
  String get remindersRealNetworkMessage =>
      'Không có kết nối. Hãy kiểm tra mạng và thử lại.';

  @override
  String get remindersRealActionErrorMessage =>
      'Không thành công. Vui lòng thử lại.';

  @override
  String get remindersRealCreatedMessage => 'Đã thêm nhắc nhở.';

  @override
  String get remindersRealUpdatedMessage => 'Đã cập nhật nhắc nhở.';

  @override
  String get remindersRealCompletedMessage =>
      'Đã đánh dấu nhắc nhở hoàn thành.';

  @override
  String get remindersRealCancelledMessage => 'Đã hủy nhắc nhở.';

  @override
  String get remindersRealDeletedMessage => 'Đã xóa nhắc nhở.';

  @override
  String get remindersRealTitleRequiredMessage => 'Hãy nhập tiêu đề nhắc nhở.';

  @override
  String get remindersRealAddSemantic => 'Thêm nhắc nhở';

  @override
  String get remindersRealCreateTitle => 'Nhắc nhở mới';

  @override
  String get remindersRealEditTitle => 'Sửa nhắc nhở';

  @override
  String get remindersRealEmptyTitle => 'Chưa có nhắc nhở';

  @override
  String get remindersRealEmptyMessage =>
      'Thêm nhắc nhở để theo dõi việc nhận phòng, chuyến bay, thanh toán và đóng gói cho chuyến đi này.';

  @override
  String remindersRealDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi chuyến đi này?';
  }

  @override
  String remindersRealCompleteSemantic(String title) {
    return 'Đánh dấu $title hoàn thành';
  }

  @override
  String remindersRealCancelSemantic(String title) {
    return 'Hủy $title';
  }

  @override
  String get budgetRealTitle => 'Ngân sách chuyến đi';

  @override
  String get budgetRealLoadingMessage => 'Đang tải ngân sách…';

  @override
  String get budgetRealErrorMessage =>
      'Không thể tải ngân sách này. Kéo để làm mới hoặc thử lại.';

  @override
  String get budgetRealForbiddenMessage =>
      'Chỉ chủ chuyến đi mới có thể đặt hoặc thay đổi ngân sách.';

  @override
  String get budgetRealGoneMessage => 'Chuyến đi này không còn khả dụng.';

  @override
  String get budgetRealNetworkMessage =>
      'Không có kết nối. Hãy kiểm tra mạng và thử lại.';

  @override
  String get budgetRealActionErrorMessage =>
      'Không thành công. Vui lòng thử lại.';

  @override
  String get budgetRealSavedMessage => 'Đã lưu ngân sách.';

  @override
  String get budgetRealDeletedMessage => 'Đã xóa ngân sách.';

  @override
  String get budgetRealAmountInvalidMessage =>
      'Hãy nhập số tiền ngân sách từ 0 trở lên.';

  @override
  String get budgetRealCurrencyRequiredMessage => 'Hãy nhập loại tiền tệ.';

  @override
  String get budgetRealEmptyTitle => 'Chưa đặt ngân sách';

  @override
  String get budgetRealEmptyMessage =>
      'Đặt tổng ngân sách để theo dõi chi tiêu cho chuyến đi này.';

  @override
  String get budgetRealSetTitle => 'Đặt ngân sách chuyến đi';

  @override
  String get budgetRealEditTitle => 'Sửa ngân sách chuyến đi';

  @override
  String get budgetRealSaveAction => 'Lưu ngân sách';

  @override
  String get budgetRealEditAction => 'Sửa';

  @override
  String get budgetRealDeleteAction => 'Xóa ngân sách';

  @override
  String get budgetRealDeleteConfirmTitle => 'Xóa ngân sách?';

  @override
  String get budgetRealDeleteConfirmMessage =>
      'Xóa tổng ngân sách của chuyến đi này? Các khoản chi vẫn được giữ nguyên.';

  @override
  String get collaborationRealTitle => 'Cộng tác';

  @override
  String get collaborationRealLoadingMessage => 'Đang tải cộng tác viên…';

  @override
  String get collaborationRealErrorMessage =>
      'Không thể tải cộng tác viên. Kéo để làm mới hoặc thử lại.';

  @override
  String get collaborationRealForbiddenMessage =>
      'Chỉ chủ chuyến đi mới có thể quản lý cộng tác viên.';

  @override
  String get collaborationRealGoneMessage =>
      'Chuyến đi này không còn khả dụng.';

  @override
  String get collaborationRealNetworkMessage =>
      'Không có kết nối. Hãy kiểm tra mạng và thử lại.';

  @override
  String get collaborationRealActionErrorMessage =>
      'Không thành công. Vui lòng thử lại.';

  @override
  String get collaborationRealInvitedMessage => 'Đã mời cộng tác viên.';

  @override
  String get collaborationRealRoleUpdatedMessage => 'Đã cập nhật vai trò.';

  @override
  String get collaborationRealRemovedMessage => 'Đã xóa cộng tác viên.';

  @override
  String get collaborationRealPublicOnMessage =>
      'Chuyến đi này hiện đang công khai.';

  @override
  String get collaborationRealPublicOffMessage =>
      'Chuyến đi này ở chế độ riêng tư.';

  @override
  String get collaborationRealInvalidMessage =>
      'Hãy nhập email cộng tác viên hợp lệ và không phải của bạn.';

  @override
  String get collaborationRealUserNotFoundMessage =>
      'Không có người dùng đã đăng ký nào với email đó.';

  @override
  String get collaborationRealAlreadyMemberMessage =>
      'Người dùng này đã là cộng tác viên.';

  @override
  String get collaborationRealEmptyTitle => 'Chưa có cộng tác viên';

  @override
  String get collaborationRealEmptyMessage =>
      'Mời ai đó qua email để cùng xem hoặc chỉnh sửa chuyến đi này.';

  @override
  String get collaborationRealEmailLabel => 'Email cộng tác viên';

  @override
  String get collaborationRealRoleLabel => 'Vai trò';

  @override
  String get collaborationRealEditRoleTitle => 'Đổi vai trò';

  @override
  String get collaborationRealOwnerBadge => 'Bạn là chủ chuyến đi này';

  @override
  String get collaborationRealPublicLabel => 'Hiển thị công khai';

  @override
  String get collaborationRealAddSemantic => 'Mời cộng tác viên';

  @override
  String collaborationRealRemoveConfirmMessage(String name) {
    return 'Xóa $name khỏi chuyến đi này? Họ sẽ mất quyền truy cập ngay lập tức.';
  }

  @override
  String get sharedTripsRealLoadingMessage =>
      'Đang tải chuyến đi được chia sẻ…';

  @override
  String get sharedTripsRealErrorMessage =>
      'Không thể tải các chuyến đi được chia sẻ. Kéo để làm mới hoặc thử lại.';

  @override
  String get sharedTripsRealForbiddenMessage =>
      'Bạn không có quyền truy cập các chuyến đi được chia sẻ này.';

  @override
  String get sharedTripsRealGoneMessage =>
      'Các chuyến đi được chia sẻ này không còn khả dụng.';

  @override
  String get sharedTripsRealEmptyTitle => 'Chưa có chuyến đi được chia sẻ';

  @override
  String get sharedTripsRealEmptyMessage =>
      'Những chuyến đi mà người khác mời bạn cùng cộng tác sẽ xuất hiện ở đây.';

  @override
  String get sharedTripsRealUntitled => 'Chuyến đi chưa đặt tên';

  @override
  String get sharedTripsRealEntryTitle => 'Được chia sẻ với tôi';

  @override
  String get sharedTripsRealEntrySubtitle =>
      'Mở những chuyến đi mà người khác đã mời bạn.';

  @override
  String get sharedTripsRealEntrySemantic =>
      'Được chia sẻ với tôi — những chuyến đi mà người khác đã mời bạn cùng cộng tác';

  @override
  String get interestRealTitle => 'Sở thích du lịch của tôi';

  @override
  String get interestRealEntryTitle => 'Sở thích du lịch';

  @override
  String get interestRealLoadingMessage => 'Đang tải sở thích của bạn…';

  @override
  String get interestRealErrorMessage =>
      'Chúng tôi không thể tải sở thích của bạn. Kéo để làm mới hoặc thử lại.';

  @override
  String get interestRealForbiddenMessage =>
      'Bạn không có quyền truy cập hồ sơ sở thích này.';

  @override
  String get interestRealGoneMessage =>
      'Hồ sơ sở thích này không còn khả dụng.';

  @override
  String get interestRealNetworkMessage =>
      'Không có kết nối. Kiểm tra mạng và thử lại.';

  @override
  String get interestRealEmptyTitle => 'Chưa có sở thích nào';

  @override
  String get interestRealEmptyMessage =>
      'Tính toán lại để xây dựng hồ sơ sở thích của bạn từ các đặt chỗ, danh sách yêu thích, bộ sưu tập đã lưu và đánh giá.';

  @override
  String get interestRealRecalculateAction => 'Tính toán lại';

  @override
  String get interestRealRecalculateSemantic =>
      'Tính toán lại hồ sơ sở thích của tôi từ hoạt động của tôi';

  @override
  String get interestRealRecalculatedMessage => 'Đã cập nhật sở thích.';

  @override
  String get interestRealRecalculateErrorMessage =>
      'Chúng tôi không thể cập nhật sở thích của bạn. Vui lòng thử lại.';

  @override
  String interestRealSignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suy ra từ $count tín hiệu',
      zero: 'Chưa có tín hiệu nào',
    );
    return '$_temp0';
  }

  @override
  String interestRealLastUpdated(String when) {
    return 'Cập nhật lần cuối $when';
  }

  @override
  String get interestRealTravelStyles => 'Phong cách du lịch';

  @override
  String get interestRealWeather => 'Thời tiết ưa thích';

  @override
  String get interestRealBudget => 'Mức ngân sách';

  @override
  String get interestRealCrowd => 'Mức độ đông đúc';

  @override
  String get interestRealAccessibility => 'Khả năng tiếp cận';

  @override
  String get interestRealProvinces => 'Điểm đến yêu thích';

  @override
  String get interestRealCategories => 'Danh mục yêu thích';

  @override
  String get interestRealTags => 'Thẻ yêu thích';

  @override
  String get walletRealLoadingMessage => 'Đang tải ví của bạn…';

  @override
  String get walletRealErrorMessage =>
      'Không thể tải ví của bạn. Kéo để làm mới hoặc thử lại.';

  @override
  String get walletRealForbiddenMessage =>
      'Bạn không có quyền truy cập mục ví này.';

  @override
  String get walletRealGoneMessage => 'Mục ví này không còn khả dụng.';

  @override
  String get walletRealNetworkMessage =>
      'Không có kết nối. Hãy kiểm tra mạng và thử lại.';

  @override
  String get walletRealActionErrorMessage =>
      'Không thành công. Vui lòng thử lại.';

  @override
  String get walletRealCreatedMessage => 'Đã thêm mục ví.';

  @override
  String get walletRealUpdatedMessage => 'Đã cập nhật mục ví.';

  @override
  String get walletRealDeletedMessage => 'Đã xóa mục ví.';

  @override
  String get walletRealFavoritedMessage => 'Đã thêm vào mục yêu thích.';

  @override
  String get walletRealUnfavoritedMessage => 'Đã xóa khỏi mục yêu thích.';

  @override
  String get walletRealArchivedMessage => 'Đã lưu trữ mục ví.';

  @override
  String get walletRealRestoredMessage => 'Đã khôi phục mục ví.';

  @override
  String get walletRealTitleRequiredMessage =>
      'Hãy nhập tiêu đề cho mục ví này.';

  @override
  String get walletRealAddSemantic => 'Thêm mục ví';

  @override
  String get walletRealCreateTitle => 'Mục ví mới';

  @override
  String get walletRealEditTitle => 'Sửa mục ví';

  @override
  String get walletRealUntitled => 'Mục chưa đặt tên';

  @override
  String get walletRealListEmptyTitle => 'Ví của bạn đang trống';

  @override
  String get walletRealListEmptyMessage =>
      'Thêm hộ chiếu, thị thực, vé, voucher hoặc biên lai để luôn sẵn sàng cho chuyến đi.';

  @override
  String get walletRealTitleField => 'Tiêu đề';

  @override
  String get walletRealIssuerField => 'Đơn vị phát hành (tùy chọn)';

  @override
  String get walletRealReferenceField => 'Số tham chiếu (tùy chọn)';

  @override
  String get walletRealReferenceNote =>
      'Số tham chiếu được lưu ở dạng che và không thể hiển thị lại.';

  @override
  String walletRealReferenceHint(String masked) {
    return 'Hiện tại: $masked. Để trống để giữ nguyên trạng thái đã xóa; nhập lại để thay thế.';
  }

  @override
  String get walletRealValidFromField => 'Có hiệu lực từ';

  @override
  String get walletRealValidUntilField => 'Có hiệu lực đến';

  @override
  String get walletRealDateNone => 'Chưa đặt';

  @override
  String get walletRealSaveAction => 'Lưu mục';

  @override
  String get walletRealEditAction => 'Sửa';

  @override
  String get walletRealDeleteAction => 'Xóa';

  @override
  String get walletRealArchiveAction => 'Lưu trữ';

  @override
  String get walletRealRestoreAction => 'Khôi phục';

  @override
  String get walletRealDeleteConfirmTitle => 'Xóa mục ví?';

  @override
  String walletRealDeleteConfirmMessage(String title) {
    return 'Xóa $title khỏi ví của bạn? Tài liệu, đặt chỗ hoặc hóa đơn được liên kết sẽ không bị ảnh hưởng.';
  }

  @override
  String walletRealFavoriteSemantic(String title) {
    return 'Thêm $title vào mục yêu thích';
  }

  @override
  String walletRealUnfavoriteSemantic(String title) {
    return 'Xóa $title khỏi mục yêu thích';
  }

  @override
  String get partnerExtranetTitle => 'Cổng đối tác';

  @override
  String get partnerWorkspaceUnnamed => 'Không gian làm việc của bạn';

  @override
  String get partnerNavGroupOverview => 'Tổng quan';

  @override
  String get partnerNavGroupProperty => 'Cơ sở lưu trú';

  @override
  String get partnerNavGroupOperations => 'Vận hành';

  @override
  String get partnerNavGroupGrowth => 'Tăng trưởng';

  @override
  String get partnerNavGroupBusiness => 'Kinh doanh';

  @override
  String get partnerNavGroupAccount => 'Tài khoản';

  @override
  String get partnerNavDashboard => 'Bảng điều khiển';

  @override
  String get partnerNavHotels => 'Khách sạn';

  @override
  String get partnerNavRooms => 'Phòng';

  @override
  String get partnerNavCalendar => 'Lịch';

  @override
  String get partnerNavPricing => 'Giá';

  @override
  String get partnerNavPromotions => 'Khuyến mãi';

  @override
  String get partnerNavBookings => 'Đặt phòng';

  @override
  String get partnerNavMessages => 'Tin nhắn';

  @override
  String get partnerNavAnalytics => 'Phân tích';

  @override
  String get partnerNavFinance => 'Tài chính';

  @override
  String get partnerNavReviews => 'Đánh giá';

  @override
  String get partnerNavNotifications => 'Thông báo';

  @override
  String get partnerNavSettings => 'Cài đặt';

  @override
  String get partnerNavMenuTooltip => 'Mở menu đối tác';

  @override
  String partnerNavBadgeSemantic(String label, int count) {
    return '$label, $count mục đang chờ';
  }

  @override
  String partnerTeamRoleLabel(String role) {
    return 'Vai trò của bạn: $role';
  }

  @override
  String get partnerTeamRoleOwner => 'Chủ sở hữu';

  @override
  String get partnerTeamRoleManager => 'Quản lý';

  @override
  String get partnerTeamRoleFrontDesk => 'Lễ tân';

  @override
  String get partnerTeamRoleFinance => 'Tài chính';

  @override
  String get partnerTeamRoleViewer => 'Người xem';

  @override
  String get partnerTeamRoleUnknown => 'Chưa xác định';

  @override
  String get partnerActionRetry => 'Thử lại';

  @override
  String get partnerActionRefresh => 'Làm mới';

  @override
  String get partnerActionBack => 'Quay lại';

  @override
  String get partnerShellMobileHint =>
      'Hãy dùng màn hình lớn hơn để có đầy đủ bảng vận hành.';

  @override
  String get partnerStatusLoadingTitle => 'Đang tải không gian làm việc';

  @override
  String get partnerStatusLoadingMessage =>
      'Đang lấy hồ sơ đối tác và hoạt động hôm nay của bạn.';

  @override
  String get partnerStatusReadyTitle => 'Đã sẵn sàng';

  @override
  String get partnerStatusReadyMessage =>
      'Không gian làm việc đối tác của bạn đã được cập nhật.';

  @override
  String get partnerStatusDemoTitle => 'Không khả dụng ở chế độ demo';

  @override
  String get partnerStatusDemoMessage =>
      'Cổng đối tác chỉ hoạt động với backend thật. Hãy đăng nhập bằng tài khoản đối tác để mở.';

  @override
  String get partnerStatusNotPartnerTitle => 'Cần quyền đối tác';

  @override
  String get partnerStatusNotPartnerMessage =>
      'Tài khoản này không phải tài khoản đối tác nên không thể mở Cổng đối tác.';

  @override
  String get partnerStatusOnboardingTitle => 'Chưa có hồ sơ đối tác';

  @override
  String get partnerStatusOnboardingMessage =>
      'Tài khoản này chưa có hồ sơ doanh nghiệp đối tác. Hồ sơ phải được tạo và phê duyệt trước khi mở không gian làm việc.';

  @override
  String get partnerStatusAwaitingApprovalTitle => 'Đang chờ phê duyệt';

  @override
  String get partnerStatusAwaitingApprovalMessage =>
      'Hồ sơ đối tác của bạn đã được gửi. Không gian làm việc sẽ mở khi quản trị viên phê duyệt.';

  @override
  String get partnerStatusRejectedTitle => 'Hồ sơ đối tác bị từ chối';

  @override
  String get partnerStatusRejectedMessage =>
      'Đơn đăng ký đối tác của bạn đã bị từ chối nên không gian làm việc đang đóng.';

  @override
  String get partnerStatusSuspendedTitle => 'Tài khoản đối tác bị tạm ngưng';

  @override
  String get partnerStatusSuspendedMessage =>
      'Quản trị viên đã tạm ngưng tài khoản đối tác này. Hãy liên hệ bộ phận hỗ trợ để khôi phục quyền truy cập.';

  @override
  String get partnerStatusMembershipSuspendedTitle =>
      'Quyền truy cập nhóm của bạn đang bị tạm ngưng';

  @override
  String get partnerStatusMembershipSuspendedMessage =>
      'Chủ sở hữu hoặc quản lý của không gian làm việc này đã tạm ngưng tư cách thành viên của bạn. Bạn sẽ có lại quyền truy cập khi họ kích hoạt lại.';

  @override
  String get partnerStatusUnauthorizedTitle => 'Hãy đăng nhập lại';

  @override
  String get partnerStatusUnauthorizedMessage =>
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại để mở lại không gian làm việc.';

  @override
  String get partnerStatusForbiddenTitle => 'Truy cập bị từ chối';

  @override
  String get partnerStatusForbiddenMessage =>
      'Máy chủ đã từ chối yêu cầu này với tài khoản của bạn.';

  @override
  String get partnerStatusErrorTitle => 'Không tải được không gian làm việc';

  @override
  String get partnerStatusErrorMessage =>
      'Chúng tôi không kết nối được tới dịch vụ đối tác. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get partnerVerificationApproved => 'Đã duyệt';

  @override
  String get partnerVerificationSubmitted => 'Đã gửi';

  @override
  String get partnerVerificationDraft => 'Bản nháp';

  @override
  String get partnerVerificationRejected => 'Bị từ chối';

  @override
  String get partnerVerificationSuspended => 'Tạm ngưng';

  @override
  String get partnerVerificationUnknown => 'Không xác định';

  @override
  String get partnerDashboardTodayHeading => 'Hôm nay';

  @override
  String partnerDashboardRepresentative(String name) {
    return 'Người đại diện: $name';
  }

  @override
  String get partnerMetricArrivals => 'Nhận phòng hôm nay';

  @override
  String get partnerMetricDepartures => 'Trả phòng hôm nay';

  @override
  String get partnerMetricUnreadMessages => 'Tin nhắn chưa đọc';

  @override
  String get partnerMetricPendingReviews => 'Đánh giá chờ xử lý';

  @override
  String get partnerMetricActivePromotions => 'Khuyến mãi đang chạy';

  @override
  String get partnerMetricNotifications => 'Thông báo';

  @override
  String get partnerMetricProperties => 'Cơ sở lưu trú';

  @override
  String get partnerMetricActiveRooms => 'Phòng đang hoạt động';

  @override
  String get partnerPropertyScopeHeading => 'Phạm vi cơ sở lưu trú';

  @override
  String get partnerPropertyScopeEmpty =>
      'Chưa có cơ sở lưu trú nào được gán cho tài khoản đối tác này.';

  @override
  String get partnerPropertyScopeUnavailable =>
      'Không tải được danh sách cơ sở lưu trú. Hãy làm mới để thử lại.';

  @override
  String partnerPropertyInactiveSemantic(String name) {
    return '$name, ngừng hoạt động';
  }

  @override
  String get partnerModulePlannedBadge => 'Dự kiến';

  @override
  String get partnerModulePlannedMessage =>
      'Mô-đun này chưa được xây dựng. Nó sẽ được kết nối với các endpoint đối tác hiện có ở giai đoạn sau; trước đó không hiển thị dữ liệu nào.';

  @override
  String partnerModuleEndpointHint(String route) {
    return 'Tuyến: $route';
  }

  @override
  String get partnerModuleReadOnlyForRole =>
      'Vai trò nhóm của bạn sẽ không thể thay đổi cài đặt trong mô-đun này.';

  @override
  String get partnerDashboardScopeHeading => 'Phạm vi báo cáo';

  @override
  String get partnerDashboardScopeHint =>
      'Áp dụng cho Hiệu suất, Công suất phòng và Doanh thu. Hoạt động hôm nay luôn tính trên tất cả cơ sở.';

  @override
  String get partnerDashboardScopeToday => 'Hôm nay · tất cả cơ sở';

  @override
  String get partnerDashboardScopeAllProperties => 'Tất cả cơ sở';

  @override
  String get partnerDashboardScopeLast30AllProperties =>
      '30 ngày gần nhất · tất cả cơ sở';

  @override
  String partnerDashboardScopeWindowAll(String window) {
    return '$window · tất cả cơ sở';
  }

  @override
  String partnerDashboardScopeWindowOne(String window) {
    return '$window · cơ sở đã chọn';
  }

  @override
  String get partnerDashboardRangeLabel => 'Khoảng thời gian';

  @override
  String get partnerDashboardRangeLast7 => '7 ngày';

  @override
  String get partnerDashboardRangeLast30 => '30 ngày';

  @override
  String get partnerDashboardRangeLast90 => '90 ngày';

  @override
  String get partnerDashboardPropertyLabel => 'Cơ sở';

  @override
  String get partnerDashboardPropertyAll => 'Tất cả cơ sở';

  @override
  String partnerDashboardPropertyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cơ sở',
      one: '1 cơ sở',
    );
    return '$_temp0';
  }

  @override
  String partnerDashboardRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phòng đang hoạt động',
      one: '1 phòng đang hoạt động',
    );
    return '$_temp0';
  }

  @override
  String partnerDashboardTeamRole(String role) {
    return 'Vai trò của bạn: $role';
  }

  @override
  String partnerDashboardActiveProperty(String name) {
    return 'Đang xem $name';
  }

  @override
  String partnerDashboardUpdatedAt(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get partnerDashboardNoActivityHint =>
      'Chưa có đặt phòng nào trong khoảng thời gian đã chọn nên các chỉ số hiệu suất bên dưới bằng 0.';

  @override
  String get partnerDashboardAttentionHeading => 'Cần xử lý';

  @override
  String get partnerDashboardAttentionClear =>
      'Hiện chưa có việc nào cần bạn xử lý.';

  @override
  String partnerDashboardAttentionSemantic(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục cần xử lý',
      one: '1 mục cần xử lý',
    );
    return '$label, $_temp0';
  }

  @override
  String get partnerDashboardQuickActionsHeading => 'Thao tác nhanh';

  @override
  String get partnerDashboardPerformanceHeading => 'Hiệu suất';

  @override
  String get partnerDashboardPerformanceEmpty =>
      'Không có đặt phòng nào trong kỳ này nên chưa có số liệu để báo cáo.';

  @override
  String get partnerDashboardOccupancyHeading => 'Công suất phòng';

  @override
  String get partnerDashboardOccupancyNoInventory =>
      'Chưa thiết lập số lượng phòng nên không thể tính công suất.';

  @override
  String get partnerDashboardOccupancyChartLabel => 'Công suất theo ngày';

  @override
  String get partnerDashboardRevenueHeading => 'Doanh thu';

  @override
  String get partnerDashboardRevenueChartLabel => 'Doanh thu theo ngày';

  @override
  String get partnerDashboardFinanceHeading => 'Tổng quan tài chính';

  @override
  String get partnerDashboardActivityHeading => 'Hoạt động gần đây';

  @override
  String get partnerDashboardActivityEmpty => 'Chưa ghi nhận hoạt động nào.';

  @override
  String partnerDashboardActivityBy(String actor) {
    return 'bởi $actor';
  }

  @override
  String get partnerDashboardActivityUnknownActor =>
      'Người dùng không xác định';

  @override
  String partnerDashboardActivityMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục cũ hơn',
      one: '1 mục cũ hơn',
    );
    return '$_temp0';
  }

  @override
  String get partnerDashboardChartEmpty => 'Không có dữ liệu trong kỳ này.';

  @override
  String get partnerDashboardErrorUnauthorized =>
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại để tải phần này.';

  @override
  String get partnerDashboardErrorForbidden =>
      'Hồ sơ đối tác của bạn chưa được duyệt để xem dữ liệu này.';

  @override
  String get partnerDashboardErrorNotFound =>
      'Dữ liệu này không khả dụng với hồ sơ đối tác của bạn.';

  @override
  String get partnerDashboardErrorValidation =>
      'Khoảng thời gian không hợp lệ. Hãy chọn kỳ khác.';

  @override
  String get partnerDashboardErrorTimeout => 'Phần này tải quá lâu.';

  @override
  String get partnerDashboardErrorNetwork =>
      'Không kết nối được máy chủ cho phần này.';

  @override
  String get partnerDashboardErrorServer =>
      'Máy chủ không tạo được dữ liệu này.';

  @override
  String get partnerDashboardErrorGeneric => 'Không tải được phần này.';

  @override
  String get partnerValueUnavailable => '—';

  @override
  String get partnerKpiCurrentGuests => 'Khách đang lưu trú';

  @override
  String get partnerKpiUpcoming => 'Sắp tới';

  @override
  String get partnerKpiOccupancy => 'Công suất phòng';

  @override
  String get partnerKpiRevenueToday => 'Doanh thu hôm nay';

  @override
  String get partnerKpiRevenueMonth => 'Doanh thu tháng này';

  @override
  String get partnerKpiAverageStay => 'Số đêm lưu trú trung bình';

  @override
  String get partnerKpiTotalRevenue => 'Tổng doanh thu';

  @override
  String get partnerKpiTotalBookings => 'Tổng lượt đặt phòng';

  @override
  String get partnerKpiAdr => 'Giá phòng trung bình';

  @override
  String get partnerKpiAdrCaption => 'Trên mỗi đêm phòng đã bán';

  @override
  String get partnerKpiConfirmed => 'Đã xác nhận';

  @override
  String get partnerKpiCancelled => 'Đã hủy';

  @override
  String get partnerKpiReviewAverage => 'Điểm đánh giá trung bình';

  @override
  String partnerKpiReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Từ $count đánh giá',
      one: 'Từ 1 đánh giá',
      zero: 'Chưa có đánh giá',
    );
    return '$_temp0';
  }

  @override
  String get partnerKpiResponseRate => 'Tỷ lệ phản hồi tin nhắn';

  @override
  String get partnerOccupancyInventory => 'Tổng số phòng';

  @override
  String get partnerOccupancySold => 'Phòng đã bán';

  @override
  String get partnerOccupancyAvailable => 'Phòng còn trống';

  @override
  String get partnerOccupancyStopSell => 'Ngày ngừng bán';

  @override
  String get partnerRevenueMonthToDate => 'Từ đầu tháng';

  @override
  String get partnerRevenueLast30 => '30 ngày gần nhất';

  @override
  String get partnerRevenueByProperty => 'Doanh thu theo cơ sở';

  @override
  String get partnerFinanceGross => 'Doanh thu gộp';

  @override
  String get partnerFinanceNet => 'Doanh thu thuần';

  @override
  String get partnerFinanceCommission => 'Hoa hồng nền tảng';

  @override
  String get partnerFinanceTax => 'Thuế ước tính';

  @override
  String get partnerFinanceRefunded => 'Đã hoàn tiền';

  @override
  String get partnerFinancePendingSettlement => 'Chờ quyết toán';

  @override
  String get partnerFinanceNextPayout => 'Kỳ chi trả dự kiến tiếp theo';

  @override
  String partnerFinanceCompletedBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đặt phòng hoàn tất',
      one: '1 đặt phòng hoàn tất',
    );
    return '$_temp0';
  }

  @override
  String partnerFinancePaidBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đặt phòng đã thanh toán',
      one: '1 đặt phòng đã thanh toán',
    );
    return '$_temp0';
  }

  @override
  String partnerPropertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cơ sở',
      one: '1 cơ sở',
      zero: 'Chưa có cơ sở',
    );
    return '$_temp0';
  }

  @override
  String get partnerPropertiesEmptyTitle => 'Chưa có cơ sở nào';

  @override
  String get partnerPropertiesEmptyMessage =>
      'Hãy tạo chỗ nghỉ đầu tiên để bắt đầu chuẩn bị tin đăng. Nó được lưu dưới dạng bản nháp mà chỉ bạn và đội ngũ Plan Your Trip nhìn thấy.';

  @override
  String get partnerPropertiesSelectedSemantic => 'Cơ sở đang chọn';

  @override
  String get partnerPropertyDetailHeading => 'Chi tiết cơ sở';

  @override
  String get partnerPropertyCloseDetail => 'Đóng chi tiết';

  @override
  String get partnerPropertyDetailNotFound =>
      'Cơ sở này không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerPropertyActionsOwnerOnly =>
      'Thao tác đăng bán chỉ dành cho chủ hồ sơ. Bạn vẫn xem được toàn bộ thông tin tại đây.';

  @override
  String get partnerPropertyStatusDraft => 'Bản nháp';

  @override
  String get partnerPropertyStatusPendingReview => 'Chờ duyệt';

  @override
  String get partnerPropertyStatusApproved => 'Đã duyệt';

  @override
  String get partnerPropertyStatusPublished => 'Đã đăng';

  @override
  String get partnerPropertyStatusHidden => 'Đang ẩn';

  @override
  String get partnerPropertyStatusArchived => 'Đã lưu trữ';

  @override
  String get partnerPropertyStatusRejected => 'Bị từ chối';

  @override
  String get partnerPropertyStatusUnknown => 'Trạng thái không xác định';

  @override
  String get partnerPropertyActive => 'Đang mở bán';

  @override
  String get partnerPropertyInactive => 'Đang tắt bán';

  @override
  String get partnerPropertyVerified => 'Đã xác minh';

  @override
  String get partnerPropertyNotVerified => 'Chưa xác minh';

  @override
  String get partnerPropertyFeatured => 'Nổi bật';

  @override
  String get partnerPropertyNotFeatured => 'Không nổi bật';

  @override
  String get partnerPropertyNotSet => 'Chưa thiết lập';

  @override
  String partnerPropertyRatingSummary(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đánh giá',
      one: '1 đánh giá',
    );
    return '$rating từ $_temp0';
  }

  @override
  String get partnerPropertyVisibilityPublic =>
      'Khách có thể tìm thấy và đặt cơ sở này ngay bây giờ.';

  @override
  String get partnerPropertyVisibilityNotPublic =>
      'Cơ sở này hiện không hiển thị với khách.';

  @override
  String get partnerPropertyModerationNote =>
      'Việc xác minh và gắn nổi bật do đội ngũ Plan Your Trip quản lý và không thể thay đổi tại đây.';

  @override
  String get partnerPropertyActivateAction => 'Bật đăng bán';

  @override
  String get partnerPropertyDeactivateAction => 'Tắt đăng bán';

  @override
  String partnerPropertyActivatedMessage(String name) {
    return '$name đã được mở bán.';
  }

  @override
  String partnerPropertyDeactivatedMessage(String name) {
    return '$name đã ngừng mở bán.';
  }

  @override
  String get partnerPropertyActionNotFound =>
      'Cơ sở đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerPropertyActionFailed =>
      'Không lưu được thay đổi. Chưa có gì bị thay đổi.';

  @override
  String get partnerPropertyActionUncertain =>
      'Mất kết nối trước khi máy chủ xác nhận. Hãy làm mới để xem trạng thái hiện tại.';

  @override
  String get partnerPropertySectionIdentity => 'Thông tin nhận dạng';

  @override
  String get partnerPropertySectionLocation => 'Vị trí';

  @override
  String get partnerPropertySectionContact => 'Liên hệ';

  @override
  String get partnerPropertySectionPolicies => 'Chính sách';

  @override
  String get partnerPropertySectionVerification => 'Xác minh';

  @override
  String get partnerPropertySectionPerformance => 'Phản hồi của khách';

  @override
  String get partnerPropertySectionMetadata => 'Hồ sơ dữ liệu';

  @override
  String get partnerPropertyFieldSlug => 'Đường dẫn URL';

  @override
  String get partnerPropertyFieldShortDescription => 'Mô tả ngắn';

  @override
  String get partnerPropertyFieldDescription => 'Mô tả';

  @override
  String get partnerPropertyFieldAddress => 'Địa chỉ';

  @override
  String get partnerPropertyFieldCoordinates => 'Tọa độ';

  @override
  String get partnerPropertyFieldPhone => 'Điện thoại';

  @override
  String get partnerPropertyFieldEmail => 'Email';

  @override
  String get partnerPropertyFieldWebsite => 'Website';

  @override
  String get partnerPropertyFieldFacebook => 'Facebook';

  @override
  String get partnerPropertyFieldInstagram => 'Instagram';

  @override
  String get partnerPropertyFieldCheckIn => 'Nhận phòng từ';

  @override
  String get partnerPropertyFieldCheckOut => 'Trả phòng trước';

  @override
  String get partnerPropertyFieldChildrenPolicy => 'Chính sách trẻ em';

  @override
  String get partnerPropertyFieldPetPolicy => 'Chính sách thú cưng';

  @override
  String get partnerPropertyFieldSmokingPolicy => 'Chính sách hút thuốc';

  @override
  String get partnerPropertyFieldVerified => 'Trạng thái xác minh';

  @override
  String get partnerPropertyFieldFeatured => 'Vị trí nổi bật';

  @override
  String get partnerPropertyFieldRating => 'Điểm trung bình';

  @override
  String get partnerPropertyFieldReviewCount => 'Đánh giá';

  @override
  String get partnerPropertyFieldOwner => 'Thuộc sở hữu của';

  @override
  String get partnerPropertyFieldCreated => 'Ngày tạo';

  @override
  String get partnerPropertyFieldUpdated => 'Cập nhật lần cuối';

  @override
  String get partnerPropertyAddAction => 'Thêm chỗ nghỉ';

  @override
  String get partnerPropertyEditAction => 'Sửa chỗ nghỉ';

  @override
  String get partnerPropertyEditorCreateTitle => 'Chỗ nghỉ mới';

  @override
  String get partnerPropertyEditorEditTitle => 'Sửa chỗ nghỉ';

  @override
  String get partnerPropertyEditorIntro =>
      'Mọi thông tin ở đây được lưu dưới dạng bản nháp. Du khách không thấy bản nháp, và chỉ đội ngũ Plan Your Trip mới có thể đăng.';

  @override
  String get partnerPropertyEditorSectionBasics => 'Thông tin cơ bản';

  @override
  String get partnerPropertyEditorSectionLocation => 'Vị trí';

  @override
  String get partnerPropertyEditorSectionContact => 'Liên hệ';

  @override
  String get partnerPropertyEditorSectionDetails => 'Chi tiết và chính sách';

  @override
  String get partnerPropertyEditorSectionAmenities => 'Tiện ích';

  @override
  String get partnerPropertyEditorSaveDraft => 'Lưu bản nháp';

  @override
  String get partnerPropertyEditorSaveChanges => 'Lưu thay đổi';

  @override
  String get partnerPropertyEditorCancel => 'Hủy';

  @override
  String get partnerPropertyFieldName => 'Tên chỗ nghỉ';

  @override
  String get partnerPropertyFieldCategory => 'Loại hình';

  @override
  String get partnerPropertyFieldSubcategory => 'Loại hình cụ thể';

  @override
  String get partnerPropertyFieldLocationUnit => 'Đơn vị hành chính';

  @override
  String get partnerPropertyFieldLatitude => 'Vĩ độ';

  @override
  String get partnerPropertyFieldLongitude => 'Kinh độ';

  @override
  String get partnerPropertyFieldStarRating => 'Hạng chỗ nghỉ';

  @override
  String get partnerPropertyFieldCancellationPolicy => 'Chính sách hủy';

  @override
  String get partnerPropertyFieldParking => 'Đỗ xe';

  @override
  String get partnerPropertyFieldWifi => 'Wi-Fi';

  @override
  String get partnerPropertyFieldLanguages => 'Ngôn ngữ phục vụ';

  @override
  String get partnerPropertyFieldPaymentMethods => 'Hình thức thanh toán';

  @override
  String get partnerPropertyFieldAmenities => 'Tiện ích của chỗ nghỉ';

  @override
  String get partnerPropertyStarRatingHelp =>
      'Hạng do chính bạn tự khai, từ 1 đến 5. Đây không phải hạng sao đã được thẩm định.';

  @override
  String get partnerPropertySlugHelp =>
      'Được tạo khi thêm chỗ nghỉ, vì nó nằm trong địa chỉ công khai.';

  @override
  String get partnerPropertyListHelp => 'Phân cách các mục bằng dấu phẩy.';

  @override
  String get partnerPropertyCoordinatesHelp =>
      'Không bắt buộc. Vĩ độ từ -90 đến 90, kinh độ từ -180 đến 180.';

  @override
  String get partnerPropertyAmenitiesHelp =>
      'Chọn từ danh mục tiện ích của Plan Your Trip. Tiện ích trong phòng sẽ được khai báo ở từng phòng sau.';

  @override
  String partnerPropertyAmenitiesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chọn $count mục',
      zero: 'Chưa chọn mục nào',
    );
    return '$_temp0';
  }

  @override
  String get partnerPropertyDraftNotice => 'Bản nháp — du khách chưa thấy';

  @override
  String get partnerPropertyFreeCancellation => 'Hủy miễn phí';

  @override
  String get partnerPropertyParkingAvailable => 'Có chỗ đỗ xe';

  @override
  String get partnerPropertyParkingFree => 'Đỗ xe miễn phí';

  @override
  String get partnerPropertyWifiAvailable => 'Có Wi-Fi';

  @override
  String get partnerPropertyWifiFree => 'Wi-Fi miễn phí';

  @override
  String get partnerPropertyLocationCountry => 'Quốc gia';

  @override
  String get partnerPropertyLocationProvince => 'Tỉnh hoặc thành phố';

  @override
  String get partnerPropertyLocationArea => 'Khu vực (không bắt buộc)';

  @override
  String get partnerPropertySelectPrompt => 'Chọn';

  @override
  String get partnerPropertyReferenceLoading => 'Đang tải các lựa chọn…';

  @override
  String get partnerPropertyReferenceError =>
      'Không tải được các lựa chọn, nên chưa thể lưu.';

  @override
  String get partnerPropertyValidationName => 'Nhập tên chỗ nghỉ.';

  @override
  String get partnerPropertyValidationAddress => 'Nhập địa chỉ cụ thể.';

  @override
  String get partnerPropertyValidationCategory => 'Chọn loại hình chỗ nghỉ.';

  @override
  String get partnerPropertyValidationLocation =>
      'Chọn tỉnh, thành phố hoặc khu vực của chỗ nghỉ.';

  @override
  String get partnerPropertyValidationTime => 'Nhập giờ theo dạng HH:MM.';

  @override
  String get partnerPropertyValidationLatitude =>
      'Vĩ độ phải nằm trong khoảng -90 đến 90.';

  @override
  String get partnerPropertyValidationLongitude =>
      'Kinh độ phải nằm trong khoảng -180 đến 180.';

  @override
  String get partnerPropertyValidationEmail => 'Nhập địa chỉ email hợp lệ.';

  @override
  String get partnerPropertyValidationStarRating => 'Chọn hạng từ 1 đến 5.';

  @override
  String partnerPropertyCreatedMessage(String name) {
    return 'Đã lưu $name dưới dạng bản nháp.';
  }

  @override
  String partnerPropertySavedMessage(String name) {
    return 'Đã cập nhật $name.';
  }

  @override
  String get partnerPropertyErrorValidation =>
      'Vui lòng kiểm tra các trường được đánh dấu.';

  @override
  String get partnerPropertyErrorCategory =>
      'Loại hình này hiện không dùng được. Hãy chọn loại khác.';

  @override
  String get partnerPropertyErrorLocation =>
      'Chỗ nghỉ không thể đặt tại vị trí đó. Hãy chọn tỉnh, thành phố hoặc khu vực.';

  @override
  String get partnerPropertyErrorAmenity =>
      'Một tiện ích đã chọn không còn khả dụng. Hãy tải lại danh sách và thử lại.';

  @override
  String get partnerPropertyErrorSlugConflict =>
      'Một chỗ nghỉ khác đang dùng địa chỉ đó.';

  @override
  String get partnerPropertyErrorApproval =>
      'Hồ sơ doanh nghiệp cần được duyệt trước khi bạn quản lý chỗ nghỉ.';

  @override
  String get partnerPropertyGateTitle => 'Cần duyệt hồ sơ doanh nghiệp';

  @override
  String get partnerPropertyGateMessage =>
      'Bạn có thể thêm và sửa chỗ nghỉ sau khi quản trị viên duyệt hồ sơ doanh nghiệp.';

  @override
  String get partnerPropertyGateAction => 'Mở tài khoản của tôi';

  @override
  String get partnerWizardTitle => 'Thiết lập chỗ nghỉ';

  @override
  String get partnerWizardSubtitle =>
      'Thiết lập chỗ nghỉ theo từng bước. Mọi thông tin được giữ dưới dạng bản nháp cho đến khi đội ngũ của chúng tôi đăng tải.';

  @override
  String partnerWizardStepOf(int current, int total) {
    return 'Bước $current trên $total';
  }

  @override
  String partnerWizardStepSemantic(int current, int total, String step) {
    return 'Bước $current trên $total: $step';
  }

  @override
  String get partnerWizardStepBusinessProfile => 'Hồ sơ doanh nghiệp';

  @override
  String get partnerWizardStepBasics => 'Thông tin cơ bản';

  @override
  String get partnerWizardStepLocation => 'Vị trí';

  @override
  String get partnerWizardStepContact => 'Liên hệ';

  @override
  String get partnerWizardStepAmenities => 'Tiện ích';

  @override
  String get partnerWizardStepPolicies => 'Chi tiết và chính sách';

  @override
  String get partnerWizardStepReview => 'Xem lại';

  @override
  String get partnerWizardProgressLabel => 'Tiến độ thiết lập';

  @override
  String get partnerWizardActionContinue => 'Tiếp tục';

  @override
  String get partnerWizardActionBack => 'Quay lại';

  @override
  String get partnerWizardActionSaveDraft => 'Lưu bản nháp';

  @override
  String get partnerWizardStepIncomplete =>
      'Hãy hoàn tất bước này trước khi tiếp tục.';

  @override
  String get partnerWizardSaveBlockedCreate =>
      'Bản nháp chỉ được lưu khi thông tin cơ bản, vị trí và giờ nhận phòng đã đầy đủ — máy chủ cần tất cả trước khi giữ chỗ nghỉ.';

  @override
  String get partnerWizardSaveBlockedClean =>
      'Mọi thông tin ở đây đã được lưu.';

  @override
  String get partnerWizardSavedJustNow => 'Vừa lưu xong';

  @override
  String partnerWizardSavedAt(String time) {
    return 'Đã lưu lúc $time';
  }

  @override
  String get partnerWizardSaving => 'Đang lưu…';

  @override
  String get partnerWizardLoading => 'Đang tải các lựa chọn…';

  @override
  String get partnerWizardPropertyError =>
      'Không mở được bản nháp này. Có thể nó không còn thuộc tài khoản của bạn.';

  @override
  String get partnerWizardDraftNotice => 'Bản nháp — du khách chưa thấy';

  @override
  String get partnerWizardProfileHeading => 'Điều kiện hồ sơ doanh nghiệp';

  @override
  String get partnerWizardProfileIntro =>
      'Việc quản lý chỗ nghỉ mở ra sau khi quản trị viên duyệt hồ sơ doanh nghiệp. Bước này chỉ kiểm tra điều đó; thông tin doanh nghiệp được sửa trong tài khoản của bạn.';

  @override
  String get partnerWizardProfileApproved =>
      'Hồ sơ doanh nghiệp đã được duyệt, bạn có thể thiết lập chỗ nghỉ.';

  @override
  String get partnerWizardProfileBlocked =>
      'Hồ sơ doanh nghiệp cần được duyệt trước khi bạn thiết lập chỗ nghỉ.';

  @override
  String get partnerWizardProfileEditAction => 'Mở hồ sơ doanh nghiệp';

  @override
  String get partnerWizardBasicsIntro => 'Tên chỗ nghỉ và loại hình của nó.';

  @override
  String get partnerWizardLocationIntro =>
      'Nơi chỗ nghỉ tọa lạc. Du khách tìm theo các địa danh này, hãy chọn đơn vị nhỏ nhất phù hợp.';

  @override
  String get partnerWizardLocationSelected => 'Vị trí đã chọn';

  @override
  String get partnerWizardContactIntro =>
      'Cách khách và đội ngũ của chúng tôi liên hệ chỗ nghỉ. Các mục ở đây không bắt buộc.';

  @override
  String get partnerWizardAmenitiesIntro =>
      'Những gì chỗ nghỉ cung cấp. Tiện ích trong phòng thuộc về từng phòng và sẽ khai báo sau.';

  @override
  String get partnerWizardAmenitiesSearch => 'Tìm tiện ích';

  @override
  String get partnerWizardAmenitiesEmpty =>
      'Không có tiện ích nào khớp với từ khóa.';

  @override
  String get partnerWizardPoliciesIntro =>
      'Giờ nhận phòng và các quy định áp dụng cho toàn bộ chỗ nghỉ.';

  @override
  String get partnerWizardReviewIntro =>
      'Kiểm tra lại mọi thông tin, sau đó lưu bản nháp.';

  @override
  String get partnerWizardReviewComplete => 'Đầy đủ';

  @override
  String get partnerWizardReviewIncomplete => 'Cần bổ sung';

  @override
  String get partnerWizardReviewFix => 'Sửa';

  @override
  String get partnerWizardReviewSavedTitle => 'Đã lưu bản nháp';

  @override
  String partnerWizardReviewSavedBody(String name) {
    return 'Đã lưu $name dưới dạng bản nháp. Du khách chưa thấy cho đến khi đội ngũ của chúng tôi đăng tải.';
  }

  @override
  String get partnerWizardReviewDone => 'Về danh sách chỗ nghỉ';

  @override
  String get partnerWizardLeaveTitle => 'Lưu thay đổi trước khi rời đi?';

  @override
  String get partnerWizardLeaveBody =>
      'Bước này có thay đổi chưa được lưu vào bản nháp.';

  @override
  String get partnerWizardLeaveSave => 'Lưu bản nháp';

  @override
  String get partnerWizardLeaveDiscard => 'Bỏ thay đổi';

  @override
  String get partnerWizardLeaveCancel => 'Tiếp tục sửa';

  @override
  String get partnerPropertyContinueSetupAction => 'Tiếp tục thiết lập';

  @override
  String get partnerPropertyDraftNotVisible => 'Du khách chưa thấy';

  @override
  String partnerRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count loại phòng',
      one: '1 loại phòng',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsListedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đang mở bán',
      one: '1 đang mở bán',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsSoldOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đã hết phòng',
      one: '1 đã hết phòng',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsForProperty(String name) {
    return 'Phòng tại $name';
  }

  @override
  String get partnerRoomsNoPropertyContext => 'Chưa chọn cơ sở';

  @override
  String get partnerRoomsPropertyScope => 'Phạm vi cơ sở';

  @override
  String get partnerRoomsSelectPropertyTitle => 'Hãy chọn một cơ sở';

  @override
  String get partnerRoomsSelectPropertyMessage =>
      'Phòng thuộc về một cơ sở cụ thể, hãy chọn cơ sở để xem các loại phòng.';

  @override
  String get partnerRoomsNoPropertiesTitle => 'Chưa có cơ sở nào';

  @override
  String get partnerRoomsNoPropertiesMessage =>
      'Phòng nằm trong một cơ sở. Khi hồ sơ của bạn được gán cơ sở, các loại phòng sẽ hiển thị tại đây.';

  @override
  String get partnerRoomsPropertyUnavailableTitle => 'Cơ sở không khả dụng';

  @override
  String get partnerRoomsPropertyUnavailableMessage =>
      'Cơ sở này không còn khả dụng với tài khoản của bạn, hoặc chưa được cấu hình phòng.';

  @override
  String get partnerRoomsEmptyTitle => 'Chưa có loại phòng nào';

  @override
  String get partnerRoomsEmptyMessage =>
      'Cơ sở này chưa có loại phòng nào được cấu hình. Việc này do đội ngũ Plan Your Trip thiết lập.';

  @override
  String get partnerRoomActionsOwnerOnly =>
      'Thao tác mở bán chỉ dành cho chủ hồ sơ. Bạn vẫn xem được mọi phòng tại đây.';

  @override
  String get partnerRoomDetailHeading => 'Chi tiết phòng';

  @override
  String get partnerRoomCloseDetail => 'Đóng chi tiết phòng';

  @override
  String get partnerRoomDetailNotFound =>
      'Phòng này không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerRoomListed => 'Đang mở bán';

  @override
  String get partnerRoomUnlisted => 'Chưa mở bán';

  @override
  String get partnerRoomSoldOut => 'Hết phòng';

  @override
  String get partnerRoomListAction => 'Mở bán phòng này';

  @override
  String get partnerRoomUnlistAction => 'Ngừng mở bán';

  @override
  String partnerRoomListedMessage(String name) {
    return '$name đã được mở bán.';
  }

  @override
  String partnerRoomUnlistedMessage(String name) {
    return '$name đã ngừng mở bán.';
  }

  @override
  String get partnerRoomActionNotFound =>
      'Phòng đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerRoomYes => 'Có';

  @override
  String get partnerRoomNo => 'Không';

  @override
  String partnerRoomGuestsValue(String count) {
    return 'Tối đa $count khách';
  }

  @override
  String partnerRoomInventoryValue(String available, String total) {
    return 'Còn $available trên $total';
  }

  @override
  String partnerRoomPriceFromValue(String price) {
    return 'Từ $price';
  }

  @override
  String partnerRoomSizeValue(String size) {
    return '$size m²';
  }

  @override
  String get partnerRoomSectionIdentity => 'Thông tin nhận dạng';

  @override
  String get partnerRoomSectionBeds => 'Giường';

  @override
  String get partnerRoomSectionCapacity => 'Sức chứa';

  @override
  String get partnerRoomSectionInventory => 'Số lượng phòng';

  @override
  String get partnerRoomSectionPricing => 'Giá phòng';

  @override
  String get partnerRoomSectionConditions => 'Điều kiện đặt phòng';

  @override
  String get partnerRoomSectionAmenities => 'Tiện nghi';

  @override
  String get partnerRoomSectionMedia => 'Hình ảnh';

  @override
  String get partnerRoomFieldCode => 'Mã phòng';

  @override
  String get partnerRoomFieldType => 'Loại phòng';

  @override
  String get partnerRoomFieldDescription => 'Mô tả';

  @override
  String get partnerRoomFieldBedType => 'Loại giường';

  @override
  String get partnerRoomFieldBedCount => 'Số giường';

  @override
  String get partnerRoomFieldMaxGuests => 'Số khách tối đa';

  @override
  String get partnerRoomFieldMaxAdults => 'Số người lớn tối đa';

  @override
  String get partnerRoomFieldMaxChildren => 'Số trẻ em tối đa';

  @override
  String get partnerRoomFieldSize => 'Diện tích phòng';

  @override
  String get partnerRoomFieldFloor => 'Tầng';

  @override
  String get partnerRoomFieldQuantity => 'Tổng số phòng';

  @override
  String get partnerRoomFieldAvailable => 'Hiện còn trống';

  @override
  String get partnerRoomFieldPriceFrom => 'Giá từ';

  @override
  String get partnerRoomFieldOriginalPrice => 'Giá gốc';

  @override
  String get partnerRoomFieldBreakfast => 'Bao gồm bữa sáng';

  @override
  String get partnerRoomFieldFreeCancellation => 'Hủy miễn phí';

  @override
  String get partnerRoomFieldInstantConfirmation => 'Xác nhận tức thì';

  @override
  String get partnerRoomFieldSmoking => 'Cho phép hút thuốc';

  @override
  String get partnerRoomFieldImages => 'Ảnh thư viện';

  @override
  String get partnerRoomTypeStandard => 'Tiêu chuẩn';

  @override
  String get partnerRoomTypeSuperior => 'Cao cấp';

  @override
  String get partnerRoomTypeDeluxe => 'Deluxe';

  @override
  String get partnerRoomTypePremier => 'Premier';

  @override
  String get partnerRoomTypeExecutive => 'Executive';

  @override
  String get partnerRoomTypeSuite => 'Suite';

  @override
  String get partnerRoomTypeFamily => 'Gia đình';

  @override
  String get partnerRoomTypeVilla => 'Villa';

  @override
  String get partnerRoomTypeBungalow => 'Bungalow';

  @override
  String get partnerRoomTypeUnknown => 'Loại không xác định';

  @override
  String get partnerBedTypeSingle => 'Giường đơn';

  @override
  String get partnerBedTypeDouble => 'Giường đôi';

  @override
  String get partnerBedTypeTwin => 'Hai giường đơn';

  @override
  String get partnerBedTypeQueen => 'Giường Queen';

  @override
  String get partnerBedTypeKing => 'Giường King';

  @override
  String get partnerBedTypeSofaBed => 'Giường sofa';

  @override
  String get partnerBedTypeBunk => 'Giường tầng';

  @override
  String get partnerBedTypeUnknown => 'Giường không xác định';

  @override
  String partnerInventoryForProperty(String name) {
    return 'Tồn phòng tại $name';
  }

  @override
  String get partnerInventoryNoPropertyContext => 'Chưa chọn cơ sở';

  @override
  String get partnerInventoryPropertyScope => 'Phạm vi cơ sở';

  @override
  String get partnerInventoryRoomScope => 'Loại phòng';

  @override
  String get partnerInventoryRangeLabel => 'Khoảng xem';

  @override
  String get partnerInventoryRangeWeek => '7 ngày';

  @override
  String get partnerInventoryRangeFortnight => '14 ngày';

  @override
  String get partnerInventoryRangeMonth => '30 ngày';

  @override
  String partnerInventoryWindow(String from, String to, int count) {
    return '$from – $to · $count ngày';
  }

  @override
  String partnerInventoryBookableDays(int bookable, int total) {
    return '$bookable trên $total ngày có thể đặt';
  }

  @override
  String partnerInventoryTotalAvailable(String count) {
    return '$count đêm phòng còn trống';
  }

  @override
  String partnerInventoryStopSellDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày ngừng bán',
      one: '1 ngày ngừng bán',
    );
    return '$_temp0';
  }

  @override
  String get partnerInventoryNoPropertiesTitle => 'Chưa có cơ sở nào';

  @override
  String get partnerInventoryNoPropertiesMessage =>
      'Tồn phòng thuộc về loại phòng trong một cơ sở. Khi hồ sơ của bạn được gán cơ sở, lịch sẽ hiển thị tại đây.';

  @override
  String get partnerInventorySelectPropertyTitle => 'Hãy chọn một cơ sở';

  @override
  String get partnerInventorySelectPropertyMessage =>
      'Chọn một cơ sở để xem lịch tồn phòng của các loại phòng.';

  @override
  String get partnerInventoryNoRoomsTitle => 'Chưa có loại phòng nào';

  @override
  String get partnerInventoryNoRoomsMessage =>
      'Cơ sở này chưa có loại phòng nào nên chưa có tồn phòng để quản lý.';

  @override
  String get partnerInventorySelectRoomTitle => 'Hãy chọn loại phòng';

  @override
  String get partnerInventorySelectRoomMessage =>
      'Tồn phòng được quản lý theo từng loại phòng. Hãy chọn một loại để xem lịch.';

  @override
  String get partnerInventoryInvalidRangeTitle => 'Khoảng ngày không hợp lệ';

  @override
  String get partnerInventoryInvalidRangeMessage =>
      'Ngày bắt đầu không được sau ngày kết thúc.';

  @override
  String get partnerInventoryUnavailableTitle => 'Không xem được tồn phòng';

  @override
  String get partnerInventoryUnavailableMessage =>
      'Cơ sở hoặc loại phòng này không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerInventoryEmptyTitle => 'Không có dữ liệu trong khoảng này';

  @override
  String get partnerInventoryEmptyMessage =>
      'Chưa thiết lập tồn phòng cho các ngày này. Hãy thử khoảng thời gian khác.';

  @override
  String get partnerInventoryDate => 'Ngày';

  @override
  String get partnerInventoryStateColumn => 'Trạng thái';

  @override
  String get partnerInventoryTotal => 'Tổng';

  @override
  String get partnerInventoryAvailable => 'Còn trống';

  @override
  String get partnerInventorySold => 'Đã bán';

  @override
  String get partnerInventoryBlocked => 'Đang giữ';

  @override
  String get partnerInventoryMaintenance => 'Bảo trì';

  @override
  String get partnerInventoryRestrictions => 'Hạn chế';

  @override
  String get partnerInventoryStopSell => 'Ngừng bán';

  @override
  String get partnerInventoryClosedArrival => 'Không nhận khách';

  @override
  String get partnerInventoryClosedDeparture => 'Không trả phòng';

  @override
  String get partnerInventoryStateBookable => 'Có thể đặt';

  @override
  String get partnerInventoryStateSoldOut => 'Hết phòng';

  @override
  String get partnerInventoryStateStopped => 'Đã ngừng bán';

  @override
  String get partnerInventoryInconsistent =>
      'Các số này không cộng lại bằng tổng.';

  @override
  String partnerInventoryInconsistentSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày có các số không cộng lại bằng tổng',
      one: '1 ngày có các số không cộng lại bằng tổng',
    );
    return '$_temp0. Chỉ máy chủ mới sửa được.';
  }

  @override
  String get partnerInventoryEditOwnerOnly =>
      'Thay đổi tình trạng phòng chỉ dành cho chủ hồ sơ. Bạn vẫn xem được lịch tại đây.';

  @override
  String get partnerInventorySaved => 'Đã lưu.';

  @override
  String get partnerInventoryActionNotFound =>
      'Ngày đó không còn khả dụng với tài khoản của bạn.';

  @override
  String partnerRatesForProperty(String name) {
    return 'Giá tại $name';
  }

  @override
  String partnerRatesForRoom(String room, String property) {
    return 'Giá cho $room tại $property';
  }

  @override
  String get partnerRatesNoPropertyContext => 'Chưa chọn cơ sở';

  @override
  String get partnerRatesPropertyScope => 'Phạm vi cơ sở';

  @override
  String get partnerRatesRoomScope => 'Loại phòng';

  @override
  String partnerRatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gói giá',
      one: '1 gói giá',
    );
    return '$_temp0';
  }

  @override
  String partnerRatesActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đang bật',
      one: '1 đang bật',
    );
    return '$_temp0';
  }

  @override
  String partnerRatesExpiredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đã hết hạn',
      one: '1 đã hết hạn',
    );
    return '$_temp0';
  }

  @override
  String get partnerRatesNoPropertiesTitle => 'Chưa có cơ sở nào';

  @override
  String get partnerRatesNoPropertiesMessage =>
      'Giá thuộc về loại phòng trong một cơ sở. Khi hồ sơ của bạn được gán cơ sở, các gói giá sẽ hiển thị tại đây.';

  @override
  String get partnerRatesSelectPropertyTitle => 'Hãy chọn một cơ sở';

  @override
  String get partnerRatesSelectPropertyMessage =>
      'Chọn một cơ sở để xem các gói giá của loại phòng.';

  @override
  String get partnerRatesNoRoomsTitle => 'Chưa có loại phòng nào';

  @override
  String get partnerRatesNoRoomsMessage =>
      'Cơ sở này chưa có loại phòng nên chưa có gì để định giá.';

  @override
  String get partnerRatesSelectRoomTitle => 'Hãy chọn loại phòng';

  @override
  String get partnerRatesSelectRoomMessage =>
      'Gói giá được quản lý theo từng loại phòng. Hãy chọn một loại để xem giá.';

  @override
  String get partnerRatesUnavailableTitle => 'Không xem được giá';

  @override
  String get partnerRatesUnavailableMessage =>
      'Cơ sở hoặc loại phòng này không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerRatesEmptyTitle => 'Chưa có gói giá nào';

  @override
  String get partnerRatesEmptyMessage =>
      'Loại phòng này chưa có gói giá. Việc này do đội ngũ Plan Your Trip thiết lập.';

  @override
  String get partnerRateDetailHeading => 'Chi tiết gói giá';

  @override
  String get partnerRateCloseDetail => 'Đóng chi tiết gói giá';

  @override
  String get partnerRateActionsOwnerOnly =>
      'Thao tác với giá chỉ dành cho chủ hồ sơ. Bạn vẫn xem được mọi gói giá tại đây.';

  @override
  String get partnerRateCurrencyNote =>
      'Số tiền hiển thị không kèm đơn vị tiền tệ vì API giá không cung cấp thông tin này.';

  @override
  String get partnerRateValidityNote =>
      'Cả hai ngày đều được tính: một kỳ lưu trú hợp lệ khi mọi đêm nằm trong khoảng này.';

  @override
  String get partnerRateActive => 'Đang bật';

  @override
  String get partnerRateInactive => 'Đang tắt';

  @override
  String get partnerRateExpired => 'Đã hết hạn';

  @override
  String partnerRatePerNight(String amount) {
    return '$amount mỗi đêm';
  }

  @override
  String partnerRateValidity(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerRatePriorityValue(String value) {
    return 'Ưu tiên $value';
  }

  @override
  String get partnerRateHasRestrictions => 'Có điều kiện';

  @override
  String partnerRateNightsValue(String count) {
    return '$count đêm';
  }

  @override
  String partnerRateDaysValue(String count) {
    return '$count ngày';
  }

  @override
  String get partnerRateActivateAction => 'Bật';

  @override
  String get partnerRateDeactivateAction => 'Tắt';

  @override
  String partnerRateActivatedMessage(String name) {
    return '$name đã được bật.';
  }

  @override
  String partnerRateDeactivatedMessage(String name) {
    return '$name đã được tắt.';
  }

  @override
  String get partnerRateActionNotFound =>
      'Gói giá đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerRateActionConflict =>
      'Thay đổi này xung đột với một gói giá khác.';

  @override
  String get partnerRateTypeStandard => 'Tiêu chuẩn';

  @override
  String get partnerRateTypePromotional => 'Giá khuyến mãi';

  @override
  String get partnerRateTypeMember => 'Thành viên';

  @override
  String get partnerRateTypeEarlyBird => 'Đặt sớm';

  @override
  String get partnerRateTypeLastMinute => 'Phút chót';

  @override
  String get partnerRateTypeUnknown => 'Loại không xác định';

  @override
  String get partnerMealPlanRoomOnly => 'Chỉ phòng';

  @override
  String get partnerMealPlanBreakfast => 'Kèm bữa sáng';

  @override
  String get partnerMealPlanHalfBoard => 'Bán phần';

  @override
  String get partnerMealPlanFullBoard => 'Trọn phần';

  @override
  String get partnerMealPlanAllInclusive => 'Trọn gói';

  @override
  String get partnerMealPlanUnknown => 'Gói ăn không xác định';

  @override
  String get partnerCancellationFree => 'Hủy miễn phí';

  @override
  String get partnerCancellationPartial => 'Hoàn một phần';

  @override
  String get partnerCancellationNonRefundable => 'Không hoàn tiền';

  @override
  String get partnerCancellationCustom => 'Chính sách riêng';

  @override
  String get partnerCancellationUnknown => 'Chính sách không xác định';

  @override
  String get partnerRateSourceBase => 'Giá gốc';

  @override
  String get partnerRateSourceDerived => 'Giá dẫn xuất';

  @override
  String get partnerRateSourceUnknown => 'Nguồn không xác định';

  @override
  String get partnerRateAdjustmentFixed => 'Số tiền cố định';

  @override
  String get partnerRateAdjustmentPercent => 'Phần trăm';

  @override
  String get partnerRateAdjustmentUnknown => 'Điều chỉnh không xác định';

  @override
  String get partnerRateSectionIdentity => 'Thông tin nhận dạng';

  @override
  String get partnerRateSectionPricing => 'Mức giá';

  @override
  String get partnerRateSectionValidity => 'Hiệu lực';

  @override
  String get partnerRateSectionRestrictions => 'Điều kiện lưu trú';

  @override
  String get partnerRateSectionCancellation => 'Hủy phòng';

  @override
  String get partnerRateSectionInclusions => 'Bao gồm';

  @override
  String get partnerRateSectionOccupancy => 'Giá theo số khách';

  @override
  String get partnerRateFieldCode => 'Mã gói';

  @override
  String get partnerRateFieldDescription => 'Mô tả';

  @override
  String get partnerRateFieldPriority => 'Độ ưu tiên';

  @override
  String get partnerRateFieldPricePerNight => 'Giá mỗi đêm';

  @override
  String get partnerRateFieldExtraBedPrice => 'Giá giường phụ';

  @override
  String get partnerRateFieldAdjustmentType => 'Kiểu điều chỉnh';

  @override
  String get partnerRateFieldAdjustmentValue => 'Mức điều chỉnh';

  @override
  String get partnerRateFieldParentPlan => 'Dẫn xuất từ gói';

  @override
  String get partnerRateFieldValidFrom => 'Hiệu lực từ';

  @override
  String get partnerRateFieldValidTo => 'Hiệu lực đến';

  @override
  String get partnerRateFieldMinStay => 'Lưu trú tối thiểu';

  @override
  String get partnerRateFieldMaxStay => 'Lưu trú tối đa';

  @override
  String get partnerRateFieldMinAdvance => 'Đặt trước tối thiểu';

  @override
  String get partnerRateFieldMaxAdvance => 'Đặt trước tối đa';

  @override
  String get partnerRateFieldClosedToArrival => 'Không nhận khách';

  @override
  String get partnerRateFieldClosedToDeparture => 'Không trả phòng';

  @override
  String get partnerRateFieldPolicy => 'Chính sách hủy';

  @override
  String get partnerRateFieldRefundable => 'Được hoàn tiền';

  @override
  String get partnerRateFieldDeadlineHours => 'Hạn hủy (giờ)';

  @override
  String get partnerRateFieldPenaltyPercent => 'Phí phạt khi hủy';

  @override
  String get partnerRateFieldMealPlan => 'Gói ăn';

  @override
  String get partnerRateFieldOccupancyPricing => 'Bật giá theo số khách';

  @override
  String get partnerRateFieldChildPricing => 'Bật giá trẻ em';

  @override
  String get partnerRateOccupancyEmpty =>
      'Gói này chưa cấu hình giá theo số khách.';

  @override
  String partnerRateOccupancyLabel(String adults, String children) {
    return '$adults người lớn, $children trẻ em';
  }

  @override
  String get partnerPoliciesTitle => 'Chính sách & cài đặt';

  @override
  String partnerPoliciesForProperty(String name) {
    return 'Chính sách của $name';
  }

  @override
  String get partnerPoliciesNoPropertyContext => 'Chưa chọn cơ sở';

  @override
  String get partnerPoliciesPropertyScope => 'Phạm vi cơ sở';

  @override
  String get partnerPoliciesNoPropertiesTitle => 'Chưa có cơ sở nào';

  @override
  String get partnerPoliciesNoPropertiesMessage =>
      'Chính sách với khách thuộc về một cơ sở. Khi hồ sơ của bạn được gán cơ sở, chính sách sẽ hiển thị tại đây.';

  @override
  String get partnerPoliciesSelectPropertyTitle => 'Hãy chọn một cơ sở';

  @override
  String get partnerPoliciesSelectPropertyMessage =>
      'Chọn một cơ sở để xem và chỉnh sửa chính sách với khách.';

  @override
  String get partnerPoliciesUnavailableTitle => 'Không xem được chính sách';

  @override
  String get partnerPoliciesUnavailableMessage =>
      'Cơ sở này không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerPoliciesPropertySection => 'Chính sách với khách';

  @override
  String get partnerPoliciesPropertyScopeNote =>
      'Chỉ áp dụng cho cơ sở này. Khách sẽ thấy nội dung này trên trang cơ sở.';

  @override
  String get partnerPoliciesLiveWarning =>
      'Thay đổi có hiệu lực ngay với mọi khách, kể cả khách đã đặt phòng — hệ thống không cố định chính sách tại thời điểm đặt.';

  @override
  String get partnerPoliciesOwnerOnly =>
      'Chỉ chủ hồ sơ mới thay đổi được chính sách với khách. Bạn vẫn xem được tại đây.';

  @override
  String get partnerPoliciesCheckIn => 'Nhận phòng từ';

  @override
  String get partnerPoliciesCheckOut => 'Trả phòng trước';

  @override
  String get partnerPoliciesTimeHelper => 'Giờ 24 tiếng, ví dụ 14:00';

  @override
  String get partnerPoliciesTimeRequired => 'Bắt buộc';

  @override
  String get partnerPoliciesHouseRules => 'Nội quy';

  @override
  String get partnerPoliciesHouseRulesNote =>
      'Không bắt buộc. Để trống để xóa một nội quy.';

  @override
  String get partnerPoliciesRuleHint => 'Để trống nếu không có nội quy';

  @override
  String get partnerPoliciesChildren => 'Chính sách trẻ em';

  @override
  String get partnerPoliciesPets => 'Chính sách thú cưng';

  @override
  String get partnerPoliciesSmoking => 'Chính sách hút thuốc';

  @override
  String get partnerPoliciesSettingsSection => 'Thông báo của tài khoản';

  @override
  String get partnerPoliciesSettingsScopeNote =>
      'Áp dụng cho toàn bộ tài khoản đối tác, không riêng một cơ sở.';

  @override
  String get partnerPoliciesSettingsRoleNote =>
      'Chỉ chủ hồ sơ hoặc quản lý mới thay đổi được cài đặt thông báo. Bạn vẫn xem được tại đây.';

  @override
  String get partnerPoliciesSettingsUnavailable =>
      'Không truy cập được cài đặt tài khoản của bạn.';

  @override
  String partnerPoliciesSettingsUpdated(String time) {
    return 'Cập nhật lần cuối $time';
  }

  @override
  String get partnerPoliciesLanguage => 'Ngôn ngữ mặc định';

  @override
  String get partnerPoliciesTimezone => 'Múi giờ';

  @override
  String get partnerPoliciesChannels => 'Kênh nhận thông báo';

  @override
  String get partnerPoliciesChannelEmail => 'Email';

  @override
  String get partnerPoliciesChannelSms => 'SMS';

  @override
  String get partnerPoliciesChannelInApp => 'Trong ứng dụng';

  @override
  String get partnerPoliciesTopics => 'Nội dung muốn nhận thông báo';

  @override
  String get partnerPoliciesTopicBooking => 'Đặt phòng';

  @override
  String get partnerPoliciesTopicPayment => 'Thanh toán';

  @override
  String get partnerPoliciesTopicReview => 'Đánh giá';

  @override
  String get partnerPoliciesTopicPromotion => 'Ưu đãi';

  @override
  String get partnerPoliciesSave => 'Lưu thay đổi';

  @override
  String get partnerPoliciesRevert => 'Hủy bỏ';

  @override
  String get partnerPoliciesNoChanges => 'Không có thay đổi chưa lưu.';

  @override
  String get partnerPoliciesSaved => 'Đã lưu.';

  @override
  String get partnerPoliciesSaveForbidden =>
      'Vai trò của bạn không cho phép thay đổi này.';

  @override
  String get partnerPoliciesSaveNotFound =>
      'Bản ghi đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerPoliciesSaveValidation =>
      'Bắt buộc nhập cả giờ nhận phòng và giờ trả phòng.';

  @override
  String get partnerAssetsSection => 'Ảnh & phương tiện';

  @override
  String get partnerAssetsDeferredBadge => 'Chưa khả dụng';

  @override
  String get partnerAssetsDeferredMessage =>
      'Quản lý ảnh không nằm trong API dành cho đối tác. Việc tải lên, thay thế, sắp xếp và xóa ảnh chỉ dành cho quản trị viên, nên đội ngũ Plan Your Trip sẽ duy trì ảnh cho cơ sở của bạn.';

  @override
  String get partnerPromotionsTitle => 'Khuyến mãi & voucher';

  @override
  String get partnerPromotionsTabPromotions => 'Quy tắc khuyến mãi';

  @override
  String get partnerPromotionsTabVoucherCheck => 'Kiểm tra voucher';

  @override
  String get partnerPromotionsScopeNote =>
      'Tại đây liệt kê mọi khuyến mãi thuộc bất kỳ cơ sở hoặc phòng nào bạn sở hữu. API đối tác không giới hạn khuyến mãi theo từng cơ sở, nên danh sách này không lọc theo cơ sở bạn đang chọn.';

  @override
  String partnerPromotionsCount(int count) {
    return '$count khuyến mãi';
  }

  @override
  String partnerPromotionsActiveCount(int count) {
    return '$count đang bật';
  }

  @override
  String partnerPromotionsExpiredCount(int count) {
    return '$count đã qua ngày kết thúc';
  }

  @override
  String get partnerPromotionsCurrencyNote =>
      'API khuyến mãi không trả về đơn vị tiền tệ, nên số tiền khuyến mãi hiển thị không kèm ký hiệu. Phần xem trước giá bên dưới có đơn vị tiền tệ riêng và sẽ hiển thị nó.';

  @override
  String get partnerPromotionsEmptyTitle => 'Chưa có khuyến mãi nào';

  @override
  String get partnerPromotionsEmptyMessage =>
      'Hiện chưa có khuyến mãi nào áp dụng cho cơ sở hoặc phòng của bạn. Các chiến dịch toàn hệ thống do Plan Your Trip vận hành không hiển thị ở đây vì bạn không quản lý chúng.';

  @override
  String get partnerPromotionsOwnerOnly =>
      'Chỉ chủ tài khoản đối tác mới thay đổi được khuyến mãi. Bạn vẫn có thể xem tại đây.';

  @override
  String get partnerPromotionDetailHeading => 'Chi tiết khuyến mãi';

  @override
  String get partnerPromotionCloseDetail => 'Đóng chi tiết khuyến mãi';

  @override
  String get partnerPromotionSectionIdentity => 'Thông tin nhận dạng';

  @override
  String get partnerPromotionFieldCode => 'Mã khuyến mãi';

  @override
  String get partnerPromotionFieldDescription => 'Mô tả';

  @override
  String get partnerPromotionFieldType => 'Loại khuyến mãi';

  @override
  String get partnerPromotionSectionDiscount => 'Mức giảm';

  @override
  String get partnerPromotionFieldDiscountType => 'Kiểu giảm giá';

  @override
  String get partnerPromotionFieldDiscountValue => 'Giá trị giảm';

  @override
  String get partnerPromotionFieldMaxDiscount => 'Mức giảm tối đa';

  @override
  String get partnerPromotionSectionValidity => 'Thời hạn áp dụng';

  @override
  String get partnerPromotionFieldStart => 'Bắt đầu';

  @override
  String get partnerPromotionFieldEnd => 'Kết thúc';

  @override
  String get partnerPromotionSectionConditions => 'Điều kiện';

  @override
  String get partnerPromotionFieldMinimumStay => 'Số đêm tối thiểu';

  @override
  String get partnerPromotionFieldMinimumSpend => 'Chi tiêu tối thiểu';

  @override
  String get partnerPromotionSectionApplication => 'Cách áp dụng';

  @override
  String get partnerPromotionFieldTarget => 'Áp dụng cho';

  @override
  String get partnerPromotionFieldPriority => 'Độ ưu tiên';

  @override
  String get partnerPromotionFieldStackable => 'Cộng dồn với khuyến mãi khác';

  @override
  String get partnerPromotionStackableNote =>
      'Bộ tính giá có thể áp dụng thêm khuyến mãi khác sau khuyến mãi này.';

  @override
  String get partnerPromotionNonStackableNote =>
      'Bộ tính giá áp dụng khuyến mãi này rồi dừng lại, nên không cộng thêm khuyến mãi có độ ưu tiên thấp hơn.';

  @override
  String get partnerPromotionActive => 'Đang bật';

  @override
  String get partnerPromotionInactive => 'Đang tắt';

  @override
  String get partnerPromotionExpired => 'Đã qua ngày kết thúc';

  @override
  String get partnerPromotionScheduled => 'Bắt đầu sau';

  @override
  String get partnerPromotionExclusivePill => 'Không cộng dồn';

  @override
  String partnerPromotionValidity(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerPromotionPriorityValue(String count) {
    return 'Ưu tiên $count';
  }

  @override
  String get partnerPromotionHasConditions => 'Có điều kiện kèm theo';

  @override
  String get partnerPromotionActivateAction => 'Bật';

  @override
  String get partnerPromotionDeactivateAction => 'Tắt';

  @override
  String get partnerPromotionTypeGeneral => 'Chung';

  @override
  String get partnerPromotionTypeRoom => 'Ưu đãi phòng';

  @override
  String get partnerPromotionTypeHotel => 'Ưu đãi cơ sở';

  @override
  String get partnerPromotionTypeMember => 'Thành viên';

  @override
  String get partnerPromotionTypeEarlyBird => 'Đặt sớm';

  @override
  String get partnerPromotionTypeLastMinute => 'Đặt sát ngày';

  @override
  String get partnerPromotionTypeWeekend => 'Cuối tuần';

  @override
  String get partnerPromotionTypeHoliday => 'Ngày lễ';

  @override
  String get partnerPromotionTypeUnknown => 'Loại không xác định';

  @override
  String get partnerDiscountTypePercentage => 'Theo phần trăm';

  @override
  String get partnerDiscountTypeFixed => 'Số tiền cố định';

  @override
  String get partnerDiscountTypeUnknown => 'Kiểu giảm giá không xác định';

  @override
  String get partnerPromotionTargetAll => 'Mọi cơ sở trên Plan Your Trip';

  @override
  String get partnerPromotionTargetHotel => 'Một cơ sở của bạn';

  @override
  String get partnerPromotionTargetRoom => 'Một phòng của bạn';

  @override
  String partnerPromotionTargetRoomNamed(String name) {
    return 'Phòng: $name';
  }

  @override
  String get partnerPromotionTargetUnknown => 'Đối tượng không xác định';

  @override
  String get partnerPromotionPreviewHeading => 'Xem trước giá';

  @override
  String get partnerPromotionPreviewNote =>
      'Máy chủ tính toán phần này. Mọi số tiền và mọi khuyến mãi được áp dụng đều đến trực tiếp từ bộ tính giá — ứng dụng không tự tính bất kỳ con số nào.';

  @override
  String get partnerPromotionPreviewAction => 'Chạy xem trước';

  @override
  String get partnerPromotionPreviewInvalidRange =>
      'Ngày trả phòng phải sau ngày nhận phòng.';

  @override
  String partnerPromotionPreviewStay(String from, String to, String nights) {
    return '$from đến $to · $nights đêm';
  }

  @override
  String get partnerPromotionPreviewBase => 'Giá gốc';

  @override
  String get partnerPromotionPreviewRatePlan => 'Giá theo gói giá';

  @override
  String partnerPromotionPreviewRatePlanNamed(String name) {
    return 'Gói giá: $name';
  }

  @override
  String get partnerPromotionPreviewDiscount => 'Số tiền khuyến mãi giảm';

  @override
  String get partnerPromotionPreviewTotal => 'Tổng cho kỳ lưu trú này';

  @override
  String get partnerPromotionPreviewAppliedHeading =>
      'Khuyến mãi mà bộ tính giá đã áp dụng';

  @override
  String get partnerPromotionPreviewNoneApplied =>
      'Bộ tính giá không áp dụng khuyến mãi nào cho kỳ lưu trú này.';

  @override
  String get partnerPromotionPreviewUnnamed => 'Khuyến mãi không tên';

  @override
  String partnerPromotionPreviewAppliedAmount(String amount) {
    return '-$amount';
  }

  @override
  String partnerPromotionActivatedMessage(String name) {
    return '$name đã được bật.';
  }

  @override
  String partnerPromotionDeactivatedMessage(String name) {
    return '$name đã được tắt.';
  }

  @override
  String get partnerPromotionActionNotFound =>
      'Khuyến mãi đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerPromotionActionConflict =>
      'Mã khuyến mãi đó đã được dùng. Mã khuyến mãi là duy nhất trên toàn Plan Your Trip.';

  @override
  String get partnerPromotionActionValidation =>
      'Máy chủ đã từ chối khuyến mãi này. Không có gì thay đổi.';

  @override
  String get partnerPromotionActionIncomplete =>
      'Khuyến mãi này thiếu những trường mà thao tác cập nhật cần, nên không có yêu cầu nào được gửi đi. Hãy liên hệ bộ phận hỗ trợ để thay đổi.';

  @override
  String get partnerVoucherCheckHeading => 'Kiểm tra voucher đặt phòng';

  @override
  String get partnerVoucherCheckNote =>
      'Đây là vé xác nhận đặt phòng, không phải mã giảm giá. Việc kiểm tra chỉ xác nhận đặt phòng của khách — không nhận phòng cho ai và không thay đổi dữ liệu.';

  @override
  String get partnerVoucherCheckField => 'Chuỗi voucher';

  @override
  String get partnerVoucherCheckAction => 'Kiểm tra voucher';

  @override
  String get partnerVoucherCheckClear => 'Xóa';

  @override
  String get partnerVoucherEligibleTitle => 'Hợp lệ — có thể đón khách';

  @override
  String get partnerVoucherEligibleMessage =>
      'Chữ ký hợp lệ và đặt phòng này đã sẵn sàng nhận phòng.';

  @override
  String get partnerVoucherNotEligibleTitle =>
      'Hợp lệ — nhưng chưa thể nhận phòng';

  @override
  String get partnerVoucherNotEligibleMessage =>
      'Chữ ký hợp lệ, nhưng đặt phòng này hiện chưa thể nhận phòng.';

  @override
  String get partnerVoucherNotRecognisedTitle => 'Không nhận diện được';

  @override
  String get partnerVoucherNotRecognisedMessage =>
      'Máy chủ không nhận diện voucher này cho tài khoản của bạn. Voucher có thể đã bị sửa, không tồn tại, hoặc thuộc về đối tác khác — máy chủ không cho biết trường hợp nào.';

  @override
  String get partnerVoucherEmptyTitle => 'Chưa có gì để kiểm tra';

  @override
  String get partnerVoucherEmptyMessage =>
      'Hãy dán hoặc quét chuỗi voucher trước.';

  @override
  String get partnerVoucherFailedTitle => 'Không kiểm tra được voucher này';

  @override
  String get partnerVoucherFieldBooking => 'Mã đặt phòng';

  @override
  String get partnerVoucherFieldBookingStatus => 'Trạng thái đặt phòng';

  @override
  String get partnerVoucherFieldGuest => 'Tên khách';

  @override
  String get partnerVoucherFieldProperty => 'Cơ sở đã đặt';

  @override
  String get partnerVoucherFieldRoom => 'Phòng đã đặt';

  @override
  String get partnerVoucherFieldStay => 'Kỳ lưu trú';

  @override
  String get partnerVoucherFieldOccupancy => 'Số khách';

  @override
  String partnerVoucherStayValue(String from, String to, String nights) {
    return '$from đến $to · $nights đêm';
  }

  @override
  String partnerVoucherOccupancyValue(String adults, String children) {
    return '$adults người lớn · $children trẻ em';
  }

  @override
  String get partnerVoucherReadOnlyNote =>
      'Chỉ kiểm tra. Việc nhận phòng thực hiện trên đặt phòng, không phải trên màn hình này.';

  @override
  String get partnerBookingsTitle => 'Đặt chỗ & lễ tân';

  @override
  String get partnerBookingsTabReservations => 'Danh sách đặt chỗ';

  @override
  String get partnerBookingsTabFrontDesk => 'Lễ tân';

  @override
  String get partnerBookingsScopeNote =>
      'Danh sách này gồm mọi đặt chỗ ở tất cả cơ sở bạn sở hữu. API đối tác không nhận tham số cơ sở, nên danh sách không lọc theo cơ sở bạn đang chọn — hãy lọc theo phòng để tập trung vào một cơ sở.';

  @override
  String get partnerBookingsEmptyTitle => 'Chưa có đặt chỗ nào';

  @override
  String get partnerBookingsEmptyMessage =>
      'Chưa có ai đặt chỗ tại các cơ sở của bạn. Đặt chỗ mới sẽ xuất hiện ở đây ngay khi khách đặt.';

  @override
  String get partnerBookingsNoMatchTitle => 'Không có đặt chỗ nào khớp bộ lọc';

  @override
  String get partnerBookingsNoMatchMessage =>
      'Không có kết quả nào khớp với bộ lọc bạn đã đặt. Hãy xóa bộ lọc để xem lại toàn bộ.';

  @override
  String get partnerBookingDetailHeading => 'Chi tiết đặt chỗ';

  @override
  String get partnerBookingCloseDetail => 'Đóng chi tiết đặt chỗ';

  @override
  String get partnerBookingNotFound =>
      'Đặt chỗ đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerBookingColumnCode => 'Mã đặt chỗ';

  @override
  String get partnerBookingColumnGuest => 'Khách';

  @override
  String get partnerBookingColumnRoom => 'Loại phòng';

  @override
  String get partnerBookingColumnCheckIn => 'Nhận phòng';

  @override
  String get partnerBookingColumnCheckOut => 'Trả phòng';

  @override
  String get partnerBookingColumnNights => 'Số đêm';

  @override
  String get partnerBookingColumnStatus => 'Trạng thái';

  @override
  String get partnerBookingColumnTotal => 'Tổng tiền';

  @override
  String partnerBookingStayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerBookingNightsValue(String count) {
    return '$count đêm';
  }

  @override
  String partnerBookingOccupancyValue(String adults, String children) {
    return '$adults người lớn · $children trẻ em';
  }

  @override
  String partnerBookingNightProgressValue(String current, String total) {
    return 'Đêm $current trên $total';
  }

  @override
  String get partnerBookingStatusPending => 'Chờ xử lý';

  @override
  String get partnerBookingStatusConfirmed => 'Đã xác nhận';

  @override
  String get partnerBookingStatusCheckInReady => 'Sẵn sàng nhận phòng';

  @override
  String get partnerBookingStatusCheckedIn => 'Đã nhận phòng';

  @override
  String get partnerBookingStatusCheckedOut => 'Đã trả phòng';

  @override
  String get partnerBookingStatusCompleted => 'Đã hoàn tất';

  @override
  String get partnerBookingStatusCancelled => 'Đã hủy';

  @override
  String get partnerBookingStatusRefunded => 'Đã hoàn tiền';

  @override
  String get partnerBookingStatusArchived => 'Đã lưu trữ';

  @override
  String get partnerBookingStatusNoShow => 'Khách không đến';

  @override
  String get partnerBookingStatusUnknown => 'Trạng thái không xác định';

  @override
  String get partnerStayStateUpcoming => 'Kỳ lưu trú sắp tới';

  @override
  String get partnerStayStateReady => 'Sẵn sàng nhận phòng';

  @override
  String get partnerStayStateInHouse => 'Đang lưu trú';

  @override
  String get partnerStayStateCheckedOut => 'Đã rời đi';

  @override
  String get partnerStayStateCompleted => 'Kỳ lưu trú đã hoàn tất';

  @override
  String get partnerStayStateCancelled => 'Kỳ lưu trú đã hủy';

  @override
  String get partnerStayStateNoShow => 'Khách đã không đến';

  @override
  String get partnerStayStateExpired => 'Đã quá thời hạn';

  @override
  String get partnerStayStateUnknown => 'Trạng thái lưu trú không xác định';

  @override
  String get partnerStayWarningCancelled =>
      'Kỳ lưu trú này đã bị hủy, đã hoàn tiền, hoặc được ghi nhận là khách không đến.';

  @override
  String get partnerStayWarningCompleted => 'Kỳ lưu trú này đã kết thúc.';

  @override
  String get partnerStayWarningInHouse => 'Khách đang lưu trú.';

  @override
  String get partnerStayWarningCheckOutOverdue =>
      'Quá hạn trả phòng — đã qua ngày trả phòng nhưng khách vẫn đang ở trạng thái đã nhận phòng.';

  @override
  String get partnerStayWarningFuture => 'Kỳ lưu trú chưa bắt đầu.';

  @override
  String get partnerStayWarningCheckInOverdue =>
      'Quá hạn nhận phòng — đã qua ngày đến nhưng khách chưa nhận phòng.';

  @override
  String get partnerStayWarningUnknown =>
      'Máy chủ báo một cảnh báo mà ứng dụng chưa nhận diện được.';

  @override
  String get partnerBookingFilterGuest => 'Tên hoặc email khách';

  @override
  String get partnerBookingFilterGuestName => 'Tên khách';

  @override
  String get partnerBookingFilterGuestEmail => 'Email khách';

  @override
  String get partnerBookingFilterCode => 'Mã đặt chỗ';

  @override
  String get partnerBookingFilterStatus => 'Trạng thái đặt chỗ';

  @override
  String get partnerBookingFilterAnyStatus => 'Mọi trạng thái';

  @override
  String get partnerBookingFilterRoom => 'Theo phòng';

  @override
  String get partnerBookingFilterAnyRoom => 'Mọi phòng';

  @override
  String get partnerBookingFilterDates => 'Ngày đến';

  @override
  String get partnerBookingFilterClear => 'Xóa bộ lọc';

  @override
  String get partnerBookingFilterArrivals => 'Đến hôm nay';

  @override
  String get partnerBookingFilterDepartures => 'Rời hôm nay';

  @override
  String get partnerBookingFilterUpcoming => 'Sắp tới';

  @override
  String get partnerBookingFilterInHouse => 'Đang lưu trú';

  @override
  String get partnerBookingFilterCancelled => 'Đã hủy';

  @override
  String get partnerBookingFilterCompleted => 'Đã hoàn tất';

  @override
  String partnerBookingFilterRangeBoth(String from, String to) {
    return 'Đến từ $from tới $to';
  }

  @override
  String partnerBookingFilterRangeFrom(String from) {
    return 'Đến từ ngày $from trở đi';
  }

  @override
  String partnerBookingFilterRangeTo(String to) {
    return 'Đến vào hoặc trước ngày $to';
  }

  @override
  String partnerBookingPageRange(String from, String to, String total) {
    return 'Hiển thị $from-$to trên $total';
  }

  @override
  String partnerBookingPagePosition(String page, String total) {
    return 'Trang $page trên $total';
  }

  @override
  String get partnerBookingPagePrevious => 'Trang trước';

  @override
  String get partnerBookingPageNext => 'Trang sau';

  @override
  String get partnerBookingSectionGuest => 'Khách';

  @override
  String get partnerBookingSectionStay => 'Kỳ lưu trú';

  @override
  String get partnerBookingSectionRoom => 'Cơ sở & phòng';

  @override
  String get partnerBookingSectionPrice => 'Giá đặt chỗ';

  @override
  String get partnerBookingSectionRatePlan => 'Gói giá được ghi nhận khi đặt';

  @override
  String get partnerBookingSectionPayment => 'Thanh toán & hóa đơn';

  @override
  String get partnerBookingSectionTimeline => 'Dòng thời gian vòng đời';

  @override
  String get partnerBookingSectionModifications => 'Lịch sử thay đổi';

  @override
  String get partnerBookingSectionAudit => 'Bản ghi nhận & trả phòng';

  @override
  String get partnerBookingFieldGuestName => 'Tên khách';

  @override
  String get partnerBookingFieldGuestEmail => 'Email khách';

  @override
  String get partnerBookingFieldOccupancy => 'Số khách';

  @override
  String get partnerBookingFieldSpecialRequest => 'Yêu cầu đặc biệt';

  @override
  String get partnerBookingFieldCheckIn => 'Ngày nhận phòng';

  @override
  String get partnerBookingFieldCheckOut => 'Ngày trả phòng';

  @override
  String get partnerBookingFieldNights => 'Số đêm đã đặt';

  @override
  String get partnerBookingFieldNightProgress => 'Tiến độ lưu trú';

  @override
  String get partnerBookingFieldActualCheckIn => 'Thời điểm nhận phòng thực tế';

  @override
  String get partnerBookingFieldActualCheckOut => 'Thời điểm trả phòng thực tế';

  @override
  String get partnerBookingFieldProperty => 'Cơ sở đã đặt';

  @override
  String get partnerBookingFieldRoom => 'Phòng đã đặt';

  @override
  String get partnerBookingFieldRoomCode => 'Mã phòng';

  @override
  String get partnerBookingFieldRoomCount => 'Số phòng đã đặt';

  @override
  String get partnerBookingFieldBasePrice => 'Giá gốc';

  @override
  String get partnerBookingFieldRatePlanPrice => 'Giá theo gói giá';

  @override
  String get partnerBookingFieldDiscount => 'Mức giảm đã áp dụng';

  @override
  String get partnerBookingFieldTotal => 'Tổng đã tính';

  @override
  String get partnerBookingPriceNote =>
      'Mọi số tiền ở đây do máy chủ tính và lưu lại vào thời điểm đặt chỗ. Ứng dụng không tính lại bất kỳ con số nào.';

  @override
  String get partnerBookingFieldRatePlanName => 'Gói giá';

  @override
  String get partnerBookingFieldRatePlanCode => 'Mã gói giá';

  @override
  String get partnerBookingFieldMealPlan => 'Gói bữa ăn';

  @override
  String get partnerBookingFieldCancellationPolicy => 'Chính sách hủy';

  @override
  String get partnerBookingFieldCancellationDeadline => 'Hạn hủy miễn phí';

  @override
  String get partnerBookingFieldRefundable => 'Được hoàn tiền';

  @override
  String get partnerBookingFieldNightlySnapshot => 'Giá mỗi đêm đã ghi nhận';

  @override
  String get partnerBookingSnapshotNote =>
      'Các giá trị này được ghi nhận vào lúc đặt chỗ. Việc chỉnh sửa gói giá hôm nay không làm thay đổi chúng.';

  @override
  String get partnerBookingNoPayments =>
      'Chưa ghi nhận khoản thanh toán nào cho đặt chỗ này.';

  @override
  String get partnerBookingPaymentUnnamed => 'Thanh toán';

  @override
  String get partnerBookingFieldInvoice => 'Số hóa đơn';

  @override
  String get partnerBookingFieldInvoiceStatus => 'Trạng thái hóa đơn';

  @override
  String get partnerBookingFieldInvoiceTotal => 'Tổng hóa đơn';

  @override
  String get partnerBookingPaymentReadOnlyNote =>
      'Thông tin thanh toán chỉ để xem. API đối tác không có thao tác thanh toán, hoàn tiền hay đối soát, và mã thẻ cùng mã giao dịch của cổng thanh toán không bao giờ được gửi tới màn hình này.';

  @override
  String get partnerBookingTimelineEmpty =>
      'Máy chủ không ghi nhận sự kiện vòng đời nào cho đặt chỗ này.';

  @override
  String get partnerBookingEventCreated => 'Đã tạo đặt chỗ';

  @override
  String get partnerBookingEventPaid => 'Đã thanh toán xong';

  @override
  String get partnerBookingEventConfirmed => 'Đã xác nhận đặt chỗ';

  @override
  String get partnerBookingEventCheckedIn => 'Khách đã nhận phòng';

  @override
  String get partnerBookingEventCheckedOut => 'Khách đã trả phòng';

  @override
  String get partnerBookingEventCompleted => 'Đã hoàn tất đặt chỗ';

  @override
  String get partnerBookingEventCancelled => 'Đã hủy đặt chỗ';

  @override
  String get partnerBookingEventArchived => 'Đã lưu trữ đặt chỗ';

  @override
  String get partnerBookingEventModified => 'Đã thay đổi đặt chỗ';

  @override
  String get partnerBookingEventReview => 'Khách đã gửi đánh giá';

  @override
  String get partnerBookingModificationNote =>
      'Khách tự thay đổi đặt chỗ của mình. Đây là bản ghi những gì đã thay đổi — API đối tác không cho phép thay đổi đặt chỗ từ đây.';

  @override
  String get partnerBookingModificationDates => 'Ngày';

  @override
  String get partnerBookingModificationOccupancy => 'Số khách';

  @override
  String get partnerBookingModificationRatePlan => 'Gói giá';

  @override
  String get partnerBookingModificationPrice => 'Giá tiền';

  @override
  String get partnerBookingNoAudit =>
      'Chưa ghi nhận việc nhận phòng hay trả phòng cho đặt chỗ này.';

  @override
  String get partnerBookingAuditCheckIn => 'Đã ghi nhận nhận phòng';

  @override
  String get partnerBookingAuditCheckOut => 'Đã ghi nhận trả phòng';

  @override
  String partnerBookingAuditByUser(String userId) {
    return 'Nhân viên #$userId';
  }

  @override
  String get partnerBookingActionCheckIn => 'Nhận phòng';

  @override
  String get partnerBookingActionCheckOut => 'Trả phòng';

  @override
  String get partnerBookingActionNoShow => 'Đánh dấu khách không đến';

  @override
  String get partnerBookingActionComplete => 'Hoàn tất đặt chỗ';

  @override
  String get partnerBookingActionsIrreversibleNote =>
      'Những thay đổi này không thể hoàn tác từ trang đối tác, và khách sẽ nhận được thông báo.';

  @override
  String get partnerBookingNoActionsAvailable =>
      'Không có thao tác vận hành nào khả dụng với trạng thái hiện tại của đặt chỗ này.';

  @override
  String get partnerBookingNoActionsClosed =>
      'Đặt chỗ này đã khép lại nên không còn thao tác vận hành nào.';

  @override
  String partnerBookingActionConfirm(String action, String code) {
    return '$action cho đặt chỗ $code? Thao tác này không thể hoàn tác từ trang đối tác, và khách sẽ nhận được thông báo.';
  }

  @override
  String get partnerBookingActionConfirmCta => 'Xác nhận';

  @override
  String get partnerBookingActionCancel => 'Hủy bỏ';

  @override
  String partnerBookingActionSucceeded(String action, String code) {
    return 'Đã $action cho đặt chỗ $code.';
  }

  @override
  String get partnerBookingActionRejected =>
      'Máy chủ từ chối thay đổi đó với trạng thái hiện tại của đặt chỗ. Không có gì thay đổi.';

  @override
  String get partnerBookingActionValidation =>
      'Máy chủ đã từ chối yêu cầu đó. Không có gì thay đổi.';

  @override
  String get partnerBookingActionUncertain =>
      'Kết nối bị ngắt trước khi máy chủ xác nhận, và thay đổi này không thể hoàn tác. Hãy làm mới để xem trạng thái hiện tại trước khi thử lại.';

  @override
  String get partnerFrontDeskHeading => 'Nhận hoặc trả phòng cho khách';

  @override
  String get partnerFrontDeskNote =>
      'Quét mã QR voucher của khách hoặc nhập mã đặt chỗ. Thao tác này thay đổi đặt chỗ và gửi thông báo cho khách.';

  @override
  String get partnerFrontDeskField => 'Chuỗi voucher hoặc mã đặt chỗ';

  @override
  String get partnerFrontDeskFieldHelp =>
      'Voucher được quét sẽ ghi nhận là quét QR; mã đặt chỗ nhập tay sẽ ghi nhận là thủ công.';

  @override
  String get partnerFrontDeskCheckInAction => 'Cho khách nhận phòng';

  @override
  String get partnerFrontDeskCheckOutAction => 'Cho khách trả phòng';

  @override
  String get partnerFrontDeskClear => 'Xóa';

  @override
  String partnerFrontDeskConfirm(String code) {
    return 'Tiếp tục với $code? Thao tác này thay đổi đặt chỗ, gửi thông báo cho khách và không thể hoàn tác từ trang đối tác.';
  }

  @override
  String get partnerFrontDeskCheckedInTitle => 'Khách đã nhận phòng';

  @override
  String get partnerFrontDeskCheckedOutTitle => 'Khách đã trả phòng';

  @override
  String get partnerFrontDeskIdempotentNote =>
      'Thực hiện lại thao tác này trên cùng một đặt chỗ là an toàn: máy chủ giữ nguyên thời điểm ban đầu và không ghi nhận trùng lặp.';

  @override
  String get partnerFrontDeskNotRecognisedTitle => 'Không nhận diện được';

  @override
  String get partnerFrontDeskNotRecognisedMessage =>
      'Máy chủ không nhận diện voucher hoặc mã đặt chỗ đó cho tài khoản của bạn. Nó có thể đã bị sửa, không tồn tại, hoặc thuộc về đối tác khác — máy chủ không cho biết trường hợp nào.';

  @override
  String get partnerFrontDeskRejectedTitle => 'Chưa thể thực hiện';

  @override
  String get partnerFrontDeskRejectedMessage =>
      'Trạng thái hoặc ngày của đặt chỗ này hiện chưa cho phép thao tác đó. Không có gì thay đổi.';

  @override
  String get partnerFrontDeskInvalidTitle => 'Chưa có gì để gửi';

  @override
  String get partnerFrontDeskInvalidMessage =>
      'Hãy quét hoặc nhập chuỗi voucher hay mã đặt chỗ trước.';

  @override
  String get partnerFrontDeskFailedTitle => 'Không thể hoàn tất thao tác này';

  @override
  String get partnerFrontDeskUncertainTitle => 'Chưa rõ kết quả';

  @override
  String get partnerFrontDeskUncertainMessage =>
      'Kết nối bị ngắt trước khi máy chủ xác nhận. Hãy kiểm tra trạng thái đặt chỗ — nếu thao tác chưa thành công thì chạy lại là an toàn.';

  @override
  String get partnerCalendarTitle => 'Lịch & tồn phòng';

  @override
  String get partnerCalendarTabOverview => 'Lịch cơ sở';

  @override
  String get partnerCalendarTabInventory => 'Tồn phòng theo phòng';

  @override
  String get partnerCalendarScopeNote =>
      'Toàn bộ phòng của cơ sở đang chọn, theo từng đêm. Các số liệu lấy từ chính những bản ghi tồn phòng mà tab Tồn phòng chỉnh sửa — màn hình này chỉ đọc.';

  @override
  String partnerCalendarWindowRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get partnerCalendarPreviousWeek => 'Tuần trước';

  @override
  String get partnerCalendarNextWeek => 'Tuần sau';

  @override
  String get partnerCalendarToday => 'Hôm nay';

  @override
  String get partnerCalendarNoRoomsTitle => 'Cơ sở này chưa có phòng nào';

  @override
  String get partnerCalendarNoRoomsMessage =>
      'Chưa có gì để lên lịch cho tới khi cơ sở có ít nhất một phòng. Phòng được quản lý trong mục Phòng.';

  @override
  String get partnerCalendarWindowEmptyMessage =>
      'Không có bản ghi tồn phòng nào cho bất kỳ phòng nào trong khoảng ngày này. Đêm không có bản ghi thì không thể bán, vì máy chủ đếm số bản ghi và từ chối kỳ lưu trú nếu thiếu bất kỳ đêm nào.';

  @override
  String partnerCalendarRoomsFailed(String failed, String total) {
    return 'Không tải được lịch của $failed trên $total phòng. Những hàng đó hiển thị là không đọc được, không phải là trống.';
  }

  @override
  String partnerCalendarRoomFailed(String room) {
    return 'Không tải được $room.';
  }

  @override
  String get partnerCalendarStateOpen => 'Đang mở bán';

  @override
  String get partnerCalendarStateSoldOut => 'Đã hết phòng';

  @override
  String get partnerCalendarStateStopSell => 'Ngừng bán';

  @override
  String get partnerCalendarStateNoRecord => 'Không có bản ghi';

  @override
  String get partnerCalendarLegendHeading => 'Mỗi đêm hiển thị điều gì';

  @override
  String get partnerCalendarLegendClosedArrival => 'Chặn nhận phòng';

  @override
  String get partnerCalendarLegendClosedDeparture => 'Chặn trả phòng';

  @override
  String get partnerCalendarLegendOccupied => 'Số phòng đã bán';

  @override
  String get partnerCalendarLegendNote =>
      'Con số trên mỗi đêm là số phòng còn trống. Chặn nhận phòng khiến kỳ lưu trú không được bắt đầu vào đêm đó; chặn trả phòng khiến kỳ lưu trú không được kết thúc ở đêm đó. Cả hai đều không ngăn đêm đó được bán trong một kỳ lưu trú dài hơn.';

  @override
  String partnerCalendarSoldValue(String count) {
    return 'đã bán $count';
  }

  @override
  String get partnerCalendarMetricSellable => 'đêm đang mở bán';

  @override
  String get partnerCalendarMetricOccupied => 'đêm có phòng đã bán';

  @override
  String get partnerCalendarMetricRestricted => 'đêm có hạn chế';

  @override
  String get partnerCalendarMetricMissing => 'đêm không có bản ghi';

  @override
  String partnerCalendarNightHeading(String room, String date) {
    return '$room · $date';
  }

  @override
  String get partnerCalendarCloseNight => 'Đóng chi tiết đêm';

  @override
  String get partnerCalendarFieldAvailable => 'Còn trống';

  @override
  String get partnerCalendarFieldSold => 'Đã bán';

  @override
  String get partnerCalendarFieldBlocked => 'Đang khóa';

  @override
  String get partnerCalendarFieldMaintenance => 'Đang bảo trì';

  @override
  String get partnerCalendarFieldTotal => 'Tổng số phòng';

  @override
  String get partnerCalendarInconsistentMessage =>
      'Số phòng còn trống, đã bán, đang khóa và đang bảo trì không cộng lại bằng tổng của đêm này. Các con số của máy chủ được hiển thị nguyên vẹn.';

  @override
  String get partnerCalendarNoRecordExplanation =>
      'Không có bản ghi tồn phòng cho đêm này. Điều đó không đồng nghĩa với còn trống: máy chủ đếm số bản ghi, nên mọi kỳ lưu trú bao gồm đêm này đều bị từ chối. Hãy tạo bản ghi trong tab Tồn phòng để đêm này có thể bán được.';

  @override
  String get partnerCalendarQuestionsHeading => 'Đêm này cho phép những gì';

  @override
  String get partnerCalendarQuestionStock => 'Vẫn còn phòng trống';

  @override
  String get partnerCalendarQuestionSellable => 'Đêm này có thể bán';

  @override
  String get partnerCalendarQuestionArrival =>
      'Kỳ lưu trú có thể bắt đầu vào đêm này';

  @override
  String get partnerCalendarQuestionDeparture =>
      'Kỳ lưu trú có thể kết thúc ở đêm này';

  @override
  String get partnerCalendarQuestionsNote =>
      'Đây là bốn phép kiểm tra riêng biệt của máy chủ, không phải một. Một đêm vẫn có thể bán được trong kỳ lưu trú dài hơn dù đang chặn nhận phòng hoặc chặn trả phòng.';

  @override
  String get partnerCalendarReasonNoStock => 'Không còn phòng nào cho đêm này.';

  @override
  String get partnerCalendarReasonStopSell => 'Đêm này đang bật ngừng bán.';

  @override
  String get partnerCalendarReasonNotSellable =>
      'Đêm này hoàn toàn không thể bán.';

  @override
  String get partnerCalendarReasonClosedArrival =>
      'Đêm này đang chặn nhận phòng.';

  @override
  String get partnerCalendarReasonClosedDeparture =>
      'Đêm này đang chặn trả phòng.';

  @override
  String get partnerCalendarReadOnlyNote =>
      'Lịch này chỉ để xem. Ngừng bán, chặn nhận phòng và chặn trả phòng được thay đổi trong tab Tồn phòng, để mọi thao tác ghi chỉ do một nơi quản lý.';

  @override
  String get partnerCalendarManageRestrictions => 'Mở tồn phòng theo phòng';

  @override
  String partnerMetricWindow(String from, String to) {
    return '$from – $to';
  }

  @override
  String get partnerMetricAllProperties => 'Tất cả cơ sở';

  @override
  String get partnerMetricChangeRange => 'Đổi khoảng ngày';

  @override
  String get partnerMetricDefaultRange => '30 ngày gần nhất';

  @override
  String get partnerMetricInvalidRange =>
      'Ngày bắt đầu không được sau ngày kết thúc. Máy chủ từ chối khoảng ngày đó.';

  @override
  String get partnerMetricScopeNotFound =>
      'Cơ sở đó không khả dụng với tài khoản của bạn.';

  @override
  String get partnerMetricNotLoaded => 'Phần này chưa được tải.';

  @override
  String get partnerMetricUnavailable => 'Không có dữ liệu';

  @override
  String partnerMetricSectionsFailed(String count) {
    return 'Không tải được $count phần. Các phần đó hiển thị là không có dữ liệu, không phải bằng 0.';
  }

  @override
  String partnerMetricPeakDay(String date, String value) {
    return 'Ngày cao nhất $date, $value';
  }

  @override
  String get partnerFinanceTitle => 'Tài chính & đối soát';

  @override
  String get partnerFinanceTabOverview => 'Doanh thu & hoa hồng';

  @override
  String get partnerFinanceTabRevenue => 'Doanh thu';

  @override
  String get partnerFinanceTabSettlement => 'Đối soát & chi trả';

  @override
  String get partnerFinanceScopeAll =>
      'Số liệu bao gồm mọi cơ sở bạn sở hữu. Hãy chọn một cơ sở trong không gian làm việc để thu hẹp phạm vi. Số tiền hiển thị dạng số có phân nhóm: API tài chính không gửi kèm đơn vị tiền tệ.';

  @override
  String get partnerFinanceScopeProperty =>
      'Số liệu chỉ bao gồm cơ sở đang chọn. Số tiền hiển thị dạng số có phân nhóm: API tài chính không gửi kèm đơn vị tiền tệ.';

  @override
  String get partnerFinanceEstimateNotice =>
      'Đây là các con số ước tính, không phải bảng kê tài chính chính thức. Hoa hồng nền tảng được máy chủ áp dụng theo một tỷ lệ cố định, số thuế chỉ mang tính tham khảo, và các kỳ đối soát được tính từ doanh thu đặt phòng chứ không đọc từ sổ đối soát.';

  @override
  String get partnerFinanceNoData =>
      'Máy chủ không trả về số liệu nào cho khoảng thời gian này.';

  @override
  String get partnerFinanceOverviewHeading => 'Doanh thu và hoa hồng';

  @override
  String get partnerFinanceOverviewSubtitle =>
      'Đặt phòng được tính theo ngày nhận phòng nằm trong khoảng đã chọn.';

  @override
  String get partnerFinanceCommissionCaption =>
      'Do máy chủ tính theo tỷ lệ cố định';

  @override
  String get partnerFinanceTaxCaption =>
      'Chỉ mang tính tham khảo — không phải số thuế thực tế';

  @override
  String get partnerFinanceCompletedLabel => 'Đặt phòng đã hoàn tất';

  @override
  String get partnerFinancePaidLabel => 'Đặt phòng đã thanh toán';

  @override
  String get partnerFinancePendingCaption =>
      'Toàn bộ doanh thu ròng của khoảng thời gian: hệ thống chưa theo dõi phần đã thực sự đối soát';

  @override
  String get partnerFinanceNextPayoutCaption =>
      'Theo chu kỳ hằng tháng giả định, không phải ngày đã lên lịch';

  @override
  String get partnerFinanceCommissionHeading => 'Chi tiết hoa hồng';

  @override
  String partnerFinanceRateNotice(String rate) {
    return 'Máy chủ đã áp dụng tỷ lệ nền tảng cố định $rate. Đây là hằng số trong dịch vụ, không phải tỷ lệ đã thương lượng, và ứng dụng không bao giờ tự áp dụng nó.';
  }

  @override
  String get partnerFinanceRevenueHeading => 'Chi tiết doanh thu';

  @override
  String get partnerFinanceRevenueSubtitle =>
      'Mọi con số đều do máy chủ tính và làm tròn. Màn hình này không tính lại bất kỳ giá trị nào.';

  @override
  String get partnerFinanceRevenueEmpty =>
      'Không ghi nhận doanh thu nào trong khoảng thời gian này.';

  @override
  String get partnerFinanceAverageBooking => 'Giá trị đặt phòng trung bình';

  @override
  String get partnerFinanceHighestBooking => 'Đặt phòng cao nhất';

  @override
  String get partnerFinanceByDay => 'Theo ngày';

  @override
  String get partnerFinanceByMonth => 'Theo tháng';

  @override
  String get partnerFinanceByProperty => 'Theo cơ sở';

  @override
  String get partnerFinanceByRoom => 'Theo phòng';

  @override
  String get partnerFinanceSettlementHeading => 'Đối soát';

  @override
  String get partnerFinanceSettlementSubtitle =>
      'Các kỳ là tháng dương lịch được tính từ doanh thu đặt phòng. Không có sổ đối soát nào đứng sau chúng.';

  @override
  String get partnerFinanceSettlementEmpty =>
      'Không có kỳ đối soát nào trong khoảng thời gian này.';

  @override
  String get partnerFinanceCurrentSettlement => 'Kỳ hiện tại';

  @override
  String get partnerFinanceLastSettlement => 'Kỳ trước';

  @override
  String get partnerFinancePending => 'Đang chờ';

  @override
  String get partnerFinancePaid => 'Đã đối soát';

  @override
  String get partnerFinanceSettlementMismatch =>
      'Máy chủ báo có khoản đã đối soát trong khi không kỳ nào bên dưới được đánh dấu đã đối soát. Cả hai giá trị đều hiển thị đúng như máy chủ gửi; hãy thận trọng với tổng đã đối soát.';

  @override
  String get partnerFinanceSettlementPeriods => 'Các kỳ';

  @override
  String get partnerFinancePeriod => 'Kỳ';

  @override
  String get partnerFinanceStatus => 'Trạng thái';

  @override
  String get partnerFinanceStatusPaid => 'Đã đối soát';

  @override
  String get partnerFinanceStatusPending => 'Đang chờ';

  @override
  String get partnerFinanceStatusUnknown => 'Không xác định';

  @override
  String get partnerFinancePayoutHeading => 'Chi trả';

  @override
  String get partnerFinancePayoutSubtitle =>
      'Vẫn là các kỳ được tính đó, chia theo trạng thái.';

  @override
  String get partnerFinancePayoutEmpty =>
      'Không có kỳ chi trả nào trong khoảng thời gian này.';

  @override
  String get partnerFinanceEstimatedPayoutDate => 'Ngày chi trả dự kiến';

  @override
  String get partnerFinanceUpcomingPayouts => 'Sắp tới';

  @override
  String get partnerFinanceCompletedPayouts => 'Đã hoàn tất';

  @override
  String get partnerFinancePayoutNoRecords =>
      'API đối tác không có bản ghi chi trả nào — không có mã tham chiếu, thông tin ngân hàng hay thông tin cổng thanh toán để hiển thị, và ứng dụng cũng không yêu cầu chúng.';

  @override
  String get partnerFinanceInvoiceHeading => 'Hóa đơn';

  @override
  String get partnerFinanceInvoiceEmpty =>
      'Không có hóa đơn nào được phát hành trong khoảng thời gian này.';

  @override
  String get partnerFinanceInvoiceIssued => 'Đã phát hành';

  @override
  String get partnerFinanceInvoicePaid => 'Đã thanh toán';

  @override
  String get partnerFinanceInvoiceCancelled => 'Đã hủy';

  @override
  String get partnerFinanceInvoiceRefunded => 'Đã hoàn tiền';

  @override
  String get partnerFinanceInvoiceTotal => 'Tổng đã xuất hóa đơn';

  @override
  String get partnerFinanceInvoiceNoDocuments =>
      'API đối tác chỉ trả về số lượng hóa đơn. Không có danh sách hóa đơn, không có số hóa đơn để mở và không có bản tải xuống, nên ứng dụng không hiển thị chức năng đó.';

  @override
  String get partnerFinanceRefundHeading => 'Hoàn tiền';

  @override
  String get partnerFinanceRefundEmpty =>
      'Không ghi nhận khoản hoàn tiền nào trong khoảng thời gian này.';

  @override
  String get partnerFinanceRefundCount => 'Số lần hoàn tiền';

  @override
  String get partnerFinanceRefundAmount => 'Số tiền đã hoàn';

  @override
  String get partnerFinanceRefundRate => 'Tỷ lệ hoàn tiền';

  @override
  String get partnerFinanceRefundReadOnly =>
      'Phần hoàn tiền ở đây chỉ để xem. API đối tác không có thao tác hoàn tiền, nên việc hoàn tiền được thực hiện ở nơi khác.';

  @override
  String get partnerAnalyticsTitle => 'Phân tích hiệu suất';

  @override
  String get partnerAnalyticsDashboardPointer =>
      'Doanh thu, công suất phòng và các tổng số chính nằm ở Bảng điều khiển, nơi đã báo cáo chúng. Trang này bổ sung những gì Bảng điều khiển chưa có.';

  @override
  String get partnerAnalyticsScopeAll =>
      'Số liệu bao gồm mọi cơ sở bạn sở hữu. Hãy chọn một cơ sở trong không gian làm việc để thu hẹp phạm vi.';

  @override
  String get partnerAnalyticsScopeProperty =>
      'Số liệu chỉ bao gồm cơ sở đang chọn.';

  @override
  String get partnerAnalyticsBookingsHeading => 'Hoạt động đặt phòng';

  @override
  String get partnerAnalyticsBookingsEmpty =>
      'Không có đặt phòng nào trong khoảng thời gian này.';

  @override
  String get partnerAnalyticsArrivals => 'Lượt đến';

  @override
  String get partnerAnalyticsDepartures => 'Lượt đi';

  @override
  String get partnerAnalyticsCancellations => 'Lượt hủy';

  @override
  String get partnerAnalyticsNoShows => 'Khách không đến';

  @override
  String get partnerAnalyticsAverageStay => 'Thời gian lưu trú trung bình';

  @override
  String get partnerAnalyticsAverageStayCaption => 'Số đêm, do máy chủ tính';

  @override
  String get partnerAnalyticsByStatus => 'Theo trạng thái';

  @override
  String get partnerAnalyticsRoomsHeading => 'Hiệu suất phòng';

  @override
  String get partnerAnalyticsRoomsEmpty =>
      'Không có hoạt động phòng nào trong khoảng thời gian này.';

  @override
  String get partnerAnalyticsOccupancyEstimate => 'Công suất ước tính';

  @override
  String get partnerAnalyticsOccupancyCaption =>
      'Máy chủ gọi đây là con số ước tính';

  @override
  String get partnerAnalyticsTopRoomsRevenue => 'Phòng dẫn đầu theo doanh thu';

  @override
  String get partnerAnalyticsTopRoomsBookings => 'Phòng dẫn đầu theo lượt đặt';

  @override
  String get partnerAnalyticsAvailability => 'Tổng hợp tình trạng phòng trống';

  @override
  String get partnerAnalyticsPromotionsHeading => 'Hoạt động khuyến mãi';

  @override
  String get partnerAnalyticsPromotionsSubtitle =>
      'Chỉ mang tính cấu trúc: máy chủ chưa thể quy khoản giảm giá về từng đặt phòng.';

  @override
  String get partnerAnalyticsPromotionsEmpty =>
      'Không có hoạt động khuyến mãi nào trong khoảng thời gian này.';

  @override
  String get partnerAnalyticsActivePromotions => 'Khuyến mãi đang bật';

  @override
  String get partnerAnalyticsDiscountedBookings => 'Đặt phòng có giảm giá';

  @override
  String get partnerAnalyticsNoAttribution =>
      'Máy chủ chưa quy được khoản giảm giá';

  @override
  String get partnerAnalyticsPromotionsByType => 'Theo loại';

  @override
  String get partnerAnalyticsPromotionsByStatus => 'Theo trạng thái khuyến mãi';

  @override
  String get partnerAnalyticsReviewsHeading => 'Tổng hợp đánh giá';

  @override
  String get partnerAnalyticsReviewsSubtitle =>
      'Tổng hợp điểm và trạng thái kiểm duyệt. Từng đánh giá và phần trả lời được quản lý trong mục Đánh giá.';

  @override
  String get partnerAnalyticsReviewsEmpty =>
      'Không có đánh giá nào trong khoảng thời gian này.';

  @override
  String get partnerAnalyticsAverageRating => 'Điểm trung bình';

  @override
  String get partnerAnalyticsApprovedOnly => 'Chỉ tính các đánh giá đã duyệt';

  @override
  String get partnerAnalyticsNoReviews =>
      'Chưa có đánh giá nào để tính trung bình';

  @override
  String get partnerAnalyticsReviewCount => 'Tổng số đánh giá';

  @override
  String get partnerAnalyticsReviewsApproved => 'Đã duyệt';

  @override
  String get partnerAnalyticsReviewsPending => 'Chờ duyệt';

  @override
  String get partnerAnalyticsReviewsRejected => 'Đã từ chối';

  @override
  String get partnerAnalyticsMessagesHeading => 'Hoạt động tin nhắn';

  @override
  String get partnerAnalyticsMessagesEmpty =>
      'Không có cuộc trò chuyện nào trong khoảng thời gian này.';

  @override
  String get partnerAnalyticsOpenConversations => 'Cuộc trò chuyện đang mở';

  @override
  String get partnerAnalyticsClosedConversations => 'Cuộc trò chuyện đã đóng';

  @override
  String get partnerAnalyticsArchivedConversations =>
      'Cuộc trò chuyện đã lưu trữ';

  @override
  String get partnerAnalyticsUnreadMessages => 'Chưa đọc dành cho bạn';

  @override
  String get partnerAnalyticsResponseTime => 'Thời gian phản hồi trung bình';

  @override
  String get partnerAnalyticsNoResponses => 'Chưa đo được thời gian phản hồi';

  @override
  String partnerAnalyticsMinutesValue(String value) {
    return '$value phút';
  }

  @override
  String get partnerReviewsTitle => 'Đánh giá của khách';

  @override
  String get partnerReviewsAnalyticsPointer =>
      'Điểm số và tổng hợp kiểm duyệt nằm ở trang Phân tích. Trang này dùng để trả lời.';

  @override
  String get partnerReviewsScopeNote =>
      'Các đánh giá đã đăng của cơ sở đang chọn. Chỉ đánh giá đã đăng mới được trả lời, và đây đúng là tập hợp mà máy chủ cho phép trả lời.';

  @override
  String get partnerReviewsNoBodyNotice =>
      'API đối tác không trả về nội dung khách đã viết — chỉ có điểm số, tiêu đề và ngày. Phần trả lời được viết dựa trên những thông tin đó.';

  @override
  String get partnerReviewsNoPropertyTitle => 'Hãy chọn một cơ sở';

  @override
  String get partnerReviewsNoPropertyMessage =>
      'Đánh giá được liệt kê theo từng cơ sở. Hãy chọn một cơ sở trong không gian làm việc để xem đánh giá.';

  @override
  String get partnerReviewsEmptyTitle => 'Chưa có đánh giá nào được đăng';

  @override
  String get partnerReviewsEmptyMessage =>
      'Chưa có nội dung nào được đăng cho cơ sở này. Đánh giá sẽ xuất hiện khi khách viết và được duyệt.';

  @override
  String get partnerReviewsNoMatchTitle => 'Không có mục nào khớp bộ lọc';

  @override
  String get partnerReviewsNoMatchMessage =>
      'Cơ sở này có đánh giá, nhưng không có mục nào thuộc nhóm đã chọn.';

  @override
  String get partnerReviewsFilterAll => 'Hiện tất cả';

  @override
  String partnerReviewsFilterAllCount(String count) {
    return 'Tất cả ($count)';
  }

  @override
  String partnerReviewsFilterNeedsReplyCount(String count) {
    return 'Cần trả lời ($count)';
  }

  @override
  String partnerReviewsFilterRepliedCount(String count) {
    return 'Đã trả lời ($count)';
  }

  @override
  String get partnerReviewsNeedsReply => 'Cần trả lời';

  @override
  String get partnerReviewsReplied => 'Đã trả lời';

  @override
  String get partnerReviewsNoTitle => 'Đánh giá không có tiêu đề';

  @override
  String partnerReviewsRatingValue(String rating) {
    return 'Chấm $rating trên 5';
  }

  @override
  String get partnerReviewsReplyHeading => 'Phản hồi của bạn';

  @override
  String get partnerReviewsCloseReply => 'Đóng phần trả lời';

  @override
  String get partnerReviewsCurrentReply => 'Đang được đăng';

  @override
  String partnerReviewsRepliedAt(String date) {
    return 'trả lời $date';
  }

  @override
  String partnerReviewsEditedAt(String date) {
    return 'sửa $date';
  }

  @override
  String get partnerReviewsReplyField => 'Trả lời khách này';

  @override
  String get partnerReviewsReplyHelp =>
      'Mỗi đánh giá chỉ có một phản hồi. Đăng lại sẽ thay thế phản hồi cũ chứ không thêm phản hồi thứ hai.';

  @override
  String get partnerReviewsPublicNotice =>
      'Phản hồi của bạn được đăng công khai bên cạnh đánh giá, và sau đó không thể xóa — chỉ có thể sửa lại nội dung. Khách sẽ được thông báo trong lần bạn trả lời đầu tiên.';

  @override
  String get partnerReviewsPublishReply => 'Đăng phản hồi';

  @override
  String get partnerReviewsUpdateReply => 'Thay phản hồi';

  @override
  String get partnerReviewsPublishConfirm =>
      'Đăng công khai phản hồi này? Sau đó không thể xóa, chỉ có thể viết lại.';

  @override
  String get partnerReviewsReplyPublished => 'Phản hồi của bạn đã được đăng.';

  @override
  String get partnerReviewsReplyEmpty =>
      'Hãy viết nội dung phản hồi trước khi đăng.';

  @override
  String get partnerReviewsReplyUncertain =>
      'Kết nối bị ngắt trước khi máy chủ xác nhận, và phản hồi thì không thể xóa. Hãy làm mới để xem phản hồi đã được đăng hay chưa.';

  @override
  String get partnerReviewsNotFound =>
      'Đánh giá đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerReviewsNotApprovedNotice =>
      'Chỉ đánh giá đã đăng mới được trả lời. Máy chủ từ chối phản hồi với mọi trạng thái khác.';

  @override
  String get partnerSettingsTitle => 'Tài khoản & cài đặt';

  @override
  String get partnerSettingsTabWorkspace => 'Chính sách & không gian làm việc';

  @override
  String get partnerSettingsTabTeam => 'Nhân sự';

  @override
  String get partnerSettingsTabPayout => 'Tài khoản nhận tiền';

  @override
  String get partnerSettingsTabProfile => 'Hồ sơ doanh nghiệp';

  @override
  String get partnerTeamHeading => 'Thành viên nhóm';

  @override
  String get partnerTeamSubtitle =>
      'Tất cả những người có thể làm việc trong không gian đối tác này, kèm vai trò mà máy chủ cấp cho họ.';

  @override
  String get partnerTeamEmpty => 'Chưa ghi nhận thành viên nào.';

  @override
  String get partnerTeamOwnerOnly =>
      'Chỉ chủ tài khoản đối tác mới thêm, sửa hoặc xóa được thành viên. Bạn vẫn có thể xem danh sách tại đây.';

  @override
  String get partnerTeamRoleField => 'Vai trò';

  @override
  String get partnerTeamActive => 'Đang hoạt động';

  @override
  String get partnerTeamInactive => 'Ngừng hoạt động';

  @override
  String get partnerTeamActivate => 'Kích hoạt';

  @override
  String get partnerTeamDeactivate => 'Tạm ngừng';

  @override
  String get partnerTeamRemove => 'Xóa khỏi nhóm';

  @override
  String partnerTeamRemoveConfirm(String member) {
    return 'Xóa $member khỏi nhóm? Thao tác này không thể hoàn tác tại đây — sẽ phải thêm lại từ đầu.';
  }

  @override
  String get partnerTeamInviteHeading => 'Thêm thành viên';

  @override
  String get partnerTeamInviteNote =>
      'Máy chủ tìm tài khoản Plan Your Trip hiện có theo email. Hệ thống không gửi lời mời, nên người đó phải có sẵn tài khoản.';

  @override
  String get partnerTeamInviteEmail => 'Email tài khoản của họ';

  @override
  String get partnerTeamInviteAction => 'Thêm thành viên';

  @override
  String get partnerPayoutHeading => 'Tài khoản nhận tiền';

  @override
  String get partnerPayoutSubtitle =>
      'Nơi các khoản đối soát sẽ được chuyển tới. Chỉ lưu dưới dạng thông tin tham chiếu.';

  @override
  String get partnerPayoutNone => 'Chưa thêm tài khoản nhận tiền nào.';

  @override
  String get partnerPayoutLoadFailed =>
      'Không tải được tài khoản nhận tiền. Điều này khác với việc chưa có tài khoản.';

  @override
  String get partnerPayoutHolder => 'Chủ tài khoản';

  @override
  String get partnerPayoutBank => 'Ngân hàng';

  @override
  String get partnerPayoutAccountNumber => 'Số tài khoản';

  @override
  String partnerPayoutMasked(String last4) {
    return 'Kết thúc bằng $last4';
  }

  @override
  String get partnerPayoutMethod => 'Hình thức nhận tiền';

  @override
  String get partnerPayoutMethodBank => 'Chuyển khoản ngân hàng';

  @override
  String get partnerPayoutMethodManual => 'Thủ công';

  @override
  String get partnerPayoutMethodUnknown => 'Hình thức không xác định';

  @override
  String get partnerPayoutStatus => 'Trạng thái xác minh';

  @override
  String get partnerPayoutUpdated => 'Cập nhật lần cuối';

  @override
  String get partnerPayoutNoExecutionNotice =>
      'Không có khoản chi trả nào được thực hiện từ đây, và số tài khoản đầy đủ không bao giờ được lưu: máy chủ chỉ giữ lại bốn chữ số cuối và loại bỏ phần còn lại ngay khi bạn gửi.';

  @override
  String get partnerPayoutRoleNotice =>
      'Chỉ chủ tài khoản đối tác hoặc thành viên phụ trách tài chính mới thay đổi được các thông tin này. Bạn vẫn có thể xem tại đây.';

  @override
  String get partnerPayoutAdd => 'Thêm tài khoản nhận tiền';

  @override
  String get partnerPayoutReplace => 'Thay thông tin';

  @override
  String get partnerPayoutCancelEdit => 'Hủy bỏ';

  @override
  String get partnerPayoutFormHeading => 'Thông tin nhận tiền mới';

  @override
  String get partnerPayoutNumberHelp =>
      'Tối thiểu 4 ký tự. Chỉ bốn chữ số cuối được lưu lại.';

  @override
  String get partnerPayoutSave => 'Lưu thông tin nhận tiền';

  @override
  String get partnerPayoutReplaceConfirm =>
      'Thay thông tin nhận tiền? Số tài khoản trước đó không thể khôi phục vì nó chưa bao giờ được lưu.';

  @override
  String get partnerProfileHeading => 'Hồ sơ doanh nghiệp';

  @override
  String get partnerProfileBusinessName => 'Tên doanh nghiệp';

  @override
  String get partnerProfileRepresentative => 'Người đại diện';

  @override
  String get partnerProfileVerification => 'Tình trạng xác minh';

  @override
  String get partnerProfileYourRole => 'Vai trò của bạn';

  @override
  String get partnerProfileReadOnlyNotice =>
      'Hồ sơ doanh nghiệp đã được duyệt không thể chỉnh sửa qua API đối tác — máy chủ chỉ nhận thay đổi khi hồ sơ còn là bản nháp hoặc đã bị từ chối. Hãy liên hệ bộ phận hỗ trợ để thay đổi.';

  @override
  String get partnerProfileStatusDraft => 'Bản nháp';

  @override
  String get partnerProfileStatusSubmitted => 'Đang chờ duyệt';

  @override
  String get partnerProfileStatusApproved => 'Đã duyệt';

  @override
  String get partnerProfileStatusRejected => 'Đã từ chối';

  @override
  String get partnerProfileStatusSuspended => 'Đã tạm ngưng';

  @override
  String get partnerProfileStatusUnknown => 'Trạng thái không xác định';

  @override
  String get partnerAccountSaved => 'Đã lưu.';

  @override
  String get partnerAccountNotFound =>
      'Bản ghi đó không còn khả dụng với tài khoản của bạn.';

  @override
  String get partnerAccountConflict =>
      'Máy chủ từ chối vì xung đột với một bản ghi đã có.';

  @override
  String get partnerAccountValidation =>
      'Hãy kiểm tra lại thông tin rồi thử lại.';

  @override
  String get partnerAccountUncertain =>
      'Kết nối bị ngắt trước khi máy chủ xác nhận. Hãy làm mới để xem trạng thái hiện tại trước khi thử lại.';

  @override
  String get adminConsoleTitle => 'Bảng quản trị';

  @override
  String adminSignedInAs(String email) {
    return 'Đăng nhập với $email';
  }

  @override
  String get adminNavDashboard => 'Tổng quan';

  @override
  String get adminNavBookings => 'Đặt phòng';

  @override
  String get adminNavPayments => 'Thanh toán';

  @override
  String get adminNavInvoices => 'Hóa đơn';

  @override
  String get adminNavReviews => 'Đánh giá';

  @override
  String get adminNavActivityLog => 'Nhật ký hoạt động';

  @override
  String get adminSectionOverview => 'Tổng quan';

  @override
  String get adminSectionOperations => 'Vận hành';

  @override
  String get adminSectionFinance => 'Tài chính';

  @override
  String get adminSectionCommunity => 'Cộng đồng';

  @override
  String get adminSectionAudit => 'Kiểm toán';

  @override
  String get adminAccessDeniedTitle => 'Cần quyền quản trị viên';

  @override
  String get adminAccessDeniedBody =>
      'Khu vực này chỉ dành cho tài khoản quản trị viên.';

  @override
  String get adminAccessDeniedAction => 'Quay lại';

  @override
  String get adminMenu => 'Menu';

  @override
  String get adminLoading => 'Đang tải…';

  @override
  String get adminEmptyTitle => 'Không có dữ liệu';

  @override
  String get adminEmptyMessage => 'Chưa có bản ghi nào phù hợp.';

  @override
  String get adminErrorUnauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get adminErrorForbidden =>
      'Tài khoản này không có quyền quản trị viên.';

  @override
  String get adminErrorNotFound => 'Không tìm thấy bản ghi.';

  @override
  String get adminErrorGeneric => 'Không thể tải dữ liệu.';

  @override
  String get adminRetry => 'Thử lại';

  @override
  String get adminRefresh => 'Làm mới';

  @override
  String get adminValueUnknown => '—';

  @override
  String get adminPaginationEmpty => 'Không có kết quả';

  @override
  String adminPaginationRange(int first, int last, int total) {
    return 'Hiển thị $first–$last trên $total';
  }

  @override
  String adminPaginationPageOf(int page, int total) {
    return 'Trang $page / $total';
  }

  @override
  String get adminPaginationPrevious => 'Trang trước';

  @override
  String get adminPaginationNext => 'Trang sau';

  @override
  String get adminSortAscending => 'Sắp xếp tăng dần';

  @override
  String get adminSortDescending => 'Sắp xếp giảm dần';

  @override
  String get adminFilterAll => 'Tất cả';

  @override
  String get adminFilterStatus => 'Trạng thái';

  @override
  String get adminSortCreatedAt => 'Ngày tạo';

  @override
  String get adminSortCheckIn => 'Ngày nhận phòng';

  @override
  String get adminSortCheckOut => 'Ngày trả phòng';

  @override
  String get adminSortFinalPrice => 'Tổng tiền';

  @override
  String get adminSortStatus => 'Trạng thái';

  @override
  String get adminSortBookingCode => 'Mã đặt phòng';

  @override
  String get adminSortAmount => 'Số tiền';

  @override
  String get adminSortPaidAt => 'Ngày thanh toán';

  @override
  String get adminSortRefundedAt => 'Ngày hoàn tiền';

  @override
  String get adminSortRating => 'Điểm đánh giá';

  @override
  String get adminSortApprovedAt => 'Ngày duyệt';

  @override
  String get adminSortIssuedAt => 'Ngày phát hành';

  @override
  String get adminSortTotalAmount => 'Tổng tiền';

  @override
  String get adminDashboardTitle => 'Tổng quan nền tảng';

  @override
  String get adminDashboardTotalBookings => 'Tổng lượt đặt';

  @override
  String get adminDashboardGrossRevenue => 'Doanh thu gộp';

  @override
  String get adminDashboardActiveHotels => 'Khách sạn đang hoạt động';

  @override
  String get adminDashboardActiveRooms => 'Phòng đang hoạt động';

  @override
  String get adminDashboardTotalUsers => 'Người dùng';

  @override
  String get adminDashboardTotalPartners => 'Đối tác';

  @override
  String get adminDashboardBookingsInRange => 'Lượt đặt trong kỳ';

  @override
  String get adminDashboardRevenueInRange => 'Doanh thu trong kỳ';

  @override
  String get adminDashboardBookingsByStatus => 'Lượt đặt theo trạng thái';

  @override
  String get adminDashboardNoBookings => 'Nền tảng chưa có lượt đặt nào.';

  @override
  String adminDashboardRange(String from, String to) {
    return 'Từ $from đến $to';
  }

  @override
  String get adminDashboardRangeDefault => 'Khoảng thời gian mặc định';

  @override
  String adminDashboardLoadedAt(String time) {
    return 'Tải lúc $time';
  }

  @override
  String get adminDashboardNoCurrency =>
      'Điểm cuối này trả về doanh thu không kèm đơn vị tiền tệ.';

  @override
  String get adminBookingsTitle => 'Đặt phòng';

  @override
  String get adminBookingCode => 'Mã';

  @override
  String get adminBookingHotel => 'Khách sạn';

  @override
  String get adminBookingRoom => 'Phòng';

  @override
  String get adminBookingStay => 'Thời gian lưu trú';

  @override
  String adminBookingNights(int count) {
    return '$count đêm';
  }

  @override
  String get adminBookingTotal => 'Tổng tiền';

  @override
  String get adminBookingCreated => 'Ngày tạo';

  @override
  String get adminBookingsEmpty => 'Không có lượt đặt nào phù hợp.';

  @override
  String get adminPaymentsTitle => 'Thanh toán';

  @override
  String get adminPaymentCode => 'Thanh toán';

  @override
  String get adminPaymentBooking => 'Đặt phòng';

  @override
  String get adminPaymentAmount => 'Số tiền';

  @override
  String get adminPaymentMethod => 'Phương thức';

  @override
  String get adminPaymentProvider => 'Nhà cung cấp';

  @override
  String get adminPaymentPaidAt => 'Đã thanh toán';

  @override
  String get adminPaymentRefundedAt => 'Đã hoàn tiền';

  @override
  String get adminPaymentFailureReason => 'Lý do thất bại';

  @override
  String get adminPaymentsEmpty => 'Không có thanh toán nào phù hợp.';

  @override
  String get adminReviewsTitle => 'Đánh giá';

  @override
  String get adminReviewPlace => 'Địa điểm';

  @override
  String get adminReviewAuthor => 'Người viết';

  @override
  String get adminReviewRating => 'Điểm';

  @override
  String get adminReviewContent => 'Nội dung';

  @override
  String adminReviewReported(int count) {
    return 'Bị báo cáo $count lần';
  }

  @override
  String get adminReviewPartnerReply => 'Phản hồi của đối tác';

  @override
  String get adminReviewNoReply => 'Chưa có phản hồi';

  @override
  String get adminReviewsEmpty => 'Không có đánh giá nào phù hợp.';

  @override
  String get adminInvoicesTitle => 'Hóa đơn';

  @override
  String get adminInvoiceNumber => 'Hóa đơn';

  @override
  String get adminInvoiceBooking => 'Đặt phòng';

  @override
  String get adminInvoiceHotel => 'Khách sạn';

  @override
  String get adminInvoiceSubtotal => 'Tạm tính';

  @override
  String get adminInvoiceDiscount => 'Giảm giá';

  @override
  String get adminInvoiceTax => 'Thuế';

  @override
  String get adminInvoiceTotal => 'Tổng cộng';

  @override
  String get adminInvoiceIssuedAt => 'Ngày phát hành';

  @override
  String get adminInvoicePaidAt => 'Ngày thanh toán';

  @override
  String get adminInvoicesEmpty => 'Không có hóa đơn nào phù hợp.';

  @override
  String get adminActivityTitle => 'Nhật ký hoạt động';

  @override
  String get adminActivityActor => 'Người thực hiện';

  @override
  String get adminActivityAction => 'Hành động';

  @override
  String get adminActivityTarget => 'Đối tượng';

  @override
  String get adminActivityWhen => 'Thời điểm';

  @override
  String get adminActivityDescription => 'Chi tiết';

  @override
  String get adminActivityBefore => 'Trước';

  @override
  String get adminActivityAfter => 'Sau';

  @override
  String get adminActivitySystemActor => 'Hệ thống';

  @override
  String get adminActivityEmpty => 'Chưa ghi nhận hành động quản trị nào.';

  @override
  String get adminActivityFixedOrder => 'Mới nhất trước, do máy chủ quy định.';

  @override
  String get adminActivityFilterAction => 'Hành động';

  @override
  String get adminNavPartners => 'Đối tác';

  @override
  String get adminPartnersEmpty => 'Chưa có đối tác nào.';

  @override
  String get adminPartnersEmptyFiltered =>
      'Không có đối tác nào khớp với bộ lọc này.';

  @override
  String get adminPartnerSearchLabel => 'Tìm đối tác';

  @override
  String get adminPartnerSearchHint =>
      'Tên doanh nghiệp, người đại diện hoặc email liên hệ';

  @override
  String get adminPartnerSearchClear => 'Xoá tìm kiếm';

  @override
  String get adminPartnerFilterBusinessType => 'Loại hình';

  @override
  String get adminPartnerSortBusinessName => 'Tên doanh nghiệp';

  @override
  String get adminPartnerSortSubmittedAt => 'Ngày nộp';

  @override
  String get adminPartnerColBusiness => 'Doanh nghiệp';

  @override
  String get adminPartnerColType => 'Loại hình';

  @override
  String get adminPartnerColSubmitted => 'Ngày nộp';

  @override
  String get adminPartnerColAction => 'Thao tác';

  @override
  String get adminPartnerOpen => 'Mở';

  @override
  String adminPartnerOpenSemantic(String business) {
    return 'Mở đối tác $business';
  }

  @override
  String get adminPartnerBackToList => 'Quay lại danh sách đối tác';

  @override
  String get adminPartnerTabOverview => 'Tổng quan';

  @override
  String get adminPartnerTabTeam => 'Nhân sự';

  @override
  String get adminPartnerTabActivity => 'Hoạt động';

  @override
  String get adminPartnerTabSettings => 'Cài đặt';

  @override
  String get adminPartnerNotFoundTitle => 'Không tìm thấy đối tác';

  @override
  String get adminPartnerNotFoundMessage =>
      'Không có đối tác nào với mã này. Có thể đối tác đã bị xoá hoặc liên kết không đúng.';

  @override
  String get adminPartnerSectionIdentity => 'Thông tin doanh nghiệp';

  @override
  String get adminPartnerSectionVerification => 'Xác minh';

  @override
  String get adminPartnerSectionSummary => 'Tóm tắt';

  @override
  String get adminPartnerRepresentative => 'Người đại diện';

  @override
  String get adminPartnerContactEmail => 'Email doanh nghiệp';

  @override
  String get adminPartnerContactPhone => 'Điện thoại';

  @override
  String get adminPartnerAddress => 'Địa chỉ';

  @override
  String get adminPartnerTaxCode => 'Mã số thuế';

  @override
  String get adminPartnerWebsite => 'Website';

  @override
  String get adminPartnerAccountEmail => 'Email tài khoản';

  @override
  String get adminPartnerApprovedAt => 'Ngày duyệt';

  @override
  String get adminPartnerApprovedBy => 'Người duyệt';

  @override
  String get adminPartnerRejectedAt => 'Ngày từ chối';

  @override
  String get adminPartnerRejectionReason => 'Lý do từ chối';

  @override
  String get adminPartnerSuspensionReason => 'Lý do tạm ngưng';

  @override
  String get adminPartnerOwnedProperties => 'Cơ sở sở hữu';

  @override
  String get adminPartnerTeamSize => 'Số nhân sự';

  @override
  String get adminPartnerPayoutStatus => 'Tài khoản nhận tiền';

  @override
  String get adminPartnerSummaryUnavailable => 'Không tải được phần tóm tắt.';

  @override
  String get adminPartnerPropertiesNotListed =>
      'Chi tiết cơ sở được quản lý ngoài phần quản lý đối tác.';

  @override
  String get adminPartnerApprove => 'Duyệt';

  @override
  String get adminPartnerReject => 'Từ chối';

  @override
  String get adminPartnerSuspend => 'Tạm ngưng';

  @override
  String get adminPartnerCancel => 'Huỷ';

  @override
  String get adminPartnerApproveTitle => 'Duyệt đối tác này?';

  @override
  String get adminPartnerApproveBody =>
      'Người nộp hồ sơ sẽ có quyền đối tác và trở thành chủ sở hữu tổ chức của họ.';

  @override
  String get adminPartnerRejectTitle => 'Từ chối hồ sơ này?';

  @override
  String get adminPartnerRejectBody =>
      'Đối tác sẽ được thông báo và có thể chỉnh sửa hồ sơ rồi nộp lại.';

  @override
  String get adminPartnerRejectReasonLabel => 'Lý do';

  @override
  String get adminPartnerRejectReasonRequired => 'Cần nhập lý do.';

  @override
  String get adminPartnerActionUncertain =>
      'Không rõ kết quả của thao tác vừa rồi. Trang đã được tải lại — hãy kiểm tra trạng thái xác minh trước khi thử lại.';

  @override
  String get adminPartnerSuspendedNotice =>
      'Đối tác này đang bị tạm ngưng. Không thể khôi phục từ bảng quản trị.';

  @override
  String get adminPartnerSuspendTitle => 'Tạm ngưng đối tác này?';

  @override
  String get adminPartnerSuspendWarningIrreversible =>
      'Không thể hoàn tác từ bảng quản trị — không có thao tác khôi phục.';

  @override
  String get adminPartnerSuspendWarningBookable =>
      'Các cơ sở đã đăng của họ vẫn hiển thị và khách vẫn đặt được.';

  @override
  String get adminPartnerSuspendWarningOperations =>
      'Họ mất quyền truy cập ngay lập tức vào đặt phòng, giá, tồn phòng và mọi công cụ đối tác khác, nên các đặt phòng mới có thể không được xử lý.';

  @override
  String get adminPartnerSuspendReasonLabel => 'Lý do';

  @override
  String get adminPartnerSuspendReasonOptional => 'Không bắt buộc';

  @override
  String get adminPartnerSuspendAcknowledge =>
      'Tôi hiểu rằng thao tác này không thể hoàn tác tại đây.';

  @override
  String get adminPartnerSuspendConfirm => 'Tạm ngưng đối tác';

  @override
  String get adminPartnerTeamEmpty => 'Chưa có nhân sự.';

  @override
  String get adminPartnerTeamReadOnlyNotice =>
      'Chỉ xem. Nhân sự do đối tác tự quản lý.';

  @override
  String get adminPartnerTeamActive => 'Đang hoạt động';

  @override
  String get adminPartnerTeamActiveYes => 'Có';

  @override
  String get adminPartnerTeamActiveNo => 'Không';

  @override
  String get adminPartnerTeamJoined => 'Ngày tham gia';

  @override
  String get adminPartnerActivityEmpty =>
      'Chưa ghi nhận hoạt động nào của đối tác.';

  @override
  String get adminPartnerActivityScopeNotice =>
      'Hoạt động của chính đối tác này. Thao tác của quản trị viên nằm ở nhật ký hoạt động của bảng quản trị.';

  @override
  String get adminPartnerActivityActor => 'Bởi';

  @override
  String get adminPartnerActivityEntity => 'Đối tượng';

  @override
  String get adminPartnerSettingsEmpty => 'Không tải được cài đặt.';

  @override
  String get adminPartnerSettingsReadOnlyNotice =>
      'Chỉ xem. Cài đặt do đối tác tự quản lý.';

  @override
  String get adminPartnerSettingsLanguage => 'Ngôn ngữ mặc định';

  @override
  String get adminPartnerSettingsTimezone => 'Múi giờ';

  @override
  String get adminPartnerSettingsEmail => 'Thông báo email';

  @override
  String get adminPartnerSettingsSms => 'Thông báo SMS';

  @override
  String get adminPartnerSettingsInApp => 'Thông báo trong ứng dụng';

  @override
  String get adminPartnerSettingsBooking => 'Thông báo đặt phòng';

  @override
  String get adminPartnerSettingsPayment => 'Thông báo thanh toán';

  @override
  String get adminPartnerSettingsReview => 'Thông báo đánh giá';

  @override
  String get adminPartnerSettingsPromotion => 'Thông báo khuyến mãi';

  @override
  String get adminNavCatalog => 'Danh mục';

  @override
  String get adminSectionCatalog => 'Danh mục';

  @override
  String get adminCatalogEmpty => 'Chưa có địa điểm nào.';

  @override
  String get adminCatalogEmptyFiltered =>
      'Không có địa điểm nào khớp với bộ lọc này.';

  @override
  String get adminCatalogSearchLabel => 'Tìm địa điểm';

  @override
  String get adminCatalogSearchClear => 'Xoá tìm kiếm';

  @override
  String get adminCatalogFilterFeatured => 'Nổi bật';

  @override
  String get adminCatalogFilterVerified => 'Đã xác minh';

  @override
  String get adminCatalogSortLabel => 'Sắp xếp';

  @override
  String get adminCatalogSortNewest => 'Mới nhất';

  @override
  String get adminCatalogSortRatingDesc => 'Đánh giá cao nhất';

  @override
  String get adminCatalogSortPriceAsc => 'Giá: thấp đến cao';

  @override
  String get adminCatalogSortPriceDesc => 'Giá: cao đến thấp';

  @override
  String get adminCatalogSortNameAsc => 'Tên A–Z';

  @override
  String get adminCatalogOrderingNotice =>
      'Các địa điểm có cùng giá trị sắp xếp có thể đổi thứ tự giữa các trang.';

  @override
  String get adminCatalogColName => 'Tên';

  @override
  String get adminCatalogColCategory => 'Danh mục';

  @override
  String get adminCatalogColLocation => 'Khu vực';

  @override
  String get adminCatalogColRating => 'Đánh giá';

  @override
  String get adminCatalogColFlags => 'Nhãn';

  @override
  String adminCatalogOpenSemantic(String name) {
    return 'Mở địa điểm $name';
  }

  @override
  String get adminCatalogBackToList => 'Quay lại danh mục';

  @override
  String get adminCatalogNotFoundTitle => 'Không tìm thấy địa điểm';

  @override
  String get adminCatalogNotFoundMessage =>
      'Không có địa điểm nào với mã này. Có thể địa điểm đã bị xoá hoặc liên kết không đúng.';

  @override
  String get adminCatalogActionUncertain =>
      'Không rõ kết quả của thao tác vừa rồi. Trang đã được tải lại — hãy kiểm tra trạng thái trước khi thử lại.';

  @override
  String get adminCatalogSectionLifecycle => 'Vòng đời';

  @override
  String get adminCatalogSectionFlags => 'Xác minh và hiển thị nổi bật';

  @override
  String get adminCatalogSectionIdentity => 'Thông tin';

  @override
  String get adminCatalogSectionRooms => 'Phòng';

  @override
  String get adminCatalogSectionMedia => 'Thư viện ảnh';

  @override
  String get adminCatalogPublicVisibility => 'Hiển thị với khách';

  @override
  String get adminCatalogVisibleToGuests => 'Đang hiển thị và đặt được';

  @override
  String get adminCatalogHiddenFromGuests => 'Không hiển thị với khách';

  @override
  String get adminCatalogNoTransitions =>
      'Không có thay đổi trạng thái nào khả dụng.';

  @override
  String get adminCatalogArchivedNotice =>
      'Địa điểm này đã lưu trữ. Không thể khôi phục từ bảng quản trị.';

  @override
  String get adminCatalogArchive => 'Lưu trữ';

  @override
  String get adminCatalogArchiveTitle => 'Lưu trữ địa điểm này?';

  @override
  String get adminCatalogArchiveWarningIrreversible =>
      'Không thể hoàn tác từ bảng quản trị — không có thao tác khôi phục.';

  @override
  String get adminCatalogArchiveWarningVisibility =>
      'Địa điểm sẽ biến mất khỏi tìm kiếm và trang công khai ngay lập tức.';

  @override
  String get adminCatalogArchiveWarningRooms =>
      'Phòng, giá và tồn phòng của địa điểm không bị thay đổi và không được giải phóng.';

  @override
  String get adminCatalogArchiveAcknowledge =>
      'Tôi hiểu rằng thao tác này không thể hoàn tác tại đây.';

  @override
  String get adminCatalogArchiveConfirm => 'Lưu trữ địa điểm';

  @override
  String get adminCatalogFlagsRequireApproved =>
      'Chỉ có thể bật xác minh và nổi bật cho địa điểm đã duyệt hoặc đã đăng.';

  @override
  String get adminCatalogPriceLevel => 'Mức giá';

  @override
  String get adminCatalogTags => 'Thẻ';

  @override
  String get adminCatalogAmenities => 'Tiện ích';

  @override
  String get adminCatalogReadOnlyNotice =>
      'Chỉ xem. Việc sửa địa điểm sẽ thay thế toàn bộ thẻ, giờ mở cửa và tiện ích, nên không được cung cấp ở đây.';

  @override
  String get adminCatalogNotAHotel =>
      'Địa điểm này không có thông tin khách sạn nên không có phòng.';

  @override
  String get adminCatalogRoomsEmpty => 'Chưa có phòng.';

  @override
  String get adminCatalogRoomsUnavailable => 'Không tải được danh sách phòng.';

  @override
  String get adminCatalogRoomActive => 'Đang hoạt động';

  @override
  String get adminCatalogRoomInactive => 'Ngừng hoạt động';

  @override
  String get adminCatalogRoomCode => 'Mã';

  @override
  String get adminCatalogRoomType => 'Loại';

  @override
  String get adminCatalogRoomQuantity => 'Số phòng';

  @override
  String get adminCatalogRoomsBoundaryNotice =>
      'Tồn phòng và giá được quản lý ngoài danh mục.';

  @override
  String get adminCatalogMediaCount => 'Số ảnh';

  @override
  String get adminCatalogMediaCover => 'Ảnh bìa';

  @override
  String get adminCatalogMediaHasCover => 'Đã đặt';

  @override
  String get adminCatalogMediaNoCover => 'Chưa có';

  @override
  String get adminCatalogMediaReadOnlyNotice =>
      'Chỉ xem. Quản lý ảnh nằm ở một khu vực quản trị riêng.';

  @override
  String get adminNavMedia => 'Thư viện';

  @override
  String get adminMediaPickOwnerTitle => 'Chọn một địa điểm';

  @override
  String get adminMediaOwnerScopeNotice =>
      'Ảnh và video được quản lý theo từng địa điểm. API quản trị chỉ đọc được thư viện của địa điểm, nên phòng, đánh giá và tài liệu chuyến đi không được quản lý ở đây.';

  @override
  String get adminMediaPlaceSearchLabel => 'Tìm địa điểm';

  @override
  String get adminMediaPlaceSearchClear => 'Xoá tìm kiếm';

  @override
  String adminMediaPlaceSearchHint(int count) {
    return 'Đang hiển thị $count kết quả đầu tiên. Hãy thu hẹp tìm kiếm để tìm đúng địa điểm.';
  }

  @override
  String get adminMediaNoPlacesFound =>
      'Không có địa điểm nào khớp với tìm kiếm này.';

  @override
  String adminMediaOpenGallerySemantic(String name) {
    return 'Mở thư viện của $name';
  }

  @override
  String get adminMediaBackToPlaces => 'Quay lại danh sách địa điểm';

  @override
  String get adminMediaEmptyTitle => 'Chưa có ảnh hoặc video';

  @override
  String get adminMediaEmptyMessage =>
      'Địa điểm này chưa đăng ký ảnh hoặc video nào.';

  @override
  String get adminMediaUrlRegistryNotice =>
      'Ảnh và video được đăng ký bằng đường dẫn. Không có tải tệp lên — hãy dán một địa chỉ http hoặc https có sẵn.';

  @override
  String get adminMediaAmbiguousOrderNotice =>
      'Có từ hai mục trở lên cùng vị trí nên thứ tự không xác định. Di chuyển bất kỳ mục nào sẽ đánh số lại toàn bộ thư viện và xử lý việc này.';

  @override
  String get adminMediaNoCoverNotice => 'Địa điểm này chưa đặt ảnh bìa.';

  @override
  String adminMediaCoverIs(int id) {
    return 'Ảnh bìa: mục $id';
  }

  @override
  String get adminMediaActionUncertain =>
      'Không rõ kết quả của thao tác vừa rồi. Thư viện đã được tải lại — hãy kiểm tra trước khi thử lại, vì thao tác ngừng sử dụng không thể hoàn tác tại đây.';

  @override
  String get adminMediaDismissNotice => 'Bỏ qua';

  @override
  String adminMediaAssetSemantic(int id) {
    return 'Mục $id';
  }

  @override
  String get adminMediaUrl => 'Đường dẫn';

  @override
  String get adminMediaUrlHelper =>
      'Địa chỉ http hoặc https đầy đủ, bao gồm tên miền.';

  @override
  String get adminMediaUrlQueryHidden =>
      'Đường dẫn có tham số truy vấn và không được hiển thị ở đây.';

  @override
  String get adminMediaThumbnailUrl => 'Đường dẫn ảnh thu nhỏ';

  @override
  String get adminMediaThumbnailUrlOptional =>
      'Đường dẫn ảnh thu nhỏ (không bắt buộc)';

  @override
  String get adminMediaType => 'Loại';

  @override
  String get adminMediaAltText => 'Văn bản thay thế';

  @override
  String get adminMediaAltTextOptional => 'Văn bản thay thế (không bắt buộc)';

  @override
  String get adminMediaSortOrder => 'Vị trí';

  @override
  String get adminMediaSortOrderOptional => 'Vị trí (không bắt buộc)';

  @override
  String get adminMediaActive => 'Đang dùng';

  @override
  String get adminMediaInactive => 'Ngừng dùng';

  @override
  String get adminMediaCover => 'Ảnh bìa';

  @override
  String get adminMediaPreviewUnavailable => 'Không xem trước được';

  @override
  String get adminMediaPreviewNotAnImage => 'Không phải ảnh';

  @override
  String get adminMediaAdd => 'Thêm ảnh hoặc video';

  @override
  String get adminMediaAddTitle => 'Đăng ký ảnh hoặc video';

  @override
  String get adminMediaEdit => 'Sửa';

  @override
  String get adminMediaEditTitle => 'Sửa ảnh hoặc video';

  @override
  String get adminMediaSave => 'Lưu';

  @override
  String get adminMediaCreate => 'Đăng ký';

  @override
  String get adminMediaSetCover => 'Đặt làm ảnh bìa';

  @override
  String get adminMediaSetAsCover => 'Dùng làm ảnh bìa';

  @override
  String get adminMediaCoverReplacesPrevious =>
      'Ảnh bìa hiện tại của địa điểm, nếu có, sẽ thôi là ảnh bìa.';

  @override
  String get adminMediaCoverImageOnly => 'Chỉ ảnh mới có thể làm ảnh bìa.';

  @override
  String get adminMediaMoveUp => 'Chuyển lên';

  @override
  String get adminMediaMoveDown => 'Chuyển xuống';

  @override
  String get adminMediaEditReplacesNotice =>
      'Lưu sẽ thay thế mọi trường hiển thị ở đây. Xoá trống một ô sẽ xoá giá trị đã lưu.';

  @override
  String get adminMediaUrlRequired => 'Cần nhập đường dẫn.';

  @override
  String get adminMediaUrlInvalid =>
      'Hãy nhập đường dẫn http hoặc https đầy đủ, có tên miền.';

  @override
  String get adminMediaSortOrderInvalid =>
      'Vị trí phải là số nguyên từ 0 trở lên.';

  @override
  String get adminMediaDeactivate => 'Ngừng dùng';

  @override
  String get adminMediaDeactivateTitle => 'Ngừng dùng mục này?';

  @override
  String get adminMediaDeactivateWarningHidden =>
      'Mục này sẽ biến mất khỏi thư viện công khai của địa điểm ngay lập tức.';

  @override
  String get adminMediaDeactivateWarningNoRestore =>
      'Không thể kích hoạt lại từ bảng quản trị.';

  @override
  String get adminMediaDeactivateWarningCover =>
      'Mục này đang là ảnh bìa. Sau thao tác này địa điểm sẽ không có ảnh bìa — không có mục nào được chọn thay thế.';

  @override
  String get adminMediaDeactivateAcknowledge =>
      'Tôi hiểu rằng thao tác này không thể hoàn tác tại đây.';

  @override
  String get adminMediaDeactivateConfirm => 'Ngừng dùng mục này';

  @override
  String get adminCatalogManageMedia => 'Quản lý thư viện';

  @override
  String adminCatalogManageMediaSemantic(String name) {
    return 'Mở thư viện ảnh của $name';
  }

  @override
  String get adminMediaBackToPlaceDetail => 'Quay lại chi tiết địa điểm';

  @override
  String adminMediaOwnerContext(int id) {
    return 'Địa điểm #$id — toàn bộ mục bên dưới thuộc về địa điểm này';
  }

  @override
  String get adminMediaOwnerMismatch =>
      'Không thể hiển thị thư viện này: máy chủ trả về mục thuộc một địa điểm khác. Không thể thay đổi gì ở đây cho đến khi phản hồi khớp với địa điểm đã yêu cầu.';

  @override
  String get partnerMessagesTitle => 'Tin nhắn';

  @override
  String get partnerMessagesSubtitle =>
      'Tin nhắn của khách về các đặt phòng tại cơ sở bạn sở hữu.';

  @override
  String get partnerMessagesLoading => 'Đang tải cuộc trò chuyện…';

  @override
  String get partnerMessagesEmptyTitle => 'Chưa có tin nhắn nào từ khách';

  @override
  String get partnerMessagesEmptyMessage =>
      'Khi khách bắt đầu trao đổi về một đặt phòng của họ, cuộc trò chuyện sẽ xuất hiện ở đây.';

  @override
  String get partnerMessagesUnpaginatedNotice =>
      'Hộp thư này không phân trang — tất cả cuộc trò chuyện máy chủ trả về đều được hiển thị.';

  @override
  String partnerMessagesUnreadBadge(int count) {
    return '$count chưa đọc';
  }

  @override
  String partnerMessagesUnreadTotal(int count, int total) {
    return '$count tin chưa đọc trong $total cuộc trò chuyện';
  }

  @override
  String get partnerMessagesNoPreview => 'Chưa có tin nhắn';

  @override
  String get partnerMessagesNoSubject => 'Không có tiêu đề';

  @override
  String partnerMessagesBookingLabel(String code) {
    return 'Đặt phòng $code';
  }

  @override
  String partnerMessagesGuestLabel(String name) {
    return 'Khách: $name';
  }

  @override
  String partnerMessagesOpenSemantic(String code) {
    return 'Mở cuộc trò chuyện của đặt phòng $code';
  }

  @override
  String get partnerMessagesBackToInbox => 'Quay lại hộp thư';

  @override
  String get partnerMessagesThreadLoading => 'Đang tải cuộc trò chuyện…';

  @override
  String get partnerMessagesThreadEmpty =>
      'Cuộc trò chuyện này chưa có tin nhắn nào.';

  @override
  String get partnerMessagesUnavailableTitle => 'Không mở được cuộc trò chuyện';

  @override
  String get partnerMessagesUnavailableMessage =>
      'Không thể mở cuộc trò chuyện này. Có thể nó không còn tồn tại. Hãy quay lại hộp thư và tải lại.';

  @override
  String get partnerMessagesSenderHost => 'Bạn';

  @override
  String get partnerMessagesSenderGuest => 'Khách';

  @override
  String get partnerMessagesSenderSupport => 'Hỗ trợ';

  @override
  String get partnerMessagesStatusOpen => 'Đang mở';

  @override
  String get partnerMessagesStatusClosed => 'Đã đóng';

  @override
  String get partnerMessagesStatusArchived => 'Đã lưu trữ';

  @override
  String get partnerMessagesComposerLabel => 'Trả lời khách';

  @override
  String get partnerMessagesComposerHint => 'Nhập nội dung trả lời…';

  @override
  String get partnerMessagesSend => 'Gửi';

  @override
  String get partnerMessagesSending => 'Đang gửi…';

  @override
  String get partnerMessagesSendEmpty => 'Hãy nhập nội dung trước khi gửi.';

  @override
  String get partnerMessagesSent => 'Đã gửi tin nhắn.';

  @override
  String get partnerMessagesSendFailed => 'Không gửi được tin nhắn.';

  @override
  String get partnerMessagesSendUncertain =>
      'Kết nối đã hết thời gian chờ và tin nhắn của bạn có thể đã được gửi. Hãy mở lại cuộc trò chuyện để kiểm tra trước khi soạn lại — hệ thống sẽ không tự động gửi lại.';

  @override
  String get partnerMessagesArchivedNotice =>
      'Cuộc trò chuyện này đã được lưu trữ và không thể nhận thêm tin nhắn.';

  @override
  String get partnerMessagesClosedNotice =>
      'Cuộc trò chuyện này đã đóng. Gửi trả lời sẽ mở lại cuộc trò chuyện cho khách.';

  @override
  String get partnerNotificationsTitle => 'Thông báo';

  @override
  String get partnerNotificationsSubtitle =>
      'Toàn bộ thông báo tài khoản của bạn đã nhận, mới nhất trước.';

  @override
  String get partnerNotificationsLoading => 'Đang tải thông báo…';

  @override
  String get partnerNotificationsEmptyTitle => 'Chưa có thông báo nào';

  @override
  String get partnerNotificationsEmptyMessage =>
      'Các cập nhật về cơ sở, đặt phòng, đánh giá và tin nhắn của khách sẽ xuất hiện ở đây.';

  @override
  String get partnerNotificationsInboxNotice =>
      'Đây là toàn bộ hộp thư của tài khoản bạn. Nó có thể gồm cả thông báo chung của nền tảng và cập nhật chuyến đi cá nhân, không chỉ hoạt động của cơ sở — máy chủ không phân loại thông báo theo đối tượng nhận.';

  @override
  String get partnerNotificationsUnpaginatedNotice =>
      'Hộp thư này không phân trang — tất cả thông báo máy chủ trả về đều được hiển thị.';

  @override
  String get partnerNotificationsUnreadLabel => 'Mới';

  @override
  String get partnerNotificationsMarkRead => 'Đánh dấu đã đọc';

  @override
  String get partnerNotificationsMarkAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get partnerNotificationsMarkedRead => 'Đã đánh dấu là đã đọc.';

  @override
  String get partnerNotificationsMarkedAllRead =>
      'Đã đánh dấu tất cả thông báo là đã đọc.';

  @override
  String get partnerNotificationsDelete => 'Xóa';

  @override
  String get partnerNotificationsDeleteTitle => 'Xóa thông báo này?';

  @override
  String get partnerNotificationsDeleteMessage =>
      'Thông báo sẽ bị xóa vĩnh viễn khỏi máy chủ. Không có mục lưu trữ và không thể hoàn tác.';

  @override
  String get partnerNotificationsDeleteCta => 'Xóa vĩnh viễn';

  @override
  String get partnerNotificationsDeleted => 'Đã xóa thông báo.';

  @override
  String get partnerNotificationsActionFailed =>
      'Không thể thực hiện. Không có gì thay đổi.';

  @override
  String get partnerNotificationsActionBusy =>
      'Vui lòng đợi thao tác hiện tại hoàn tất.';

  @override
  String get partnerNotificationsActionNotFound =>
      'Thông báo này không còn tồn tại. Hãy tải lại để xem danh sách hiện tại.';

  @override
  String get partnerNotificationsNoDestination =>
      'Thông báo này không liên kết tới màn hình nào trong không gian làm việc của đối tác.';

  @override
  String get partnerNotificationsTypeUnknown => 'Thông báo';

  @override
  String get adminReviewModerationNotice =>
      'Kiểm duyệt thay đổi những gì khách nhìn thấy. Mọi thao tác đều được xác nhận trước và ghi vào nhật ký hoạt động.';

  @override
  String get adminReviewApprove => 'Duyệt';

  @override
  String get adminReviewReject => 'Từ chối';

  @override
  String get adminReviewHide => 'Ẩn';

  @override
  String get adminReviewActionCurrent => 'Đánh giá này đã ở trạng thái đó.';

  @override
  String get adminReviewApproveTitle => 'Duyệt đánh giá này?';

  @override
  String get adminReviewApproveWarning =>
      'Đánh giá sẽ hiển thị công khai, được tính vào điểm của địa điểm và người viết sẽ nhận được thông báo.';

  @override
  String get adminReviewApproveConfirm => 'Duyệt đánh giá';

  @override
  String get adminReviewRejectTitle => 'Từ chối đánh giá này?';

  @override
  String get adminReviewRejectWarning =>
      'Đánh giá vẫn bị ẩn với khách và người viết sẽ nhận được thông báo kèm lý do bạn nhập bên dưới.';

  @override
  String get adminReviewRejectConfirm => 'Từ chối đánh giá';

  @override
  String get adminReviewRejectReasonLabel => 'Lý do từ chối';

  @override
  String get adminReviewRejectReasonHelp =>
      'Sẽ được gửi tới người viết đánh giá. Hãy nêu đúng sự việc.';

  @override
  String get adminReviewRejectReasonRequired =>
      'Hãy nhập lý do trước khi từ chối.';

  @override
  String get adminReviewHideTitle => 'Ẩn đánh giá này?';

  @override
  String get adminReviewHideWarning =>
      'Đánh giá sẽ biến mất khỏi trang công khai của địa điểm và không còn được tính vào điểm. Người viết không nhận được thông báo.';

  @override
  String get adminReviewHideConfirm => 'Ẩn đánh giá';

  @override
  String get adminReviewModerated => 'Đã cập nhật đánh giá.';

  @override
  String get adminReviewModerationFailed =>
      'Không thể cập nhật đánh giá. Không có gì thay đổi.';

  @override
  String get adminNavReferenceData => 'Dữ liệu tham chiếu';

  @override
  String get adminReferenceTabAmenities => 'Tiện nghi';

  @override
  String get adminReferenceTabCategories => 'Danh mục';

  @override
  String get adminReferenceCmsStatusNotice =>
      'Trạng thái CMS chỉ đánh dấu mục này đang hoạt động trong bảng quản trị. Hiện nó không lọc kết quả của API công khai hay API khách hàng — backend có lưu cờ này nhưng không truy vấn nào áp dụng nó.';

  @override
  String get adminReferenceNoDeleteNotice =>
      'Không thể xoá dữ liệu tham chiếu. API quản trị chỉ cung cấp xem danh sách, tạo mới, cập nhật và đổi trạng thái CMS.';

  @override
  String get adminReferenceOrderingNotice =>
      'Các dòng hiển thị theo thứ tự máy chủ trả về. Backend không sắp xếp và không dùng trường thứ tự để sắp xếp.';

  @override
  String get adminReferenceUpdateReplacesNotice =>
      'Khi lưu, mọi trường của mục này bị ghi đè, nên để trống một ô sẽ xoá giá trị đã lưu.';

  @override
  String get adminReferenceSlugHelper =>
      'Để trống thì máy chủ tự tạo slug từ tên. Slug không đổi được sau khi mục đã được tạo.';

  @override
  String get adminReferenceSlugFixedNotice =>
      'Slug cố định sau khi tạo. Các phần khác của hệ thống tra cứu mục này theo slug nên không cho sửa ở đây.';

  @override
  String get adminReferenceTypeNotice =>
      'Loại được dùng để nhắm mã giảm giá và quy tắc cá nhân hoá, nên phải chọn từ các giá trị sẵn có thay vì tự nhập.';

  @override
  String get adminReferenceParentGuardNotice =>
      'Danh mục này và toàn bộ danh mục con của nó không được liệt kê, nên không thể đặt danh mục cha là con của chính nó.';

  @override
  String get adminReferenceStatusPublicNotice =>
      'Thao tác này chỉ đổi trạng thái CMS. Nó không đảm bảo mục này bị loại khỏi kết quả của API công khai hay API khách hàng.';

  @override
  String get adminReferenceNewAmenity => 'Tiện nghi mới';

  @override
  String get adminReferenceNewCategory => 'Danh mục mới';

  @override
  String get adminReferenceRefresh => 'Tải lại';

  @override
  String get adminReferenceEdit => 'Sửa';

  @override
  String get adminReferenceSave => 'Lưu';

  @override
  String get adminReferenceCreate => 'Tạo';

  @override
  String get adminReferenceDismiss => 'Đóng';

  @override
  String get adminReferenceAmenityCreateTitle => 'Tiện nghi mới';

  @override
  String get adminReferenceAmenityEditTitle => 'Sửa tiện nghi';

  @override
  String get adminReferenceCategoryCreateTitle => 'Danh mục mới';

  @override
  String get adminReferenceCategoryEditTitle => 'Sửa danh mục';

  @override
  String get adminReferenceFieldName => 'Tên';

  @override
  String get adminReferenceFieldSlug => 'Slug';

  @override
  String get adminReferenceFieldIcon => 'Biểu tượng';

  @override
  String get adminReferenceFieldGroup => 'Nhóm';

  @override
  String get adminReferenceFieldDescription => 'Mô tả';

  @override
  String get adminReferenceFieldSortOrder => 'Thứ tự';

  @override
  String get adminReferenceFieldType => 'Loại';

  @override
  String get adminReferenceFieldParent => 'Danh mục cha';

  @override
  String get adminReferenceFieldColor => 'Màu';

  @override
  String get adminReferenceFieldCoverImageUrl => 'Đường dẫn ảnh bìa';

  @override
  String get adminReferenceParentNone => 'Không có cha (cấp cao nhất)';

  @override
  String get adminReferenceValueNotSet => 'Chưa đặt';

  @override
  String get adminReferenceNameRequired => 'Hãy nhập tên.';

  @override
  String get adminReferenceSortOrderInvalid =>
      'Hãy nhập một số nguyên, hoặc để trống.';

  @override
  String get adminReferenceColName => 'Tên';

  @override
  String get adminReferenceColSlug => 'Slug';

  @override
  String get adminReferenceColGroup => 'Nhóm';

  @override
  String get adminReferenceColType => 'Loại';

  @override
  String get adminReferenceColParent => 'Cha';

  @override
  String get adminReferenceColSortOrder => 'Thứ tự';

  @override
  String get adminReferenceColCmsStatus => 'Trạng thái CMS';

  @override
  String get adminReferenceColAction => 'Thao tác';

  @override
  String get adminReferenceStatusActive => 'Đang bật trong CMS';

  @override
  String get adminReferenceStatusInactive => 'Đang tắt trong CMS';

  @override
  String get adminReferenceActivate => 'Bật trong CMS';

  @override
  String get adminReferenceDeactivate => 'Tắt trong CMS';

  @override
  String get adminReferenceActivateTitle => 'Bật trong CMS?';

  @override
  String get adminReferenceDeactivateTitle => 'Tắt trong CMS?';

  @override
  String adminReferenceActivateBody(String name) {
    return '$name sẽ được đánh dấu đang bật trong CMS.';
  }

  @override
  String adminReferenceDeactivateBody(String name) {
    return '$name sẽ được đánh dấu đang tắt trong CMS.';
  }

  @override
  String get adminReferenceStatusConfirm => 'Cập nhật trạng thái CMS';

  @override
  String get adminReferenceMutationFailed =>
      'Không lưu được mục này. Chưa có gì thay đổi.';

  @override
  String get adminReferenceDuplicateSlug =>
      'Slug này đã được dùng. Hãy chọn tên hoặc slug khác.';

  @override
  String get adminReferenceMutationUncertain =>
      'Không rõ kết quả của thao tác vừa rồi. Danh sách đã được tải lại — hãy kiểm tra trước khi thử lại.';

  @override
  String get adminReferenceEmptyAmenities => 'Chưa có tiện nghi nào.';

  @override
  String get adminReferenceEmptyCategories => 'Chưa có danh mục nào.';

  @override
  String adminReferenceEditSemantic(String name) {
    return 'Sửa $name';
  }

  @override
  String get adminReferenceTabLocations => 'Địa danh';

  @override
  String get adminLocationNew => 'Địa danh mới';

  @override
  String get adminLocationCreateTitle => 'Địa danh mới';

  @override
  String get adminLocationEditTitle => 'Sửa địa danh';

  @override
  String get adminLocationColCode => 'Mã';

  @override
  String get adminLocationColLevel => 'Cấp';

  @override
  String get adminLocationColCoordinates => 'Toạ độ';

  @override
  String get adminLocationFieldCode => 'Mã';

  @override
  String get adminLocationFieldOldName => 'Tên cũ';

  @override
  String get adminLocationFieldFullPath => 'Đường dẫn đầy đủ';

  @override
  String get adminLocationFieldLevel => 'Cấp';

  @override
  String get adminLocationFieldCoordinates => 'Toạ độ';

  @override
  String get adminLocationCodeHelper =>
      'Không bắt buộc. Là khoá nghiệp vụ ngắn để các hệ thống khác tra cứu địa danh này.';

  @override
  String get adminLocationCodeHelperFixed =>
      'Mã có thể được thay bằng giá trị khác nhưng không thể xoá — các hệ thống khác tra cứu địa danh này theo mã.';

  @override
  String get adminLocationCodeCannotBeCleared =>
      'Không thể xoá mã. Hãy nhập mã thay thế, hoặc giữ nguyên mã hiện tại.';

  @override
  String get adminLocationReadOnlyNotice =>
      'Các giá trị bên dưới do máy chủ lưu và không sửa được ở đây. Chúng được gửi lại nguyên vẹn khi lưu.';

  @override
  String get adminLocationFieldParent => 'Địa danh cha';

  @override
  String get adminLocationParentHint => 'Chọn địa danh cha';

  @override
  String get adminLocationParentRequired =>
      'Loại này cần có địa danh cha. Chỉ COUNTRY mới được ở cấp cao nhất.';

  @override
  String get adminLocationParentNoCandidates =>
      'Không có địa danh nào đã tải có thể làm cha cho loại này.';

  @override
  String get adminLocationParentCleared =>
      'Địa danh cha trước đó không thể chứa loại này nên đã bị bỏ chọn. Hãy chọn địa danh cha mới.';

  @override
  String get adminLocationParentGuardNotice =>
      'Địa danh này và toàn bộ địa danh bên dưới không được liệt kê, nên không thể đặt nó dưới chính nó.';

  @override
  String get adminLocationHierarchyRule =>
      'COUNTRY ở cấp cao nhất. PROVINCE hoặc CITY nằm dưới một COUNTRY. AREA nằm dưới một PROVINCE hoặc CITY.';

  @override
  String get adminLocationTypeReservedMarker => 'Dành riêng — không dùng được';

  @override
  String get adminLocationTypeUnavailable =>
      'Không thể lưu loại này. WARD và COMMUNE được dành riêng; hãy chọn COUNTRY, PROVINCE, CITY hoặc AREA.';

  @override
  String get adminLocationTypeBlockedByChildren =>
      'Địa danh này có địa danh con không thể nằm dưới loại này. Hãy giữ loại hiện tại, hoặc chuyển các địa danh con đó trước.';

  @override
  String get adminLocationFullPathGeneratedNotice =>
      'Máy chủ tự tạo từ địa danh cha và tên khi lưu. Bản xem trước này chỉ để tham khảo.';

  @override
  String get adminLocationEmpty => 'Chưa có địa danh nào.';

  @override
  String get adminLocationFilterEmpty =>
      'Không có địa danh nào khớp tìm kiếm này.';

  @override
  String get adminLocationFilterLabel => 'Tìm địa danh';

  @override
  String get adminLocationFilterHelper =>
      'Lọc trong các địa danh đã tải, theo tên, slug, mã hoặc tên cũ.';

  @override
  String get adminLocationFilterClear => 'Xoá tìm kiếm';

  @override
  String get adminLocationDuplicateCodeOrSlug =>
      'Mã hoặc slug này đã được dùng. Hãy chọn giá trị khác.';

  @override
  String get surfaceTitlePartner => 'Plan Your Trip Đối tác';

  @override
  String get surfaceTitleAdmin => 'Plan Your Trip Quản trị';

  @override
  String get authPartnerLoginHero =>
      'Quản lý cơ sở lưu trú, đặt phòng và thanh toán trong một không gian làm việc.';

  @override
  String get authPartnerLoginTitle => 'Đăng nhập đối tác';

  @override
  String get authPartnerLoginSubtitle =>
      'Đăng nhập bằng tài khoản đối tác để mở không gian làm việc.';

  @override
  String get authAdminLoginHero => 'Vận hành nền tảng Plan Your Trip.';

  @override
  String get authAdminLoginTitle => 'Đăng nhập quản trị';

  @override
  String get authAdminLoginSubtitle =>
      'Đăng nhập bằng tài khoản quản trị viên để mở bảng điều khiển.';

  @override
  String get authStaffAccountRequired =>
      'Chế độ demo và tự đăng ký chỉ có trong ứng dụng du khách. Không gian này cần một tài khoản có sẵn.';

  @override
  String get surfaceAccessDeniedTitle =>
      'Bạn không có quyền truy cập ứng dụng này';

  @override
  String get surfaceAccessDeniedUser =>
      'Tài khoản này không dùng được ứng dụng du khách. Hãy đăng xuất rồi đăng nhập bằng tài khoản du khách.';

  @override
  String get surfaceAccessDeniedPartner =>
      'Tài khoản này không dùng được không gian đối tác. Hãy đăng xuất rồi đăng nhập bằng tài khoản đối tác.';

  @override
  String get surfaceAccessDeniedAdmin =>
      'Tài khoản này không dùng được bảng điều khiển quản trị. Hãy đăng xuất rồi đăng nhập bằng tài khoản quản trị viên.';

  @override
  String surfaceSignedInAs(String email) {
    return 'Đã đăng nhập: $email';
  }

  @override
  String get surfaceSignOut => 'Đăng xuất';

  @override
  String get surfaceConfigErrorTitle => 'Ứng dụng chưa được cấu hình';

  @override
  String get surfaceConfigErrorBody =>
      'Không xác định được ứng dụng cần mở. Hãy khởi động bằng một trong các entrypoint đã được ghi trong tài liệu.';

  @override
  String get adminReviewModerationUncertain =>
      'Không rõ kết quả của thao tác vừa rồi. Trang đã được tải lại — hãy kiểm tra trạng thái đánh giá trước khi thử lại.';

  @override
  String get authErrorGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get authErrorNetwork =>
      'Không kết nối được máy chủ. Kiểm tra kết nối rồi thử lại.';

  @override
  String get authErrorTimeout => 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';

  @override
  String get authErrorServer =>
      'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';

  @override
  String get authErrorValidation =>
      'Vui lòng kiểm tra các trường được đánh dấu.';

  @override
  String get authErrorEmailTaken => 'Email này đã có tài khoản.';

  @override
  String get authErrorInvalidCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authErrorAccountDisabled =>
      'Tài khoản này đã bị vô hiệu hoá. Liên hệ hỗ trợ để khôi phục.';

  @override
  String get authErrorAccountUnavailable =>
      'Tài khoản này không thể đăng nhập. Liên hệ hỗ trợ.';

  @override
  String get authErrorEmailNotVerified =>
      'Hãy xác minh email trước khi đăng nhập.';

  @override
  String get authErrorTokenInvalid =>
      'Liên kết không hợp lệ hoặc đã được sử dụng.';

  @override
  String get authErrorTokenExpired =>
      'Liên kết đã hết hạn. Hãy yêu cầu liên kết mới.';

  @override
  String get authErrorCurrentPassword => 'Mật khẩu hiện tại không đúng.';

  @override
  String get authErrorPasswordUnchanged =>
      'Hãy chọn mật khẩu khác với mật khẩu hiện tại.';

  @override
  String get authErrorEmailDelivery =>
      'Hiện chưa gửi được email. Vui lòng thử lại sau.';

  @override
  String get authErrorSessionExpired =>
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.';

  @override
  String get authValidationPasswordMax => 'Mật khẩu tối đa 72 byte.';

  @override
  String get authValidationTermsRequired =>
      'Hãy đồng ý điều khoản Đối tác để tiếp tục.';

  @override
  String get authValidationTokenRequired => 'Hãy dán mã từ liên kết của bạn.';

  @override
  String get authPartnerBecomeQuestion => 'Bạn mới biết Plan Your Trip?';

  @override
  String get authPartnerBecomeAction => 'Trở thành Đối tác';

  @override
  String get partnerRegisterTitle => 'Tạo tài khoản Đối tác';

  @override
  String get partnerRegisterSubtitle =>
      'Đăng chỗ nghỉ và quản lý đặt phòng, giá, thanh toán trong một nơi làm việc.';

  @override
  String get partnerRegisterAction => 'Tạo tài khoản Đối tác';

  @override
  String get partnerRegisterTerms =>
      'Tôi đồng ý với điều khoản dành cho Đối tác';

  @override
  String get partnerRegisterTermsHint =>
      'Phiên bản điều khoản bạn đồng ý sẽ được lưu cùng tài khoản.';

  @override
  String get partnerRegisterHaveAccount => 'Đã có tài khoản Đối tác?';

  @override
  String get partnerRegisterSignInAction => 'Đăng nhập';

  @override
  String get verifyEmailTitle => 'Xác minh email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Tài khoản Đối tác cho $email đã được tạo. Hãy xác minh địa chỉ này để đăng nhập.';
  }

  @override
  String get verifyEmailNoDeliveryNotice =>
      'Ở môi trường phát triển nội bộ, không có email nào được gửi. Backend ghi liên kết xác minh kèm nhãn [DEV ONLY — NO EMAIL SENT]; hãy sao chép phần sau #token= và dán vào ô bên dưới.';

  @override
  String get verifyEmailTokenLabel => 'Mã xác minh';

  @override
  String get verifyEmailAction => 'Xác minh email';

  @override
  String get verifyEmailSuccessTitle => 'Đã xác minh email';

  @override
  String get verifyEmailSuccessBody =>
      'Địa chỉ của bạn đã được xác minh. Bạn có thể đăng nhập vào nơi làm việc Đối tác.';

  @override
  String get verifyEmailAlreadyTitle => 'Đã xác minh trước đó';

  @override
  String get verifyEmailAlreadyBody =>
      'Email này đã được xác minh. Bạn có thể đăng nhập.';

  @override
  String get verifyEmailContinueAction => 'Tiếp tục đến đăng nhập Đối tác';

  @override
  String get verifyEmailResendAction => 'Gửi lại xác minh';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return 'Bạn có thể yêu cầu liên kết xác minh khác sau $seconds giây.';
  }

  @override
  String get verifyEmailResendAck =>
      'Nếu địa chỉ đó đang chờ xác minh, liên kết mới sẽ được gửi.';

  @override
  String get verifyEmailBackAction => 'Quay lại đăng nhập Đối tác';

  @override
  String get forgotPasswordAck =>
      'Nếu địa chỉ đó có tài khoản, liên kết đặt lại mật khẩu sẽ được gửi.';

  @override
  String get forgotPasswordNoDeliveryNotice =>
      'Ở môi trường phát triển nội bộ, không có email nào được gửi. Backend ghi liên kết đặt lại kèm nhãn [DEV ONLY — NO EMAIL SENT].';

  @override
  String get resetPasswordTitle => 'Đặt mật khẩu mới';

  @override
  String get resetPasswordSubtitle =>
      'Dán mã từ liên kết đặt lại và chọn mật khẩu mới.';

  @override
  String get resetPasswordTokenLabel => 'Mã đặt lại';

  @override
  String get resetPasswordNewLabel => 'Mật khẩu mới';

  @override
  String get resetPasswordAction => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordSuccessTitle => 'Đã đặt lại mật khẩu';

  @override
  String get resetPasswordSuccessBody =>
      'Mật khẩu đã được đổi và mọi phiên đăng nhập khác đã bị đăng xuất.';

  @override
  String get resetPasswordBackAction => 'Quay lại đăng nhập';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordSubtitle =>
      'Đổi mật khẩu sẽ đăng xuất mọi thiết bị khác.';

  @override
  String get changePasswordCurrentLabel => 'Mật khẩu hiện tại';

  @override
  String get changePasswordAction => 'Cập nhật mật khẩu';

  @override
  String get changePasswordSuccess => 'Đã đổi mật khẩu thành công.';

  @override
  String get accountTitle => 'Tài khoản';

  @override
  String get accountDetailsHeading => 'Thông tin tài khoản';

  @override
  String get accountRoleLabel => 'Vai trò';

  @override
  String get accountRolePartner => 'Đối tác';

  @override
  String get accountRoleAdmin => 'Quản trị viên';

  @override
  String get accountRoleUser => 'Khách du lịch';

  @override
  String get accountSecurityHeading => 'Bảo mật';

  @override
  String get accountSecurityBody => 'Cập nhật mật khẩu bạn dùng để đăng nhập.';

  @override
  String get accountBackToWorkspace => 'Quay lại nơi làm việc';

  @override
  String get accountBackToConsole => 'Quay lại bảng điều khiển';

  @override
  String get accountOpenAction => 'Tài khoản';

  @override
  String get partnerBusinessHeading => 'Hồ sơ doanh nghiệp';

  @override
  String get partnerBusinessNoneTitle => 'Chưa có hồ sơ doanh nghiệp';

  @override
  String get partnerBusinessNoneBody =>
      'Hãy nhập thông tin doanh nghiệp và gửi duyệt để mở nơi làm việc Đối tác.';

  @override
  String get partnerBusinessAddAction => 'Thêm thông tin doanh nghiệp';

  @override
  String get partnerBusinessEditAction => 'Sửa thông tin doanh nghiệp';

  @override
  String get partnerBusinessSaveAction => 'Lưu';

  @override
  String get partnerBusinessSubmitAction => 'Lưu và gửi duyệt';

  @override
  String get partnerBusinessSavedMessage => 'Đã lưu thông tin doanh nghiệp.';

  @override
  String get partnerBusinessSubmittedMessage => 'Đã gửi duyệt.';

  @override
  String get partnerBusinessStatusDraftBody =>
      'Hoàn tất thông tin doanh nghiệp và gửi duyệt.';

  @override
  String get partnerBusinessStatusSubmittedBody =>
      'Hồ sơ Đối tác của bạn đang chờ quản trị viên duyệt.';

  @override
  String get partnerBusinessStatusApprovedBody =>
      'Tài khoản Đối tác đã được duyệt. Nơi làm việc đã mở.';

  @override
  String get partnerBusinessStatusRejectedBody =>
      'Hồ sơ bị từ chối. Hãy cập nhật thông tin doanh nghiệp và gửi lại.';

  @override
  String get partnerBusinessStatusSuspendedBody =>
      'Quyền Đối tác của bạn đang bị tạm ngưng. Liên hệ hỗ trợ.';

  @override
  String get partnerBusinessStatusUnknownBody =>
      'Hồ sơ có trạng thái mà ứng dụng chưa nhận diện được.';

  @override
  String partnerBusinessRejectReason(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String get partnerBusinessFieldName => 'Tên doanh nghiệp';

  @override
  String get partnerBusinessFieldType => 'Loại hình';

  @override
  String get partnerBusinessFieldRepresentative => 'Người đại diện';

  @override
  String get partnerBusinessFieldPhone => 'Điện thoại doanh nghiệp';

  @override
  String get partnerBusinessFieldEmail => 'Email doanh nghiệp';

  @override
  String get partnerBusinessFieldAddress => 'Địa chỉ doanh nghiệp';

  @override
  String get partnerBusinessFieldTaxCode => 'Mã số thuế';

  @override
  String get partnerBusinessFieldWebsite => 'Website';

  @override
  String partnerBusinessOptionalSuffix(String label) {
    return '$label (không bắt buộc)';
  }

  @override
  String get partnerBusinessTypeHotel => 'Khách sạn';

  @override
  String get partnerBusinessTypeRestaurant => 'Nhà hàng';

  @override
  String get partnerBusinessTypeCafe => 'Quán cà phê';

  @override
  String get partnerBusinessTypeTourOperator => 'Đơn vị lữ hành';

  @override
  String get partnerBusinessTypeTransport => 'Vận chuyển';

  @override
  String get partnerBusinessTypeOther => 'Khác';

  @override
  String get partnerBusinessTypeUnknown => 'Loại hình chưa nhận diện';

  @override
  String get partnerBusinessValidationRequired => 'Trường này là bắt buộc.';

  @override
  String get partnerNavTeam => 'Nhóm';

  @override
  String get partnerTeamRoleRevenue => 'Doanh thu';

  @override
  String get partnerTeamRoleReservations => 'Đặt phòng';

  @override
  String get partnerTeamRoleContent => 'Nội dung';

  @override
  String get partnerTeamRoleHousekeeping => 'Buồng phòng';

  @override
  String get partnerTeamScopeField => 'Áp dụng cho';

  @override
  String get partnerTeamScopeCompany => 'Toàn công ty';

  @override
  String get partnerTeamScopeProperty => 'Cơ sở lưu trú';

  @override
  String get partnerTeamScopeUnit => 'Loại phòng';

  @override
  String partnerTeamScopePropertyNumber(int id) {
    return 'Cơ sở #$id';
  }

  @override
  String partnerTeamScopeUnitNumber(int id) {
    return 'Loại phòng #$id';
  }

  @override
  String get partnerTeamScopeChoose => 'Chọn';

  @override
  String get partnerTeamScopeChooseRole => 'Hãy chọn vai trò trước';

  @override
  String get partnerTeamScopeNoRooms => 'Cơ sở này chưa có loại phòng';

  @override
  String get partnerTeamScopeNoneForRole =>
      'Bạn không thể cấp vai trò này ở phạm vi nào bạn quản lý.';

  @override
  String get partnerTeamStatusActive => 'Đang hoạt động';

  @override
  String get partnerTeamStatusSuspended => 'Đã tạm ngưng';

  @override
  String get partnerTeamStatusRevoked => 'Đã gỡ';

  @override
  String get partnerInvitationStatusPending => 'Đang chờ';

  @override
  String get partnerInvitationStatusAccepted => 'Đã chấp nhận';

  @override
  String get partnerInvitationStatusDeclined => 'Đã từ chối';

  @override
  String get partnerInvitationStatusRevoked => 'Đã thu hồi';

  @override
  String get partnerInvitationStatusExpired => 'Đã hết hạn';

  @override
  String get partnerInvitationDeliveryQueued => 'Chưa xác nhận gửi email';

  @override
  String get partnerInvitationDeliverySent => 'Đã gửi email';

  @override
  String get partnerInvitationDeliveryFailed => 'Gửi email thất bại';

  @override
  String get partnerTeamScreenTitle => 'Nhóm';

  @override
  String get partnerTeamScreenSubtitle =>
      'Ai có thể làm việc trong không gian đối tác này, với vai trò nào và ở đâu. Thay đổi có hiệu lực ở yêu cầu tiếp theo của thành viên.';

  @override
  String partnerTeamCountMembers(int count) {
    return 'Thành viên: $count';
  }

  @override
  String partnerTeamCountSuspended(int count) {
    return 'Tạm ngưng: $count';
  }

  @override
  String partnerTeamCountPending(int count) {
    return 'Lời mời đang chờ: $count';
  }

  @override
  String get partnerTeamReadOnly =>
      'Bạn có thể xem nhóm nhưng không thể thay đổi. Thay đổi nhóm cần quyền quản lý nhóm.';

  @override
  String get partnerTeamNoAccess =>
      'Vai trò của bạn không bao gồm quyền xem nhóm.';

  @override
  String get partnerTeamAccessUnavailable =>
      'Không tải được quyền truy cập của bạn nên các thao tác nhóm không khả dụng. Hãy làm mới để thử lại.';

  @override
  String get partnerTeamLoading => 'Đang tải nhóm';

  @override
  String get partnerTeamLoadFailed => 'Không tải được danh sách nhóm.';

  @override
  String get partnerTeamMembersHeading => 'Thành viên';

  @override
  String get partnerTeamMembersSubtitle =>
      'Các thành viên đang hoạt động và tạm ngưng mà bạn được xem. Thành viên đã gỡ được lưu làm lịch sử và không hiển thị.';

  @override
  String get partnerTeamMembersEmpty =>
      'Chưa có thành viên nào trong phạm vi bạn xem.';

  @override
  String get partnerTeamColumnMember => 'Thành viên';

  @override
  String get partnerTeamColumnAccess => 'Vai trò và phạm vi';

  @override
  String get partnerTeamColumnStatus => 'Trạng thái';

  @override
  String get partnerTeamYou => 'Bạn';

  @override
  String get partnerTeamPrimaryOwner => 'Chủ sở hữu chính';

  @override
  String get partnerTeamPrimaryOwnerProtected =>
      'Chủ sở hữu chính — được bảo vệ, không thể thay đổi trong không gian làm việc';

  @override
  String get partnerTeamPendingOwner => 'Chờ xác nhận chủ sở hữu';

  @override
  String partnerTeamGrantLabel(String role, String scope) {
    return '$role · $scope';
  }

  @override
  String partnerTeamMemberActions(String name) {
    return 'Thao tác cho $name';
  }

  @override
  String get partnerTeamEditAccess => 'Sửa vai trò và phạm vi';

  @override
  String get partnerTeamSuspend => 'Tạm ngưng';

  @override
  String get partnerTeamReactivate => 'Kích hoạt lại';

  @override
  String get partnerTeamRemoveAction => 'Gỡ khỏi nhóm';

  @override
  String get partnerTeamLeave => 'Rời không gian làm việc này';

  @override
  String get partnerTeamCancel => 'Hủy';

  @override
  String get partnerTeamReasonLabel => 'Lý do (không bắt buộc)';

  @override
  String get partnerTeamOwnerStepUpHint =>
      'Thay đổi liên quan đến chủ sở hữu sẽ yêu cầu bạn xác nhận mật khẩu.';

  @override
  String get partnerTeamSuspendTitle => 'Tạm ngưng thành viên này?';

  @override
  String partnerTeamSuspendBody(String name) {
    return '$name sẽ mất quyền truy cập ở yêu cầu tiếp theo. Vai trò và phạm vi được giữ lại để kích hoạt sau.';
  }

  @override
  String get partnerTeamReactivateTitle => 'Kích hoạt lại thành viên này?';

  @override
  String partnerTeamReactivateBody(String name) {
    return '$name sẽ có lại vai trò và phạm vi trước đó.';
  }

  @override
  String get partnerTeamRemoveTitle => 'Gỡ thành viên này?';

  @override
  String partnerTeamRemoveBody(String name) {
    return '$name sẽ mất quyền truy cập. Tư cách thành viên được lưu làm lịch sử và không thể khôi phục; muốn làm việc lại, hãy gửi lời mời mới.';
  }

  @override
  String get partnerTeamLeaveTitle => 'Rời không gian làm việc này?';

  @override
  String get partnerTeamLeaveBody =>
      'Bạn sẽ mất quyền truy cập không gian đối tác này ngay lập tức. Muốn quay lại, chủ sở hữu hoặc quản lý phải mời bạn lần nữa.';

  @override
  String get partnerTeamSaved => 'Đã lưu vai trò và phạm vi.';

  @override
  String get partnerTeamSuspended => 'Đã tạm ngưng thành viên.';

  @override
  String get partnerTeamReactivated => 'Đã kích hoạt lại thành viên.';

  @override
  String get partnerTeamRemoved => 'Đã gỡ thành viên.';

  @override
  String get partnerTeamLeft => 'Bạn đã rời không gian làm việc.';

  @override
  String get partnerTeamConcurrentReloaded =>
      'Thành viên này đã thay đổi kể từ khi bạn mở. Danh sách đã được làm mới — hãy xem lại và thử lại.';

  @override
  String get partnerTeamGrantAdd => 'Thêm vai trò hoặc phạm vi';

  @override
  String get partnerTeamGrantRemove => 'Bỏ quyền này';

  @override
  String get partnerInvitesHeading => 'Lời mời';

  @override
  String get partnerInvitesSubtitle =>
      'Các lời mời bạn được xem. Chấp nhận một lời mời sẽ tạo tư cách thành viên mới với đúng các vai trò được mời.';

  @override
  String get partnerInvitesEmpty => 'Không có lời mời nào.';

  @override
  String get partnerInvitesUnavailable => 'Không tải được danh sách lời mời.';

  @override
  String get partnerInviteAction => 'Mời';

  @override
  String get partnerInviteTitle => 'Mời vào nhóm';

  @override
  String get partnerInviteBody =>
      'Địa chỉ email sẽ nhận một liên kết để tham gia bằng tài khoản Đối tác dùng địa chỉ đó. Không ai tham gia cho đến khi họ chấp nhận, và không tài khoản nào được tạo hay thay đổi.';

  @override
  String get partnerInviteEmailLabel => 'Địa chỉ email';

  @override
  String get partnerInviteEmailRequired => 'Hãy nhập địa chỉ email.';

  @override
  String get partnerInviteEmailInvalid => 'Hãy nhập địa chỉ email hợp lệ.';

  @override
  String get partnerInviteGrantsLabel => 'Vai trò và phạm vi';

  @override
  String get partnerInviteReview => 'Bạn sắp cấp';

  @override
  String get partnerInviteLimits =>
      'Lời mời có hiệu lực 7 ngày. Mỗi công ty có tối đa 20 lời mời đang chờ, mỗi địa chỉ được mời hoặc gửi lại mỗi phút một lần, và mỗi lời mời được gửi lại tối đa 5 lần.';

  @override
  String get partnerInviteSubmit => 'Gửi lời mời';

  @override
  String get partnerInviteRecorded =>
      'Đã ghi nhận yêu cầu mời. Trạng thái gửi hiển thị trong danh sách.';

  @override
  String get partnerInviteResend => 'Gửi lại';

  @override
  String get partnerInviteResent =>
      'Đã yêu cầu liên kết mới; liên kết trước không còn hiệu lực.';

  @override
  String get partnerInviteRevoke => 'Thu hồi';

  @override
  String get partnerInviteRevokeTitle => 'Thu hồi lời mời này?';

  @override
  String partnerInviteRevokeBody(String email) {
    return 'Liên kết đã gửi tới $email sẽ không còn hiệu lực.';
  }

  @override
  String get partnerInviteRevoked => 'Đã thu hồi lời mời.';

  @override
  String partnerInviteExpires(String date) {
    return 'Hết hạn $date';
  }

  @override
  String partnerInviteInvitedBy(String name) {
    return 'Người mời: $name';
  }

  @override
  String partnerInviteResends(int count, int max) {
    return 'Đã gửi lại $count/$max';
  }

  @override
  String partnerInviteResendAfter(String time) {
    return 'Có thể gửi lại sau $time';
  }

  @override
  String get partnerInviteResendLimit =>
      'Đã đạt giới hạn gửi lại — hãy thu hồi và gửi lời mời mới.';

  @override
  String get partnerTeamErrorEmailUnavailable =>
      'Hiện không gửi được email nên chưa có gì được gửi hay tạo. Hãy thử lại sau.';

  @override
  String get partnerTeamErrorRateLimited =>
      'Quá nhiều lời mời: hãy chờ một phút giữa các lần gửi, giữ tối đa 20 lời mời đang chờ và gửi lại tối đa 5 lần.';

  @override
  String get partnerTeamErrorAlreadyMember =>
      'Địa chỉ này đã thuộc về một thành viên trong nhóm.';

  @override
  String get partnerTeamErrorOwnerProtected =>
      'Chỉ chủ sở hữu mới quản lý được chủ sở hữu, và không thể thay đổi chủ sở hữu chính trong không gian làm việc.';

  @override
  String get partnerTeamErrorNotDelegable =>
      'Bạn không thể cấp hoặc quản lý vai trò hay phạm vi này.';

  @override
  String get partnerTeamErrorSelf =>
      'Bạn không thể thay đổi tư cách thành viên của chính mình. Bạn có thể rời không gian làm việc.';

  @override
  String get partnerTeamErrorStepUp =>
      'Hãy xác nhận mật khẩu để thực hiện thay đổi liên quan đến chủ sở hữu.';

  @override
  String get partnerTeamErrorLastOwner =>
      'Công ty phải giữ ít nhất một chủ sở hữu đang hoạt động.';

  @override
  String get partnerTeamErrorConcurrent =>
      'Đã có người thay đổi mục này. Hãy tải lại và thử lại.';

  @override
  String get partnerTeamErrorWorkspaceConflict =>
      'Người này đã thuộc một không gian đối tác khác.';

  @override
  String get partnerTeamErrorInvitationNotPending =>
      'Lời mời này không còn ở trạng thái chờ. Danh sách đã được làm mới.';

  @override
  String get partnerTeamErrorInvitationStale =>
      'Một phạm vi của lời mời này không còn thuộc công ty. Hãy thu hồi và mời lại.';

  @override
  String get partnerTeamErrorScopeInvalid =>
      'Không thể cấp vai trò đó ở phạm vi đó.';

  @override
  String get partnerTeamErrorPermission =>
      'Vai trò của bạn không cho phép thao tác này.';

  @override
  String get partnerTeamErrorReason =>
      'Lý do không được chứa mật khẩu, bí mật, khóa, mã truy cập hay số thẻ hoặc số tài khoản.';

  @override
  String get partnerTeamErrorEmail => 'Hãy nhập địa chỉ email hợp lệ.';

  @override
  String get partnerTeamErrorValidation =>
      'Một số thông tin không hợp lệ. Hãy kiểm tra và thử lại.';

  @override
  String get partnerTeamErrorSession =>
      'Phiên của bạn đã kết thúc. Hãy đăng nhập lại.';

  @override
  String get partnerTeamErrorGone =>
      'Mục này không còn khả dụng. Danh sách đã được làm mới.';

  @override
  String get partnerTeamErrorUncertain =>
      'Kết nối bị gián đoạn trước khi có phản hồi. Danh sách đã được làm mới — hãy kiểm tra thay đổi đã được thực hiện chưa.';

  @override
  String get partnerTeamErrorNetwork =>
      'Không kết nối được máy chủ. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get partnerTeamErrorServer => 'Máy chủ gặp lỗi. Hãy thử lại.';

  @override
  String get partnerEditGrantsTitle => 'Sửa vai trò và phạm vi';

  @override
  String get partnerEditGrantsBody =>
      'Các quyền này thay thế quyền hiện tại của thành viên. Bạn chỉ có thể cấp vai trò và phạm vi mình quản lý.';

  @override
  String get partnerEditGrantsSubmit => 'Lưu';

  @override
  String get partnerStepUpTitle => 'Xác nhận mật khẩu';

  @override
  String get partnerStepUpBody =>
      'Thay đổi liên quan đến chủ sở hữu cần lần đăng nhập gần đây. Hãy nhập mật khẩu để tiếp tục.';

  @override
  String get partnerStepUpPasswordLabel => 'Mật khẩu';

  @override
  String get partnerStepUpPasswordRequired => 'Hãy nhập mật khẩu.';

  @override
  String get partnerStepUpConfirm => 'Xác nhận';

  @override
  String get partnerAcceptTitle => 'Tham gia nhóm đối tác';

  @override
  String get partnerAcceptGuidance =>
      'Bạn đã mở một lời mời tham gia nhóm. Hãy đăng nhập bằng tài khoản Đối tác dùng địa chỉ được mời. Không thể dùng tài khoản du khách — nếu địa chỉ được mời là tài khoản du khách của bạn, hãy nhờ người mời dùng địa chỉ khác (ví dụ email công việc).';

  @override
  String get partnerAcceptJoinNote =>
      'Chấp nhận sẽ đưa bạn vào không gian đối tác đã mời với vai trò và phạm vi nhóm đã chọn. Việc này không tạo công ty riêng cho bạn.';

  @override
  String get partnerAcceptAction => 'Chấp nhận lời mời';

  @override
  String get partnerAcceptDecline => 'Từ chối';

  @override
  String get partnerAcceptDeclineTitle => 'Từ chối lời mời này?';

  @override
  String get partnerAcceptDeclineBody =>
      'Liên kết sẽ không còn hiệu lực. Nhóm sẽ phải mời bạn lại.';

  @override
  String get partnerAcceptDeclined => 'Bạn đã từ chối lời mời.';

  @override
  String get partnerAcceptSuccess =>
      'Bạn đã tham gia nhóm. Không gian làm việc sẽ mở với vai trò và phạm vi bạn được mời.';

  @override
  String get partnerAcceptOpenWorkspace => 'Mở không gian làm việc';

  @override
  String get partnerAcceptNoLink =>
      'Chưa mở liên kết lời mời nào. Hãy mở liên kết trong email mời — liên kết chỉ dùng được một lần.';

  @override
  String get partnerAcceptMineHeading => 'Lời mời gửi tới bạn';

  @override
  String get partnerAcceptErrorInvalid =>
      'Liên kết lời mời không hợp lệ hoặc đã được dùng. Hãy nhờ nhóm gửi lời mời mới.';

  @override
  String get partnerAcceptErrorExpired =>
      'Lời mời đã hết hạn. Hãy nhờ nhóm gửi lời mời mới.';

  @override
  String get partnerAcceptErrorPartnerAccount =>
      'Hãy tham gia bằng tài khoản Đối tác đã xác minh dùng địa chỉ được mời. Không thể dùng tài khoản du khách hoặc quản trị viên.';

  @override
  String get partnerAcceptErrorMismatch =>
      'Lời mời này được gửi tới địa chỉ khác. Hãy đăng nhập bằng tài khoản Đối tác dùng địa chỉ được mời.';

  @override
  String get partnerAcceptErrorOwnCompany =>
      'Tài khoản này đã có công ty riêng nên không thể tham gia không gian khác. Hãy dùng tài khoản Đối tác khác.';

  @override
  String get partnerAcceptErrorOtherWorkspace =>
      'Tài khoản này đã thuộc một không gian đối tác. Hãy rời khỏi đó trước hoặc dùng tài khoản Đối tác khác.';

  @override
  String get partnerAcceptErrorUnavailable =>
      'Công ty này hiện không thể nhận thành viên mới.';

  @override
  String get partnerAcceptErrorStale =>
      'Lời mời này không còn hiệu lực. Hãy nhờ nhóm gửi lời mời mới.';

  @override
  String get adminSectionAccess => 'Truy cập';

  @override
  String get adminNavAccess => 'Quản trị viên';

  @override
  String get adminNoProfileTitle => 'Chưa có hồ sơ quản trị';

  @override
  String get adminNoProfileMessage =>
      'Tài khoản của bạn là tài khoản quản trị nhưng chưa được gán hồ sơ quản trị nào, nên không thể dùng phần nào của bảng điều khiển. Hãy nhờ chủ sở hữu nền tảng gán hồ sơ cho bạn.';

  @override
  String get adminAccessLoadFailed =>
      'Không thể tải quyền quản trị của bạn. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get adminAccessSubtitle =>
      'Hồ sơ quản trị quyết định mỗi quản trị viên được làm gì. Thay đổi có hiệu lực từ yêu cầu tiếp theo của họ; bạn không thể tự đổi hồ sơ của mình.';

  @override
  String get adminAccessRefresh => 'Tải lại danh sách quản trị viên';

  @override
  String get adminAccessEmptyTitle => 'Không có quản trị viên';

  @override
  String get adminAccessEmptyMessage =>
      'Không tìm thấy tài khoản quản trị nào.';

  @override
  String get adminAccessEdit => 'Sửa hồ sơ';

  @override
  String get adminAccessSelfHint => 'Bạn không thể tự đổi hồ sơ của mình';

  @override
  String get adminAccessUnknownHint =>
      'Quản trị viên này có một hồ sơ mà phiên bản bảng điều khiển này chưa biết. Hãy cập nhật bảng điều khiển trước khi đổi hồ sơ của họ.';

  @override
  String get adminAccessYou => 'Bạn';

  @override
  String get adminAccessDisabled => 'Đã vô hiệu hóa';

  @override
  String get adminAccessNoProfiles => 'Chưa có hồ sơ';

  @override
  String adminAccessEditTitle(String name) {
    return 'Hồ sơ của $name';
  }

  @override
  String get adminAccessEditHint =>
      'Quản trị viên có quyền là hợp của các hồ sơ được chọn. Bỏ chọn tất cả để thu hồi mọi quyền.';

  @override
  String get adminAccessReason => 'Lý do (không bắt buộc)';

  @override
  String get adminAccessCancel => 'Hủy';

  @override
  String get adminAccessSave => 'Lưu hồ sơ';

  @override
  String get adminAccessSaved => 'Đã lưu hồ sơ quản trị.';

  @override
  String get adminAccessErrorLastOwner =>
      'Phải còn ít nhất một chủ sở hữu nền tảng.';

  @override
  String get adminAccessErrorSelf =>
      'Bạn không thể tự đổi hồ sơ quản trị của mình.';

  @override
  String get adminAccessErrorPermission =>
      'Chỉ chủ sở hữu nền tảng mới được đổi hồ sơ quản trị.';

  @override
  String get adminAccessErrorStepUp =>
      'Hãy xác nhận mật khẩu để đổi hồ sơ quản trị.';

  @override
  String get adminAccessErrorValidation =>
      'Chỉ chọn các hồ sơ quản trị hợp lệ, và lý do không được chứa thông tin đăng nhập.';

  @override
  String get adminAccessErrorUncertain =>
      'Không chắc thay đổi đã được lưu hay chưa. Danh sách đã được tải lại — hãy kiểm tra trước khi thử lại.';

  @override
  String get adminAccessErrorGone =>
      'Quản trị viên này không còn tồn tại. Danh sách đã được tải lại.';

  @override
  String get adminAccessErrorNetwork =>
      'Không thể kết nối máy chủ. Hãy thử lại.';

  @override
  String get adminProfilePlatformOwner => 'Chủ sở hữu nền tảng';

  @override
  String get adminProfilePartnerOperations => 'Vận hành đối tác';

  @override
  String get adminProfileContentCatalogue => 'Nội dung danh mục';

  @override
  String get adminProfileBookingSupport => 'Hỗ trợ đặt phòng';

  @override
  String get adminProfileFinanceOperations => 'Vận hành tài chính';

  @override
  String get adminProfileGrowthMarketing => 'Tăng trưởng & tiếp thị';

  @override
  String get adminProfileTrustSafety => 'Tin cậy & an toàn';

  @override
  String get adminProfileReviewModeration => 'Kiểm duyệt đánh giá';

  @override
  String get adminProfileAnalytics => 'Phân tích';

  @override
  String get adminProfileLocationCatalogue => 'Danh mục địa điểm hành chính';

  @override
  String get adminProfileTechSupport => 'Hỗ trợ kỹ thuật';

  @override
  String get adminProfilePlatformOwnerHint =>
      'Mọi quyền quản trị, gồm quản lý quản trị viên, chuyển cơ sở lưu trú giữa các công ty và gửi thông báo hàng loạt.';

  @override
  String get adminProfilePartnerOperationsHint =>
      'Xác minh và tạm ngưng đối tác, quản lý tồn phòng và giá thay đối tác.';

  @override
  String get adminProfileContentCatalogueHint =>
      'Địa điểm, phòng, hình ảnh, danh mục, tiện nghi, kiểm duyệt và xuất bản.';

  @override
  String get adminProfileBookingSupportHint =>
      'Đặt phòng, hội thoại, khách hàng, xem thanh toán và hóa đơn.';

  @override
  String get adminProfileFinanceOperationsHint =>
      'Hoàn tiền, can thiệp thanh toán, hóa đơn, giá trị lưu trữ và tín dụng.';

  @override
  String get adminProfileGrowthMarketingHint =>
      'Khuyến mãi, mã giảm giá, sản phẩm thẻ quà tặng, chương trình khách hàng, cá nhân hóa.';

  @override
  String get adminProfileTrustSafetyHint =>
      'Nhật ký kiểm toán, tạm ngưng đối tác, gỡ tin đăng, hội thoại, kiểm duyệt đánh giá.';

  @override
  String get adminProfileReviewModerationHint => 'Hàng đợi đánh giá.';

  @override
  String get adminProfileAnalyticsHint =>
      'Chỉ báo cáo tổng hợp — không có dữ liệu từng dòng hay dữ liệu cá nhân.';

  @override
  String get adminProfileLocationCatalogueHint => 'Cây đơn vị hành chính.';

  @override
  String get adminProfileTechSupportHint =>
      'Nhật ký kiểm toán, xem đặt phòng và thanh toán với danh tính khách được che, tác vụ hệ thống.';
}
