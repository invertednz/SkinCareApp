import 'package:flutter/material.dart';
import '../../theme/brand.dart';
import '../../services/tracking_state.dart';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final TrackingState _state = TrackingState.instance;
  final TextEditingController _customController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  // Common skin symptoms
  static const List<Map<String, dynamic>> _commonSymptoms = [
    {'name': 'Acne', 'icon': '🔴'},
    {'name': 'Redness', 'icon': '🔥'},
    {'name': 'Dryness', 'icon': '🏜️'},
    {'name': 'Oiliness', 'icon': '💧'},
    {'name': 'Itching', 'icon': '😣'},
    {'name': 'Flaking', 'icon': '❄️'},
    {'name': 'Bumps', 'icon': '⚪'},
    {'name': 'Dark spots', 'icon': '🟤'},
    {'name': 'Fine lines', 'icon': '〰️'},
    {'name': 'Puffiness', 'icon': '🎈'},
    {'name': 'Sensitivity', 'icon': '⚡'},
    {'name': 'Breakout', 'icon': '💥'},
  ];

  List<String> _mySymptoms = [];
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
    
    // Load user's symptoms from onboarding or use defaults
    if (_state.userSymptoms.isNotEmpty) {
      _mySymptoms = List.from(_state.userSymptoms);
    } else {
      // Default symptoms to track
      _mySymptoms = ['Acne', 'Redness', 'Dryness', 'Oiliness'];
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
                    _buildMySymptoms(),
                    const SizedBox(height: 20),
                    _buildAddCustom(),
                    const SizedBox(height: 20),
                    _buildCommonSymptoms(),
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
            'Symptoms',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Track how your skin feels today',
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
            'Mark All Mild',
            Icons.check_circle_outline,
            Brand.mintColor,
            _markAllMild,
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

  Widget _buildMySymptoms() {
    final symptoms = _state.getSymptomsForDate(_dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Symptoms - Tap to mark for today',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._mySymptoms.map((symptom) {
          final severity = symptoms[symptom];
          final isTracked = severity != null;
          final iconData = _commonSymptoms.firstWhere(
            (s) => s['name'] == symptom,
            orElse: () => {'icon': '❓'},
          )['icon'];

          return _buildSymptomCard(
            symptom,
            iconData,
            isTracked,
            severity,
          );
        }),
      ],
    );
  }

  Widget _buildSymptomCard(
    String name,
    String icon,
    bool isTracked,
    String? severity,
  ) {
    Color cardColor = isTracked ? _getSeverityColor(severity!).withOpacity(0.15) : Colors.white;
    Color borderColor = isTracked ? _getSeverityColor(severity!) : Brand.borderLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isTracked ? 2 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTracked
                      ? _getSeverityColor(severity!).withOpacity(0.2)
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
                    color: isTracked ? _getSeverityColor(severity!) : Brand.textPrimary,
                  ),
                ),
              ),
              if (isTracked)
                Icon(Icons.check_circle, color: _getSeverityColor(severity!), size: 22)
              else
                Icon(Icons.radio_button_unchecked, color: Brand.borderMedium, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Severity:',
                style: TextStyle(
                  fontSize: 12,
                  color: isTracked ? _getSeverityColor(severity!) : Brand.textSecondary,
                ),
              ),
              const Spacer(),
              _buildSeverityButton(name, 'Mild', severity),
              const SizedBox(width: 8),
              _buildSeverityButton(name, 'Moderate', severity),
              const SizedBox(width: 8),
              _buildSeverityButton(name, 'Severe', severity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityButton(String symptom, String severityValue, String? currentSeverity) {
    final isSelected = currentSeverity == severityValue;
    final color = _getSeverityColor(severityValue);

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _state.removeSymptomForDate(_dateKey, symptom);
        } else {
          _state.setSymptomForDate(_dateKey, symptom, severityValue);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? color : Brand.borderMedium),
        ),
        child: Text(
          severityValue,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Brand.textSecondary,
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
                hintText: 'Add a custom symptom...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addCustomSymptom(),
            ),
          ),
          GestureDetector(
            onTap: _addCustomSymptom,
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

  Widget _buildCommonSymptoms() {
    // Filter out symptoms already in user's list
    final available = _commonSymptoms
        .where((s) => !_mySymptoms.contains(s['name']))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add from common symptoms',
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
          children: available.map((symptom) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _mySymptoms.add(symptom['name']);
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
                    Text(symptom['icon'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      symptom['name'],
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
  void _markAllMild() {
    for (final symptom in _mySymptoms) {
      _state.setSymptomForDate(_dateKey, symptom, 'Mild');
    }
  }

  void _clearAll() {
    for (final symptom in _mySymptoms) {
      _state.removeSymptomForDate(_dateKey, symptom);
    }
  }

  void _addCustomSymptom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (!_mySymptoms.contains(text)) {
      setState(() {
        _mySymptoms.add(text);
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Mild':
        return Brand.mintColor;
      case 'Moderate':
        return Colors.amber;
      case 'Severe':
        return Colors.redAccent;
      default:
        return Brand.textTertiary;
    }
  }
}
