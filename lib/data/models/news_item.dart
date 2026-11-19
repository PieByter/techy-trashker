class NewsItem {
  const NewsItem({
    required this.title,
    required this.category,
    required this.date,
    required this.imageAsset,
    required this.summary,
  });

  final String title;
  final String category;
  final String date;
  final String imageAsset;
  final String summary;
}
