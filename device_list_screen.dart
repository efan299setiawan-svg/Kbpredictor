import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_provider.dart';
import '../utils/constants.dart';
import 'device_detail_screen.dart';

/// Lists every device that has recorded history (plus the example
/// devices from the spec so the user always has something to tap into),
/// each showing a quick win-rate summary.
class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final devicesWithHistory = history.all.map((e) => e.device).toSet();
    final allDevices = {...AppConstants.exampleDevices, ...devicesWithHistory}.toList()..sort();

    // Rank by win rate (devices with data first, most active/highest win rate on top).
    allDevices.sort((a, b) {
      final statsA = history.statsForDevice(a);
      final statsB = history.statsForDevice(b);
      if (statsA.total == 0 && statsB.total == 0) return a.compareTo(b);
      if (statsA.total == 0) return 1;
      if (statsB.total == 0) return -1;
      return statsB.winRate.compareTo(statsA.winRate);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: allDevices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final device = allDevices[i];
          final stats = history.statsForDevice(device);
          final rank = i + 1;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            stats.total == 0
                                ? 'No history yet'
                                : '${stats.wins}W / ${stats.losses}L \u2022 ${stats.total} total',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stats.total == 0 ? '\u2014' : '${stats.winRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: stats.total == 0
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
