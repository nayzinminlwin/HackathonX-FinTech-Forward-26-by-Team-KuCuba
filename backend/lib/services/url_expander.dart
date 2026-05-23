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
  static const int _maxRedirects = 5;

  final Dio _dio;

  UrlExpander()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          followRedirects: false,
          validateStatus: (_) => true,
        ));

  Future<List<UrlExpansionResult>> expandAll(List<String> urls) async {
    final results = <UrlExpansionResult>[];

    for (final url in urls) {
      results.add(await expand(url));
    }

    return results;
  }

  Future<UrlExpansionResult> expand(String url) async {
    var currentUrl = url;

    try {
      for (var redirectCount = 0;
          redirectCount < _maxRedirects;
          redirectCount++) {
        final nextUrl = await _nextRedirect(currentUrl);
        if (nextUrl == null || nextUrl == currentUrl) {
          return UrlExpansionResult(
            originalUrl: url,
            expandedUrl: currentUrl,
          );
        }

        currentUrl = nextUrl;
      }

      return UrlExpansionResult(originalUrl: url, expandedUrl: currentUrl);
    } catch (e) {
      print('[url_expander] Could not expand $url: $e');
      return UrlExpansionResult(originalUrl: url, expandedUrl: null);
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
}
