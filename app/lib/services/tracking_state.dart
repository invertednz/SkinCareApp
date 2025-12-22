import 'package:flutter/foundation.dart';

/// Global singleton for shared tracking state across all pages
class TrackingState extends ChangeNotifier {
  static final TrackingState _instance = TrackingState._internal();
  factory TrackingState() => _instance;
  static TrackingState get instance => _instance;
  TrackingState._internal();

  // ─────────────────────────────────────────────────────────────────
  // Shared selected date across all tracking pages
  // ─────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String get selectedDateKey =>
      '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // Daily mood/feeling tracking (per day)
  // ─────────────────────────────────────────────────────────────────
  final Map<String, int> _feelingsByDate = {}; // 0=terrible, 4=great

  int? getFeelingForDate(String dateKey) => _feelingsByDate[dateKey];
  int? get todayFeeling => _feelingsByDate[selectedDateKey];

  void setFeelingForDate(String dateKey, int feeling) {
    _feelingsByDate[dateKey] = feeling;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // Quick tracking flags (Had All / Different)
  // ─────────────────────────────────────────────────────────────────
  final Map<String, bool?> _routineByDate = {};
  final Map<String, bool?> _supplementsByDate = {};
  final Map<String, bool?> _dietByDate = {};

  bool? getRoutineForDate(String dateKey) => _routineByDate[dateKey];
  bool? getSupplementsForDate(String dateKey) => _supplementsByDate[dateKey];
  bool? getDietForDate(String dateKey) => _dietByDate[dateKey];

  void setRoutineForDate(String dateKey, bool? value) {
    _routineByDate[dateKey] = value;
    notifyListeners();
  }

  void setSupplementsForDate(String dateKey, bool? value) {
    _supplementsByDate[dateKey] = value;
    notifyListeners();
  }

  void setDietForDate(String dateKey, bool? value) {
    _dietByDate[dateKey] = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // Skin condition counter (like bowel motions but for breakouts)
  // ─────────────────────────────────────────────────────────────────
  final Map<String, int> _breakoutsByDate = {};

  int getBreakoutsForDate(String dateKey) => _breakoutsByDate[dateKey] ?? 0;

  void setBreakoutsForDate(String dateKey, int count) {
    _breakoutsByDate[dateKey] = count;
    notifyListeners();
  }

  void incrementBreakouts(String dateKey) {
    _breakoutsByDate[dateKey] = (_breakoutsByDate[dateKey] ?? 0) + 1;
    notifyListeners();
  }

  void decrementBreakouts(String dateKey) {
    final current = _breakoutsByDate[dateKey] ?? 0;
    if (current > 0) {
      _breakoutsByDate[dateKey] = current - 1;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Detailed tracking data (per day)
  // ─────────────────────────────────────────────────────────────────
  
  // Symptoms: dateKey -> Set of symptom names with severity
  final Map<String, Map<String, String>> _symptomsByDate = {}; // name -> severity

  Map<String, String> getSymptomsForDate(String dateKey) =>
      _symptomsByDate[dateKey] ?? {};

  void setSymptomForDate(String dateKey, String symptom, String severity) {
    _symptomsByDate[dateKey] ??= {};
    _symptomsByDate[dateKey]![symptom] = severity;
    notifyListeners();
  }

  void removeSymptomForDate(String dateKey, String symptom) {
    _symptomsByDate[dateKey]?.remove(symptom);
    notifyListeners();
  }

  // Routine items: dateKey -> item -> {am: bool, pm: bool}
  final Map<String, Map<String, Map<String, bool>>> _routineItemsByDate = {};

  Map<String, Map<String, bool>> getRoutineItemsForDate(String dateKey) =>
      _routineItemsByDate[dateKey] ?? {};

  void setRoutineItemForDate(String dateKey, String item, bool am, bool pm) {
    _routineItemsByDate[dateKey] ??= {};
    _routineItemsByDate[dateKey]![item] = {'am': am, 'pm': pm};
    notifyListeners();
  }

  // Supplements: dateKey -> Set of taken supplement names with AM/PM
  final Map<String, Map<String, Map<String, bool>>> _supplementItemsByDate = {};

  Map<String, Map<String, bool>> getSupplementItemsForDate(String dateKey) =>
      _supplementItemsByDate[dateKey] ?? {};

  void setSupplementItemForDate(String dateKey, String item, bool am, bool pm) {
    _supplementItemsByDate[dateKey] ??= {};
    _supplementItemsByDate[dateKey]![item] = {'am': am, 'pm': pm};
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // Daily log entries
  // ─────────────────────────────────────────────────────────────────
  final Map<String, List<DailyLogEntry>> _logEntriesByDate = {};

  List<DailyLogEntry> getLogsForDate(String dateKey) =>
      _logEntriesByDate[dateKey] ?? [];

  void addLogEntry(String dateKey, DailyLogEntry entry) {
    _logEntriesByDate[dateKey] ??= [];
    _logEntriesByDate[dateKey]!.add(entry);
    notifyListeners();
  }

  void removeLogEntry(String dateKey, int index) {
    if (_logEntriesByDate[dateKey] != null &&
        index < _logEntriesByDate[dateKey]!.length) {
      _logEntriesByDate[dateKey]!.removeAt(index);
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // User's default tracking lists (from onboarding)
  // ─────────────────────────────────────────────────────────────────
  List<String> _userSymptoms = [];
  List<SupplementEntry> _userSupplements = [];
  List<RoutineEntry> _userRoutineItems = [];
  List<String> _userDietTriggers = [];

  List<String> get userSymptoms => _userSymptoms;
  List<SupplementEntry> get userSupplements => _userSupplements;
  List<RoutineEntry> get userRoutineItems => _userRoutineItems;
  List<String> get userDietTriggers => _userDietTriggers;

  void setUserSymptoms(List<String> symptoms) {
    _userSymptoms = symptoms;
    notifyListeners();
  }

  void setUserSupplements(List<SupplementEntry> supplements) {
    _userSupplements = supplements;
    notifyListeners();
  }

  void setUserRoutineItems(List<RoutineEntry> items) {
    _userRoutineItems = items;
    notifyListeners();
  }

  void setUserDietTriggers(List<String> triggers) {
    _userDietTriggers = triggers;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // Streak calculation
  // ─────────────────────────────────────────────────────────────────
  int get currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      final hasData = _feelingsByDate.containsKey(key) ||
          _breakoutsByDate.containsKey(key) ||
          _supplementsByDate.containsKey(key) ||
          _routineByDate.containsKey(key) ||
          _dietByDate.containsKey(key) ||
          (_logEntriesByDate[key]?.isNotEmpty ?? false) ||
          (_symptomsByDate[key]?.isNotEmpty ?? false);

      if (hasData) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // Today has no data yet, check yesterday
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak > 0 ? streak : 0;
  }

  // ─────────────────────────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────────────────────────
  int get totalDaysTracked {
    final allDates = <String>{};
    allDates.addAll(_feelingsByDate.keys);
    allDates.addAll(_breakoutsByDate.keys);
    allDates.addAll(_supplementsByDate.keys);
    allDates.addAll(_routineByDate.keys);
    allDates.addAll(_dietByDate.keys);
    allDates.addAll(_logEntriesByDate.keys);
    allDates.addAll(_symptomsByDate.keys);
    return allDates.length;
  }

  double? get averageFeeling {
    if (_feelingsByDate.isEmpty) return null;
    final total = _feelingsByDate.values.reduce((a, b) => a + b);
    return total / _feelingsByDate.length;
  }

  int get daysWithSupplements =>
      _supplementsByDate.entries.where((e) => e.value == true).length;

  int get daysWithRoutine =>
      _routineByDate.entries.where((e) => e.value == true).length;
}

// ─────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────

class DailyLogEntry {
  final String description;
  final DateTime timestamp;
  final String? imagePath;

  DailyLogEntry({
    required this.description,
    required this.timestamp,
    this.imagePath,
  });

  String get timeString {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class SupplementEntry {
  final String name;
  bool takesAM;
  bool takesPM;

  SupplementEntry({
    required this.name,
    this.takesAM = true,
    this.takesPM = false,
  });
}

class RoutineEntry {
  final String name;
  final String icon;
  bool isAM;
  bool isPM;

  RoutineEntry({
    required this.name,
    this.icon = '✨',
    this.isAM = true,
    this.isPM = false,
  });
}
