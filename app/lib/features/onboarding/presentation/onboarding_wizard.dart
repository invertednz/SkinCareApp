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

  static const Color _rose = Color(0xFFD0A3AF); // Dusty rose primary

  @override
  void initState() {
    super.initState();
    final raw = widget.payload['items'];
    if (raw is List) {
      // Support both legacy [String] and new [{label,checked,am,pm}] formats
      _items = raw.map<Map<String, dynamic>>((e) {
        if (e is String) {
          return {
            'label': e,
            'checked': true,
            'am': true,
            'pm': false,
          };
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

  void _toggleQuick(String name, bool selected) {
    final i = _items.indexWhere((e) => (e['label'] as String).toLowerCase() == name.toLowerCase());
    if (selected) {
      if (i < 0) {
        setState(() {
          _items.add({'label': name, 'checked': true, 'am': true, 'pm': false});
        });
      } else {
        setState(() => _items[i]['checked'] = true);
      }
    } else {
      if (i >= 0) setState(() => _items.removeAt(i));
    }
    _emit();
  }

  void _addCustom() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    final exists = _items.any((e) => (e['label'] as String).toLowerCase() == v.toLowerCase());
    if (!exists) {
      setState(() {
        _items.add({'label': v, 'checked': true, 'am': true, 'pm': false});
      });
      _emit();
    }
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLower = _items.map((e) => (e['label'] as String).toLowerCase()).toSet();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Quick picks pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in widget.options)
                FilterChip(
                  label: Text(opt),
                  selected: selectedLower.contains(opt.toLowerCase()),
                  selectedColor: _rose,
                  onSelected: (sel) => _toggleQuick(opt, sel),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Input to add custom
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Add a supplement'),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addCustom, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          // List section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (int i = 0; i < _items.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: i < _items.length - 1
                            ? const Border(bottom: BorderSide(color: Color(0xFFF0E8EB))) // Light rose border
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _items[i]['checked'] == true,
                                onChanged: (v) {
                                  setState(() => _items[i]['checked'] = v == true);
                                  _emit();
                                },
                              ),
                              Text(_items[i]['label']?.toString() ?? ''),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('AM'),
                                selected: _items[i]['am'] == true,
                                selectedColor: _rose,
                                onSelected: (_) {
                                  setState(() => _items[i]['am'] = !(_items[i]['am'] == true));
                                  _emit();
                                },
                              ),
                              ChoiceChip(
                                label: const Text('PM'),
                                selected: _items[i]['pm'] == true,
                                selectedColor: _rose,
                                onSelected: (_) {
                                  setState(() => _items[i]['pm'] = !(_items[i]['pm'] == true));
                                  _emit();
                                },
                              ),
                            ],
                          ),
                        ],
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
  // Whether this step is currently visible in the PageView
  final bool isActive;

  @override
  State<_RoutineBuilderStep> createState() => _RoutineBuilderStepState();
}

class _RoutineBuilderStepState extends State<_RoutineBuilderStep> {
  static const List<String> _freqOptions = ['daily', 'weekly', 'as-needed'];

  late List<Map<String, dynamic>> _am;
  late List<Map<String, dynamic>> _pm;
  bool _skip = false;

  final _amCtrl = TextEditingController();
  final _pmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.payload;
    _skip = p['skip'] == true;
    if (p['am'] is List && p['pm'] is List) {
      _am = (p['am'] as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _pm = (p['pm'] as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      // Start blank by default; if legacy flags exist, add those
      _am = [];
      _pm = [];
      for (final k in ['cleanser','moisturizer','sunscreen','actives']) {
        if (p[k] == true) {
          _ensureInList(_am, k, _labelFor(k), checked: true);
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

  Map<String, dynamic> _makeItem(String key, String label, {bool checked = true, String freq = 'daily'}) =>
      {'key': key, 'label': label, 'checked': checked, 'freq': freq};

  String _labelFor(String key) {
    switch (key) {
      case 'cleanser': return 'Cleanser';
      case 'moisturizer': return 'Moisturizer';
      case 'sunscreen': return 'Sunscreen';
      case 'actives': return 'Actives';
      default: return key[0].toUpperCase() + key.substring(1);
    }
  }

  void _ensureInList(List<Map<String, dynamic>> list, String key, String label, {bool checked = true}) {
    final i = list.indexWhere((e) => (e['key'] as String).toLowerCase() == key.toLowerCase());
    if (i >= 0) {
      list[i]['checked'] = checked;
    } else {
      list.add(_makeItem(key, label, checked: checked));
    }
  }

  void _emit() {
    widget.onChanged({
      'am': _am,
      'pm': _pm,
      'skip': _skip,
    });
  }

  void _addTo(String section) {
    final ctrl = section == 'am' ? _amCtrl : _pmCtrl;
    final list = section == 'am' ? _am : _pm;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    // Avoid duplicates (case-insensitive)
    if (!list.any((e) => (e['key'] as String).toLowerCase() == key)) {
      setState(() {
        list.add(_makeItem(key, name, checked: true, freq: 'daily'));
      });
      _emit();
    }
    ctrl.clear();
  }

  Widget _buildSection(String title, String section, List<Map<String, dynamic>> list, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Single-line items: label + frequency chips, no drag, no delete, no checkbox
        Column(
          children: [
            for (var index = 0; index < list.length; index++)
              Builder(
                builder: (context) {
                  final item = list[index];
                  return Container(
                    key: ValueKey('$section-${item['key']}-$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF0E8EB)), // Light rose border
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(item['label']?.toString() ?? item['key'].toString())),
                        SizedBox(
                          height: 36,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final f in _freqOptions) ...[
                                  ChoiceChip(
                                    label: Text(_freqLabel(f)),
                                    selected: item['freq'] == f,
                                    selectedColor: const Color(0xFFD0A3AF), // Dusty rose
                                    onSelected: (_) {
                                      setState(() => item['freq'] = f);
                                      _emit();
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      list.removeAt(index);
                                    });
                                    _emit();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: section == 'am' ? 'Add morning step' : 'Add evening step',
                ),
                onSubmitted: (_) => _addTo(section),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _addTo(section), child: const Text('Add')),
          ],
        ),
      ],
    );
  }

  String _freqLabel(String value) {
    switch (value) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'as-needed': return 'As needed';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildSection('Morning', 'am', _am, _amCtrl),
            const SizedBox(height: 16),
            _buildSection('Evening', 'pm', _pm, _pmCtrl),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _skip,
              onChanged: (v) {
                setState(() => _skip = v == true);
                _emit();
              },
              title: const Text("I don't have a routine yet"),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
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
        return _ConcernsStep(
          title: 'Sensitivities (ingredients, etc.)',
          options: OnboardingValidators.allowedSensitivities.toList(),
          values: (_state.getStepPayload(step)['items'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a sensitivity or trigger',
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'items': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.dietFlags:
        return _ConcernsStep(
          title: 'Diet flags',
          options: OnboardingValidators.allowedDietFlags.toList(),
          values: (_state.getStepPayload(step)['flags'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a diet flag',
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
        return _ConcernsStep(
          title: 'Lifestyle factors',
          options: OnboardingValidators.allowedLifestyle.toList(),
          values: (_state.getStepPayload(step)['factors'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a lifestyle factor',
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'factors': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.medications:
        return _ConcernsStep(
          title: 'Medications',
          options: OnboardingValidators.allowedMedications.toList(),
          values: (_state.getStepPayload(step)['medications'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a medication',
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'medications': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.consentInfo:
        final payload = _state.getStepPayload(step);
        final checked = payload['acknowledged'] == true;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consent and Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('We use your data to personalize insights. You can delete your data at any time.'),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: checked,
                onChanged: (v) async {
                  setState(() => _state.setStepPayload(step, {'acknowledged': v == true}));
                  await _persistStep(step);
                },
                title: const Text('I acknowledge'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        );
      
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

class _ConcernsStep extends StatefulWidget {
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
  State<_ConcernsStep> createState() => _ConcernsStepState();
}

class _ConcernsStepState extends State<_ConcernsStep> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleOption(String opt, bool selected) {
    final next = List<String>.from(widget.values);
    bool eq(String a, String b) => a.toLowerCase() == b.toLowerCase();
    if (selected) {
      if (!next.any((e) => eq(e, opt))) next.add(opt);
    } else {
      next.removeWhere((e) => eq(e, opt));
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

  @override
  Widget build(BuildContext context) {
    final lowerOptions = widget.options.map((e) => e.toLowerCase()).toSet();
    final customOnly = widget.values.where((v) => !lowerOptions.contains(v.toLowerCase())).toList();

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
                  selected: widget.values.any((e) => e.toLowerCase() == opt.toLowerCase()),
                  onSelected: (sel) => _toggleOption(opt, sel),
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
          if (customOnly.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in customOnly)
                  Chip(
                    label: Text(item),
                    onDeleted: () {
                      final next = List<String>.from(widget.values)
                        ..removeWhere((e) => e.toLowerCase() == item.toLowerCase());
                      widget.onChanged(next);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
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
