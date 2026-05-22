/// Extracts URLs from arbitrary text using a regex pattern.
///
/// Pipeline Step 1: Run before Safe Browsing or Gemini calls.
/// Pattern matches URLs starting with http://, https://, or www.
class LinkExtractor {
  /// Regex from Phase 1 §2.3 / SKILL.md:
  ///   (https?:\/\/|www\.)[^\s<>"{}|\\^`\[\]]+
  static final RegExp _urlPattern = RegExp(
    r'(https?://|www\.)[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  /// Returns a list of URL strings found in [text].
  ///
  /// Returns an empty list if no URLs are found.
  /// The returned URLs are the raw matched strings (not normalised).
  static List<String> extractUrls(String text) {
    if (text.isEmpty) return [];

    final matches = _urlPattern.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }
}
