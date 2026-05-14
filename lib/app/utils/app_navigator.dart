import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _logoutInProgress = false;
  static bool _dialogShowing = false;

  static Future<void> forceLogout({
    String message = 'Your session is expired',
  }) async {
    if (_logoutInProgress) {
      return;
    }

    _logoutInProgress = true;
    final navigator = navigatorKey.currentState;
    final context = navigator?.overlay?.context;
    if (context == null) {
      navigator?.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      _logoutInProgress = false;
      return;
    }

    if (_dialogShowing) {
      _logoutInProgress = false;
      return;
    }

    _dialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Session expired'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    _dialogShowing = false;
    navigator?.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    _logoutInProgress = false;
  }
}