import 'package:flutter/widgets.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/home/presentation/coming_soon_screen.dart';
import '../features/home/presentation/main_navigation_screen.dart';
import '../features/home/presentation/service_detail_screen.dart';
import '../features/home/presentation/service_view_detail_screen.dart';
import '../features/home/presentation/widgets/main_bottom_bar.dart';
import '../features/role/presentation/choose_role_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String homeComingSoon = '/home-coming-soon';
  static const String kiranaComingSoon = '/kirana-coming-soon';
  static const String serviceDetail = '/service-detail';
  static const String serviceViewDetail = '/service-view-detail';
  static const String cart = '/cart';
  static const String chooseRole = '/choose-role';

  static Map<String, WidgetBuilder> routes() => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    otp: (_) => const OtpScreen(),
    home: (_) => const MainNavigationScreen(),
    homeComingSoon: (_) =>
        const ComingSoonScreen(selectedTab: MainTab.home, pageLabel: 'Home'),
    kiranaComingSoon: (_) => const ComingSoonScreen(
      selectedTab: MainTab.kirana,
      pageLabel: 'Kirana4U',
    ),
    serviceDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final rawCategoryId = args == null ? null : args['categoryId'];
      final categoryId = rawCategoryId is int
          ? rawCategoryId
          : int.tryParse(rawCategoryId?.toString() ?? '') ?? 0;
      final title = args?['title']?.toString() ?? 'Service';
      final image = args?['image']?.toString() ?? '';
      return ServiceDetailScreen(
        categoryId: categoryId,
        serviceTitle: title,
        serviceImage: image,
      );
    },
    serviceViewDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final rawServiceId = args == null ? null : args['serviceId'];
      final serviceId = rawServiceId is int
          ? rawServiceId
          : int.tryParse(rawServiceId?.toString() ?? '') ?? 0;
      final title = args?['title']?.toString() ?? 'Service';
      final image = args?['image']?.toString() ?? '';
      final price = args?['price']?.toString() ?? '₹699';
      return ServiceViewDetailScreen(
        serviceId: serviceId,
        serviceTitle: title,
        serviceImage: image,
        price: price,
      );
    },
    cart: (_) => const CartScreen(),
    chooseRole: (_) => const ChooseRoleScreen(),
  };
}
