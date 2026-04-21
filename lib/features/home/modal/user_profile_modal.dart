class UserProfileModal {
  const UserProfileModal({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.profileCompleted,
  });

  final int id;
  final String phone;
  final String fullName;
  final String? email;
  final String? gender;
  final bool profileCompleted;

  factory UserProfileModal.fromJson(Map<String, dynamic> json) {
    return UserProfileModal(
      id: _asInt(json['id']),
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      profileCompleted: json['profileCompleted'] == true,
    );
  }
}

class UserProfileResponseModal {
  const UserProfileResponseModal({
    required this.success,
    required this.data,
  });

  final bool success;
  final UserProfileModal data;

  factory UserProfileResponseModal.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return UserProfileResponseModal(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? UserProfileModal.fromJson(dataJson)
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

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
