class WasteBank {
  const WasteBank({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final bool isOpen;

  /// Koordinat asli untuk Google Maps.
  final double latitude;
  final double longitude;

  /// Posisi relatif pada preview map (0..1), dipakai saat API key belum ada
  /// atau pada golden/widget test.
  final double mapX;
  final double mapY;
}
