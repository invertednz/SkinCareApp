import 'package:flutter/material.dart';
import '../features/insights/insights_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../widgets/error_widget.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/error_handler.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  final _pages = const [
    InsightsScreen(),
    DiaryScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    try {
      return PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, result) {
          try {
            // Android back: if not on first tab, go to first tab instead of exiting
            if (didPop) return;
            if (_index != 0) {
              setState(() => _index = 0);
            }
          } catch (error) {
            ErrorHandler.handleError(context, error);
          }
        },
        child: Scaffold(
          body: ResponsiveWrapper(
            child: IndexedStack(
              index: _index,
              children: _pages.map((page) => _SafePageWrapper(child: page)).toList(),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              try {
                setState(() => _index = i);
              } catch (error) {
                ErrorHandler.handleError(context, error);
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Insights'),
              NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Diary'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
      ),
    );
    } catch (error) {
      // If the entire shell fails to build, show error widget
      return Scaffold(
        body: AppErrorWidget(
          error: error,
          title: 'App Shell Error',
          onRetry: () {
            setState(() {
              // Reset to first tab and try again
              _index = 0;
            });
          },
        ),
      );
    }
  }
}

/// Wrapper that provides error boundary for individual pages
class _SafePageWrapper extends StatelessWidget {
  const _SafePageWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (error) {
      return AppErrorWidget(
        error: error,
        title: 'Page Error',
        onRetry: () {
          // Force rebuild by creating new widget
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => child),
          );
        },
      );
    }
  }
}

