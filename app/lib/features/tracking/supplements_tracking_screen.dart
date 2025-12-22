import 'package:flutter/material.dart';
import '../../theme/brand.dart';
import '../../services/tracking_state.dart';

class SupplementsTrackingScreen extends StatefulWidget {
  const SupplementsTrackingScreen({super.key});

  @override
  State<SupplementsTrackingScreen> createState() => _SupplementsTrackingScreenState();
}

class _SupplementsTrackingScreenState extends State<SupplementsTrackingScreen> {
  final TrackingState _state = TrackingState.instance;
  final TextEditingController _customController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  // Common supplements for skin health
  static const List<Map<String, dynamic>> _commonSupplements = [
    {'name': 'Zinc', 'icon': '🔩'},
    {'name': 'Omega-3', 'icon': '🐟'},
    {'name': 'Vitamin D', 'icon': '☀️'},
    {'name': 'Vitamin C', 'icon': '🍊'},
    {'name': 'Vitamin E', 'icon': '🥜'},
    {'name': 'Probiotics', 'icon': '🦠'},
    {'name': 'Collagen', 'icon': '💪'},
    {'name': 'Biotin', 'icon': '💊'},
    {'name': 'Vitamin A', 'icon': '🥕'},
    {'name': 'Hyaluronic Acid', 'icon': '💧'},
  ];

  List<Map<String, dynamic>> _mySupplements = [];
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

    // Load user's supplements from onboarding or use defaults
    if (_state.userSupplements.isNotEmpty) {
      _mySupplements = _state.userSupplements.map((s) => {
        'name': s.name,
        'icon': _getIconForSupplement(s.name),
        'takesAM': s.takesAM,
        'takesPM': s.takesPM,
      }).toList();
    } else {
      // Default supplements
      _mySupplements = [
        {'name': 'Zinc', 'icon': '🔩', 'takesAM': true, 'takesPM': false},
        {'name': 'Omega-3', 'icon': '🐟', 'takesAM': true, 'takesPM': false},
        {'name': 'Vitamin D', 'icon': '☀️', 'takesAM': true, 'takesPM': false},
      ];
    }
  }

  String _getIconForSupplement(String name) {
    final match = _commonSupplements.firstWhere(
      (s) => s['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {'icon': '💊'},
    );
    return match['icon'] as String;
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
                    _buildMySupplements(),
                    const SizedBox(height: 20),
                    _buildAddCustom(),
                    const SizedBox(height: 20),
                    _buildCommonSupplements(),
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
            'Supplements',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Track your daily supplements',
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
            'Mark All Taken',
            Icons.check_circle_outline,
            Brand.mintColor,
            _markAllTaken,
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

  Widget _buildMySupplements() {
    final supplementData = _state.getSupplementItemsForDate(_dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Supplements - Tap AM/PM to mark taken',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._mySupplements.map((supp) {
          final name = supp['name'] as String;
          final data = supplementData[name];
          final amTaken = data?['am'] ?? false;
          final pmTaken = data?['pm'] ?? false;
          final showAM = supp['takesAM'] ?? true;
          final showPM = supp['takesPM'] ?? false;
          final isTaken = (showAM ? amTaken : true) && (showPM ? pmTaken : true);

          return _buildSupplementCard(
            name,
            supp['icon'] as String,
            showAM,
            showPM,
            amTaken,
            pmTaken,
            isTaken,
          );
        }),
      ],
    );
  }

  Widget _buildSupplementCard(
    String name,
    String icon,
    bool showAM,
    bool showPM,
    bool amTaken,
    bool pmTaken,
    bool isTaken,
  ) {
    Color cardColor = isTaken ? Brand.mintColor.withOpacity(0.15) : Colors.white;
    Color borderColor = isTaken ? Brand.mintColor : Brand.borderLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isTaken ? 2 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTaken
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
                    color: isTaken ? Brand.mintColor : Brand.textPrimary,
                  ),
                ),
              ),
              if (isTaken)
                Icon(Icons.check_circle, color: Brand.mintColor, size: 22)
              else
                Icon(Icons.radio_button_unchecked, color: Brand.borderMedium, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Taken:',
                style: TextStyle(
                  fontSize: 12,
                  color: isTaken ? Brand.mintColor : Brand.textSecondary,
                ),
              ),
              const Spacer(),
              if (showAM)
                _buildTimeToggle(name, 'AM', '☀️ AM', amTaken),
              if (showAM && showPM)
                const SizedBox(width: 8),
              if (showPM)
                _buildTimeToggle(name, 'PM', '🌙 PM', pmTaken),
              if (!showAM && !showPM)
                _buildTimeToggle(name, 'AM', '✓ Taken', amTaken),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeToggle(String itemName, String timeKey, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        final currentData = _state.getSupplementItemsForDate(_dateKey)[itemName];
        final currentAM = currentData?['am'] ?? false;
        final currentPM = currentData?['pm'] ?? false;

        if (timeKey == 'AM') {
          _state.setSupplementItemForDate(_dateKey, itemName, !currentAM, currentPM);
        } else {
          _state.setSupplementItemForDate(_dateKey, itemName, currentAM, !currentPM);
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
                hintText: 'Add a custom supplement...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addCustomSupplement(),
            ),
          ),
          GestureDetector(
            onTap: _addCustomSupplement,
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

  Widget _buildCommonSupplements() {
    // Filter out supplements already in user's list
    final myNames = _mySupplements.map((s) => s['name'].toString().toLowerCase()).toSet();
    final available = _commonSupplements
        .where((s) => !myNames.contains(s['name'].toString().toLowerCase()))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add from common supplements',
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
          children: available.map((supp) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _mySupplements.add({
                    'name': supp['name'],
                    'icon': supp['icon'],
                    'takesAM': true,
                    'takesPM': false,
                  });
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
                    Text(supp['icon'] as String, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      supp['name'] as String,
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
  void _markAllTaken() {
    for (final supp in _mySupplements) {
      final name = supp['name'] as String;
      final showAM = supp['takesAM'] ?? true;
      final showPM = supp['takesPM'] ?? false;
      _state.setSupplementItemForDate(_dateKey, name, showAM, showPM);
    }
    // Also mark as "Had All" on home screen
    _state.setSupplementsForDate(_dateKey, true);
  }

  void _clearAll() {
    for (final supp in _mySupplements) {
      final name = supp['name'] as String;
      _state.setSupplementItemForDate(_dateKey, name, false, false);
    }
    _state.setSupplementsForDate(_dateKey, null);
  }

  void _addCustomSupplement() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (!_mySupplements.any((s) => s['name'].toString().toLowerCase() == text.toLowerCase())) {
      setState(() {
        _mySupplements.add({
          'name': text,
          'icon': '💊',
          'takesAM': true,
          'takesPM': false,
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
