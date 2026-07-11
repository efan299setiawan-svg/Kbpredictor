/// All rule models used by the local, fully-editable rule engine.
///
/// Nothing here ever calls the network - every rule is stored in SQLite
/// and can be edited, added, removed, imported or exported by the user.

/// A rule that maps a minute range (start-end inclusive) to a prediction.
/// Used both for the generic "Time Rules" and, with [browser] set,
/// for the per-browser rules (Google/Safari/etc).
class TimeRule {
  final int? id;
  final String? browser; // null => generic time rule, otherwise browser-specific
  final int startMinute;
  final int endMinute;
  final String result; // 'B' or 'K'

  TimeRule({
    this.id,
    this.browser,
    required this.startMinute,
    required this.endMinute,
    required this.result,
  });

  bool matches(int minute) => minute >= startMinute && minute <= endMinute;

  Map<String, dynamic> toMap() => {
        'id': id,
        'browser': browser,
        'startMinute': startMinute,
        'endMinute': endMinute,
        'result': result,
      };

  factory TimeRule.fromMap(Map<String, dynamic> map) => TimeRule(
        id: map['id'] as int?,
        browser: map['browser'] as String?,
        startMinute: map['startMinute'] as int,
        endMinute: map['endMinute'] as int,
        result: map['result'] as String,
      );

  TimeRule copyWith({
    int? id,
    String? browser,
    int? startMinute,
    int? endMinute,
    String? result,
  }) =>
      TimeRule(
        id: id ?? this.id,
        browser: browser ?? this.browser,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
        result: result ?? this.result,
      );
}

/// A rule that maps a device name directly to a fixed prediction
/// (the "Fresh Device Rules" table).
class DeviceRule {
  final int? id;
  final String device;
  final String result; // 'B' or 'K'

  DeviceRule({this.id, required this.device, required this.result});

  Map<String, dynamic> toMap() => {
        'id': id,
        'device': device,
        'result': result,
      };

  factory DeviceRule.fromMap(Map<String, dynamic> map) => DeviceRule(
        id: map['id'] as int?,
        device: map['device'] as String,
        result: map['result'] as String,
      );

  DeviceRule copyWith({int? id, String? device, String? result}) => DeviceRule(
        id: id ?? this.id,
        device: device ?? this.device,
        result: result ?? this.result,
      );
}

/// A rule that maps a streak pattern (sequence of B/K, most recent last)
/// to a predicted next outcome. e.g. "KK" -> "B".
class StreakRule {
  final int? id;
  final String pattern; // e.g. "KK", "BKB"
  final String result; // 'B' or 'K'

  StreakRule({this.id, required this.pattern, required this.result});

  Map<String, dynamic> toMap() => {
        'id': id,
        'pattern': pattern,
        'result': result,
      };

  factory StreakRule.fromMap(Map<String, dynamic> map) => StreakRule(
        id: map['id'] as int?,
        pattern: map['pattern'] as String,
        result: map['result'] as String,
      );

  StreakRule copyWith({int? id, String? pattern, String? result}) => StreakRule(
        id: id ?? this.id,
        pattern: pattern ?? this.pattern,
        result: result ?? this.result,
      );
}
