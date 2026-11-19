class NewsItem {
  const NewsItem({
    required this.title,
    required this.category,
    required this.date,
    required this.imageAsset,
    required this.summary,
    this.id,
    this.imageUrl,
    this.content,
  });

  final String? id;
  final String title;
  final String category;
  final String date;
  final String imageAsset;
  final String summary;
  final String? imageUrl;
  final String? content;

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? 'Lingkungan',
    date: json['date'] as String? ?? '',
    imageAsset: '',
    summary: json['summary'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    content: json['content'] as String?,
  );
}
