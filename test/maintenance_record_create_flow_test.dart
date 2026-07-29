import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/screens/add_screen.dart';
import 'package:life_maintenance/screens/maintenance_record_screens.dart';

void main() {
  late AppDatabase database;
  late AppCompositionRoot root;
  final seededAt = DateTime.utc(2026, 7, 20, 9);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    root = AppCompositionRoot(database: database);
  });

  tearDown(() async {
    try {
      await database.close();
    } catch (_) {
      // A failure-path test intentionally closes the database before teardown.
    }
  });

  testWidgets('formal Add entry opens an honest empty form without an Item', (
    tester,
  ) async {
    await _pumpAddScreen(tester, root);

    expect(find.text('補登完成紀錄'), findsOneWidget);
    expect(find.text('突發事項／工程'), findsOneWidget);
    expect(find.text('一般提醒'), findsOneWidget);

    await _openForm(tester);

    expect(find.byType(ManualMaintenanceRecordFormScreen), findsOneWidget);
    expect(find.text('目前還沒有生活項目'), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-record-save')), findsNothing);
    expect(await root.maintenanceRecordRepository.listAll(), isEmpty);
  });

  testWidgets(
    'archives remain selectable and a past fact is read back exactly into History and detail',
    (tester) async {
      await _seedItem(root, id: 'item-active', name: '客廳冷氣');
      await _seedItem(
        root,
        id: 'item-archived',
        name: '舊洗衣機',
        status: 'archived',
      );
      await root.maintenanceRecordRepository.createSimpleRecord(
        _record('record-existing', 'item-active', '既有紀錄', seededAt),
      );
      await _pumpAddScreen(tester, root);
      await _openForm(tester);

      final itemField = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('maintenance-record-item')),
      );
      expect(itemField.initialValue, isNull);

      await _selectItem(tester, '舊洗衣機（已封存）');
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-title')),
        '  已完成搬離  ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-note')),
        '  保留收據  ',
      );
      await _pickYesterday(tester);

      final beforeTasks = await root.driftRepositories.tasks.listAll();
      final beforePlans = await root.driftRepositories.maintenancePlans
          .listForItem('item-archived');
      final beforeSchedules = await root.driftRepositories.schedules
          .listForItem('item-archived');
      final beforeCases = await root.workCaseRuntime.listCasesForItem(
        'item-archived',
      );

      await tester.tap(find.byKey(const ValueKey('maintenance-record-save')));
      await tester.pumpAndSettle();

      final records = await root.maintenanceRecordRepository.listForItem(
        'item-archived',
      );
      expect(records, hasLength(1));
      final created = records.single;
      expect(created.id, startsWith('record-'));
      expect(created.id, isNot('record-existing'));
      expect(created.itemId, 'item-archived');
      expect(created.title, '已完成搬離');
      expect(created.note, '保留收據');
      expect(created.recordType, RecordType.other);
      expect(created.taskId, isNull);
      expect(created.maintenancePlanId, isNull);
      expect(
        await root.maintenanceRecordRepository.findById(created.id),
        isNotNull,
      );
      expect(find.text('已完成搬離'), findsOneWidget);
      expect(find.text('保留收據'), findsOneWidget);
      expect(
        (await root.itemReadRepository.loadItems())
            .singleWhere((item) => item.id == 'item-archived')
            .status,
        ItemStatus.archived,
      );
      expect(await root.driftRepositories.tasks.listAll(), beforeTasks);
      expect(
        await root.driftRepositories.maintenancePlans.listForItem(
          'item-archived',
        ),
        beforePlans,
      );
      expect(
        await root.driftRepositories.schedules.listForItem('item-archived'),
        beforeSchedules,
      );
      expect(
        await root.workCaseRuntime.listCasesForItem('item-archived'),
        beforeCases,
      );

      final history = await root.historyProjectionRepository.projectForItem(
        'item-archived',
      );
      final entries = history.entries
          .whereType<MaintenanceRecordHistoryEntry>()
          .where((entry) => entry.sourceId == created.id)
          .toList();
      expect(entries, hasLength(1));
      expect(entries.single.occurredAt, created.date);
      expect(entries.single.record.id, created.id);
    },
  );

  testWidgets(
    'today is the default, blank notes normalize, and double taps write once',
    (tester) async {
      await _seedItem(root, id: 'item-active', name: '客廳冷氣');
      await _pumpAddScreen(tester, root);
      await _openForm(tester);

      expect(find.text(_formatDate(DateTime.now())), findsOneWidget);
      await _selectItem(tester, '客廳冷氣');
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-title')),
        '完成清潔',
      );
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-note')),
        '   ',
      );
      final save = find.byKey(const ValueKey('maintenance-record-save'));
      await tester.tap(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final records = await root.maintenanceRecordRepository.listForItem(
        'item-active',
      );
      expect(records, hasLength(1));
      expect(records.single.note, isNull);
      expect(records.single.date, _dateOnly(DateTime.now()));
    },
  );

  testWidgets('blank titles and cancellation never write a record', (
    tester,
  ) async {
    await _seedItem(root, id: 'item-active', name: '客廳冷氣');
    await _pumpAddScreen(tester, root);
    await _openForm(tester);
    await _selectItem(tester, '客廳冷氣');
    await tester.enterText(
      find.byKey(const ValueKey('maintenance-record-title')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('maintenance-record-save')));
    await tester.pump();

    expect(find.text('請填寫完成內容'), findsOneWidget);
    expect(await root.maintenanceRecordRepository.listAll(), isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AddScreen), findsOneWidget);
    expect(await root.maintenanceRecordRepository.listAll(), isEmpty);
  });

  testWidgets('the date picker cannot select a future local date', (
    tester,
  ) async {
    await _seedItem(root, id: 'item-active', name: '客廳冷氣');
    await _pumpAddScreen(tester, root);
    await _openForm(tester);
    await tester.tap(find.byKey(const ValueKey('maintenance-record-date')));
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.lastDate, _dateOnly(DateTime.now()));
    expect(
      calendar.lastDate.isBefore(
        _dateOnly(DateTime.now()).add(const Duration(days: 1)),
      ),
      isTrue,
    );
    expect(await root.maintenanceRecordRepository.listAll(), isEmpty);
  });

  testWidgets(
    'a repository failure keeps normalized input available to retry',
    (tester) async {
      await _seedItem(root, id: 'item-active', name: '客廳冷氣');
      await _pumpAddScreen(tester, root);
      await _openForm(tester);
      await _selectItem(tester, '客廳冷氣');
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-title')),
        '完成測試',
      );
      await tester.enterText(
        find.byKey(const ValueKey('maintenance-record-note')),
        '保留內容',
      );

      await database.close();
      await tester.tap(find.byKey(const ValueKey('maintenance-record-save')));
      await tester.pumpAndSettle();

      expect(find.byType(ManualMaintenanceRecordFormScreen), findsOneWidget);
      expect(find.text('目前無法建立紀錄，請稍後再試。'), findsOneWidget);
      expect(find.text('完成測試'), findsOneWidget);
      expect(find.text('保留內容'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).last,
      );
      expect(button.onPressed, isNotNull);
    },
  );
}

Future<void> _pumpAddScreen(
  WidgetTester tester,
  AppCompositionRoot root,
) async {
  await tester.pumpWidget(
    AppCompositionScope(
      root: root,
      child: const MaterialApp(home: Scaffold(body: AddScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) async {
  final entry = find.text('補登完成紀錄');
  await tester.scrollUntilVisible(entry, 150);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _selectItem(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('maintenance-record-item')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _pickYesterday(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('maintenance-record-date')));
  await tester.pumpAndSettle();
  final yesterday = _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
  await tester.tap(find.text('${yesterday.day}').last);
  final confirm = find.text('確定').evaluate().isNotEmpty
      ? find.text('確定')
      : find.text('OK');
  await tester.tap(confirm);
  await tester.pumpAndSettle();
  expect(find.text(_formatDate(yesterday)), findsOneWidget);
}

Future<void> _seedItem(
  AppCompositionRoot root, {
  required String id,
  required String name,
  String status = 'active',
}) async {
  const categoryId = 'category-other';
  if (await root.driftRepositories.itemCategories.findById(categoryId) ==
      null) {
    await root.driftRepositories.itemCategories.save(
      ItemCategoryRow(
        id: categoryId,
        systemCode: 'other',
        displayName: '其他',
        sortOrder: 0,
        status: 'active',
        createdAt: DateTime.utc(2026, 7, 20, 9),
        updatedAt: DateTime.utc(2026, 7, 20, 9),
      ),
    );
  }
  await root.driftRepositories.items.save(
    ItemRow(
      id: id,
      name: name,
      categoryId: categoryId,
      status: status,
      createdAt: DateTime.utc(2026, 7, 20, 9),
      updatedAt: DateTime.utc(2026, 7, 20, 9),
      archivedAt: status == 'archived' ? DateTime.utc(2026, 7, 21) : null,
    ),
  );
}

MaintenanceRecord _record(
  String id,
  String itemId,
  String title,
  DateTime date,
) => MaintenanceRecord(
  id: id,
  itemId: itemId,
  recordType: RecordType.other,
  date: date,
  title: title,
  createdAt: date,
);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _formatDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
