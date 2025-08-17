import 'package:flutter/material.dart';

/// Central error widget for consistent error display across the app
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.showDetails = false,
  });

  final dynamic error;
  final VoidCallback? onRetry;
  final String? title;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getUserFriendlyMessage(error),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (showDetails) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Error Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'You need to sign in to access this content.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You don\'t have permission to access this content.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested content could not be found.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'There\'s a problem with our servers. Please try again later.';
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Please check your input and try again.';
    }

    // Default fallback message
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Compact error widget for inline error display
class CompactErrorWidget extends StatelessWidget {
  const CompactErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  final dynamic error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getUserFriendlyMessage(error),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication required';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Content not found';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error';
    }

    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Invalid input';
    }

    // Default fallback message
    return 'Something went wrong';
  }
}
