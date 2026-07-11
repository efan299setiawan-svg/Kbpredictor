import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local settings store (SharedPreferences-backed, fully
/// on-device). Powers the "Local settings page" feature.
class SettingsProvider extends ChangeNotifier {
  static const _kDefaultDevice = 'default_device';
  static const _kDefaultBrowser = 'default_browser';
  static const _kConfirmDelete = 'confirm_delete';
  static const _kShowConfidence = 'show_confidence';

  String defaultDevice = '';
  String defaultBrowser = '';
  bool confirmBeforeDelete = true;
  bool showConfidenceOnDashboard = true;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      defaultDevice = prefs.getString(_kDefaultDevice) ?? '';
      defaultBrowser = prefs.getString(_kDefaultBrowser) ?? '';
      confirmBeforeDelete = prefs.getBool(_kConfirmDelete) ?? true;
      showConfidenceOnDashboard = prefs.getBool(_kShowConfidence) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setDefaultDevice(String value) async {
    defaultDevice = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultDevice, value);
  }

  Future<void> setDefaultBrowser(String value) async {
    defaultBrowser = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultBrowser, value);
  }

  Future<void> setConfirmBeforeDelete(bool value) async {
    confirmBeforeDelete = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConfirmDelete, value);
  }

  Future<void> setShowConfidenceOnDashboard(bool value) async {
    showConfidenceOnDashboard = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowConfidence, value);
  }
}
