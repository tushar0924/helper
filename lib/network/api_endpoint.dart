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
}

class HomeApiEndpoint {
  HomeApiEndpoint._();

  static const String categories = 'categories';
  static const String services = 'services';
}

class CartApiEndpoint {
  CartApiEndpoint._();

  static const String add = 'cart/add';
  static const String updateItem = 'cart/update-item';
  static const String summary = 'cart/summary';
  static const String clear = 'cart/clear';
  static const String availableCoupons = 'coupons/available';
}
