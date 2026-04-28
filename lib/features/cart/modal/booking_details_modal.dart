class BookingDetailsModal {
  const BookingDetailsModal({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.servicePlanId,
    required this.categoryId,
    required this.helperId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalHours,
    required this.paymentExpiresAt,
    required this.status,
    required this.location,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    required this.totalAmount,
    required this.platformFee,
    required this.tax,
    required this.finalAmount,
    required this.payoutStatus,
    required this.commissionRateSnapshot,
    required this.platformCommissionAmount,
    required this.helperPayoutAmount,
    required this.isPaymentExpired,
    required this.bookingRequestId,
    required this.createdAt,
    required this.updatedAt,
    required this.bookingDateLabel,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.startOtp,
    required this.serviceDisplayName,
    required this.formattedDate,
    required this.formattedTime,
    required this.fullAddress,
    required this.helper,
    required this.customer,
    required this.payment,
  });

  final int id;
  final int customerId;
  final int? serviceId;
  final int? servicePlanId;
  final int categoryId;
  final int helperId;
  final DateTime? bookingDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final int duration;
  final int totalHours;
  final DateTime? paymentExpiresAt;
  final String status;
  final String? location;
  final String? address;
  final String? city;
  final String? pinCode;
  final double latitude;
  final double longitude;
  final int totalAmount;
  final int platformFee;
  final int tax;
  final int finalAmount;
  final String payoutStatus;
  final double? commissionRateSnapshot;
  final double? platformCommissionAmount;
  final double? helperPayoutAmount;
  final bool isPaymentExpired;
  final String? bookingRequestId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? bookingDateLabel;
  final String? startTimeLabel;
  final String? endTimeLabel;
  final String? startOtp;
  final String serviceDisplayName;
  final String? formattedDate;
  final String? formattedTime;
  final String? fullAddress;
  final BookingHelperModal? helper;
  final BookingCustomerModal? customer;
  final BookingPaymentModal? payment;

  factory BookingDetailsModal.fromJson(Map<String, dynamic> json) {
    final helperJson = _asMap(json['helper']);
    final customerJson = _asMap(json['customer']);
    final paymentJson = _asMap(json['payment']);

    return BookingDetailsModal(
      id: _asInt(json['id']),
      customerId: _asInt(json['customerId']),
      serviceId: _asNullableInt(json['serviceId']),
      servicePlanId: _asNullableInt(json['servicePlanId']),
      categoryId: _asInt(json['categoryId']),
      helperId: _asInt(json['helperId']),
      bookingDate: DateTime.tryParse(json['bookingDate']?.toString() ?? ''),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      duration: _asInt(json['duration']),
      totalHours: _asInt(json['totalHours']),
      paymentExpiresAt: DateTime.tryParse(
        json['paymentExpiresAt']?.toString() ?? '',
      ),
      status: json['status']?.toString().toUpperCase() ?? '',
      location: json['location']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      pinCode: json['pinCode']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      totalAmount: _asInt(json['totalAmount']),
      platformFee: _asInt(json['platformFee']),
      tax: _asInt(json['tax']),
      finalAmount: _asInt(json['finalAmount']),
      payoutStatus: json['payoutStatus']?.toString().toUpperCase() ?? '',
      commissionRateSnapshot: _asNullableDouble(json['commissionRateSnapshot']),
      platformCommissionAmount: _asNullableDouble(
        json['platformCommissionAmount'],
      ),
      helperPayoutAmount: _asNullableDouble(json['helperPayoutAmount']),
      isPaymentExpired: json['isPaymentExpired'] == true,
      bookingRequestId: json['bookingRequestId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      bookingDateLabel: json['bookingDateLabel']?.toString(),
      startTimeLabel: json['startTimeLabel']?.toString(),
      endTimeLabel: json['endTimeLabel']?.toString(),
      startOtp: json['startOtp']?.toString(),
      serviceDisplayName: json['serviceDisplayName']?.toString() ?? 'Service',
      formattedDate: json['formattedDate']?.toString(),
      formattedTime: json['formattedTime']?.toString(),
      fullAddress: json['fullAddress']?.toString(),
      helper: helperJson == null
          ? null
          : BookingHelperModal.fromJson(helperJson),
      customer: customerJson == null
          ? null
          : BookingCustomerModal.fromJson(customerJson),
      payment: paymentJson == null
          ? null
          : BookingPaymentModal.fromJson(paymentJson),
    );
  }

  Map<String, dynamic> toPartnerDetailsMap() {
    final helperUser = helper?.user;
    return <String, dynamic>{
      'id': helper?.id ?? helperId,
      'userId': helper?.userId ?? 0,
      'name': helperUser?.fullName ?? 'Partner',
      'phone': helperUser?.phone ?? '',
      'rating': helper?.rating ?? 0,
      'experience': helperUser?.experience ?? '',
      'profileImage': helperUser?.profileImage ?? '',
      'bookingId': id,
      'serviceDisplayName': serviceDisplayName,
      'status': status,
    };
  }

  String get statusLabel => _toTitleCase(status);

  String get paymentStatusLabel =>
      payment == null ? 'Unknown' : _toTitleCase(payment!.status);

  String get displayDateLabel {
    final label = bookingDateLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    final formatted = formattedDate?.trim();
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }

    return bookingDate == null ? 'Date unavailable' : _formatDate(bookingDate!);
  }

  String get displayTimeLabel {
    final startLabel = startTimeLabel?.trim();
    final endLabel = endTimeLabel?.trim();
    if (startLabel != null && startLabel.isNotEmpty) {
      if (endLabel != null && endLabel.isNotEmpty) {
        return '$startLabel to $endLabel';
      }
      return startLabel;
    }

    final formatted = formattedTime?.trim();
    if (formatted != null && formatted.isNotEmpty) {
      return formatted;
    }

    if (startTime != null && endTime != null) {
      return '${_formatTime(startTime!)} to ${_formatTime(endTime!)}';
    }

    return 'Time unavailable';
  }

  String get otpLabel =>
      startOtp?.trim().isNotEmpty == true ? startOtp!.trim() : '----';
}

class BookingHelperModal {
  const BookingHelperModal({
    required this.id,
    required this.userId,
    required this.rating,
    required this.user,
  });

  final int id;
  final int userId;
  final double rating;
  final BookingHelperUserModal? user;

  factory BookingHelperModal.fromJson(Map<String, dynamic> json) {
    final userJson = _asMap(json['user']);
    return BookingHelperModal(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      rating: _asDouble(json['rating']),
      user: userJson == null ? null : BookingHelperUserModal.fromJson(userJson),
    );
  }

  String get displayName => user?.fullName.trim().isNotEmpty == true
      ? user!.fullName.trim()
      : 'Partner';
}

class BookingHelperUserModal {
  const BookingHelperUserModal({
    required this.fullName,
    required this.phone,
    required this.experience,
    required this.profileImage,
  });

  final String fullName;
  final String? phone;
  final String? experience;
  final String? profileImage;

  factory BookingHelperUserModal.fromJson(Map<String, dynamic> json) {
    return BookingHelperUserModal(
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      experience: json['experience']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }
}

class BookingCustomerModal {
  const BookingCustomerModal({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final int id;
  final String fullName;
  final String? phone;

  factory BookingCustomerModal.fromJson(Map<String, dynamic> json) {
    return BookingCustomerModal(
      id: _asInt(json['id']),
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class BookingPaymentModal {
  const BookingPaymentModal({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.method,
    required this.escrowStatus,
    required this.refundReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int bookingId;
  final int amount;
  final String status;
  final String? transactionId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? method;
  final String? escrowStatus;
  final String? refundReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookingPaymentModal.fromJson(Map<String, dynamic> json) {
    return BookingPaymentModal(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId']),
      amount: _asInt(json['amount']),
      status: json['status']?.toString().toUpperCase() ?? '',
      transactionId: json['transactionId']?.toString(),
      razorpayOrderId: json['razorpayOrderId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId']?.toString(),
      method: json['method']?.toString(),
      escrowStatus: json['escrowStatus']?.toString().toUpperCase(),
      refundReason: json['refundReason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return null;
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

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  final parsed = _asInt(value);
  return parsed == 0 ? null : parsed;
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String _toTitleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .toLowerCase()
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _formatDate(DateTime date) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  var hour12 = local.hour % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:$minute $period';
}
