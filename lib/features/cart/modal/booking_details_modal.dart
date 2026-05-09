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
    required this.categoryName,
    required this.categoryImageUrl,
    required this.items,
    required this.itemsSummary,
    required this.formattedDate,
    required this.formattedTime,
    required this.fullAddress,
    required this.notes,
    required this.specialRequirements,
    required this.startedAt,
    required this.completedAt,
    required this.startedAtLabel,
    required this.completedAtLabel,
    required this.cancelReason,
    required this.ratings,
    required this.arrival,
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
  final String? categoryName;
  final String? categoryImageUrl;
  final List<BookingItemModal> items;
  final BookingItemsSummaryModal? itemsSummary;
  final String? formattedDate;
  final String? formattedTime;
  final String? fullAddress;
  final String? notes;
  final String? specialRequirements;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? startedAtLabel;
  final String? completedAtLabel;
  final String? cancelReason;
  final BookingRatingsModal? ratings;
  final BookingArrivalModal? arrival;
  final BookingHelperModal? helper;
  final BookingCustomerModal? customer;
  final BookingPaymentModal? payment;

  factory BookingDetailsModal.fromJson(Map<String, dynamic> json) {
    final helperJson = _asMap(json['helper']);
    final customerJson = _asMap(json['customer']);
    final paymentJson = _asMap(json['payment']);
    final categoryJson = _asMap(json['category']);
    final arrivalJson = _asMap(json['arrival']);
    final ratingsJson = _asMap(json['ratings']);
    final itemsSummaryJson = _asMap(json['itemsSummary']);

    final itemsList =
        (json['items'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => BookingItemModal.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList() ??
        const <BookingItemModal>[];

    final serviceDisplayName =
        json['serviceDisplayName']?.toString().trim() ??
        itemsSummaryJson?['serviceNames']?.toString().trim() ??
        (itemsList.isNotEmpty ? itemsList.first.serviceName : '') ??
        categoryJson?['name']?.toString().trim() ??
        'Service';

    final paymentExpiresRaw =
        json['paymentExpiresAt']?.toString() ??
        paymentJson?['expiresAt']?.toString();

    final computedDuration = _asInt(json['duration']);
    final computedTotalHours = _asInt(json['totalHours']);
    final itemsDurationFallback = itemsList.fold<int>(
      0,
      (acc, item) =>
          acc + (item.duration * (item.quantity <= 0 ? 1 : item.quantity)),
    );

    return BookingDetailsModal(
      id: _asInt(json['id']),
      customerId: _asInt(json['customerId'] ?? 0),
      serviceId: _asNullableInt(json['serviceId']),
      servicePlanId: _asNullableInt(json['servicePlanId']),
      categoryId: _asInt(
        json['categoryId'] ?? (categoryJson != null ? categoryJson['id'] : 0),
      ),
      helperId: helperJson != null
          ? _asInt(helperJson['id'])
          : _asInt(json['helperId']),
      bookingDate: DateTime.tryParse(json['bookingDate']?.toString() ?? ''),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      duration: computedDuration > 0
          ? computedDuration
          : (itemsDurationFallback > 0 ? itemsDurationFallback : 0),
      totalHours: computedTotalHours > 0
          ? computedTotalHours
          : (computedDuration > 0 ? computedDuration : itemsDurationFallback),
      paymentExpiresAt: DateTime.tryParse(paymentExpiresRaw ?? ''),
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
      serviceDisplayName: serviceDisplayName.isEmpty
          ? 'Service'
          : serviceDisplayName,
      categoryName: categoryJson == null
          ? null
          : categoryJson['name']?.toString(),
      categoryImageUrl: categoryJson == null
          ? null
          : categoryJson['imageUrl']?.toString(),
      items: itemsList,
      itemsSummary: itemsSummaryJson == null
          ? null
          : BookingItemsSummaryModal.fromJson(itemsSummaryJson),
      formattedDate: json['formattedDate']?.toString(),
      formattedTime: json['formattedTime']?.toString(),
      fullAddress: json['fullAddress']?.toString(),
      notes: json['notes']?.toString(),
      specialRequirements: json['specialRequirements']?.toString(),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      startedAtLabel: json['startedAtLabel']?.toString(),
      completedAtLabel: json['completedAtLabel']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      ratings: ratingsJson == null
          ? null
          : BookingRatingsModal.fromJson(ratingsJson),
      arrival: arrivalJson == null
          ? null
          : BookingArrivalModal.fromJson(arrivalJson),
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
    return <String, dynamic>{
      'id': helper?.id ?? helperId,
      'userId': helper?.userId ?? 0,
      'name': helper?.displayName ?? 'Partner',
      'phone': helper?.phone ?? '',
      'rating': helper?.rating ?? 0,
      'experience': helper?.experience ?? '',
      'profileImage': helper?.profileImage ?? '',
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

  bool get hasTrackingEnabled => arrival?.trackingEnabled == true;

  bool get isServiceRated => ratings?.serviceRated == true;

  bool get isPartnerRated => ratings?.partnerRated == true;

  String? get primaryServiceImageUrl {
    if (items.isNotEmpty && items.first.imageUrl != null) {
      final image = items.first.imageUrl!.trim();
      if (image.isNotEmpty) {
        return image;
      }
    }
    final categoryImage = categoryImageUrl?.trim();
    if (categoryImage != null && categoryImage.isNotEmpty) {
      return categoryImage;
    }
    return null;
  }
}

class BookingItemModal {
  const BookingItemModal({
    required this.serviceId,
    required this.serviceName,
    required this.imageUrl,
    required this.quantity,
    required this.duration,
    required this.price,
  });

  final int serviceId;
  final String serviceName;
  final String? imageUrl;
  final int quantity;
  final int duration;
  final int price;

  factory BookingItemModal.fromJson(Map<String, dynamic> json) {
    return BookingItemModal(
      serviceId: _asInt(json['serviceId']),
      serviceName: json['serviceName']?.toString() ?? 'Service',
      imageUrl: json['imageUrl']?.toString(),
      quantity: _asInt(json['quantity']),
      duration: _asInt(json['duration']),
      price: _asInt(json['price']),
    );
  }
}

class BookingItemsSummaryModal {
  const BookingItemsSummaryModal({
    required this.totalItems,
    required this.serviceNames,
  });

  final int totalItems;
  final String serviceNames;

  factory BookingItemsSummaryModal.fromJson(Map<String, dynamic> json) {
    return BookingItemsSummaryModal(
      totalItems: _asInt(json['totalItems']),
      serviceNames: json['serviceNames']?.toString() ?? '',
    );
  }
}

class BookingRatingsModal {
  const BookingRatingsModal({
    required this.serviceRated,
    required this.partnerRated,
  });

  final bool serviceRated;
  final bool partnerRated;

  factory BookingRatingsModal.fromJson(Map<String, dynamic> json) {
    return BookingRatingsModal(
      serviceRated: json['serviceRated'] == true,
      partnerRated: json['partnerRated'] == true,
    );
  }
}

class BookingArrivalModal {
  const BookingArrivalModal({
    required this.trackingEnabled,
    required this.arrivalState,
    required this.etaSeconds,
    required this.helperLocation,
    required this.isLocationStale,
  });

  final bool trackingEnabled;
  final String? arrivalState;
  final int? etaSeconds;
  final BookingLocationModal? helperLocation;
  final bool isLocationStale;

  factory BookingArrivalModal.fromJson(Map<String, dynamic> json) {
    final helperLocationJson = _asMap(json['helperLocation']);
    return BookingArrivalModal(
      trackingEnabled: json['trackingEnabled'] == true,
      arrivalState: json['arrivalState']?.toString().toUpperCase(),
      etaSeconds: _asNullableInt(json['etaSeconds']),
      helperLocation: helperLocationJson == null
          ? null
          : BookingLocationModal.fromJson(helperLocationJson),
      isLocationStale: json['isLocationStale'] == true,
    );
  }
}

class BookingLocationModal {
  const BookingLocationModal({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory BookingLocationModal.fromJson(Map<String, dynamic> json) {
    return BookingLocationModal(
      lat: _asDouble(json['lat'] ?? json['latitude']),
      lng: _asDouble(json['lng'] ?? json['longitude']),
    );
  }

  bool get isValid => lat != 0 && lng != 0;
}

class BookingHelperModal {
  const BookingHelperModal({
    required this.id,
    required this.userId,
    required this.rating,
    required this.totalRatings,
    required this.fullName,
    required this.phone,
    required this.profileImage,
    required this.experienceYears,
    required this.verified,
    required this.user,
  });

  final int id;
  final int userId;
  final double rating;
  final int totalRatings;
  final String fullName;
  final String? phone;
  final String? profileImage;
  final int experienceYears;
  final bool verified;
  final BookingHelperUserModal? user;

  factory BookingHelperModal.fromJson(Map<String, dynamic> json) {
    final userJson = _asMap(json['user']);
    final normalizedFullName =
        json['fullName']?.toString() ?? userJson?['fullName']?.toString() ?? '';
    final normalizedPhone =
        json['phone']?.toString() ?? userJson?['phone']?.toString();
    final normalizedProfileImage =
        json['profileImage']?.toString() ??
        userJson?['profileImage']?.toString();

    final normalizedUser = userJson == null
        ? BookingHelperUserModal(
            fullName: normalizedFullName,
            phone: normalizedPhone,
            experience:
                json['experience']?.toString() ??
                json['experienceYears']?.toString(),
            profileImage: normalizedProfileImage,
          )
        : BookingHelperUserModal.fromJson(userJson);

    return BookingHelperModal(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      rating: _asDouble(json['rating']),
      totalRatings: _asInt(json['totalRatings']),
      fullName: normalizedFullName,
      phone: normalizedPhone,
      profileImage: normalizedProfileImage,
      experienceYears: _asInt(json['experienceYears']),
      verified: json['verified'] == true,
      user: normalizedUser,
    );
  }

  String get displayName {
    final nested = user?.fullName.trim();
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }

    final direct = fullName.trim();
    if (direct.isNotEmpty) {
      return direct;
    }

    return 'Partner';
  }

  String? get experience {
    final nested = user?.experience?.trim();
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
    if (experienceYears > 0) {
      return '$experienceYears years';
    }
    return null;
  }
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
    required this.expiresAt,
    required this.remainingSeconds,
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
  final DateTime? expiresAt;
  final int? remainingSeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BookingPaymentModal.fromJson(Map<String, dynamic> json) {
    // API returns different shapes for payment between endpoints.
    // Support both detailed payment object and lightweight one.
    return BookingPaymentModal(
      id: _asInt(json['id'] ?? 0),
      bookingId: _asInt(json['bookingId'] ?? json['id'] ?? 0),
      amount: _asInt(json['amount'] ?? 0),
      status: json['status']?.toString().toUpperCase() ?? '',
      transactionId: json['transactionId']?.toString(),
      razorpayOrderId: json['razorpayOrderId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId']?.toString(),
      method: json['method']?.toString(),
      escrowStatus: json['escrowStatus']?.toString().toUpperCase(),
      refundReason: json['refundReason']?.toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      remainingSeconds: _asNullableRawInt(json['remainingSeconds']),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? json['expiresAt']?.toString() ?? '',
      ),
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

int? _asNullableRawInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
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
