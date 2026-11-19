class WasteBank {
  const WasteBank({
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    required this.mapX,
    required this.mapY,
    this.id = '',
    this.phone,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final double mapX;
  final double mapY;
  final String? phone;

  factory WasteBank.fromJson(Map<String, dynamic> json) => WasteBank(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Bank Sampah',
    address: json['address'] as String? ?? '',
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    isOpen: json['isOpen'] as bool? ?? false,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    mapX: (json['mapX'] as num?)?.toDouble() ?? 0.5,
    mapY: (json['mapY'] as num?)?.toDouble() ?? 0.5,
    phone: json['phone'] as String?,
  );
}
