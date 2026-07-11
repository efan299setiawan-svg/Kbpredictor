import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../predictor/predictor.dart';
import '../services/history_provider.dart';
import '../services/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/history_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/prediction_result_view.dart';

/// Per-device detail page: Wins, Losses, Win Rate, History and a
/// "Next Prediction" panel powered by the local rule engine.
class DeviceDetailScreen extends StatefulWidget {
  final String device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  PredictionResult? _prediction;
  bool _loading = false;

  Future<void> _predictNext() async {
    setState(() => _loading = true);
    final settings = context.read<SettingsProvider>();
    final engine = PredictionEngine();
    final result = await engine.predict(PredictionContext(
      device: widget.device,
      browser: settings.defaultBrowser.isNotEmpty
          ? settings.defaultBrowser
          : AppConstants.exampleBrowsers.first,
      minute: DateTime.now().minute,
    ));
    if (!mounted) return;
    setState(() {
      _prediction = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final entries = history.entriesForDevice(widget.device);
    final stats = history.statsForDevice(widget.device);

    return Scaffold(
      appBar: AppBar(title: Text(widget.device)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              StatCard(label: 'Wins', value: '${stats.wins}', icon: Icons.emoji_events_outlined, color: Colors.teal.shade600),
              StatCard(label: 'Losses', value: '${stats.losses}', icon: Icons.trending_down, color: Colors.redAccent.shade200),
              StatCard(label: 'Win Rate', value: '${stats.winRate.toStringAsFixed(0)}%', icon: Icons.percent),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Next Prediction', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                if (_prediction == null)
                  FilledButton.icon(
                    onPressed: _loading ? null : _predictNext,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: const Text('Generate Prediction'),
                  )
                else ...[
                  PredictionResultView(result: _prediction!),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _predictNext,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-run'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('History (${entries.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No history for this device',
              message: 'Recorded results for this device will appear here.',
            )
          else
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HistoryTile(entry: e),
                )),
        ],
      ),
    );
  }
}
