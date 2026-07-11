import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_provider.dart';
import '../widgets/empty_state.dart';

/// Statistics screen: overall win-rate pie chart, per-device and
/// per-browser performance bar charts, plus device/browser/win-rate
/// rankings.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (history.all.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: const EmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'No data yet',
          message: 'Add some history to see charts and rankings.',
        ),
      );
    }

    final devices = history.all.map((e) => e.device).toSet().toList();
    final browsers = history.all.map((e) => e.browser).toSet().toList();

    final deviceStats = {for (final d in devices) d: history.statsForDevice(d)};
    final browserStats = {for (final b in browsers) b: history.statsForBrowser(b)};

    final rankedDevices = devices.where((d) => deviceStats[d]!.total > 0).toList()
      ..sort((a, b) => deviceStats[b]!.winRate.compareTo(deviceStats[a]!.winRate));
    final rankedBrowsers = browsers.where((b) => browserStats[b]!.total > 0).toList()
      ..sort((a, b) => browserStats[b]!.winRate.compareTo(browserStats[a]!.winRate));

    final overall = history.overallStats;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Overall Win Rate', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: overall.wins.toDouble(),
                          color: Colors.teal.shade600,
                          title: '${overall.wins}',
                          radius: 26,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: overall.losses.toDouble(),
                          color: Colors.redAccent.shade200,
                          title: '${overall.losses}',
                          radius: 26,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${overall.winRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text('Win rate across all history'),
                      const SizedBox(height: 10),
                      _LegendDot(color: Colors.teal.shade600, label: 'Wins (B): ${overall.wins}'),
                      const SizedBox(height: 4),
                      _LegendDot(color: Colors.redAccent.shade200, label: 'Losses (K): ${overall.losses}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Device Performance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _PerformanceBarChart(labels: rankedDevices, statsMap: deviceStats),
          const SizedBox(height: 24),
          Text('Browser Performance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _PerformanceBarChart(labels: rankedBrowsers, statsMap: browserStats),
          const SizedBox(height: 24),
          Text('Device Ranking', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _RankingList(labels: rankedDevices, statsMap: deviceStats),
          const SizedBox(height: 24),
          Text('Browser Ranking', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _RankingList(labels: rankedBrowsers, statsMap: browserStats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PerformanceBarChart extends StatelessWidget {
  final List<String> labels;
  final Map<String, dynamic> statsMap;
  const _PerformanceBarChart({required this.labels, required this.statsMap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (labels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
        child: const Text('No data yet'),
      );
    }
    final shown = labels.take(8).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
      child: BarChart(
        BarChartData(
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      shown[i].length > 6 ? '${shown[i].substring(0, 6)}\u2026' : shown[i],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < shown.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: statsMap[shown[i]].winRate,
                    color: scheme.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final List<String> labels;
  final Map<String, dynamic> statsMap;
  const _RankingList({required this.labels, required this.statsMap});

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No ranked data yet'),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(labels[i])),
                  Text(
                    '${statsMap[labels[i]].winRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
