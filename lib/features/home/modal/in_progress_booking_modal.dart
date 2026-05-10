class InProgressBookingModal {
  const InProgressBookingModal({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.bookingDate,
    required this.startTime,
    required this.serviceImage,
  });

  final int id;
  final String status;
  final String serviceName;
  final String bookingDate;
  final String startTime;
  final String serviceImage;

  factory InProgressBookingModal.fromJson(Map<String, dynamic> json) {
    return InProgressBookingModal(
      id: _asInt(json['id']),
      status: json['status']?.toString() ?? 'pending',
      serviceName: json['serviceDisplayName']?.toString() ?? json['service']?.toString() ?? 'Service',
      bookingDate: json['displayDateLabel']?.toString() ?? json['bookingDate']?.toString() ?? '',
      startTime: json['displayTimeLabel']?.toString() ?? json['startTimeLabel']?.toString() ?? '',
      serviceImage: json['serviceImage']?.toString() ?? 'https://via.placeholder.com/150',
    );
  }
}

class InProgressBookingsModal {
  const InProgressBookingsModal({
    required this.success,
    required this.message,
    required this.bookings,
  });

  final bool success;
  final String message;
  final List<InProgressBookingModal> bookings;

  factory InProgressBookingsModal.fromJson(Map<String, dynamic> json) {
    final bookingsJson = json['bookings'];
    return InProgressBookingsModal(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      bookings: bookingsJson is List
          ? bookingsJson
              .whereType<Map<String, dynamic>>()
              .map(InProgressBookingModal.fromJson)
              .toList(growable: false)
          : const <InProgressBookingModal>[],
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
