/// Represents a single recorded result/history entry.
///
/// Every prediction the app makes is ultimately grounded in a growing
/// dataset of these entries, grouped by [device] and [browser].
class HistoryEntry {
  final int? id;
  final String device;
  final String browser;
  final int minute; // 0-59, minute of the match/round
  final String match1;
  final String match2;
  final String? match3; // optional
  final String result; // 'B' or 'K'
  final String score; // e.g. "2-0" / "2-1"
  final DateTime timestamp;

  HistoryEntry({
    this.id,
    required this.device,
    required this.browser,
    required this.minute,
    required this.match1,
    required this.match2,
    this.match3,
    required this.result,
    required this.score,
    required this.timestamp,
  });

  /// Creates a copy of this entry with optionally overridden fields.
  HistoryEntry copyWith({
    int? id,
    String? device,
    String? browser,
    int? minute,
    String? match1,
    String? match2,
    String? match3,
    String? result,
    String? score,
    DateTime? timestamp,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      device: device ?? this.device,
      browser: browser ?? this.browser,
      minute: minute ?? this.minute,
      match1: match1 ?? this.match1,
      match2: match2 ?? this.match2,
      match3: match3 ?? this.match3,
      result: result ?? this.result,
      score: score ?? this.score,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device': device,
      'browser': browser,
      'minute': minute,
      'match1': match1,
      'match2': match2,
      'match3': match3,
      'result': result,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      device: map['device'] as String,
      browser: map['browser'] as String,
      minute: map['minute'] as int,
      match1: map['match1'] as String,
      match2: map['match2'] as String,
      match3: map['match3'] as String?,
      result: map['result'] as String,
      score: map['score'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// CSV row representation (header must match [csvHeader]).
  List<dynamic> toCsvRow() => [
        id ?? '',
        device,
        browser,
        minute,
        match1,
        match2,
        match3 ?? '',
        result,
        score,
        timestamp.toIso8601String(),
      ];

  static const List<String> csvHeader = [
    'id',
    'device',
    'browser',
    'minute',
    'match1',
    'match2',
    'match3',
    'result',
    'score',
    'timestamp',
  ];
}
