import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/db_helper.dart';
import '../models/history_entry.dart';

/// Handles exporting history data to CSV / JSON files, entirely on
/// device - files are saved to the app's documents directory and then
/// handed to the OS share sheet so the user can save/send them anywhere.
class ExportService {
  final DBHelper _db;
  ExportService({DBHelper? db}) : _db = db ?? DBHelper.instance;

  Future<List<HistoryEntry>> _entriesToExport({
    List<HistoryEntry>? entries,
  }) async {
    return entries ?? await _db.getAllHistory();
  }

  /// Exports history as a CSV file and opens the share sheet.
  Future<File> exportCsv({List<HistoryEntry>? entries}) async {
    final data = await _entriesToExport(entries: entries);
    final rows = <List<dynamic>>[HistoryEntry.csvHeader, ...data.map((e) => e.toCsvRow())];
    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/kb_predictor_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'KB Predictor AI - History Export (CSV)');
    return file;
  }

  /// Exports history as a JSON file and opens the share sheet.
  Future<File> exportJson({List<HistoryEntry>? entries}) async {
    final data = await _entriesToExport(entries: entries);
    final list = data.map((e) => e.toMap()).toList();
    final json = const JsonEncoder.withIndent('  ').convert(list);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/kb_predictor_history_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)], text: 'KB Predictor AI - History Export (JSON)');
    return file;
  }
}
