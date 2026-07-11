import '../database/db_helper.dart';
import '../models/history_entry.dart';
import '../predictor/predictor.dart';

/// Repository abstraction over history data. Screens/providers never
/// touch [DBHelper] directly for history - they go through here, which
/// keeps persistence details isolated (Repository Pattern) and makes it
/// trivial to swap the storage layer later without touching UI code.
abstract class IHistoryRepository {
  Future<List<HistoryEntry>> getAll();
  Future<List<HistoryEntry>> getByDevice(String device);
  Future<List<HistoryEntry>> getByBrowser(String browser);
  Future<int> add(HistoryEntry entry);
  Future<void> update(HistoryEntry entry);
  Future<void> delete(int id);
  Future<List<String>> distinctDevices();
  Future<List<String>> distinctBrowsers();
  Future<void> clearAll();
  Future<HistoryStats> statsFor(List<HistoryEntry> entries);
}

class HistoryRepository implements IHistoryRepository {
  final DBHelper _db;
  HistoryRepository({DBHelper? db}) : _db = db ?? DBHelper.instance;

  @override
  Future<List<HistoryEntry>> getAll() => _db.getAllHistory();

  @override
  Future<List<HistoryEntry>> getByDevice(String device) => _db.getHistoryByDevice(device);

  @override
  Future<List<HistoryEntry>> getByBrowser(String browser) => _db.getHistoryByBrowser(browser);

  @override
  Future<int> add(HistoryEntry entry) => _db.insertHistory(entry);

  @override
  Future<void> update(HistoryEntry entry) => _db.updateHistory(entry);

  @override
  Future<void> delete(int id) => _db.deleteHistory(id);

  @override
  Future<List<String>> distinctDevices() => _db.getDistinctDevices();

  @override
  Future<List<String>> distinctBrowsers() => _db.getDistinctBrowsers();

  @override
  Future<void> clearAll() => _db.clearAllHistory();

  @override
  Future<HistoryStats> statsFor(List<HistoryEntry> entries) async =>
      HistoryStats.fromEntries(entries);

  /// Applies device / browser / date-range / result filters plus an
  /// optional free-text search across device, browser and score.
  List<HistoryEntry> applyFilters(
    List<HistoryEntry> source, {
    String? device,
    String? browser,
    String? result,
    DateTime? from,
    DateTime? to,
    String? searchText,
  }) {
    return source.where((e) {
      if (device != null && device.isNotEmpty && e.device != device) return false;
      if (browser != null && browser.isNotEmpty && e.browser != browser) return false;
      if (result != null && result.isNotEmpty && e.result != result) return false;
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      if (searchText != null && searchText.isNotEmpty) {
        final q = searchText.toLowerCase();
        final haystack = '${e.device} ${e.browser} ${e.score} ${e.match1} ${e.match2} ${e.match3 ?? ''}'
            .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Sorts a list of entries by the given field.
  List<HistoryEntry> applySort(
    List<HistoryEntry> source,
    HistorySortField field,
    bool ascending,
  ) {
    final list = [...source];
    int cmp(HistoryEntry a, HistoryEntry b) {
      switch (field) {
        case HistorySortField.date:
          return a.timestamp.compareTo(b.timestamp);
        case HistorySortField.device:
          return a.device.compareTo(b.device);
        case HistorySortField.browser:
          return a.browser.compareTo(b.browser);
        case HistorySortField.result:
          return a.result.compareTo(b.result);
        case HistorySortField.minute:
          return a.minute.compareTo(b.minute);
      }
    }

    list.sort(ascending ? cmp : (a, b) => cmp(b, a));
    return list;
  }
}

enum HistorySortField { date, device, browser, result, minute }
