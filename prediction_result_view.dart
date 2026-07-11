import 'package:flutter/material.dart';

import '../predictor/predictor.dart';

/// Renders a full [PredictionResult]: the final B/K call, a confidence
/// percentage, and a checklist explaining exactly which rules were
/// evaluated and which one made the final decision - matching the
/// "Prediction Output" example from the spec.
class PredictionResultView extends StatelessWidget {
  final PredictionResult result;

  const PredictionResultView({super.key, required this.result});

  Color _resultColor(BuildContext context) =>
      result.prediction == 'B' ? Colors.teal.shade600 : Colors.redAccent.shade200;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _resultColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                'PREDICTION',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                result.prediction,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Confidence: ${result.confidence}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Analysis', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...result.analyses.map((a) => _AnalysisRow(analysis: a)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Final Decision: ${result.prediction} (via ${result.decidingRule.label})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final RuleAnalysis analysis;
  const _AnalysisRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = analysis.matched ? Icons.check : Icons.remove;
    final iconColor = analysis.applied
        ? Colors.teal.shade600
        : (analysis.matched ? scheme.onSurfaceVariant : scheme.outline);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${analysis.priority.label}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: analysis.applied ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: analysis.detail + (analysis.applied ? '  (applied)' : ''),
                    style: TextStyle(
                      color: analysis.applied ? scheme.onSurface : scheme.onSurfaceVariant,
                      fontStyle: analysis.matched ? FontStyle.normal : FontStyle.italic,
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
