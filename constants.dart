import '../models/rule_models.dart';

/// Central place for default/seed data. All of this is only used to
/// populate the database the very first time the app runs - after that,
/// everything lives in SQLite and is fully user-editable.
class AppConstants {
  AppConstants._();

  static const String appName = 'KB Predictor AI';

  /// Results are always one of these two.
  static const List<String> results = ['B', 'K'];

  /// Suggested score presets shown in the input form.
  static const List<String> scorePresets = ['2-0', '2-1'];

  /// Example / suggested device list (user may still type any device).
  static const List<String> exampleDevices = [
    'IP11',
    'IP12',
    'IP13',
    'IP14',
    'IP15',
    'IP16',
    'Redmi',
    'POCO',
    'Realme',
    'Samsung',
    'Tecno',
    'Infinix Note',
    'Infinix Hot',
    'Vivo',
    'ROG',
  ];

  /// Suggested browser list (user may still type any browser).
  static const List<String> exampleBrowsers = [
    'Chrome',
    'Google',
    'Safari',
    'Firefox',
    'Edge',
    'Opera',
    'Samsung Internet',
  ];

  /// Generic time rules (used when browser has no specific rule set).
  static List<TimeRule> defaultTimeRules() => [
        TimeRule(startMinute: 0, endMinute: 15, result: 'K'),
        TimeRule(startMinute: 16, endMinute: 20, result: 'B'),
        TimeRule(startMinute: 21, endMinute: 27, result: 'K'),
        TimeRule(startMinute: 28, endMinute: 35, result: 'K'),
        TimeRule(startMinute: 36, endMinute: 59, result: 'B'),
      ];

  /// Browser-specific time rules (Google / Safari share the same table
  /// per the spec, applied to both browser names).
  static List<TimeRule> defaultBrowserRules() {
    final ranges = <List<int>>[
      [0, 6],
      [7, 16],
      [17, 25],
      [26, 36],
      [37, 45],
      [46, 59],
    ];
    final outcomes = ['K', 'B', 'K', 'B', 'K', 'B'];
    final browsers = ['Google', 'Safari'];

    final rules = <TimeRule>[];
    for (final browser in browsers) {
      for (var i = 0; i < ranges.length; i++) {
        rules.add(TimeRule(
          browser: browser,
          startMinute: ranges[i][0],
          endMinute: ranges[i][1],
          result: outcomes[i],
        ));
      }
    }
    return rules;
  }

  /// Fresh device rules - fixed prediction per device model.
  static List<DeviceRule> defaultDeviceRules() => [
        DeviceRule(device: 'IP11', result: 'B'),
        DeviceRule(device: 'IP12', result: 'K'),
        DeviceRule(device: 'IP13', result: 'K'),
        DeviceRule(device: 'IP14', result: 'K'),
        DeviceRule(device: 'IP15', result: 'K'),
        DeviceRule(device: 'IP16', result: 'B'),
        DeviceRule(device: 'Redmi', result: 'K'),
        DeviceRule(device: 'POCO', result: 'K'),
        DeviceRule(device: 'Realme', result: 'B'),
        DeviceRule(device: 'Samsung', result: 'B'),
        DeviceRule(device: 'Tecno', result: 'B'),
        DeviceRule(device: 'Infinix Note', result: 'B'),
        DeviceRule(device: 'Infinix Hot', result: 'K'),
        DeviceRule(device: 'Vivo', result: 'K'),
      ];

  /// Default streak patterns -> predicted next outcome.
  static List<StreakRule> defaultStreakRules() => [
        StreakRule(pattern: 'KK', result: 'B'),
        StreakRule(pattern: 'BB', result: 'K'),
        StreakRule(pattern: 'KBK', result: 'B'),
        StreakRule(pattern: 'BKB', result: 'K'),
        StreakRule(pattern: 'KKK', result: 'B'),
        StreakRule(pattern: 'BBB', result: 'K'),
      ];
}
