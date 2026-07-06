import '../models/news_item.dart';

abstract class NewsRepository {
  Future<List<NewsItem>> fetchNews();
}
