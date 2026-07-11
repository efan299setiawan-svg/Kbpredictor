import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../predictor/predictor.dart';
import '../services/history_provider.dart';
import '../services/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/prediction_result_view.dart';

/// Opens the "Predict" flow: pick device/browser/minute, then run the
/// local [PredictionEngine] and show the full analysis breakdown.
Future<void> showPredictSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PredictSheet(),
  );
}

class _PredictSheet extends StatefulWidget {
  const _PredictSheet();

  @override
  State<_PredictSheet> createState() => _PredictSheetState();
}

class _PredictSheetState extends State<_PredictSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _device;
  late String _browser;
  final _minuteController = TextEditingController(text: '0');
  PredictionResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _device = settings.defaultDevice.isNotEmpty
        ? settings.defaultDevice
        : AppConstants.exampleDevices.first;
    _browser = settings.defaultBrowser.isNotEmpty
        ? settings.defaultBrowser
        : AppConstants.exampleBrowsers.first;
  }

  @override
  void dispose() {
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final engine = PredictionEngine();
    final ctx = PredictionContext(
      device: _device,
      browser: _browser,
      minute: int.parse(_minuteController.text),
    );
    final result = await engine.predict(ctx);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final devices = {...AppConstants.exampleDevices, ...history.all.map((e) => e.device)}.toList()..sort();
    final browsers = {...AppConstants.exampleBrowsers, ...history.all.map((e) => e.browser)}.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Run Prediction', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Uses only your local, editable rules - fully offline.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: devices.contains(_device) ? _device : null,
                      decoration: const InputDecoration(labelText: 'Device'),
                      items: devices
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _device = v ?? _device),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: browsers.contains(_browser) ? _browser : null,
                      decoration: const InputDecoration(labelText: 'Browser'),
                      items: browsers
                          .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) => setState(() => _browser = v ?? _browser),
                    ),
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _runPrediction,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Predict'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                PredictionResultView(result: _result!),
              ],
            ],
          ),
        );
      },
    );
  }
}
