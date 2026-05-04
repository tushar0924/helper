class ApiEndpoint {
  ApiEndpoint._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.zynexxindia.com/api/',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_BASE_URL',
    defaultValue: 'https://api.zynexxindia.com',
  );
}

class AuthApiEndpoint {
  AuthApiEndpoint._();

  static const String login = 'auth/login';
  static const String signup = 'auth/signup';
  static const String verifyOtp = 'auth/verify-otp';
  static const String helperVerifyOtp = 'auth/helper/verify-otp';
  static const String refreshToken = 'auth/refresh-token';
  static const String logout = 'auth/logout';
}

class PartnerApiEndpoint {
  PartnerApiEndpoint._();

  static const String onboardingStatus = 'partner/onboarding/status';
  static const String onboardingProfile = 'partner/onboarding/profile';
  static const String onboardingBank = 'partner/onboarding/bank';

  static const String uploadSelfie = 'partner/kyc/upload-selfie';
  static const String uploadPan = 'partner/kyc/upload-pan';
  static const String uploadAadhar = 'partner/kyc/upload-aadhar';
  static const String uploadPolice = 'partner/kyc/upload-police';

  static const String earningsSummary = 'partner/earnings/summary';

  static String bookingById(int bookingId) => 'partner/bookings/$bookingId';
}

class HomeApiEndpoint {
  HomeApiEndpoint._();

  static const String categories = 'categories';
  static const String services = 'services';
  static String homeByPincode(String pincode) => 'home?pincode=$pincode';
  static String banners({String? city}) {
    final normalized = city?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'banners';
    }
    return 'banners?city=${Uri.encodeQueryComponent(normalized)}';
  }
}

class ServiceabilityApiEndpoint {
  ServiceabilityApiEndpoint._();

  static const String notify = 'serviceability/notify';
}

class UserApiEndpoint {
  UserApiEndpoint._();

  static const String me = 'user/me';
  static const String profile = 'user/profile';
  static const String addresses = 'user/addresses';

  static String bookingById(int bookingId) => 'user/bookings/$bookingId';

  static String addressById(int id) => 'user/addresses/$id';
}

class CartApiEndpoint {
  CartApiEndpoint._();

  static const String add = 'cart/add';
  static const String updateItem = 'cart/update-item';
  static const String updateAddress = 'cart/update-address';
  static const String updateSlot = 'cart/update-slot';
  static const String summary = 'cart/summary';
  static const String clear = 'cart/clear';
  static const String availableCoupons = 'coupons/available';
  static const String applyCoupon = 'coupons/apply';
  static const String removeCoupon = 'coupons/remove';
  static const String appliedCoupons = 'coupons/applied';
}

class BookingRequestApiEndpoint {
  BookingRequestApiEndpoint._();

  static const String createFromCart = 'booking-requests/create-from-cart';
}

class PaymentApiEndpoint {
  PaymentApiEndpoint._();

  static const String initiate = 'payments/initiate';
  static const String createOrder = 'payments/create-order';
}
