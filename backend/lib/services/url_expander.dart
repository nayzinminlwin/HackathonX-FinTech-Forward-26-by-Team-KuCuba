import 'package:dio/dio.dart';

class UrlExpansionResult {
  final String originalUrl;
  final String? expandedUrl;

  const UrlExpansionResult({
    required this.originalUrl,
    required this.expandedUrl,
  });

  bool get expanded => expandedUrl != null && expandedUrl != originalUrl;
}

/// Safely resolves shortened URLs by following HTTP redirects only.
///
/// This does not execute JavaScript or open a browser. It uses tight timeouts
/// and a small redirect limit so a bad shortener cannot stall analysis.
class UrlExpander {
  static const int _maxRedirects = 3;
  static const Duration _cacheTtl = Duration(minutes: 10);

  final Dio _dio;
  final Map<String, _CacheEntry<UrlExpansionResult>> _cache = {};

  UrlExpander()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
          sendTimeout: const Duration(milliseconds: 1500),
          followRedirects: false,
          validateStatus: (_) => true,
        ));

  Future<List<UrlExpansionResult>> expandAll(List<String> urls) async {
    return Future.wait(urls.toSet().map(expand));
  }

  Future<UrlExpansionResult> expand(String url) async {
    final cached = _getCached(url);
    if (cached != null) return cached;

    var currentUrl = url;

    try {
      for (var redirectCount = 0;
          redirectCount < _maxRedirects;
          redirectCount++) {
        final nextUrl = await _nextRedirect(currentUrl);
        if (nextUrl == null || nextUrl == currentUrl) {
          final result = UrlExpansionResult(
            originalUrl: url,
            expandedUrl: currentUrl,
          );
          _setCached(url, result);
          return result;
        }

        currentUrl = nextUrl;
      }

      final result =
          UrlExpansionResult(originalUrl: url, expandedUrl: currentUrl);
      _setCached(url, result);
      return result;
    } catch (e) {
      print('[url_expander] Could not expand shortened URL: $e');
      final result = UrlExpansionResult(originalUrl: url, expandedUrl: null);
      _setCached(url, result);
      return result;
    }
  }

  Future<String?> _nextRedirect(String url) async {
    final headRedirect = await _redirectFrom(url, method: 'HEAD');
    if (headRedirect != null) return headRedirect;

    return _redirectFrom(url, method: 'GET');
  }

  Future<String?> _redirectFrom(String url, {required String method}) async {
    final response = await _dio.request<ResponseBody>(
      url,
      options: Options(
        method: method,
        responseType: ResponseType.stream,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 300 || statusCode >= 400) return null;

    final location = response.headers.value('location');
    if (location == null || location.trim().isEmpty) return null;

    return _resolveRedirect(url, location.trim());
  }

  String _resolveRedirect(String baseUrl, String location) {
    final redirectUri = Uri.tryParse(location);
    if (redirectUri != null && redirectUri.hasScheme) {
      return redirectUri.toString();
    }

    final baseUri = Uri.parse(baseUrl);
    return baseUri.resolve(location).toString();
  }

  UrlExpansionResult? _getCached(String url) {
    final entry = _cache[url];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.createdAt) > _cacheTtl) {
      _cache.remove(url);
      return null;
    }

    print('[url_expander] Cache hit for shortened URL.');
    return entry.value;
  }

  void _setCached(String url, UrlExpansionResult value) {
    _cache[url] = _CacheEntry(value: value, createdAt: DateTime.now());
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;

  const _CacheEntry({
    required this.value,
    required this.createdAt,
  });
}
