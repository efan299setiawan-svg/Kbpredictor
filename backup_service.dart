import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/db_helper.dart';

/// Backs up and restores the raw SQLite database file so the user never
/// loses their history or edited rules. Purely file-system based - no
/// network involved at any point.
class BackupService {
  final DBHelper _db;
  BackupService({DBHelper? db}) : _db = db ?? DBHelper.instance;

  /// Copies the live database file to the documents directory with a
  /// timestamped name and opens the share sheet so the user can save it
  /// wherever they like (Drive, local storage, etc - all initiated by
  /// the user, the app itself never uploads anything).
  Future<File> backup() async {
    final dbPath = await _db.getDbPath();
    final source = File(dbPath);
    final dir = await getApplicationDocumentsDirectory();
    final backupFile = File('${dir.path}/kb_predictor_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await source.copy(backupFile.path);
    await Share.shareXFiles([XFile(backupFile.path)], text: 'KB Predictor AI - Database Backup');
    return backupFile;
  }

  /// Lets the user pick a previously-exported .db file and restores it,
  /// completely replacing the current database.
  Future<bool> restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return false;

    final pickedFile = File(result.files.single.path!);
    final dbPath = await _db.getDbPath();

    // Close the current connection before overwriting the file on disk.
    await _db.close();
    await pickedFile.copy(dbPath);
    await _db.reopen();
    return true;
  }
}
