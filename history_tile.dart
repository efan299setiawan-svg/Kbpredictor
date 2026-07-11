import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import 'result_badge.dart';

/// A single row in any history list (Dashboard "recent history",
/// History Viewer, Device detail, etc).
class HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HistoryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MMM d, yyyy \u2022 HH:mm').format(entry.timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainer,
          ),
          child: Row(
            children: [
              ResultBadge(result: entry.result, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.device} \u2022 ${entry.browser}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Min ${entry.minute} \u2022 Score ${entry.score} \u2022 $dateStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
