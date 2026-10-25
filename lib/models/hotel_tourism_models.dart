class TourismSiteModel {
  const TourismSiteModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.openingHours,
    required this.website,
    required this.phone,
    required this.entranceFee,
    required this.rating,
    required this.reviewsCount,
    required this.imagesUrls,
    required this.verified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double? latitude;
  final double? longitude;
  final String address;
  final String openingHours;
  final String website;
  final String phone;
  final double? entranceFee;
  final double? rating;
  final int reviewsCount;
  final List<String> imagesUrls;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TourismSiteModel.fromRow(Map<String, dynamic> row) {
    final id = _readString(row['id']);
    final name = _readString(row['name']);
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Tourist site is missing its id or name.');
    }
    return TourismSiteModel(
      id: id,
      name: name,
      description: _readString(row['description']),
      category: _readString(row['category']).toLowerCase(),
      latitude: _readDouble(row['latitude']),
      longitude: _readDouble(row['longitude']),
      address: _readString(row['address']),
      openingHours: _readString(row['opening_hours']),
      website: _readString(row['website']),
      phone: _readString(row['phone']),
      entranceFee: _readDouble(row['entrance_fee']),
      rating: _readDouble(row['rating']),
      reviewsCount: _readInt(row['reviews_count']) ?? 0,
      imagesUrls: _readStringList(row['images_urls']),
      verified: row['verified'] == true,
      createdAt: _readDate(row['created_at']),
      updatedAt: _readDate(row['updated_at']),
    );
  }

  String get categoryLabel {
    if (category.isEmpty) return 'Uncategorised';
    return category[0].toUpperCase() + category.substring(1);
  }

  String get entryFeeLabel {
    final fee = entranceFee;
    if (fee == null) return 'Fee not listed';
    if (fee <= 0) return 'Free';
    return '${formatAmount(fee)} ETB';
  }

  String get ratingLabel =>
      rating == null ? 'Not rated' : rating!.toStringAsFixed(1);

  String get coordinatesLabel {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return 'Coordinates not listed';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

class HotelModel {
  const HotelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.imageUrls,
    required this.status,
    required this.rooms,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String phone;
  final double? latitude;
  final double? longitude;
  final int? starRating;
  final List<String> imageUrls;
  final String status;
  final List<HotelRoomModel> rooms;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HotelModel.fromRow(Map<String, dynamic> row) {
    final id = _readString(row['id']);
    final name = _readString(row['name']);
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Hotel is missing its id or name.');
    }
    final rawRooms = row['hotel_rooms'];
    final rooms = rawRooms is List
        ? rawRooms
            .whereType<Map>()
            .map((room) => HotelRoomModel.fromRow(
                  Map<String, dynamic>.from(room),
                ))
            .toList(growable: false)
        : const <HotelRoomModel>[];
    return HotelModel(
      id: id,
      name: name,
      description: _readString(row['description']),
      address: _readString(row['address']),
      city: _readString(row['city']),
      phone: _readString(row['phone']),
      latitude: _readDouble(row['latitude']),
      longitude: _readDouble(row['longitude']),
      starRating: _readInt(row['star_rating']),
      imageUrls: _readStringList(row['image_urls']),
      status: _readString(row['status']),
      rooms: rooms,
      createdAt: _readDate(row['created_at']),
      updatedAt: _readDate(row['updated_at']),
    );
  }

  List<HotelRoomModel> get availableRooms => rooms
      .where((room) => room.status == 'available')
      .toList(growable: false);

  double? get lowestAvailableRate {
    double? lowest;
    for (final room in availableRooms) {
      if (lowest == null || room.nightlyRate < lowest) {
        lowest = room.nightlyRate;
      }
    }
    return lowest;
  }

  String get ratingLabel =>
      starRating == null ? 'Unrated' : '$starRating star';
  String get locationLabel {
    if (address.isNotEmpty && city.isNotEmpty) return '$address, $city';
    if (address.isNotEmpty) return address;
    if (city.isNotEmpty) return city;
    return 'Location not listed';
  }
}

class HotelRoomModel {
  const HotelRoomModel({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.roomType,
    required this.capacity,
    required this.nightlyRate,
    required this.currency,
    required this.status,
  });

  final String id;
  final String hotelId;
  final String roomNumber;
  final String roomType;
  final int capacity;
  final double nightlyRate;
  final String currency;
  final String status;

  factory HotelRoomModel.fromRow(Map<String, dynamic> row) {
    final id = _readString(row['id']);
    final hotelId = _readString(row['hotel_id']);
    final roomNumber = _readString(row['room_number']);
    final roomType = _readString(row['room_type']);
    if (id.isEmpty || hotelId.isEmpty || roomNumber.isEmpty) {
      throw const FormatException('Hotel room is missing required fields.');
    }
    return HotelRoomModel(
      id: id,
      hotelId: hotelId,
      roomNumber: roomNumber,
      roomType: roomType,
      capacity: _readInt(row['capacity']) ?? 1,
      nightlyRate: _readDouble(row['nightly_rate']) ?? 0,
      currency: _readString(row['currency']).isEmpty
          ? 'ETB'
          : _readString(row['currency']),
      status: _readString(row['status']).isEmpty
          ? 'available'
          : _readString(row['status']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'available':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  String get rateLabel => '${formatAmount(nightlyRate)} $currency';
}

class HotelReservationModel {
  const HotelReservationModel({
    required this.id,
    required this.bookingCode,
    required this.hotelId,
    required this.roomId,
    required this.hotelName,
    required this.roomNumber,
    required this.roomType,
    required this.guestName,
    required this.guestPhone,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookingCode;
  final String hotelId;
  final String roomId;
  final String hotelName;
  final String roomNumber;
  final String roomType;
  final String guestName;
  final String guestPhone;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final double totalAmount;
  final String currency;
  final String status;
  final DateTime? decidedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HotelReservationModel.fromRow(Map<String, dynamic> row) {
    final id = _readString(row['id']);
    final bookingCode = _readString(row['booking_code']);
    if (id.isEmpty || bookingCode.isEmpty) {
      throw const FormatException('Reservation is missing its id or code.');
    }
    return HotelReservationModel(
      id: id,
      bookingCode: bookingCode,
      hotelId: _readString(row['hotel_id']),
      roomId: _readString(row['room_id']),
      hotelName: _readString(row['hotel_name']),
      roomNumber: _readString(row['room_number']),
      roomType: _readString(row['room_type']),
      guestName: _readString(row['guest_name']),
      guestPhone: _readString(row['guest_phone']),
      checkIn: _readDate(row['check_in']),
      checkOut: _readDate(row['check_out']),
      guests: _readInt(row['guests']) ?? 1,
      totalAmount: _readDouble(row['total_amount']) ?? 0,
      currency: _readString(row['currency']).isEmpty
          ? 'ETB'
          : _readString(row['currency']),
      status: _readString(row['status']).isEmpty
          ? 'pending'
          : _readString(row['status']),
      decidedAt: _readDate(row['decided_at']),
      createdAt: _readDate(row['created_at']),
      updatedAt: _readDate(row['updated_at']),
    );
  }

  bool get isPending => status == 'pending';

  int get nights {
    final start = checkIn;
    final end = checkOut;
    if (start == null || end == null) return 0;
    final days = end.difference(start).inDays;
    return days > 0 ? days : 0;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'checked_in':
        return 'Checked in';
      case 'checked_out':
        return 'Checked out';
      case 'no_show':
        return 'No show';
      default:
        return status;
    }
  }

  String get totalLabel => '${formatAmount(totalAmount)} $currency';
}

/// Formats a money value without relying on locale data.
String formatAmount(double? value) {
  if (value == null) return '0';
  final fixed = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  if (parts.length > 1) return '${buffer.toString()}.${parts[1]}';
  return buffer.toString();
}

String formatBookingDate(DateTime? date) {
  if (date == null) return 'Not set';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _readString(Object? value) => value == null ? '' : value.toString();

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _readDate(Object? value) {
  final raw = _readString(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
