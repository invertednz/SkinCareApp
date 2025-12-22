import 'package:flutter/material.dart';
import '../../theme/brand.dart';
import '../../services/tracking_state.dart';

class RoutineTrackingScreen extends StatefulWidget {
  const RoutineTrackingScreen({super.key});

  @override
  State<RoutineTrackingScreen> createState() => _RoutineTrackingScreenState();
}

class _RoutineTrackingScreenState extends State<RoutineTrackingScreen> {
  final TrackingState _state = TrackingState.instance;
  final TextEditingController _customController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  // Default routine items
  static const List<Map<String, dynamic>> _defaultRoutineItems = [
    {'name': 'Cleanser', 'icon': '🧴', 'isAM': true, 'isPM': true},
    {'name': 'Toner', 'icon': '💧', 'isAM': true, 'isPM': true},
    {'name': 'Serum', 'icon': '✨', 'isAM': true, 'isPM': true},
    {'name': 'Moisturizer', 'icon': '🧊', 'isAM': true, 'isPM': true},
    {'name': 'Sunscreen', 'icon': '☀️', 'isAM': true, 'isPM': false},
    {'name': 'Eye Cream', 'icon': '👁️', 'isAM': true, 'isPM': true},
    {'name': 'Retinol', 'icon': '💊', 'isAM': false, 'isPM': true},
    {'name': 'Face Mask', 'icon': '🎭', 'isAM': false, 'isPM': true},
  ];

  List<Map<String, dynamic>> _myRoutineItems = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _loadFromState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _customController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _loadFromState() {
    if (_initialized) return;
    _initialized = true;

    // Load user's routine from onboarding or use defaults
    if (_state.userRoutineItems.isNotEmpty) {
      _myRoutineItems = _state.userRoutineItems.map((item) => {
        'name': item.name,
        'icon': item.icon,
        'isAM': item.isAM,
        'isPM': item.isPM,
      }).toList();
    } else {
      // Default to basic routine items
      _myRoutineItems = [
        {'name': 'Cleanser', 'icon': '🧴', 'isAM': true, 'isPM': true},
        {'name': 'Moisturizer', 'icon': '🧊', 'isAM': true, 'isPM': true},
        {'name': 'Sunscreen', 'icon': '☀️', 'isAM': true, 'isPM': false},
      ];
    }
  }

  void _scrollToToday() {
    final dayWidth = 64.0;
    final daysFromStart = DateTime.now().difference(_getStartDate()).inDays;
    final offset = (daysFromStart * dayWidth) - (MediaQuery.of(context).size.width / 2) + (dayWidth / 2);
    if (_calendarScrollController.hasClients) {
      _calendarScrollController.animateTo(
        offset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  DateTime _getStartDate() => DateTime.now().subtract(const Duration(days: 30));

  String get _dateKey => _state.selectedDateKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.charcoal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildCalendarBar(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildMyRoutine(),
                    const SizedBox(height: 20),
                    _buildAddCustom(),
                    const SizedBox(height: 20),
                    _buildCommonItems(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Routine',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Track your skincare routine',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBar() {
    final startDate = _getStartDate();
    final today = DateTime.now();
    final days = List.generate(60, (i) => startDate.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          controller: _calendarScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            final isSelected = _isSameDay(date, _state.selectedDate);
            final isToday = _isSameDay(date, today);

            return GestureDetector(
              onTap: () => _state.setSelectedDate(date),
              child: Container(
                width: 56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Brand.primaryStart
                      : (isToday ? Brand.primaryStart.withOpacity(0.1) : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: Brand.primaryStart, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayName(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Brand.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Brand.textPrimary,
                      ),
                    ),
                    Text(
                      _getMonthName(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withOpacity(0.8) : Brand.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'Mark All Done',
            Icons.check_circle_outline,
            Brand.mintColor,
            _markAllDone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickActionButton(
            'Clear All',
            Icons.cancel_outlined,
            Colors.redAccent,
            _clearAll,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRoutine() {
    final routineData = _state.getRoutineItemsForDate(_dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Routine - Tap AM/PM to mark done',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._myRoutineItems.map((item) {
          final itemName = item['name'] as String;
          final itemData = routineData[itemName];
          final amDone = itemData?['am'] ?? false;
          final pmDone = itemData?['pm'] ?? false;
          final showAM = item['isAM'] ?? true;
          final showPM = item['isPM'] ?? true;
          final isDone = (showAM ? amDone : true) && (showPM ? pmDone : true);

          return _buildRoutineCard(
            itemName,
            item['icon'] as String,
            showAM,
            showPM,
            amDone,
            pmDone,
            isDone,
          );
        }),
      ],
    );
  }

  Widget _buildRoutineCard(
    String name,
    String icon,
    bool showAM,
    bool showPM,
    bool amDone,
    bool pmDone,
    bool isDone,
  ) {
    Color cardColor = isDone ? Brand.mintColor.withOpacity(0.15) : Colors.white;
    Color borderColor = isDone ? Brand.mintColor : Brand.borderLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isDone ? 2 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? Brand.mintColor.withOpacity(0.2)
                      : Brand.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Brand.mintColor : Brand.textPrimary,
                  ),
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: Brand.mintColor, size: 22)
              else
                Icon(Icons.radio_button_unchecked, color: Brand.borderMedium, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Completed:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDone ? Brand.mintColor : Brand.textSecondary,
                ),
              ),
              const Spacer(),
              if (showAM)
                _buildTimeToggle(name, 'AM', '☀️ AM', amDone),
              if (showAM && showPM)
                const SizedBox(width: 8),
              if (showPM)
                _buildTimeToggle(name, 'PM', '🌙 PM', pmDone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeToggle(String itemName, String timeKey, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        final currentData = _state.getRoutineItemsForDate(_dateKey)[itemName];
        final currentAM = currentData?['am'] ?? false;
        final currentPM = currentData?['pm'] ?? false;
        
        if (timeKey == 'AM') {
          _state.setRoutineItemForDate(_dateKey, itemName, !currentAM, currentPM);
        } else {
          _state.setRoutineItemForDate(_dateKey, itemName, currentAM, !currentPM);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? Brand.primaryGradient : null,
          color: isActive ? null : Brand.backgroundLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? Colors.transparent : Brand.borderMedium),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Brand.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustom() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a custom routine step...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addCustomItem(),
            ),
          ),
          GestureDetector(
            onTap: _addCustomItem,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: Brand.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonItems() {
    // Filter out items already in user's list
    final myItemNames = _myRoutineItems.map((i) => i['name']).toSet();
    final available = _defaultRoutineItems
        .where((item) => !myItemNames.contains(item['name']))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add from common routine steps',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: available.map((item) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _myRoutineItems.add(Map<String, dynamic>.from(item));
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item['icon'] as String, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.add, color: Colors.white.withOpacity(0.5), size: 16),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Actions
  void _markAllDone() {
    for (final item in _myRoutineItems) {
      final name = item['name'] as String;
      final showAM = item['isAM'] ?? true;
      final showPM = item['isPM'] ?? true;
      _state.setRoutineItemForDate(_dateKey, name, showAM, showPM);
    }
    // Also mark as "Had All" on home screen
    _state.setRoutineForDate(_dateKey, true);
  }

  void _clearAll() {
    for (final item in _myRoutineItems) {
      final name = item['name'] as String;
      _state.setRoutineItemForDate(_dateKey, name, false, false);
    }
    _state.setRoutineForDate(_dateKey, null);
  }

  void _addCustomItem() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (!_myRoutineItems.any((i) => i['name'] == text)) {
      setState(() {
        _myRoutineItems.add({
          'name': text,
          'icon': '✨',
          'isAM': true,
          'isPM': true,
        });
      });
    }
    _customController.clear();
  }

  // Helpers
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}
