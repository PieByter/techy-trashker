enum DepositStatus { completed, processing, scheduled }

enum DepositMethod { dropOff, pickup }

class WasteDeposit {
  const WasteDeposit({
    required this.id,
    required this.material,
    required this.category,
    required this.weightKg,
    required this.points,
    required this.date,
    required this.status,
    required this.method,
  });

  final String id;
  final String material;
  final String category;
  final double weightKg;
  final int points;
  final DateTime date;
  final DepositStatus status;
  final DepositMethod method;

  String get weightLabel => '${weightKg.toStringAsFixed(1)} kg';
}
