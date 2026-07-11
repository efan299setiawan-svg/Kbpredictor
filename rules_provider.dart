import 'package:flutter/material.dart';

import '../models/rule_models.dart';
import 'rules_service.dart';

/// Central ChangeNotifier for the fully-editable local rule set (Time,
/// Browser, Device and Streak rules). This is what the Rules screen
/// binds to; the PredictionEngine itself always reads straight from
/// the database so edits take effect immediately on the next prediction.
class RulesProvider extends ChangeNotifier {
  final RulesService _service;
  RulesProvider({RulesService? service}) : _service = service ?? RulesService();

  List<TimeRule> genericTimeRules = [];
  List<TimeRule> browserRules = [];
  List<DeviceRule> deviceRules = [];
  List<StreakRule> streakRules = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    genericTimeRules = await _service.getGenericTimeRules();
    final allTime = await _service.getAllTimeRules();
    browserRules = allTime.where((r) => r.browser != null).toList();
    deviceRules = await _service.getDeviceRules();
    streakRules = await _service.getStreakRules();
    loading = false;
    notifyListeners();
  }

  Future<void> saveTimeRule(TimeRule rule) async {
    await _service.saveTimeRule(rule);
    await load();
  }

  Future<void> deleteTimeRule(int id) async {
    await _service.deleteTimeRule(id);
    await load();
  }

  Future<void> saveDeviceRule(DeviceRule rule) async {
    await _service.saveDeviceRule(rule);
    await load();
  }

  Future<void> deleteDeviceRule(int id) async {
    await _service.deleteDeviceRule(id);
    await load();
  }

  Future<void> saveStreakRule(StreakRule rule) async {
    await _service.saveStreakRule(rule);
    await load();
  }

  Future<void> deleteStreakRule(int id) async {
    await _service.deleteStreakRule(id);
    await load();
  }

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    await load();
  }

  Future<void> exportRules() => _service.exportRulesToFile();

  Future<bool> importRules() async {
    final ok = await _service.importRulesFromFile();
    if (ok) await load();
    return ok;
  }
}
