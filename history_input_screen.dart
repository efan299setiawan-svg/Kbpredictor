import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_entry.dart';
import '../services/history_provider.dart';
import '../utils/constants.dart';

/// Form for recording a new result (or editing an existing one when
/// [existing] is provided).
class HistoryInputScreen extends StatefulWidget {
  final HistoryEntry? existing;
  const HistoryInputScreen({super.key, this.existing});

  @override
  State<HistoryInputScreen> createState() => _HistoryInputScreenState();
}

class _HistoryInputScreenState extends State<HistoryInputScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _deviceController;
  late TextEditingController _browserController;
  late TextEditingController _minuteController;
  late TextEditingController _match1Controller;
  late TextEditingController _match2Controller;
  late TextEditingController _match3Controller;
  late TextEditingController _scoreController;
  String _result = 'B';
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _deviceController = TextEditingController(text: e?.device ?? '');
    _browserController = TextEditingController(text: e?.browser ?? '');
    _minuteController = TextEditingController(text: e != null ? '${e.minute}' : '');
    _match1Controller = TextEditingController(text: e?.match1 ?? '');
    _match2Controller = TextEditingController(text: e?.match2 ?? '');
    _match3Controller = TextEditingController(text: e?.match3 ?? '');
    _scoreController = TextEditingController(text: e?.score ?? '');
    _result = e?.result ?? 'B';
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _browserController.dispose();
    _minuteController.dispose();
    _match1Controller.dispose();
    _match2Controller.dispose();
    _match3Controller.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final entry = HistoryEntry(
      id: widget.existing?.id,
      device: _deviceController.text.trim(),
      browser: _browserController.text.trim(),
      minute: int.parse(_minuteController.text.trim()),
      match1: _match1Controller.text.trim(),
      match2: _match2Controller.text.trim(),
      match3: _match3Controller.text.trim().isEmpty ? null : _match3Controller.text.trim(),
      result: _result,
      score: _scoreController.text.trim(),
      timestamp: widget.existing?.timestamp ?? DateTime.now(),
    );

    final provider = context.read<HistoryProvider>();
    if (_isEditing) {
      await provider.updateEntry(entry);
    } else {
      await provider.addEntry(entry);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Entry updated' : 'Entry saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Result' : 'Add Result')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _deviceController,
              decoration: const InputDecoration(labelText: 'Device', hintText: 'e.g. IP13, Samsung, POCO'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Device is required' : null,
            ),
            const SizedBox(height: 8),
            _QuickPickChips(
              options: AppConstants.exampleDevices,
              onPicked: (v) => setState(() => _deviceController.text = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _browserController,
              decoration: const InputDecoration(labelText: 'Browser', hintText: 'e.g. Chrome, Safari, Google'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Browser is required' : null,
            ),
            const SizedBox(height: 8),
            _QuickPickChips(
              options: AppConstants.exampleBrowsers,
              onPicked: (v) => setState(() => _browserController.text = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _minuteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minute (0-59)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0 || n > 59) return 'Enter a minute between 0 and 59';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _match1Controller,
              decoration: const InputDecoration(labelText: 'Match 1'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Match 1 is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _match2Controller,
              decoration: const InputDecoration(labelText: 'Match 2'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Match 2 is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _match3Controller,
              decoration: const InputDecoration(labelText: 'Match 3 (optional)'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: AppConstants.scorePresets.contains(_scoreController.text)
                  ? _scoreController.text
                  : null,
              decoration: const InputDecoration(labelText: 'Score'),
              items: AppConstants.scorePresets
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _scoreController.text = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Score is required' : null,
            ),
            const SizedBox(height: 18),
            Text('Result', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'B', label: Text('B (Win)'), icon: Icon(Icons.check_circle_outline)),
                ButtonSegment(value: 'K', label: Text('K (Loss)'), icon: Icon(Icons.cancel_outlined)),
              ],
              selected: {_result},
              onSelectionChanged: (s) => setState(() => _result = s.first),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of tappable suggestion chips used to quickly fill in
/// the Device / Browser fields without typing.
class _QuickPickChips extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onPicked;

  const _QuickPickChips({required this.options, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final option = options[i];
          return ActionChip(
            label: Text(option, style: const TextStyle(fontSize: 12)),
            onPressed: () => onPicked(option),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
