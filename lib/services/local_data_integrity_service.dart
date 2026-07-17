import 'dart:convert';

import 'package:flutter/foundation.dart';

class LocalDataIntegrityIssue {
  const LocalDataIntegrityIssue({
    required this.storageKey,
    required this.message,
    required this.invalidEntryCount,
  });

  final String storageKey;
  final String message;
  final int invalidEntryCount;
}

class LocalDataWriteBlockedException implements Exception {
  const LocalDataWriteBlockedException();

  @override
  String toString() {
    return 'Local data writes are blocked until integrity issues are resolved.';
  }
}

class LocalDataIntegrityService extends ChangeNotifier {
  LocalDataIntegrityService._();

  static final LocalDataIntegrityService instance =
      LocalDataIntegrityService._();

  final Map<String, LocalDataIntegrityIssue> _issues =
      <String, LocalDataIntegrityIssue>{};

  bool get hasIssues => _issues.isNotEmpty;

  List<LocalDataIntegrityIssue> get issues =>
      List<LocalDataIntegrityIssue>.unmodifiable(_issues.values);

  bool hasIssueForKey(String storageKey) => _issues.containsKey(storageKey);

  List<T> decodeList<T>({
    required String storageKey,
    required String rawValue,
    required T Function(Map<String, dynamic> json) decodeEntry,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawValue);
    } catch (_) {
      _setIssue(
        storageKey: storageKey,
        message: '本機資料格式無法解析',
        invalidEntryCount: 1,
      );
      return <T>[];
    }

    if (decoded is! List) {
      _setIssue(
        storageKey: storageKey,
        message: '本機資料格式不是有效清單',
        invalidEntryCount: 1,
      );
      return <T>[];
    }

    final values = <T>[];
    var invalidEntryCount = 0;

    for (final entry in decoded) {
      try {
        if (entry is! Map) {
          throw const FormatException('Entry is not a JSON object.');
        }

        values.add(decodeEntry(Map<String, dynamic>.from(entry)));
      } catch (_) {
        invalidEntryCount += 1;
      }
    }

    if (invalidEntryCount > 0) {
      _setIssue(
        storageKey: storageKey,
        message: '部分本機資料無法讀取',
        invalidEntryCount: invalidEntryCount,
      );
    } else {
      clearIssue(storageKey);
    }

    return values;
  }

  void reportIssue({
    required String storageKey,
    required String message,
    int invalidEntryCount = 1,
  }) {
    _setIssue(
      storageKey: storageKey,
      message: message,
      invalidEntryCount: invalidEntryCount,
    );
  }

  void ensureWritesAllowed() {
    if (hasIssues) {
      throw const LocalDataWriteBlockedException();
    }
  }

  void clearIssue(String storageKey) {
    if (_issues.remove(storageKey) != null) {
      notifyListeners();
    }
  }

  void resetForTesting() {
    if (_issues.isEmpty) {
      return;
    }

    _issues.clear();
    notifyListeners();
  }

  void _setIssue({
    required String storageKey,
    required String message,
    required int invalidEntryCount,
  }) {
    final previous = _issues[storageKey];
    final next = LocalDataIntegrityIssue(
      storageKey: storageKey,
      message: message,
      invalidEntryCount: invalidEntryCount,
    );
    _issues[storageKey] = next;

    if (previous?.message != next.message ||
        previous?.invalidEntryCount != next.invalidEntryCount) {
      notifyListeners();
    }
  }
}
