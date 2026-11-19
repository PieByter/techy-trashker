class WasteBank {
  const WasteBank({
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.isOpen,
    required this.mapX,
    required this.mapY,
  });

  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final bool isOpen;

  /// Relative position on the stylised map (0..1).
  final double mapX;
  final double mapY;
}
