import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/brand.dart';
import '../../services/tracking_state.dart';

class TrackingHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const TrackingHomeScreen({super.key, this.onNavigateToTab});

  @override
  State<TrackingHomeScreen> createState() => _TrackingHomeScreenState();
}

class _TrackingHomeScreenState extends State<TrackingHomeScreen> {
  final TrackingState _state = TrackingState.instance;
  final TextEditingController _logController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    // Scroll to show today's date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _logController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _scrollToToday() {
    // Each day cell is roughly 56 pixels wide + 8 margin
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

  DateTime _getStartDate() {
    return DateTime.now().subtract(const Duration(days: 30));
  }

  String _getDateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.charcoal,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Calendar bar
                    _buildCalendarBar(),
                    const SizedBox(height: 20),
                    // How are you feeling
                    _buildFeelingSection(),
                    const SizedBox(height: 20),
                    // Quick tracking grid
                    _buildQuickTrackingGrid(),
                    const SizedBox(height: 24),
                    // Health insights
                    _buildHealthInsights(),
                    const SizedBox(height: 24),
                    // Daily logs
                    _buildDailyLogs(),
                    const SizedBox(height: 100), // Space for input bar
                  ],
                ),
              ),
            ),
            
            // Bottom input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SkinCare',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Track your daily skin health',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Brand.mintColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${_state.currentStreak}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Brand.mintColor,
                  ),
                ),
              ],
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
            final hasData = _hasDataForDate(date);

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
                    if (hasData && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Brand.mintColor,
                          shape: BoxShape.circle,
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

  Widget _buildFeelingSection() {
    final dateKey = _state.selectedDateKey;
    final currentFeeling = _state.getFeelingForDate(dateKey);
    
    final feelings = [
      {'emoji': '😫', 'label': 'Terrible'},
      {'emoji': '😞', 'label': 'Bad'},
      {'emoji': '😐', 'label': 'Okay'},
      {'emoji': '🙂', 'label': 'Good'},
      {'emoji': '😄', 'label': 'Great'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How is your skin feeling?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(feelings.length, (index) {
              final isSelected = currentFeeling == index;
              return GestureDetector(
                onTap: () => _state.setFeelingForDate(dateKey, index),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getFeelingColor(index).withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getFeelingColor(index)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        feelings[index]['emoji']!,
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feelings[index]['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? _getFeelingColor(index)
                            : Brand.textTertiary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTrackingGrid() {
    final dateKey = _state.selectedDateKey;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBreakoutCounter(dateKey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickCard(
                'Routine',
                Icons.spa_outlined,
                _state.getRoutineForDate(dateKey),
                (val) => _state.setRoutineForDate(dateKey, val),
                1, // Navigate to routine tab
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickCard(
                'Supplements',
                Icons.medication_outlined,
                _state.getSupplementsForDate(dateKey),
                (val) => _state.setSupplementsForDate(dateKey, val),
                2, // Navigate to supplements tab
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickCard(
                'Diet',
                Icons.restaurant_outlined,
                _state.getDietForDate(dateKey),
                (val) => _state.setDietForDate(dateKey, val),
                -1, // No navigation for diet currently
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakoutCounter(String dateKey) {
    final count = _state.getBreakoutsForDate(dateKey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grain, size: 18, color: Brand.primaryStart),
              const SizedBox(width: 6),
              Text(
                'Breakouts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Brand.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Brand.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildCounterButton(
                    Icons.remove,
                    () => _state.decrementBreakouts(dateKey),
                  ),
                  const SizedBox(width: 8),
                  _buildCounterButton(
                    Icons.add,
                    () => _state.incrementBreakouts(dateKey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Brand.charcoal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Brand.charcoal),
      ),
    );
  }

  Widget _buildQuickCard(
    String title,
    IconData icon,
    bool? followed,
    Function(bool?) onChanged,
    int tabIndex,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Brand.primaryStart),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Brand.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: followed == true
                          ? Brand.mintColor.withOpacity(0.15)
                          : Brand.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: followed == true
                            ? Brand.mintColor
                            : Brand.borderMedium,
                        width: followed == true ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Had All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: followed == true
                              ? Brand.mintColor
                              : Brand.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    onChanged(false);
                    if (tabIndex >= 0 && widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(tabIndex);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: followed == false
                          ? Colors.amber.withOpacity(0.15)
                          : Brand.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: followed == false
                            ? Colors.amber
                            : Brand.borderMedium,
                        width: followed == false ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Different',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: followed == false
                              ? Colors.amber.shade700
                              : Brand.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInsights() {
    final avgFeeling = _state.averageFeeling;
    String avgFeelingText = 'N/A';
    if (avgFeeling != null) {
      final feelings = ['😫', '😞', '😐', '🙂', '😄'];
      avgFeelingText = feelings[avgFeeling.round().clamp(0, 4)];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Skin Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Brand.charcoal.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      Icons.calendar_today,
                      'Days Tracked',
                      '${_state.totalDaysTracked}',
                      'Total',
                      Brand.primaryStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInsightCard(
                      Icons.mood,
                      'Avg Feeling',
                      avgFeelingText,
                      avgFeeling != null ? '' : 'N/A',
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInsightCard(
                      Icons.local_fire_department,
                      'Streak',
                      '${_state.currentStreak}',
                      'Days',
                      Brand.mintColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Brand.primaryStart.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Brand.primaryStart.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking Summary',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _state.totalDaysTracked > 0
                                ? 'Routine followed: ${_state.daysWithRoutine} days • Supplements: ${_state.daysWithSupplements} days'
                                : 'Start tracking today to see your patterns and insights!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyLogs() {
    final dateKey = _state.selectedDateKey;
    final logs = _state.getLogsForDate(dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Logs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    color: Colors.white.withOpacity(0.3),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No logs yet for this day',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...logs.asMap().entries.map((entry) => _buildLogEntry(entry.value, entry.key, dateKey)),
      ],
    );
  }

  Widget _buildLogEntry(DailyLogEntry log, int index, String dateKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                log.imagePath!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Brand.backgroundLight,
                  child: Icon(Icons.image, color: Brand.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Brand.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.timeString,
                  style: TextStyle(
                    fontSize: 12,
                    color: Brand.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _state.removeLogEntry(dateKey, index),
            child: Icon(
              Icons.close,
              size: 18,
              color: Brand.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Brand.charcoal,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Camera button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Brand.primaryStart.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: Brand.primaryStart,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text input
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _logController,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'What did you eat, do, or feel?',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addLogEntry(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _addLogEntry,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: Brand.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLogEntry() {
    final text = _logController.text.trim();
    if (text.isEmpty) return;

    _state.addLogEntry(
      _state.selectedDateKey,
      DailyLogEntry(
        description: text,
        timestamp: DateTime.now(),
      ),
    );
    _logController.clear();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Add log entry with image
      _state.addLogEntry(
        _state.selectedDateKey,
        DailyLogEntry(
          description: 'Photo log',
          timestamp: DateTime.now(),
          imagePath: image.path,
        ),
      );
    }
  }

  // Helper methods
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasDataForDate(DateTime date) {
    final key = _getDateKey(date);
    return _state.getFeelingForDate(key) != null ||
        _state.getBreakoutsForDate(key) > 0 ||
        _state.getRoutineForDate(key) != null ||
        _state.getSupplementsForDate(key) != null ||
        _state.getDietForDate(key) != null ||
        _state.getLogsForDate(key).isNotEmpty;
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  Color _getFeelingColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Brand.mintColor;
      default:
        return Brand.textTertiary;
    }
  }
}
