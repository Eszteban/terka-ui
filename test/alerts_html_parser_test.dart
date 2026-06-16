import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terka/widgets/alerts_section.dart';

void main() {
  group('AlertsSection parseHtmlToTextSpans tests', () {
    const baseStyle = TextStyle(fontSize: 14.0);

    test('Plain text parsing', () {
      final spans = AlertsSection.parseHtmlToTextSpans('Hello World', baseStyle);
      expect(spans.length, 1);
      expect(spans[0], isA<TextSpan>());
      expect((spans[0] as TextSpan).text, 'Hello World');
      expect((spans[0] as TextSpan).style, baseStyle);
    });

    test('Bold & strong parsing', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        'Hello <b>World</b>, <strong>Flutter</strong>',
        baseStyle,
      );
      expect(spans.length, 4);
      expect((spans[0] as TextSpan).text, 'Hello ');
      expect((spans[0] as TextSpan).style!.fontWeight, isNot(FontWeight.bold));

      expect((spans[1] as TextSpan).text, 'World');
      expect((spans[1] as TextSpan).style!.fontWeight, FontWeight.bold);

      expect((spans[2] as TextSpan).text, ', ');

      expect((spans[3] as TextSpan).text, 'Flutter');
      expect((spans[3] as TextSpan).style!.fontWeight, FontWeight.bold);
    });

    test('Italic & emphasis parsing', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        'Hello <i>World</i>, <em>Flutter</em>',
        baseStyle,
      );
      expect(spans.length, 4);
      expect((spans[0] as TextSpan).text, 'Hello ');
      expect((spans[1] as TextSpan).text, 'World');
      expect((spans[1] as TextSpan).style!.fontStyle, FontStyle.italic);
      expect((spans[2] as TextSpan).text, ', ');
      expect((spans[3] as TextSpan).text, 'Flutter');
      expect((spans[3] as TextSpan).style!.fontStyle, FontStyle.italic);
    });

    test('Line break parsing', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        'Line 1<br>Line 2<br />Line 3',
        baseStyle,
      );
      expect(spans.length, 1);
      expect((spans[0] as TextSpan).text, 'Line 1\nLine 2\nLine 3');
    });

    test('Unordered list and list items parsing', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        'Before list<ul><li>Item 1</li><li>Item 2</li></ul>After list',
        baseStyle,
      );
      
      final renderedText = spans.map((s) => (s as TextSpan).text).join();
      expect(renderedText, 'Before list\n• Item 1\n• Item 2\nAfter list');
    });

    test('Nested bold and italic inside list items', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        '<ul><li><b>Bold</b> <em>Italic</em></li></ul>',
        baseStyle,
      );
      
      expect(spans.any((s) => (s as TextSpan).text == '• '), isTrue);
      final boldSpan = spans.firstWhere((s) => (s as TextSpan).text == 'Bold') as TextSpan;
      expect(boldSpan.style!.fontWeight, FontWeight.bold);

      final italicSpan = spans.firstWhere((s) => (s as TextSpan).text == 'Italic') as TextSpan;
      expect(italicSpan.style!.fontStyle, FontStyle.italic);
    });

    test('Whitespace stripping around block tags', () {
      final spans = AlertsSection.parseHtmlToTextSpans(
        '  <ul> \n  <li>Item 1</li> \n  </ul>  ',
        baseStyle,
      );
      final renderedText = spans.map((s) => (s as TextSpan).text).join();
      expect(renderedText, '• Item 1');
    });
  });
}
