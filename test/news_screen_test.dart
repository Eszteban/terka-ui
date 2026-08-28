import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terka/injection_container.dart';
import 'package:terka/models/news_item.dart';
import 'package:terka/repositories/news_repository.dart';
import 'package:terka/screens/news_screen.dart';

class FakeNewsRepository implements NewsRepository {
  final List<NewsItem> items;
  FakeNewsRepository(this.items);

  @override
  Future<List<NewsItem>> fetchNews() async => items;
}

void main() {
  setUp(() async {
    await sl.reset();
  });

  testWidgets('NewsScreen renders items without Material assertion errors', (tester) async {
    final fakeRepo = FakeNewsRepository([
      NewsItem(
        title: 'MÁVINFORM teszt hír 1',
        link: 'https://www.mavcsoport.hu/node/1',
        pubDate: DateTime(2026, 8, 17, 12, 30),
      ),
      NewsItem(
        title: 'MÁVINFORM teszt hír 2',
        link: 'https://www.mavcsoport.hu/node/2',
        rawPubDate: '2026.08.17 13:00',
      ),
    ]);

    sl.registerLazySingleton<NewsRepository>(() => fakeRepo);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NewsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MÁVINFORM teszt hír 1'), findsOneWidget);
    expect(find.text('MÁVINFORM teszt hír 2'), findsOneWidget);
  });
}
