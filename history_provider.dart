import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../predictor/predictor.dart';
import 'history_repository.dart';

/// Central ChangeNotifier for all history-related state. Screens listen
/// to this instead of talking to the repository/database directly.
class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repo;
  HistoryProvider({HistoryRepository? repo}) : _repo = repo ?? HistoryRepository();

  List<HistoryEntry> _all = [];
  bool _loading = false;

  // Filter / search / sort state (used by the History Viewer screen).
  String? filterDevice;
  String? filterBrowser;
  String? filterResult;
  DateTime? filterFrom;
  DateTime? filterTo;
  String searchText = '';
  HistorySortField sortField = HistorySortField.date;
  bool sortAscending = false;

  List<HistoryEntry> get all => _all;
  bool get loading => _loading;

  HistoryStats get overallStats => HistoryStats.fromEntries(_all);

  List<HistoryEntry> get recent => _all.take(10).toList();

  List<HistoryEntry> get filteredAndSorted {
    final filtered = _repo.applyFilters(
      _all,
      device: filterDevice,
      browser: filterBrowser,
      result: filterResult,
      from: filterFrom,
      to: filterTo,
      searchText: searchText,
    );
    return _repo.applySort(filtered, sortField, sortAscending);
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> addEntry(HistoryEntry entry) async {
    await _repo.add(entry);
    await load();
  }

  Future<void> updateEntry(HistoryEntry entry) async {
    await _repo.update(entry);
    await load();
  }

  Future<void> deleteEntry(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    await load();
  }

  Future<List<String>> distinctDevices() => _repo.distinctDevices();
  Future<List<String>> distinctBrowsers() => _repo.distinctBrowsers();

  List<HistoryEntry> entriesForDevice(String device) =>
      _all.where((e) => e.device == device).toList();

  List<HistoryEntry> entriesForBrowser(String browser) =>
      _all.where((e) => e.browser == browser).toList();

  HistoryStats statsForDevice(String device) =>
      HistoryStats.fromEntries(entriesForDevice(device));

  HistoryStats statsForBrowser(String browser) =>
      HistoryStats.fromEntries(entriesForBrowser(browser));

  void updateFilters({
    String? device,
    String? browser,
    String? result,
    DateTime? from,
    DateTime? to,
  }) {
    filterDevice = device;
    filterBrowser = browser;
    filterResult = result;
    filterFrom = from;
    filterTo = to;
    notifyListeners();
  }

  void updateSearch(String text) {
    searchText = text;
    notifyListeners();
  }

  void updateSort(HistorySortField field, bool ascending) {
    sortField = field;
    sortAscending = ascending;
    notifyListeners();
  }

  void clearFilters() {
    filterDevice = null;
    filterBrowser = null;
    filterResult = null;
    filterFrom = null;
    filterTo = null;
    searchText = '';
    notifyListeners();
  }
}
