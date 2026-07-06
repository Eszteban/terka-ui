class NewsItem {
  final String title;
  final String link;
  final DateTime? pubDate;
  final String? rawPubDate;

  const NewsItem({
    required this.title,
    required this.link,
    this.pubDate,
    this.rawPubDate,
  });
}
