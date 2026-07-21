import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

typedef SqliteSnapshotWriter =
    Future<void> Function(Database source, Database destination);

typedef AtomicBackupPromoter =
    Future<void> Function(File stagedFile, File destinationFile);

/// Native disaster-recovery boundary for the formal Drift SQLite database.
///
/// The database owner must close Drift before calling this service. A backup is
/// always written and validated in an isolated staging file. Restore follows
/// the same rule and only promotes a fully validated staging database, so a
/// failed operation cannot partially overwrite the destination.
class DriftDatabaseBackupService {
  DriftDatabaseBackupService({
    SqliteSnapshotWriter? snapshotWriter,
    AtomicBackupPromoter? backupPromoter,
  }) : _snapshotWriter = snapshotWriter ?? _writeSqliteSnapshot,
       _backupPromoter = backupPromoter ?? _promoteAtomically;

  static const int formatVersion = 2;

  static const Set<String> requiredTables = <String>{
    'item_categories',
    'items',
    'maintenance_plans',
    'maintenance_plan_steps',
    'general_reminders',
    'milestones',
    'schedules',
    'tasks',
    'maintenance_records',
    'work_cases',
    'work_case_updates',
    'work_case_closures',
    'attachments',
  };

  final SqliteSnapshotWriter _snapshotWriter;
  final AtomicBackupPromoter _backupPromoter;

  Future<DatabaseBackupValidation> validate(File file) async {
    if (!await file.exists()) {
      throw DatabaseBackupException('Database file does not exist.');
    }

    Database? database;
    try {
      database = sqlite3.open(file.path, mode: OpenMode.readOnly);
      return _validateOpenDatabase(database);
    } on DatabaseBackupException {
      rethrow;
    } catch (error) {
      throw DatabaseBackupException(
        'Database file is not a readable SQLite backup.',
        cause: error,
      );
    } finally {
      database?.close();
    }
  }

  Future<DatabaseBackupValidation> createBackup({
    required File source,
    required File destination,
  }) async {
    _requireDistinctPaths(source, destination);
    if (await destination.exists()) {
      throw DatabaseBackupException(
        'Backup destination already exists and will not be overwritten.',
      );
    }

    final sourceValidation = await validate(source);
    final staged = _stagingFileFor(destination);
    await _deleteIfPresent(staged);

    try {
      await _copySnapshot(source: source, destination: staged);
      final stagedValidation = await validate(staged);
      _requireSameContents(sourceValidation, stagedValidation);
      await _backupPromoter(staged, destination);
      return stagedValidation;
    } catch (_) {
      await _deleteIfPresent(staged);
      rethrow;
    }
  }

  Future<DatabaseBackupValidation> restore({
    required File backup,
    required File destination,
  }) async {
    _requireDistinctPaths(backup, destination);
    final backupValidation = await validate(backup);
    final staged = _stagingFileFor(destination);
    await _deleteIfPresent(staged);

    try {
      await _copySnapshot(source: backup, destination: staged);
      final stagedValidation = await validate(staged);
      _requireSameContents(backupValidation, stagedValidation);
      await _backupPromoter(staged, destination);
      return stagedValidation;
    } catch (_) {
      await _deleteIfPresent(staged);
      rethrow;
    }
  }

  DatabaseBackupValidation _validateOpenDatabase(Database database) {
    final version = database
        .select('PRAGMA user_version')
        .single['user_version'];
    if (version != formatVersion) {
      throw DatabaseBackupException(
        'Unsupported database backup version: $version.',
      );
    }

    final tables = database
        .select(
          "SELECT name FROM sqlite_schema WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .map((row) => row['name'] as String)
        .toSet();
    final missingTables = requiredTables.difference(tables);
    if (missingTables.isNotEmpty) {
      throw DatabaseBackupException(
        'Database backup is missing required tables: '
        '${missingTables.toList()..sort()}.',
      );
    }

    final integrityRows = database.select('PRAGMA integrity_check');
    final integrityMessages = integrityRows
        .map((row) => row.values.first.toString())
        .toList(growable: false);
    if (integrityMessages.length != 1 || integrityMessages.single != 'ok') {
      throw DatabaseBackupException(
        'Database backup failed integrity_check: $integrityMessages.',
      );
    }

    final foreignKeyViolations = database.select('PRAGMA foreign_key_check');
    if (foreignKeyViolations.isNotEmpty) {
      throw DatabaseBackupException(
        'Database backup has ${foreignKeyViolations.length} '
        'foreign-key violations.',
      );
    }

    final rowCounts = <String, int>{};
    for (final table in requiredTables) {
      rowCounts[table] =
          database
                  .select('SELECT COUNT(*) AS count FROM $table')
                  .single['count']
              as int;
    }
    return DatabaseBackupValidation(
      formatVersion: version as int,
      rowCounts: Map.unmodifiable(rowCounts),
    );
  }

  Future<void> _copySnapshot({
    required File source,
    required File destination,
  }) async {
    Database? sourceDatabase;
    Database? destinationDatabase;
    try {
      sourceDatabase = sqlite3.open(source.path, mode: OpenMode.readOnly);
      destinationDatabase = sqlite3.open(destination.path);
      await _snapshotWriter(sourceDatabase, destinationDatabase);
    } finally {
      destinationDatabase?.close();
      sourceDatabase?.close();
    }
  }

  void _requireSameContents(
    DatabaseBackupValidation source,
    DatabaseBackupValidation copy,
  ) {
    if (source.formatVersion != copy.formatVersion ||
        !_mapsEqual(source.rowCounts, copy.rowCounts)) {
      throw DatabaseBackupException(
        'Staged database does not match the validated backup contents.',
      );
    }
  }

  void _requireDistinctPaths(File source, File destination) {
    if (source.absolute.path == destination.absolute.path) {
      throw DatabaseBackupException(
        'Source and destination database paths must be different.',
      );
    }
  }

  File _stagingFileFor(File destination) =>
      File('${destination.path}.restore-staging');

  static Future<void> _writeSqliteSnapshot(
    Database source,
    Database destination,
  ) async {
    await source.backup(destination, nPage: -1).drain<void>();
  }

  static Future<void> _promoteAtomically(
    File stagedFile,
    File destinationFile,
  ) async {
    await stagedFile.rename(destinationFile.path);
  }

  static Future<void> _deleteIfPresent(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool _mapsEqual(Map<String, int> left, Map<String, int> right) {
    if (left.length != right.length) {
      return false;
    }
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }
}

class DatabaseBackupValidation {
  const DatabaseBackupValidation({
    required this.formatVersion,
    required this.rowCounts,
  });

  final int formatVersion;
  final Map<String, int> rowCounts;
}

class DatabaseBackupException implements Exception {
  const DatabaseBackupException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'DatabaseBackupException: $message';
}
