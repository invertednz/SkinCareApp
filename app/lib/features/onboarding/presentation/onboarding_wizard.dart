import 'package:flutter/material.dart';
import '../state/onboarding_state.dart';
import '../../profile/profile_service.dart';
import '../data/onboarding_repository.dart';
import '../data/local_draft_store.dart';
import '../../../services/analytics.dart';
import '../../../theme/brand.dart';
import '../../../widgets/brand_scaffold.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
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
  static const List<String> _freqOptions = ['daily', '2-3x', 'weekly', 'as-needed'];

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
        if (widget.isActive)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
              });
              _emit();
            },
            itemBuilder: (context, index) {
              final item = list[index];
              return Container(
                key: ValueKey('$section-${item['key']}-$index'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8, top: 4),
                        child: Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: item['checked'] == true,
                                onChanged: (v) {
                                  setState(() => item['checked'] = v == true);
                                  _emit();
                                },
                              ),
                              Expanded(child: Text(item['label']?.toString() ?? item['key'].toString())),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final f in _freqOptions)
                                ChoiceChip(
                                  label: Text(_freqLabel(f)),
                                  selected: item['freq'] == f,
                                  onSelected: (_) {
                                    setState(() => item['freq'] = f);
                                    _emit();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete',
                      onPressed: () {
                        setState(() {
                          list.removeAt(index);
                        });
                        _emit();
                      },
                    ),
                  ],
                ),
              );
            },
          )
        else
          Column(
            children: [
              for (var index = 0; index < list.length; index++)
                Builder(
                  builder: (context) {
                    final item = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 8, top: 4),
                            child: Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: item['checked'] == true,
                                      onChanged: (v) {
                                        setState(() => item['checked'] = v == true);
                                        _emit();
                                      },
                                    ),
                                    Expanded(child: Text(item['label']?.toString() ?? item['key'].toString())),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final f in _freqOptions)
                                      ChoiceChip(
                                        label: Text(_freqLabel(f)),
                                        selected: item['freq'] == f,
                                        onSelected: (_) {
                                          setState(() => item['freq'] = f);
                                          _emit();
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            tooltip: 'Delete',
                            onPressed: () {
                              setState(() {
                                list.removeAt(index);
                              });
                              _emit();
                            },
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
      case '2-3x': return '2–3x/wk';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header with close
            GradientHeader(
              title: 'Onboarding',
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                tooltip: 'Save & exit',
              ),
            ),
            // Card body
            Expanded(
              child: OverlapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
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
                    const SizedBox(height: 8),
                    Text('Step ${_index + 1} of ${steps.length}', style: Theme.of(context).textTheme.bodySmall),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: steps.length,
                        itemBuilder: (context, i) => _buildStep(context, steps[i], i == _index),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving || _index == 0 ? null : _back,
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving || !_currentValid
                                ? null
                                : (_isLast ? _submit : _next),
                            child: _saving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isLast ? 'Submit' : 'Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingStepKey step, bool isActive) {
    switch (step) {
      case OnboardingStepKey.skinConcerns:
        return _ConcernsStep(
          title: 'Skin concerns',
          options: OnboardingValidators.allowedConcerns.toList(),
          values: (_state.getStepPayload(step)['concerns'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add another concern',
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'concerns': values}));
            await _persistStep(step);
          },
        );
      case OnboardingStepKey.skinType:
        final options = OnboardingValidators.allowedSkinTypes.toList();
        final current = _state.getStepPayload(step)['type'] as String?;
        return _DropdownStep(
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
        return _ConcernsStep(
          title: 'Supplements',
          options: OnboardingValidators.allowedSupplements.toList(),
          values: (_state.getStepPayload(step)['items'] as List?)?.cast<String>() ?? const [],
          hintText: 'Add a supplement',
          onChanged: (values) async {
            setState(() => _state.setStepPayload(step, {'items': values}));
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
