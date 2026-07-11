import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../database/db_helper.dart';
import '../models/rule_models.dart';

/// Handles all rule persistence + import/export of the rule set as JSON.
/// This is what powers the "Editable Rules Page" and "Import/Export
/// rules" feature. Everything stays local - files are written to the
/// device's app documents directory and shared via the OS share sheet.
class RulesService {
  final DBHelper _db;
  RulesService({DBHelper? db}) : _db = db ?? DBHelper.instance;

  // Generic time rules -----------------------------------------------
  Future<List<TimeRule>> getGenericTimeRules() => _db.getGenericTimeRules();
  Future<List<TimeRule>> getAllTimeRules() => _db.getAllTimeRules();
  Future<List<TimeRule>> getBrowserRules(String browser) => _db.getBrowserTimeRules(browser);
  Future<void> saveTimeRule(TimeRule rule) =>
      rule.id == null ? _db.insertTimeRule(rule) : _db.updateTimeRule(rule);
  Future<void> deleteTimeRule(int id) => _db.deleteTimeRule(id);

  // Device rules --------------------------------------------------------
  Future<List<DeviceRule>> getDeviceRules() => _db.getAllDeviceRules();
  Future<void> saveDeviceRule(DeviceRule rule) =>
      rule.id == null ? _db.insertDeviceRule(rule) : _db.updateDeviceRule(rule);
  Future<void> deleteDeviceRule(int id) => _db.deleteDeviceRule(id);

  // Streak rules ----------------------------------------------------------
  Future<List<StreakRule>> getStreakRules() => _db.getAllStreakRules();
  Future<void> saveStreakRule(StreakRule rule) =>
      rule.id == null ? _db.insertStreakRule(rule) : _db.updateStreakRule(rule);
  Future<void> deleteStreakRule(int id) => _db.deleteStreakRule(id);

  Future<void> resetToDefaults() => _db.resetRulesToDefault();

  /// Serializes every rule table into a single JSON document.
  Future<String> exportRulesJson() async {
    final time = await _db.getAllTimeRules();
    final device = await _db.getAllDeviceRules();
    final streak = await _db.getAllStreakRules();

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'timeRules': time.map((r) => r.toMap()..remove('id')).toList(),
      'deviceRules': device.map((r) => r.toMap()..remove('id')).toList(),
      'streakRules': streak.map((r) => r.toMap()..remove('id')).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Writes the rules JSON to a file and opens the native share sheet.
  Future<void> exportRulesToFile() async {
    final json = await exportRulesJson();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/kb_predictor_rules_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], text: 'KB Predictor AI - Rules Export');
  }

  /// Lets the user pick a JSON rules file and replaces the current rule
  /// tables with its contents.
  Future<bool> importRulesFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    return importRulesJson(content);
  }

  /// Parses a JSON rules document and replaces the current rule tables.
  Future<bool> importRulesJson(String content) async {
    try {
      final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;

      final db = await _db.database;
      await db.delete('time_rules');
      await db.delete('device_rules');
      await db.delete('streak_rules');

      final batch = db.batch();
      for (final r in (data['timeRules'] as List? ?? [])) {
        batch.insert('time_rules', Map<String, dynamic>.from(r as Map)..remove('id'));
      }
      for (final r in (data['deviceRules'] as List? ?? [])) {
        batch.insert('device_rules', Map<String, dynamic>.from(r as Map)..remove('id'));
      }
      for (final r in (data['streakRules'] as List? ?? [])) {
        batch.insert('streak_rules', Map<String, dynamic>.from(r as Map)..remove('id'));
      }
      await batch.commit(noResult: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
