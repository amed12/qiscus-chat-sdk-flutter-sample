// ignore: constant_identifier_names
const APP_ID = 'your_app_id';
// ignore: constant_identifier_names
const CHANNEL_ID = 0;

/// HTTP error codes and descriptions for centralized handling.
class QiscusErrorCodes {
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int serverError = 500;
  static const int notFound = 404;
  static const int badRequest = 400;
  static const int tooManyRequests = 429;

  /// Human-friendly message mapping for known HTTP status codes.
  static const Map<int, String> messages = {
    unauthorized: 'Session expired. Please log in again.',
    forbidden: 'Access denied. Please check your credentials.',
    serverError: 'Server error occurred. Please try again later.',
    notFound: 'Room not found. Please check your credentials.',
    badRequest: 'Bad request. Please check your credentials.',
    tooManyRequests: 'Too many requests. Please try again later.',
  };
}
