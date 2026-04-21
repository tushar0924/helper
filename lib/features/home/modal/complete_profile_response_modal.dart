import 'user_profile_modal.dart';

class CompleteProfileResponseModal {
  const CompleteProfileResponseModal({
    required this.success,
    required this.message,
    required this.user,
  });

  final bool success;
  final String message;
  final UserProfileModal user;

  factory CompleteProfileResponseModal.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return CompleteProfileResponseModal(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      user: userJson is Map<String, dynamic>
          ? UserProfileModal.fromJson(userJson)
          : const UserProfileModal(
              id: 0,
              phone: '',
              fullName: '',
              email: null,
              gender: null,
              profileCompleted: false,
            ),
    );
  }
}
