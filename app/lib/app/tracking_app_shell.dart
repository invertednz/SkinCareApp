import 'package:flutter/material.dart';
import '../features/tracking/tracking_home_screen.dart';
import '../features/tracking/symptoms_screen.dart';
import '../features/tracking/routine_tracking_screen.dart';
import '../features/tracking/supplements_tracking_screen.dart';
import '../features/chat/chat_screen.dart';
import '../widgets/error_widget.dart';
import '../theme/brand.dart';

/// Main app shell with daily tracking navigation
class TrackingAppShell extends StatefulWidget {
  const TrackingAppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<TrackingAppShell> createState() => _TrackingAppShellState();
}

class _TrackingAppShellState extends State<TrackingAppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            TrackingHomeScreen(onNavigateToTab: _navigateToTab),
            const SymptomsScreen(),
            const RoutineTrackingScreen(),
            const SupplementsTrackingScreen(),
            const ChatScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Brand.charcoal,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.warning_amber_outlined, Icons.warning_amber, 'Symptoms'),
              _buildNavItem(2, Icons.spa_outlined, Icons.spa, 'Routine'),
              _buildNavItem(3, Icons.medication_outlined, Icons.medication, 'Supps'),
              _buildNavItem(4, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _navigateToTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Brand.primaryStart : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Brand.primaryStart : Colors.white.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
