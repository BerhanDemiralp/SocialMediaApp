import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TimingHttpClient extends http.BaseClient {
  TimingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _inner.send(request);
      stopwatch.stop();
      _log(request, response.statusCode, stopwatch.elapsedMilliseconds);
      return response;
    } catch (error) {
      stopwatch.stop();
      debugPrint(
        '[http-time] ${request.method} ${request.url} error ${stopwatch.elapsedMilliseconds}ms $error',
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  void _log(http.BaseRequest request, int statusCode, int durationMs) {
    debugPrint(
      '[http-time] ${request.method} ${request.url} $statusCode ${durationMs}ms',
    );
  }
}
