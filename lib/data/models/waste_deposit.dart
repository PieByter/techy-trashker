enum DepositStatus { completed, processing, scheduled, cancelled }

enum DepositMethod { dropOff, pickup }

class WasteDeposit {
  const WasteDeposit({
    required this.id,
    required this.code,
    required this.material,
    required this.category,
    required this.weightKg,
    required this.points,
    required this.date,
    required this.status,
    required this.method,
    this.address,
    this.scheduledAt,
    this.notes,
  });

  final String id;
  final String code;
  final String material;
  final String category;
  final double weightKg;
  final int points;
  final DateTime date;
  final DepositStatus status;
  final DepositMethod method;
  final String? address;
  final DateTime? scheduledAt;
  final String? notes;

  String get weightLabel => '${weightKg.toStringAsFixed(1)} kg';

  factory WasteDeposit.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'completed' => DepositStatus.completed,
      'scheduled' => DepositStatus.scheduled,
      'cancelled' => DepositStatus.cancelled,
      _ => DepositStatus.processing,
    };
    final method = json['method'] == 'pickup'
        ? DepositMethod.pickup
        : DepositMethod.dropOff;
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final scheduledAt = DateTime.tryParse(json['scheduledAt'] as String? ?? '');
    return WasteDeposit(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? json['id'] as String? ?? '',
      material: json['material'] as String? ?? 'Sampah',
      category: json['category'] as String? ?? 'Lainnya',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      date: createdAt ?? scheduledAt ?? DateTime.now(),
      status: status,
      method: method,
      address: json['address'] as String?,
      scheduledAt: scheduledAt,
      notes: json['notes'] as String?,
    );
  }
}
