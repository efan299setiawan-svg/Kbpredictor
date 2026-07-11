import '../database/db_helper.dart';
import '../models/history_entry.dart';

/// -----------------------------------------------------------------------
/// KB Predictor AI - Local Rule Engine
/// -----------------------------------------------------------------------
/// This file contains ALL prediction logic for the app. It is 100%
/// offline: it only reads rules and history that already live in the
/// local SQLite database (via [DBHelper]) and never touches the network.
///
/// The engine is intentionally modular: every rule type is implemented
/// as its own small evaluator function returning a [RuleAnalysis]. New
/// rule types can be added by writing a new evaluator and adding it to
/// the [_evaluators] list / [PredictionPriority] enum without touching
/// any other part of the app.
/// -----------------------------------------------------------------------

/// The ordered priority the spec requires:
/// 1. Device Rules
/// 2. Browser Rules
/// 3. Time Rules
/// 4. Device History (LW)
/// 5. Streak Pattern
enum PredictionPriority {
  deviceRule(1, 'Device Rule'),
  browserRule(2, 'Browser Rule'),
  timeRule(3, 'Time Rule'),
  deviceHistory(4, 'LW Pattern'),
  streakPattern(5, 'Streak Pattern');

  final int rank;
  final String label;
  const PredictionPriority(this.rank, this.label);
}

/// Input context needed to run a prediction.
class PredictionContext {
  final String device;
  final String browser;
  final int minute;

  PredictionContext({
    required this.device,
    required this.browser,
    required this.minute,
  });
}

/// The outcome of evaluating a single rule type against the context.
class RuleAnalysis {
  final PredictionPriority priority;
  final bool matched; // did this rule type produce a usable prediction?
  final String? prediction; // 'B' / 'K' / null if not matched
  final String detail; // human readable explanation, e.g. "KKK -> B"
  final bool applied; // was this the rule that decided the final result?

  RuleAnalysis({
    required this.priority,
    required this.matched,
    required this.prediction,
    required this.detail,
    this.applied = false,
  });

  RuleAnalysis copyWithApplied(bool value) => RuleAnalysis(
        priority: priority,
        matched: matched,
        prediction: prediction,
        detail: detail,
        applied: value,
      );
}

/// Full result of a prediction run - everything the UI needs to render
/// the "Prediction Output" screen from the spec.
class PredictionResult {
  final String prediction; // final 'B' or 'K'
  final int confidence; // 0-100
  final List<RuleAnalysis> analyses;
  final PredictionPriority decidingRule;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.analyses,
    required this.decidingRule,
  });
}

/// Relative weight each rule type contributes to the confidence score.
/// Higher-priority rules carry more weight. Sums to 100.
const Map<PredictionPriority, int> _weights = {
  PredictionPriority.deviceRule: 32,
  PredictionPriority.browserRule: 24,
  PredictionPriority.timeRule: 20,
  PredictionPriority.deviceHistory: 14,
  PredictionPriority.streakPattern: 10,
};

class PredictionEngine {
  final DBHelper _db;

  PredictionEngine({DBHelper? db}) : _db = db ?? DBHelper.instance;

  /// Runs the full modular pipeline and returns a [PredictionResult].
  Future<PredictionResult> predict(PredictionContext context) async {
    final analyses = <RuleAnalysis>[
      await _evaluateDeviceRule(context),
      await _evaluateBrowserRule(context),
      await _evaluateTimeRule(context),
      await _evaluateDeviceHistory(context),
      await _evaluateStreakPattern(context),
    ];

    // Priority cascade: pick the first (lowest rank number) matched rule.
    final sorted = [...analyses]..sort((a, b) => a.priority.rank.compareTo(b.priority.rank));
    RuleAnalysis? decision;
    for (final a in sorted) {
      if (a.matched && a.prediction != null) {
        decision = a;
        break;
      }
    }

    // Absolute fallback if literally nothing matched (e.g. brand new
    // device/browser with zero history and no matching rule row at all).
    decision ??= RuleAnalysis(
      priority: PredictionPriority.streakPattern,
      matched: true,
      prediction: 'K',
      detail: 'No rule matched - default fallback',
    );

    final finalAnalyses = analyses
        .map((a) => a.copyWithApplied(a.priority == decision!.priority && a.matched))
        .toList();

    final confidence = _computeConfidence(analyses, decision.prediction!);

    return PredictionResult(
      prediction: decision.prediction!,
      confidence: confidence,
      analyses: finalAnalyses,
      decidingRule: decision.priority,
    );
  }

  // -----------------------------------------------------------------
  // Rule evaluators - each is self-contained and independently testable
  // -----------------------------------------------------------------

  /// Priority 1: Fresh Device Rules table.
  Future<RuleAnalysis> _evaluateDeviceRule(PredictionContext ctx) async {
    final rule = await _db.getDeviceRule(ctx.device);
    if (rule == null) {
      return RuleAnalysis(
        priority: PredictionPriority.deviceRule,
        matched: false,
        prediction: null,
        detail: 'No device rule for "${ctx.device}"',
      );
    }
    return RuleAnalysis(
      priority: PredictionPriority.deviceRule,
      matched: true,
      prediction: rule.result,
      detail: 'Device Rule = ${rule.result}',
    );
  }

  /// Priority 2: Browser-specific time-window rules (Google/Safari/etc).
  Future<RuleAnalysis> _evaluateBrowserRule(PredictionContext ctx) async {
    final rules = await _db.getBrowserTimeRules(ctx.browser);
    for (final r in rules) {
      if (r.matches(ctx.minute)) {
        return RuleAnalysis(
          priority: PredictionPriority.browserRule,
          matched: true,
          prediction: r.result,
          detail: 'Browser Rule (${ctx.browser} ${r.startMinute}-${r.endMinute}) = ${r.result}',
        );
      }
    }
    return RuleAnalysis(
      priority: PredictionPriority.browserRule,
      matched: false,
      prediction: null,
      detail: 'No browser rule for "${ctx.browser}" at minute ${ctx.minute}',
    );
  }

  /// Priority 3: Generic time-window rules.
  Future<RuleAnalysis> _evaluateTimeRule(PredictionContext ctx) async {
    final rules = await _db.getGenericTimeRules();
    for (final r in rules) {
      if (r.matches(ctx.minute)) {
        return RuleAnalysis(
          priority: PredictionPriority.timeRule,
          matched: true,
          prediction: r.result,
          detail: 'Time Rule (${r.startMinute}-${r.endMinute}) = ${r.result}',
        );
      }
    }
    return RuleAnalysis(
      priority: PredictionPriority.timeRule,
      matched: false,
      prediction: null,
      detail: 'No time rule matches minute ${ctx.minute}',
    );
  }

  /// Priority 4: Device history bias - the most frequent recent result
  /// ("LW" = Last-Weighted result) for this specific device.
  Future<RuleAnalysis> _evaluateDeviceHistory(PredictionContext ctx) async {
    final history = await _db.getHistoryByDevice(ctx.device);
    if (history.length < 3) {
      return RuleAnalysis(
        priority: PredictionPriority.deviceHistory,
        matched: false,
        prediction: null,
        detail: 'Not enough history for "${ctx.device}" (${history.length} entries)',
      );
    }
    final recent = history.take(5).toList();
    final kCount = recent.where((h) => h.result == 'K').length;
    final bCount = recent.where((h) => h.result == 'B').length;
    final lwString = recent.map((h) => h.result).join();
    if (kCount == bCount) {
      return RuleAnalysis(
        priority: PredictionPriority.deviceHistory,
        matched: false,
        prediction: null,
        detail: 'LW Pattern = $lwString (tied, inconclusive)',
      );
    }
    final prediction = kCount > bCount ? 'K' : 'B';
    return RuleAnalysis(
      priority: PredictionPriority.deviceHistory,
      matched: true,
      prediction: prediction,
      detail: 'LW Pattern = $lwString',
    );
  }

  /// Priority 5: Streak pattern detection (KK -> B, BB -> K, etc).
  /// Falls back to the device rule's prediction (if any) when no
  /// pattern matches, per the spec.
  Future<RuleAnalysis> _evaluateStreakPattern(PredictionContext ctx) async {
    final history = await _db.getHistoryByDevice(ctx.device);
    if (history.isEmpty) {
      return RuleAnalysis(
        priority: PredictionPriority.streakPattern,
        matched: false,
        prediction: null,
        detail: 'No history to detect a streak',
      );
    }

    // History is newest-first; reverse to build oldest -> newest sequence.
    final chronological = history.reversed.map((h) => h.result).join();
    final streakRules = await _db.getAllStreakRules();
    // Try longest patterns first (already sorted by length DESC from DB).
    for (final rule in streakRules) {
      if (chronological.length >= rule.pattern.length &&
          chronological.endsWith(rule.pattern)) {
        return RuleAnalysis(
          priority: PredictionPriority.streakPattern,
          matched: true,
          prediction: rule.result,
          detail: '${rule.pattern} \u2192 ${rule.result}',
        );
      }
    }

    // No streak pattern matched -> fall back to the device rule.
    final deviceRule = await _db.getDeviceRule(ctx.device);
    if (deviceRule != null) {
      return RuleAnalysis(
        priority: PredictionPriority.streakPattern,
        matched: true,
        prediction: deviceRule.result,
        detail: 'No streak match \u2192 fallback to Device Rule (${deviceRule.result})',
      );
    }

    return RuleAnalysis(
      priority: PredictionPriority.streakPattern,
      matched: false,
      prediction: null,
      detail: 'No streak pattern matched and no device rule to fall back to',
    );
  }

  /// Confidence = weighted proportion of *applicable* rules that agree
  /// with the final decision, clamped to a believable 40-97% range.
  int _computeConfidence(List<RuleAnalysis> analyses, String finalPrediction) {
    final applicable = analyses.where((a) => a.matched).toList();
    if (applicable.isEmpty) return 40;

    final totalWeight = applicable.fold<int>(0, (sum, a) => sum + (_weights[a.priority] ?? 0));
    final agreeingWeight = applicable
        .where((a) => a.prediction == finalPrediction)
        .fold<int>(0, (sum, a) => sum + (_weights[a.priority] ?? 0));

    if (totalWeight == 0) return 40;
    final raw = (agreeingWeight / totalWeight) * 100;
    final scaled = 40 + (raw * 0.57); // map 0-100 raw into ~40-97 range
    return scaled.clamp(40, 97).round();
  }
}

/// Simple aggregated stats used across Dashboard / Device / Statistics
/// screens. Kept here since it is directly derived from history data
/// that the predictor also consumes.
class HistoryStats {
  final int wins; // count of 'B'
  final int losses; // count of 'K'

  HistoryStats({required this.wins, required this.losses});

  int get total => wins + losses;

  double get winRate => total == 0 ? 0 : (wins / total) * 100;

  factory HistoryStats.fromEntries(List<HistoryEntry> entries) {
    final wins = entries.where((e) => e.result == 'B').length;
    final losses = entries.where((e) => e.result == 'K').length;
    return HistoryStats(wins: wins, losses: losses);
  }
}
