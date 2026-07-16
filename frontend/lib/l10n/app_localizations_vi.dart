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
  String get tripOverviewExpensesAction => 'Chi phí';

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
  String get commonBackSemantic => 'Quay lại';

  @override
  String get demoModeLabel => 'Chế độ demo';
}
