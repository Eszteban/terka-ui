import '../utils/markup_text_utils.dart';

extension StringHtmlCleaner on String {
  String toPlainTextFromHtml() {
    return plainTextFromHtml(this);
  }
}
