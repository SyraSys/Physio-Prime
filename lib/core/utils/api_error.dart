import 'package:dio/dio.dart';

/// A user-presentable API failure produced from any thrown error.
///
/// Maps the backend error envelope `{ "error": { "message", "issues" } }`
/// (and common variations) plus Dio transport errors into one type so screens
/// can render consistent error, retry and sign-in states.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _fromDio(error);
    if (error is FormatException) {
      return const ApiException('We received an unexpected response from the server. Please try again.');
    }
    return const ApiException('Something went wrong. Please try again.');
  }

  static ApiException _fromDio(DioException e) {
    final type = e.type;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        'The server is taking too long to respond. Check your connection and try again.',
        isNetworkError: true,
      );
    }
    if (type == DioExceptionType.connectionError) {
      return const ApiException(
        'No internet connection. Please check your network and try again.',
        isNetworkError: true,
      );
    }
    if (type == DioExceptionType.cancel) {
      return const ApiException('The request was cancelled.');
    }
    if (type == DioExceptionType.badCertificate) {
      return const ApiException('A secure connection to PhysioPrime could not be established.', isNetworkError: true);
    }

    final status = e.response?.statusCode;
    final serverMessage = _extractMessage(e.response?.data);

    if (status == null) {
      return ApiException(serverMessage ?? 'Unable to reach PhysioPrime. Please try again.', isNetworkError: true);
    }

    final fallback = switch (status) {
      400 || 422 => 'Some details look incorrect. Please review and try again.',
      401 => 'Your session has expired. Please sign in to continue.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested item could not be found.',
      409 => 'This request conflicts with an existing booking. Please refresh and try again.',
      429 => 'Too many requests. Please wait a moment and try again.',
      >= 500 => 'PhysioPrime is temporarily unavailable. Please try again shortly.',
      _ => 'Something went wrong. Please try again.',
    };

    // Never surface a raw server message for 401s — keep the sign-in prompt clear.
    final message = status == 401 ? fallback : (serverMessage ?? fallback);
    return ApiException(message, statusCode: status);
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        final msg = error['message'];
        final issues = error['issues'];
        if (issues is List && issues.isNotEmpty) {
          final first = issues.first;
          final issueMsg = first is Map ? first['message'] : first;
          if (issueMsg is String && issueMsg.trim().isNotEmpty) {
            return msg is String && msg.trim().isNotEmpty ? '${msg.trim()}: ${issueMsg.trim()}' : issueMsg.trim();
          }
        }
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      if (error is String && error.trim().isNotEmpty) return error.trim();
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    return null;
  }

  @override
  String toString() => message;
}
