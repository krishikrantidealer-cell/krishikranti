/// Utility functions for HTML parsing, entity unescaping, and string sanitization.

/// Converts HTML entities (numeric, hex, named) into their literal character representations.
/// Specifically handles `/` (&#x2F;, &#47;, &sol;), quotes, ampersands, spaces, etc.
String unescapeHtml(String text) {
  if (text.isEmpty) return text;

  // 1. Double-encoded HTML entities
  String result = text
      .replaceAll('&amp;#', '&#')
      .replaceAll('&amp;amp;', '&')
      .replaceAll('&amp;lt;', '<')
      .replaceAll('&amp;gt;', '>')
      .replaceAll('&amp;quot;', '"')
      .replaceAll('&amp;apos;', "'")
      .replaceAll('&amp;sol;', '/');

  // 2. Named HTML entities
  result = result
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&sol;', '/')
      .replaceAll('&SOL;', '/')
      .replaceAll('&ndash;', '–')
      .replaceAll('&mdash;', '—');

  // 3. Decimal numeric entities (e.g. &#47; -> /, &#39; -> ')
  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (match) {
      final code = int.tryParse(match.group(1)!);
      if (code != null) {
        return String.fromCharCode(code);
      }
      return match.group(0)!;
    },
  );

  // 4. Hexadecimal numeric entities (e.g. &#x2F; -> /, &#x27; -> ')
  result = result.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      if (code != null) {
        return String.fromCharCode(code);
      }
      return match.group(0)!;
    },
  );

  return result;
}
