import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioDebugLoggingInterceptor extends Interceptor {
  const DioDebugLoggingInterceptor();

  static const _startedAtKey = '__startedAt';
  static const _requestIdKey = '__requestId';
  static const _requestLabelKey = 'requestLabel';
  static const _redacted = '***';
  static int _nextRequestId = 0;
  static const _secretKeys = {
    'x-emby-token',
    'x-emby-authorization',
    'authorization',
    'api_key',
    'pw',
    'password',
    'token',
    'accesstoken',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    options.extra[_requestIdKey] = ++_nextRequestId;

    debugPrint(
      '${_prefix(options, phase: 'REQ')} ${options.method.toUpperCase()} ${_displayUri(options)}',
    );

    final query = _sanitizeMap(options.queryParameters);
    if (query.isNotEmpty) {
      debugPrint('   query: $query');
    }

    final headers = _sanitizeMap(options.headers);
    if (headers.isNotEmpty) {
      debugPrint('   headers: $headers');
    }

    final body = _sanitizeData(options.data);
    if (body != null) {
      debugPrint('   body: $body');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final elapsed = _elapsed(response.requestOptions);
    final summary = _responseSummary(response.data);
    debugPrint(
      '${_prefix(response.requestOptions, phase: 'RES', statusCode: response.statusCode)} '
      '${response.requestOptions.method.toUpperCase()} '
      '${_displayUri(response.requestOptions)} (${elapsed}ms)$summary',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final elapsed = _elapsed(options);
    final statusCode = err.response?.statusCode;
    final reason = err.message ?? err.type.name;

    debugPrint(
      '${_prefix(options, phase: 'ERR', statusCode: statusCode)} '
      '${options.method.toUpperCase()} ${_displayUri(options)} '
      '(${elapsed}ms) ${err.type.name}: $reason',
    );

    final responseData = _sanitizeData(err.response?.data);
    if (responseData != null) {
      debugPrint('   error-body: $responseData');
    }

    handler.next(err);
  }

  String _displayUri(RequestOptions options) {
    final uri = options.uri;
    if (uri.host.isEmpty) {
      return options.path;
    }
    return '${uri.scheme}://${uri.authority}${uri.path}';
  }

  String _prefix(
    RequestOptions options, {
    required String phase,
    int? statusCode,
  }) {
    final requestId = options.extra[_requestIdKey];
    final label = options.extra[_requestLabelKey];
    final status = statusCode == null ? phase : '$phase $statusCode';
    final buffer = StringBuffer('[${_timestamp()}][HTTP#$requestId]');
    if (label is String && label.trim().isNotEmpty) {
      buffer.write('[${label.trim()}]');
    }
    buffer.write('[$status]');
    return buffer.toString();
  }

  String _timestamp() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }

  int _elapsed(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is DateTime) {
      return DateTime.now().difference(startedAt).inMilliseconds;
    }
    return 0;
  }

  String _responseSummary(Object? data) {
    if (data is Map<String, dynamic>) {
      final items = data['Items'];
      if (items is List) {
        final total = data['TotalRecordCount'];
        if (total is int) {
          return ' items=${items.length}/$total';
        }
        return ' items=${items.length}';
      }
      if (data.containsKey('AccessToken')) {
        return ' login=ok';
      }
    }
    if (data is List) {
      return ' items=${data.length}';
    }
    return '';
  }

  Object? _sanitizeData(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      return _sanitizeMap(value);
    }
    if (value is List) {
      return value.map(_sanitizeData).toList(growable: false);
    }
    return value;
  }

  Map<String, Object?> _sanitizeMap(Map<dynamic, dynamic> source) {
    final result = <String, Object?>{};
    for (final entry in source.entries) {
      final key = '${entry.key}';
      result[key] = _sanitizeValue(key, entry.value);
    }
    return result;
  }

  Object? _sanitizeValue(String key, Object? value) {
    if (_secretKeys.contains(key.toLowerCase())) {
      return _redacted;
    }
    if (value is Map) {
      return _sanitizeMap(value);
    }
    if (value is List) {
      return value
          .map((item) => _sanitizeValue(key, item))
          .toList(growable: false);
    }
    return value;
  }
}
