import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rule_models.dart';
import '../services/rules_provider.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

/// Fully editable local rule engine configuration page. Users can add,
/// edit, delete, reset, import and export every rule type used by the
/// [PredictionEngine]: Time Rules, Browser Rules, Device Rules and
/// Streak Rules.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prediction Rules'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Time'),
              Tab(text: 'Browser'),
              Tab(text: 'Device'),
              Tab(text: 'Streak'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) async {
                final provider = context.read<RulesProvider>();
                if (v == 'export') {
                  await provider.exportRules();
                } else if (v == 'import') {
                  final ok = await provider.importRules();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Rules imported' : 'Import cancelled or failed')),
                    );
                  }
                } else if (v == 'reset') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Reset rules?'),
                      content: const Text('This replaces all rules with the built-in defaults.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (confirmed == true) await provider.resetToDefaults();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'export', child: Text('Export rules (JSON)')),
                PopupMenuItem(value: 'import', child: Text('Import rules (JSON)')),
                PopupMenuItem(value: 'reset', child: Text('Reset to defaults')),
              ],
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _TimeRulesTab(),
            _BrowserRulesTab(),
            _DeviceRulesTab(),
            _StreakRulesTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Time Rules
// ---------------------------------------------------------------------

class _TimeRulesTab extends StatelessWidget {
  const _TimeRulesTab();

  Future<void> _editRule(BuildContext context, {TimeRule? rule}) async {
    final startController = TextEditingController(text: rule?.startMinute.toString() ?? '');
    final endController = TextEditingController(text: rule?.endMinute.toString() ?? '');
    String result = rule?.result ?? 'K';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? 'Add Time Rule' : 'Edit Time Rule'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: startController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Start minute (0-59)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0 || n > 59) ? 'Invalid' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'End minute (0-59)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0 || n > 59) ? 'Invalid' : null;
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'K', label: Text('K')),
                  ],
                  selected: {result},
                  onSelectionChanged: (s) => setState(() => result = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final newRule = TimeRule(
        id: rule?.id,
        browser: null,
        startMinute: int.parse(startController.text),
        endMinute: int.parse(endController.text),
        result: result,
      );
      await context.read<RulesProvider>().saveTimeRule(newRule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RulesProvider>();
    final rules = provider.genericTimeRules;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editRule(context),
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? const EmptyState(icon: Icons.schedule, title: 'No time rules', message: 'Add a rule to get started.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rules[i];
                return _RuleTile(
                  title: 'Minute ${r.startMinute}\u2013${r.endMinute}',
                  subtitle: 'Predicts ${r.result}',
                  result: r.result,
                  onEdit: () => _editRule(context, rule: r),
                  onDelete: () => provider.deleteTimeRule(r.id!),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Browser Rules
// ---------------------------------------------------------------------

class _BrowserRulesTab extends StatelessWidget {
  const _BrowserRulesTab();

  Future<void> _editRule(BuildContext context, {TimeRule? rule}) async {
    final browserController = TextEditingController(text: rule?.browser ?? '');
    final startController = TextEditingController(text: rule?.startMinute.toString() ?? '');
    final endController = TextEditingController(text: rule?.endMinute.toString() ?? '');
    String result = rule?.result ?? 'K';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? 'Add Browser Rule' : 'Edit Browser Rule'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: AppConstants.exampleBrowsers.contains(browserController.text)
                      ? browserController.text
                      : null,
                  decoration: const InputDecoration(labelText: 'Browser'),
                  items: AppConstants.exampleBrowsers
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => browserController.text = v ?? '',
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: startController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Start minute (0-59)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0 || n > 59) ? 'Invalid' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'End minute (0-59)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0 || n > 59) ? 'Invalid' : null;
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'K', label: Text('K')),
                  ],
                  selected: {result},
                  onSelectionChanged: (s) => setState(() => result = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final newRule = TimeRule(
        id: rule?.id,
        browser: browserController.text,
        startMinute: int.parse(startController.text),
        endMinute: int.parse(endController.text),
        result: result,
      );
      await context.read<RulesProvider>().saveTimeRule(newRule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RulesProvider>();
    final rules = provider.browserRules;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editRule(context),
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? const EmptyState(icon: Icons.public, title: 'No browser rules', message: 'Add a rule to get started.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rules[i];
                return _RuleTile(
                  title: '${r.browser} \u2022 Minute ${r.startMinute}\u2013${r.endMinute}',
                  subtitle: 'Predicts ${r.result}',
                  result: r.result,
                  onEdit: () => _editRule(context, rule: r),
                  onDelete: () => provider.deleteTimeRule(r.id!),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Device Rules
// ---------------------------------------------------------------------

class _DeviceRulesTab extends StatelessWidget {
  const _DeviceRulesTab();

  Future<void> _editRule(BuildContext context, {DeviceRule? rule}) async {
    final deviceController = TextEditingController(text: rule?.device ?? '');
    String result = rule?.result ?? 'K';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? 'Add Device Rule' : 'Edit Device Rule'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: deviceController,
                  decoration: const InputDecoration(labelText: 'Device name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'K', label: Text('K')),
                  ],
                  selected: {result},
                  onSelectionChanged: (s) => setState(() => result = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final newRule = DeviceRule(id: rule?.id, device: deviceController.text.trim(), result: result);
      await context.read<RulesProvider>().saveDeviceRule(newRule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RulesProvider>();
    final rules = provider.deviceRules;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editRule(context),
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? const EmptyState(icon: Icons.smartphone, title: 'No device rules', message: 'Add a rule to get started.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rules[i];
                return _RuleTile(
                  title: r.device,
                  subtitle: 'Predicts ${r.result}',
                  result: r.result,
                  onEdit: () => _editRule(context, rule: r),
                  onDelete: () => provider.deleteDeviceRule(r.id!),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Streak Rules
// ---------------------------------------------------------------------

class _StreakRulesTab extends StatelessWidget {
  const _StreakRulesTab();

  Future<void> _editRule(BuildContext context, {StreakRule? rule}) async {
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    String result = rule?.result ?? 'K';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? 'Add Streak Rule' : 'Edit Streak Rule'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: patternController,
                  decoration: const InputDecoration(labelText: 'Pattern (e.g. KKB)', hintText: 'Only B/K characters'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final pattern = v.trim().toUpperCase();
                    if (!RegExp(r'^[BK]+$').hasMatch(pattern)) return 'Only B/K characters allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'K', label: Text('K')),
                  ],
                  selected: {result},
                  onSelectionChanged: (s) => setState(() => result = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final newRule = StreakRule(
        id: rule?.id,
        pattern: patternController.text.trim().toUpperCase(),
        result: result,
      );
      await context.read<RulesProvider>().saveStreakRule(newRule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RulesProvider>();
    final rules = provider.streakRules;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editRule(context),
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? const EmptyState(icon: Icons.timeline, title: 'No streak rules', message: 'Add a rule to get started.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rules[i];
                return _RuleTile(
                  title: r.pattern,
                  subtitle: 'Predicts ${r.result}',
                  result: r.result,
                  onEdit: () => _editRule(context, rule: r),
                  onDelete: () => provider.deleteStreakRule(r.id!),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared rule tile widget
// ---------------------------------------------------------------------

class _RuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String result;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleTile({
    required this.title,
    required this.subtitle,
    required this.result,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = result == 'B' ? Colors.teal.shade600 : Colors.redAccent.shade200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(result, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
