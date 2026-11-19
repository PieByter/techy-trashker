class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.stock,
    required this.canRedeem,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final int stock;
  final bool canRedeem;
  final String? imageUrl;

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Reward',
    description: json['description'] as String? ?? '',
    pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    canRedeem: json['canRedeem'] as bool? ?? false,
    imageUrl: json['imageUrl'] as String?,
  );
}
