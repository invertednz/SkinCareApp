import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'analytics_service.dart';

/// Central error handling service for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  static ErrorHandler get instance => _instance;

  /// Initialize global error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack, details.context.toString());
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack, 'Platform Error');
      return true;
    };
  }

  /// Log error to analytics and debug console
  static void _logError(dynamic error, StackTrace? stack, String context) {
    if (kDebugMode) {
      debugPrint('ERROR [$context]: $error');
      if (stack != null) {
        debugPrint('STACK: $stack');
      }
    }

    // Log to analytics in production
    if (kReleaseMode) {
      AnalyticsService.capture('error_occurred', {
        'error': error.toString(),
        'context': context,
        'stack_trace': stack?.toString() ?? 'No stack trace',
      });
    }
  }

  /// Show error snackbar with consistent styling
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6A11CB),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar with consistent styling
  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle and display common errors with user-friendly messages
  static void handleError(BuildContext context, dynamic error) {
    String userMessage = getUserFriendlyMessage(error);
    showErrorSnackBar(context, userMessage);
    _logError(error, StackTrace.current, 'Handled Error');
  }

  /// Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication error. Please sign in again.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied. You don\'t have permission for this action.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Requested resource not found.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Invalid input. Please check your data and try again.';
    }

    // Default fallback message
    return 'Something went wrong. Please try again.';
  }
}
