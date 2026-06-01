bool containsSpanMarkup(String value) {
  return RegExp(r'<\s*span\b', caseSensitive: false).hasMatch(value);
}

String plainTextFromHtml(String input) {
  final noTags = input.replaceAll(RegExp(r'<[^>]+>'), '');
  return decodeHtmlEntities(noTags);
}

String decodeHtmlEntities(String input) {
  const namedEntities = <String, String>{
    'nbsp': ' ',
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
  };

  return input.replaceAllMapped(
    RegExp(r'&(#x?[0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]+);'),
    (match) {
      final token = match.group(1);
      if (token == null) {
        return match.group(0) ?? '';
      }

      if (token.startsWith('#x') || token.startsWith('#X')) {
        final codePoint = int.tryParse(token.substring(2), radix: 16);
        return codePoint == null
            ? (match.group(0) ?? '')
            : String.fromCharCode(codePoint);
      }

      if (token.startsWith('#')) {
        final codePoint = int.tryParse(token.substring(1));
        return codePoint == null
            ? (match.group(0) ?? '')
            : String.fromCharCode(codePoint);
      }

      return namedEntities[token] ?? (match.group(0) ?? '');
    },
  );
}
