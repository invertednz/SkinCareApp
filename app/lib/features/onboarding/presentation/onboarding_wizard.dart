import 'package:flutter/material.dart';
import '../state/onboarding_state.dart';
import '../../profile/profile_service.dart';
import '../data/onboarding_repository.dart';
import '../data/local_draft_store.dart';
import '../../../services/analytics.dart';
import '../../../theme/brand.dart';
import '../../../widgets/brand_scaffold.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _ConcernsWithSeverityStep extends StatefulWidget {
  const _ConcernsWithSeverityStep({
    required this.title,
    required this.options,
    required this.concerns,
    required this.severities,
    required this.onChanged,
    required this.hintText,
  });
  final String title;
  final List<String> options;
  final List<String> concerns;
  final Map<String, double> severities; // 0.0 (none) -> 1.0 (severe)
  final void Function(List<String> concerns, Map<String, double> severities) onChanged;
  final String hintText;

  @override
  State<_ConcernsWithSeverityStep> createState() => _ConcernsWithSeverityStepState();
}

class _ConcernsWithSeverityStepState extends State<_ConcernsWithSeverityStep> {
  final _ctrl = TextEditingController();
  static const Color _rose = Color(0xFFD0A3AF); // Dusty rose primary

  // Keep display labels as provided, but normalize severity map keys to lowercase
  late List<String> _selected; // display labels
  late Map<String, double> _sev; // keys: lowercase of label

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.concerns);
    // Normalize incoming severities to lowercase keys
    _sev = {
      for (final e in widget.severities.entries) e.key.toLowerCase(): e.value
    };
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _emit() {
    // Persist severities with lowercase keys
    widget.onChanged(_selected, Map<String, double>.from(_sev));
  }

  bool _containsIgnoreCase(List<String> list, String value) =>
      list.any((e) => e.toLowerCase() == value.toLowerCase());

  void _toggleChip(String opt, bool sel) {
    setState(() {
      if (sel) {
        if (!_containsIgnoreCase(_selected, opt)) {
          _selected.add(opt);
          _sev[opt.toLowerCase()] = _sev[opt.toLowerCase()] ?? 0.0;
        }
      } else {
        _selected.removeWhere((e) => e.toLowerCase() == opt.toLowerCase());
        _sev.remove(opt.toLowerCase());
      }
    });
    _emit();
  }

  void _addCustom() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!_containsIgnoreCase(_selected, v)) {
        _selected.add(v);
        _sev[v.toLowerCase()] = 0.0;
      }
      _ctrl.clear();
    });
    _emit();
  }

  void _remove(String key) {
    setState(() {
      _selected.removeWhere((e) => e.toLowerCase() == key.toLowerCase());
      _sev.remove(key.toLowerCase());
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLower = _selected.map((e) => e.toLowerCase()).toSet();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in widget.options)
                FilterChip(
                  label: Text(opt),
                  selected: selectedLower.contains(opt.toLowerCase()),
                  selectedColor: _rose,
                  onSelected: (sel) => _toggleChip(opt, sel),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(hintText: widget.hintText),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addCustom, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Current severity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Sliders for each selected concern
          Column(
            children: [
              for (final item in _selected)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0E8EB)), // Light rose border
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _remove(item),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text('None'),
                          Spacer(),
                          Text('Moderate'),
                          Spacer(),
                          Text('Severe'),
                        ],
                      ),
                      Slider(
                        value: (_sev[item.toLowerCase()] ?? 0.0).clamp(0.0, 1.0),
                        onChanged: (v) {
                          setState(() => _sev[item.toLowerCase()] = v);
                          _emit();
                        },
                        activeColor: _rose,
                        min: 0.0,
                        max: 1.0,
                        divisions: 4,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SingleSelectBoxes extends StatelessWidget {
  const _SingleSelectBoxes({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  static const _rose = Color(0xFFD0A3AF); // Dusty rose primary

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: [
              for (int i = 0; i < options.length; i++) ...[
                _Box(
                  label: options[i],
                  selected: value != null && value!.toLowerCase() == options[i].toLowerCase(),
                  onTap: () => onChanged(options[i]),
                ),
                if (i < options.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _rose = Color(0xFFD0A3AF); // Dusty rose primary
  static const _roseAccent = Color(0xFFBA8593); // Deeper rose

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _rose : Colors.white;
    final fg = selected ? Colors.black87 : Colors.black87;
    final border = selected ? _roseAccent.withOpacity(0.6) : const Color(0xFFE8E0E3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _rose.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _SupplementsStep extends StatefulWidget {
  const _SupplementsStep({
    required this.title,
    required this.options,
    required this.payload,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final Map<String, dynamic> payload;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<_SupplementsStep> createState() => _SupplementsStepState();
}

class _SupplementsStepState extends State<_SupplementsStep> {
  final _ctrl = TextEditingController();
  late List<Map<String, dynamic>> _items; // {label, checked, am, pm}

  static const Map<String, String> _icons = {
    'zinc': '🔩',
    'omega-3': '🐟',
    'vitamin d': '☀️',
    'probiotics': '🦠',
    'collagen': '💪',
  };

  @override
  void initState() {
    super.initState();
    final raw = widget.payload['items'];
    if (raw is List) {
      _items = raw.map<Map<String, dynamic>>((e) {
        if (e is String) {
          return {'label': e, 'checked': true, 'am': true, 'pm': false};
        } else if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          return {
            'label': (m['label'] ?? m['name'] ?? '').toString(),
            'checked': m['checked'] == true,
            'am': m['am'] == true,
            'pm': m['pm'] == true,
          };
        }
        return {'label': e.toString(), 'checked': true, 'am': true, 'pm': false};
      }).toList();
    } else {
      _items = [];
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged({'items': _items});
  }

  bool _isSelected(String name) =>
      _items.any((e) => (e['label'] as String).toLowerCase() == name.toLowerCase());

  void _toggleOption(String name) {
    final i = _items.indexWhere((e) => (e['label'] as String).toLowerCase() == name.toLowerCase());
    if (i >= 0) {
      setState(() => _items.removeAt(i));
    } else {
      setState(() => _items.add({'label': name, 'checked': true, 'am': true, 'pm': false}));
    }
    _emit();
  }

  void _addCustom() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    if (!_isSelected(v)) {
      setState(() => _items.add({'label': v, 'checked': true, 'am': true, 'pm': false}));
      _emit();
    }
    _ctrl.clear();
  }

  String _getIcon(String name) => _icons[name.toLowerCase()] ?? '💊';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Brand.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select supplements you take and when you take them',
            style: TextStyle(fontSize: 14, color: Brand.textSecondary),
          ),
          const SizedBox(height: 20),

          // Default options as cards
          ...widget.options.map((opt) => _buildSupplementCard(opt)),

          // Custom items
          ..._items
              .where((item) => !widget.options.any(
                  (opt) => opt.toLowerCase() == (item['label'] as String).toLowerCase()))
              .map((item) => _buildSupplementCard(item['label'] as String, isCustom: true)),

          // Add custom row
          _buildAddCustomRow(),
        ],
      ),
    );
  }

  Widget _buildSupplementCard(String name, {bool isCustom = false}) {
    final isSelected = _isSelected(name);
    final item = _items.firstWhere(
      (e) => (e['label'] as String).toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Brand.primaryStart.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Brand.primaryStart : Brand.borderLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.primaryStart.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleOption(name),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: Brand.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(_getIcon(name), style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name[0].toUpperCase() + name.substring(1),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Brand.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Brand.borderLight,
                        width: 2,
                      ),
                      gradient: isSelected ? Brand.primaryGradient : null,
                      color: isSelected ? null : Colors.white,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            // AM/PM toggles when selected
            if (isSelected && item.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('When:', style: TextStyle(fontSize: 12, color: Brand.textSecondary)),
                  const Spacer(),
                  _buildTimeButton(item, 'am', '☀️ AM'),
                  const SizedBox(width: 8),
                  _buildTimeButton(item, 'pm', '🌙 PM'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(Map<String, dynamic> item, String key, String label) {
    final isActive = item[key] == true;
    return InkWell(
      onTap: () {
        setState(() => item[key] = !isActive);
        _emit();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? Brand.primaryGradient : null,
          color: isActive ? null : Brand.cardBackgroundSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? Colors.transparent : Brand.borderLight),
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

  Widget _buildAddCustomRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Brand.borderLight),
              ),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Add a supplement',
                  hintStyle: TextStyle(color: Brand.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _addCustom,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: Brand.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineItem {
  final String id;
  final String name;
  final String icon;
  bool isSelected;
  String frequency; // 'daily', 'weekly', 'as-needed'

  _RoutineItem({
    required this.id,
    required this.name,
    required this.icon,
    this.isSelected = false,
    this.frequency = 'daily',
  });

  Map<String, dynamic> toJson() => {
    'key': id,
    'label': name,
    'icon': icon,
    'checked': isSelected,
    'freq': frequency,
  };
}

class _RoutineBuilderStep extends StatefulWidget {
  const _RoutineBuilderStep({
    required this.title,
    required this.payload,
    required this.onChanged,
    this.isActive = true,
  });
  final String title;
  final Map<String, dynamic> payload;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool isActive;

  @override
  State<_RoutineBuilderStep> createState() => _RoutineBuilderStepState();
}

class _RoutineBuilderStepState extends State<_RoutineBuilderStep> {
  bool _skip = false;
  final _amCtrl = TextEditingController();
  final _pmCtrl = TextEditingController();

  // Default morning routine items
  final List<_RoutineItem> _morningItems = [
    _RoutineItem(id: 'cleanser_am', name: 'Cleanser', icon: '🧴'),
    _RoutineItem(id: 'toner_am', name: 'Toner', icon: '💧'),
    _RoutineItem(id: 'serum_am', name: 'Serum', icon: '✨'),
    _RoutineItem(id: 'moisturizer_am', name: 'Moisturizer', icon: '🧈'),
    _RoutineItem(id: 'sunscreen', name: 'Sunscreen', icon: '☀️'),
    _RoutineItem(id: 'eye_cream_am', name: 'Eye Cream', icon: '👁️'),
  ];

  // Default evening routine items
  final List<_RoutineItem> _eveningItems = [
    _RoutineItem(id: 'makeup_remover', name: 'Makeup Remover', icon: '🧹'),
    _RoutineItem(id: 'cleanser_pm', name: 'Cleanser', icon: '🧴'),
    _RoutineItem(id: 'exfoliant', name: 'Exfoliant', icon: '🌟'),
    _RoutineItem(id: 'toner_pm', name: 'Toner', icon: '💧'),
    _RoutineItem(id: 'treatment', name: 'Treatment/Actives', icon: '💉'),
    _RoutineItem(id: 'serum_pm', name: 'Serum', icon: '✨'),
    _RoutineItem(id: 'eye_cream_pm', name: 'Eye Cream', icon: '👁️'),
    _RoutineItem(id: 'moisturizer_pm', name: 'Night Cream', icon: '🌙'),
    _RoutineItem(id: 'face_oil', name: 'Face Oil', icon: '🫒'),
  ];

  // Custom items added by user
  final List<_RoutineItem> _customMorningItems = [];
  final List<_RoutineItem> _customEveningItems = [];

  @override
  void initState() {
    super.initState();
    _loadFromPayload();
  }

  void _loadFromPayload() {
    final p = widget.payload;
    _skip = p['skip'] == true;

    // Load saved AM items
    if (p['am'] is List) {
      for (final item in (p['am'] as List)) {
        if (item is Map) {
          final key = item['key']?.toString() ?? '';
          final checked = item['checked'] == true;
          final freq = item['freq']?.toString() ?? 'daily';

          // Check if it's a default item
          final defaultItem = _morningItems.where((e) => e.id == key).firstOrNull;
          if (defaultItem != null) {
            defaultItem.isSelected = checked;
            defaultItem.frequency = freq;
          } else if (key.isNotEmpty) {
            // Custom item
            _customMorningItems.add(_RoutineItem(
              id: key,
              name: item['label']?.toString() ?? key,
              icon: item['icon']?.toString() ?? '💊',
              isSelected: checked,
              frequency: freq,
            ));
          }
        }
      }
    }

    // Load saved PM items
    if (p['pm'] is List) {
      for (final item in (p['pm'] as List)) {
        if (item is Map) {
          final key = item['key']?.toString() ?? '';
          final checked = item['checked'] == true;
          final freq = item['freq']?.toString() ?? 'daily';

          final defaultItem = _eveningItems.where((e) => e.id == key).firstOrNull;
          if (defaultItem != null) {
            defaultItem.isSelected = checked;
            defaultItem.frequency = freq;
          } else if (key.isNotEmpty) {
            _customEveningItems.add(_RoutineItem(
              id: key,
              name: item['label']?.toString() ?? key,
              icon: item['icon']?.toString() ?? '💊',
              isSelected: checked,
              frequency: freq,
            ));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _amCtrl.dispose();
    _pmCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final amItems = [..._morningItems, ..._customMorningItems]
        .where((e) => e.isSelected)
        .map((e) => e.toJson())
        .toList();
    final pmItems = [..._eveningItems, ..._customEveningItems]
        .where((e) => e.isSelected)
        .map((e) => e.toJson())
        .toList();

    widget.onChanged({
      'am': amItems,
      'pm': pmItems,
      'skip': _skip,
    });
  }

  void _addCustomItem(String section) {
    final ctrl = section == 'am' ? _amCtrl : _pmCtrl;
    final list = section == 'am' ? _customMorningItems : _customEveningItems;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;

    final id = '${section}_custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
    final allItems = section == 'am'
        ? [..._morningItems, ..._customMorningItems]
        : [..._eveningItems, ..._customEveningItems];

    if (!allItems.any((e) => e.id == id)) {
      setState(() {
        list.add(_RoutineItem(
          id: id,
          name: name,
          icon: '💊',
          isSelected: true,
          frequency: 'daily',
        ));
      });
      _emit();
    }
    ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Brand.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the steps in your skincare routine',
            style: TextStyle(fontSize: 14, color: Brand.textSecondary),
          ),
          const SizedBox(height: 20),

          // Morning section
          _buildSectionHeader('☀️ Morning Routine'),
          const SizedBox(height: 12),
          ..._morningItems.map((item) => _buildRoutineCard(item)),
          ..._customMorningItems.map((item) => _buildRoutineCard(item, isCustom: true)),
          _buildAddCustomRow('am', _amCtrl, 'Add morning step'),
          const SizedBox(height: 24),

          // Evening section
          _buildSectionHeader('🌙 Evening Routine'),
          const SizedBox(height: 12),
          ..._eveningItems.map((item) => _buildRoutineCard(item)),
          ..._customEveningItems.map((item) => _buildRoutineCard(item, isCustom: true)),
          _buildAddCustomRow('pm', _pmCtrl, 'Add evening step'),
          const SizedBox(height: 16),

          // Skip option
          InkWell(
            onTap: () {
              setState(() => _skip = !_skip);
              _emit();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _skip ? Colors.transparent : Brand.borderLight,
                        width: 2,
                      ),
                      gradient: _skip ? Brand.primaryGradient : null,
                      color: _skip ? null : Colors.white,
                    ),
                    child: _skip
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "I don't have a routine yet",
                    style: TextStyle(
                      fontSize: 14,
                      color: Brand.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Brand.textPrimary,
      ),
    );
  }

  Widget _buildRoutineCard(_RoutineItem item, {bool isCustom = false}) {
    final isSelected = item.isSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Brand.primaryStart.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Brand.primaryStart : Brand.borderLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Brand.primaryStart.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() => item.isSelected = !item.isSelected);
                _emit();
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: Brand.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(item.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Brand.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Brand.borderLight,
                        width: 2,
                      ),
                      gradient: isSelected ? Brand.primaryGradient : null,
                      color: isSelected ? null : Colors.white,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            // Frequency buttons - only show when selected
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Frequency:',
                    style: TextStyle(fontSize: 12, color: Brand.textSecondary),
                  ),
                  const Spacer(),
                  _buildFreqButton(item, 'daily', 'Daily'),
                  const SizedBox(width: 6),
                  _buildFreqButton(item, 'weekly', 'Weekly'),
                  const SizedBox(width: 6),
                  _buildFreqButton(item, 'as-needed', 'As needed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreqButton(_RoutineItem item, String value, String label) {
    final isActive = item.frequency == value;
    return InkWell(
      onTap: () {
        setState(() => item.frequency = value);
        _emit();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isActive ? Brand.primaryGradient : null,
          color: isActive ? null : Brand.cardBackgroundSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.transparent : Brand.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Brand.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustomRow(String section, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Brand.borderLight),
              ),
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Brand.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _addCustomItem(section),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _addCustomItem(section),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: Brand.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  late final OnboardingState _state;
  late final PageController _controller;
  int _index = 0;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _state = OnboardingState();
    _controller = PageController();
    // Load any saved drafts on start
    Future.microtask(() async {
      final drafts = await OnboardingDraftStore.instance.load();
      if (!mounted) return;
      for (final entry in drafts.entries) {
        _state.setStepPayload(entry.key, entry.value);
      }
      setState(() {});
    });
    AnalyticsService.capture('onboarding_start');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() async {
    final step = _state.steps[_index];
    await _persistStep(step);
    AnalyticsService.capture('onboarding_step_submit', {
      'step_key': step.key,
    });
    if (_index < _state.steps.length - 1) {
      setState(() => _index++);
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_index > 0) {
      setState(() => _index--);
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Persist last step before completing
      final step = _state.steps[_index];
      await _persistStep(step);
      AnalyticsService.capture('onboarding_step_submit', {
        'step_key': step.key,
        'final': true,
      });

      // If onComplete callback is provided, use it (for enhanced flow)
      if (widget.onComplete != null) {
        await OnboardingDraftStore.instance.clear();
        if (!mounted) return;
        widget.onComplete!();
      } else {
        // Legacy standalone behavior
        await ProfileService.instance.markOnboardingCompleted();
        await OnboardingDraftStore.instance.clear();
        AnalyticsService.capture('onboarding_complete');
        if (!mounted) return;
        if (context.mounted) {
          // Router guard will send to paywall
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to complete onboarding');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _isLast => _index == _state.steps.length - 1;
  bool get _currentValid => _state.isStepValid(_state.steps[_index]);

  @override
  Widget build(BuildContext context) {
    final steps = _state.steps;
    final progress = (_index + 1) / steps.length;
    return Scaffold(
      backgroundColor: Brand.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Brand.textPrimary),
          onPressed: _saving || _index == 0 ? null : _back,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Brand.textPrimary),
            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
            tooltip: 'Save & exit',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Brand.borderMedium,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: Brand.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/${steps.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Brand.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Content card
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Brand.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.primaryStart.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: PageView.builder(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length,
                      itemBuilder: (context, i) => _buildStep(context, steps[i], i == _index),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Navigation buttons
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Brand.primaryStart,
                          side: BorderSide(color: Brand.primaryStart, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _index == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _saving || !_currentValid
                          ? null
                          : (_isLast ? _submit : _next),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Brand.primaryStart,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Brand.borderMedium,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isLast ? 'Complete' : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingStepKey step, bool isActive) {
    switch (step) {
      case OnboardingStepKey.skinConcerns: {
        final payload = _state.getStepPayload(step);
        final concerns = (payload['concerns'] as List?)?.cast<String>() ?? const [];
        final severities = Map<String, num>.from(payload['severities'] as Map? ?? {});
        return _ConcernsWithSeverityStep(
          title: 'Skin concerns',
          options: OnboardingValidators.allowedConcerns.toList(),
          concerns: concerns,
          severities: severities.map((k, v) => MapEntry(k, (v as num).toDouble())),
          hintText: 'Add another concern',
          onChanged: (nextConcerns, nextSeverities) async {
            setState(() => _state.setStepPayload(step, {
                  'concerns': nextConcerns,
                  'severities': nextSeverities,
                }));
            await _persistStep(step);
          },
        );
      }
      case OnboardingStepKey.skinType:
        final options = OnboardingValidators.allowedSkinTypes.toList();
        final current = _state.getStepPayload(step)['type'] as String?;
        return _SingleSelectBoxes(
          title: 'Skin type',
          options: options,
          value: current,
          onChanged: (v) async {
            setState(() => _state.setStepPayload(step, {'type': v}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.routine:
        final payload = _state.getStepPayload(step);
        return _RoutineBuilderStep(
          title: 'Current routine',
          payload: payload,
          isActive: isActive,
          onChanged: (next) async {
            setState(() => _state.setStepPayload(step, next));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.sensitivities:
        return _CardSelectStep(
          title: 'Sensitivities',
          subtitle: 'Select any ingredients or substances that irritate your skin',
          options: OnboardingValidators.allowedSensitivities.toList(),
          values: (_state.getStepPayload(step)['items'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a sensitivity or trigger',
          icons: const {
            'fragrance': '🌸',
            'essential oils': '🫒',
            'alcohol': '🍷',
            'lanolin': '🐑',
            'dyes': '🎨',
            'parabens': '⚗️',
            'sulfates': '🧪',
          },
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'items': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.dietFlags:
        return _CardSelectStep(
          title: 'Diet & Nutrition',
          subtitle: 'Select foods or dietary factors that may affect your skin',
          options: OnboardingValidators.allowedDietFlags.toList(),
          values: (_state.getStepPayload(step)['flags'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a diet trigger',
          icons: const {
            'dairy': '🥛',
            'gluten': '🍞',
            'sugar': '🍬',
            'alcohol': '🍷',
            'caffeine': '☕',
          },
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'flags': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.supplements:
        final payload = _state.getStepPayload(step);
        return _SupplementsStep(
          title: 'Supplements',
          options: OnboardingValidators.allowedSupplements.toList(),
          payload: payload,
          onChanged: (next) async {
            setState(() => _state.setStepPayload(step, next));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.lifestyle:
        return _CardSelectStep(
          title: 'Lifestyle Factors',
          subtitle: 'Select factors that may be affecting your skin health',
          options: OnboardingValidators.allowedLifestyle.toList(),
          values: (_state.getStepPayload(step)['factors'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a lifestyle factor',
          icons: const {
            'low sleep': '😴',
            'high stress': '😰',
            'low exercise': '🏃',
            'smoker': '🚬',
            'high sun exposure': '☀️',
          },
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'factors': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.medications:
        return _CardSelectStep(
          title: 'Medications',
          subtitle: 'Select any skin-related medications you are currently using',
          options: OnboardingValidators.allowedMedications.toList(),
          values: (_state.getStepPayload(step)['medications'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a medication',
          icons: const {
            'adapalene': '💊',
            'tretinoin': '💉',
            'benzoyl peroxide': '🧴',
            'clindamycin': '💊',
            'isotretinoin': '💊',
            'spironolactone': '💊',
          },
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'medications': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.consentInfo:
        // Consent moved to signup page - auto-acknowledge and continue
        Future.microtask(() async {
          if (_state.getStepPayload(step)['acknowledged'] != true) {
            setState(() => _state.setStepPayload(step, {'acknowledged': true}));
            await _persistStep(step);
          }
        });
        return const SizedBox.shrink();
      
    }
  }

  Future<void> _persistStep(OnboardingStepKey step) async {
    try {
      final payload = _state.getStepPayload(step);
      await OnboardingDraftStore.instance.saveStep(step, payload);
      await OnboardingRepository.instance.upsertStep(step, payload);
    } catch (e) {
      setState(() => _error = 'Failed to save step');
    }
  }

  
}

class _MultiSelectChips extends StatelessWidget {
  const _MultiSelectChips({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in options)
                FilterChip(
                  label: Text(opt),
                  selected: values.contains(opt),
                  onSelected: (sel) {
                    final next = List<String>.from(values);
                    if (sel) {
                      next.add(opt);
                    } else {
                      next.remove(opt);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card-based selection step with icons for onboarding
class _CardSelectStep extends StatefulWidget {
  const _CardSelectStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.values,
    required this.onChanged,
    required this.hintText,
    this.icons = const {},
  });
  final String title;
  final String subtitle;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final Map<String, String> icons; // option -> emoji

  @override
  State<_CardSelectStep> createState() => _CardSelectStepState();
}

class _CardSelectStepState extends State<_CardSelectStep> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isSelected(String opt) =>
      widget.values.any((e) => e.toLowerCase() == opt.toLowerCase());

  void _toggleOption(String opt) {
    final next = List<String>.from(widget.values);
    if (_isSelected(opt)) {
      next.removeWhere((e) => e.toLowerCase() == opt.toLowerCase());
    } else {
      next.add(opt);
    }
    widget.onChanged(next);
  }

  void _addCustom() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    final next = List<String>.from(widget.values);
    final exists = next.any((e) => e.toLowerCase() == v.toLowerCase());
    if (!exists) {
      next.add(v);
      widget.onChanged(next);
    }
    _ctrl.clear();
  }

  String _getIcon(String opt) {
    return widget.icons[opt.toLowerCase()] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    final lowerOptions = widget.options.map((e) => e.toLowerCase()).toSet();
    final customOnly = widget.values.where((v) => !lowerOptions.contains(v.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Brand.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(fontSize: 14, color: Brand.textSecondary),
          ),
          const SizedBox(height: 20),

          // Option cards
          ...widget.options.map((opt) => _buildOptionCard(opt)),

          // Custom items
          ...customOnly.map((item) => _buildOptionCard(item, isCustom: true)),

          // Add custom row
          _buildAddCustomRow(),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String opt, {bool isCustom = false}) {
    final isSelected = _isSelected(opt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _toggleOption(opt),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Brand.primaryStart.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Brand.primaryStart : Brand.borderLight,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.primaryStart.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: Brand.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(_getIcon(opt), style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opt[0].toUpperCase() + opt.substring(1),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Brand.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Brand.borderLight,
                    width: 2,
                  ),
                  gradient: isSelected ? Brand.primaryGradient : null,
                  color: isSelected ? null : Colors.white,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCustomRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Brand.borderLight),
              ),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Brand.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _addCustom,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: Brand.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy _ConcernsStep kept for compatibility but uses new card design
class _ConcernsStep extends StatelessWidget {
  const _ConcernsStep({
    required this.title,
    required this.options,
    required this.values,
    required this.onChanged,
    required this.hintText,
  });
  final String title;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return _CardSelectStep(
      title: title,
      subtitle: 'Select all that apply',
      options: options,
      values: values,
      onChanged: onChanged,
      hintText: hintText,
    );
  }
}

class _DropdownStep extends StatelessWidget {
  const _DropdownStep({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(labelText: 'Select one'),
          ),
        ],
      ),
    );
  }
}

class _TextListStep extends StatefulWidget {
  const _TextListStep({
    required this.title,
    required this.values,
    required this.onChanged,
    required this.hintText,
  });
  final String title;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String hintText;

  @override
  State<_TextListStep> createState() => _TextListStepState();
}

class _TextListStepState extends State<_TextListStep> {
  late List<String> _items;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.values);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _items.add(v);
      _ctrl.clear();
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(hintText: widget.hintText),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _items)
                Chip(
                  label: Text(item),
                  onDeleted: () {
                    setState(() => _items.remove(item));
                    widget.onChanged(_items);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
