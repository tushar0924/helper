import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static String? _lastMessage;
  static DateTime? _lastShownAt;
  static const Duration _dedupeWindow = Duration(milliseconds: 1200);
  static const Duration _toastDuration = Duration(seconds: 2);
  static const Duration _retryDelay = Duration(milliseconds: 120);
  static const int _maxAttempts = 5;

  static Future<bool> success(String message) {
    return _show(
      message,
      backgroundColor: const Color(0xFF16A34A),
      textColor: Colors.white,
    );
  }

  static Future<bool> error(String message) {
    return _show(
      message,
      backgroundColor: const Color(0xFFDC2626),
      textColor: Colors.white,
    );
  }

  static Future<bool> info(String message) {
    return _show(
      message,
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
    );
  }

  static Future<bool> _show(
    String message, {
    required Color backgroundColor,
    required Color textColor,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    if (_lastMessage == trimmedMessage && _lastShownAt != null) {
      final elapsed = now.difference(_lastShownAt!);
      if (elapsed <= _dedupeWindow) {
        return false;
      }
    }

    _lastMessage = trimmedMessage;
    _lastShownAt = now;

    return _showSnackBar(
      message: trimmedMessage,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  static Future<bool> _showSnackBar({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    int attempt = 0,
  }) async {
    final messenger = messengerKey.currentState;
    if (messenger == null || !messenger.mounted) {
      if (attempt >= _maxAttempts) {
        debugPrint('AppToast dropped before messenger was ready: $message');
        return false;
      }

      await Future<void>.delayed(_retryDelay);
      return _showSnackBar(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        attempt: attempt + 1,
      );
    }

    try {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            duration: _toastDuration,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      return true;
    } catch (_) {
      return false;
    }
  }
}
