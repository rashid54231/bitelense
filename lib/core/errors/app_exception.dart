/// Base application exception with error codes and friendly messages.
class AppException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const AppException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message)';

  factory AppException.fromError(dynamic error) {
    if (error is AppException) return error;

    final str = error.toString().toLowerCase();

    if (str.contains('network') ||
        str.contains('socket') ||
        str.contains('connection') ||
        str.contains('offline')) {
      return const AppException(
        code: 'NETWORK_ERROR',
        message: 'Network issue. Please check your internet connection.',
      );
    }

    if (str.contains('invalid login') ||
        str.contains('invalid credentials') ||
        str.contains('wrong password')) {
      return const AppException(
        code: 'AUTH_INVALID_CREDENTIALS',
        message: 'Invalid email or password. Please try again.',
      );
    }

    if (str.contains('user already registered') ||
        str.contains('already exists')) {
      return const AppException(
        code: 'AUTH_USER_EXISTS',
        message: 'An account with this email already exists.',
      );
    }

    if (str.contains('limit_reached') || str.contains('429')) {
      return const AppException(
        code: 'LIMIT_REACHED',
        message:
            'You have reached your 3 free scans for today. Upgrade to Pro for unlimited scans!',
      );
    }

    if (str.contains('not_food')) {
      return const AppException(
        code: 'NOT_FOOD',
        message: 'No food detected in this photo. Please take a clearer photo of a meal.',
      );
    }

    if (str.contains('ai_bad_response') || str.contains('timeout')) {
      return const AppException(
        code: 'AI_TIMEOUT',
        message: 'AI analysis timed out or returned an invalid format. Please retry.',
      );
    }

    return AppException(
      code: 'UNKNOWN',
      message: 'Something went wrong: ${error.toString().split('\n').first}',
      details: error,
    );
  }
}
