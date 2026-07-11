import 'package:flutter/material.dart';

/// Small colored badge showing a B (win) or K (loss) result. This is a
/// pure UI/labeling convention - it has no effect on the prediction
/// logic itself.
class ResultBadge extends StatelessWidget {
  final String result; // 'B' or 'K'
  final double size;

  const ResultBadge({super.key, required this.result, this.size = 36});

  bool get _isWin => result == 'B';

  @override
  Widget build(BuildContext context) {
    final color = _isWin ? Colors.teal.shade600 : Colors.redAccent.shade200;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        result,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
