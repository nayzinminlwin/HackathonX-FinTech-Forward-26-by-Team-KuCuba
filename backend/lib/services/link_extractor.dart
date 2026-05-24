/// Extracts URLs from arbitrary text using a regex pattern.
///
/// Pipeline Step 1: Run before Safe Browsing or Gemini calls.
/// Pattern matches clickable URLs with or without http://, https://, or www.
class LinkExtractor {
  static const Set<String> _shortenerHosts = {
    'bit.ly',
    'tinyurl.com',
    'is.gd',
    't.co',
    'goo.gl',
    'ow.ly',
    'buff.ly',
    'cutt.ly',
    'rebrand.ly',
    'shorturl.at',
    's.id',
    'lnkd.in',
  };

  /// Matches full URLs, www-prefixed domains, and raw domains that mobile
  /// apps commonly auto-link, such as `maybank-secure-login.com`.
  static final RegExp _urlPattern = RegExp(
    r'''(?:^|[\s(<\["'])(?:://)?((?:https?://)?(?:www\.)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:com\.my|gov\.my|edu\.my|net\.my|org\.my|[a-z]{2,24})(?::\d{2,5})?(?:[/?#][^\s<>"{}|\\^`\[\]]*)?)''',
    caseSensitive: false,
  );

  /// Returns a list of URL strings found in [text], normalized for lookup.
  ///
  /// Returns an empty list if no URLs are found.
  /// Scheme-less domains are returned with `https://` so Safe Browsing can
  /// check links users can tap even when the message omits `www.` or `http`.
  static List<String> extractUrls(String text) {
    if (text.isEmpty) return [];

    final matches = _urlPattern.allMatches(text);
    final urls = <String>{};

    for (final match in matches) {
      final url = match.group(1);
      if (url == null || url.isEmpty) continue;

      urls.add(_normalizeUrl(url));
    }

    return urls.toList();
  }

  static bool containsShortenedUrl(List<String> urls) {
    return urls.any((url) => _shortenerHosts.contains(_hostFromUrl(url)));
  }

  static List<String> extractShortenedUrls(List<String> urls) {
    return urls
        .where((url) => _shortenerHosts.contains(_hostFromUrl(url)))
        .toSet()
        .toList();
  }

  static String _normalizeUrl(String url) {
    final trimmed = _trimTrailingPunctuation(url);

    if (trimmed.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  static String _hostFromUrl(String url) {
    final withScheme =
        url.startsWith(RegExp(r'https?://', caseSensitive: false))
            ? url
            : 'https://$url';

    final uri = Uri.tryParse(withScheme);
    return uri?.host.toLowerCase() ?? '';
  }

  static String _trimTrailingPunctuation(String url) {
    var trimmed = url;
    while (trimmed.isNotEmpty &&
        RegExp(r'''[.,!?;:'")\]]''').hasMatch(trimmed[trimmed.length - 1])) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}
