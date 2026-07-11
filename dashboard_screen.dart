import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/history_tile.dart';
import '../widgets/empty_state.dart';
import 'predict_sheet.dart';
import 'history_input_screen.dart';

/// Home dashboard: totals, win rate, recent history, and the primary
/// "Predict" action.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final stats = history.overallStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KB Predictor AI'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryInputScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Result'),
      ),
      body: RefreshIndicator(
        onRefresh: history.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  label: 'Total Wins (B)',
                  value: '${stats.wins}',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.teal.shade600,
                ),
                StatCard(
                  label: 'Total Losses (K)',
                  value: '${stats.losses}',
                  icon: Icons.trending_down,
                  color: Colors.redAccent.shade200,
                ),
                StatCard(
                  label: 'Win Rate',
                  value: '${stats.winRate.toStringAsFixed(1)}%',
                  icon: Icons.percent,
                ),
                StatCard(
                  label: 'Total Records',
                  value: '${stats.total}',
                  icon: Icons.storage_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PredictCard(onTap: () => showPredictSheet(context)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent History', style: Theme.of(context).textTheme.titleMedium),
                Text('${history.all.length} total',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            if (history.recent.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No history yet',
                message: 'Tap "Add Result" to record your first match.',
              )
            else
              ...history.recent.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HistoryTile(entry: e),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _PredictCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PredictCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Predict Next Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Runs your local rule engine \u2014 100% offline',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
