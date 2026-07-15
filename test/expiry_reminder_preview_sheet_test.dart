import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/repositories/schedule_local_repository.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:life_maintenance/widgets/expiry_reminder_preview_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'items': jsonEncode([_testItem.toJson()]),
      'schedules': jsonEncode([]),
    });
  });

  testWidgets('reminder date field opens date picker and is read only', (
    tester,
  ) async {
    await _openSheet(tester);

    final dateField = tester.widget<TextField>(_dateFieldFinder());
    expect(dateField.readOnly, isTrue);

    await tester.tap(_dateFieldFinder());
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('selected reminder date is displayed as yyyy-MM-dd', (
    tester,
  ) async {
    await _openSheet(tester);

    final today = DateTime.now();
    final expectedDate = _formatDate(today);

    await _pickInitialDate(tester);

    expect(find.text(expectedDate), findsOneWidget);
  });

  testWidgets('canceling date picker keeps the previous reminder date', (
    tester,
  ) async {
    await _openSheet(tester);

    final today = DateTime.now();
    final expectedDate = _formatDate(today);

    await _pickInitialDate(tester);
    await tester.tap(_dateFieldFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text(expectedDate), findsOneWidget);
  });

  testWidgets('selected reminder date can be saved to a schedule', (
    tester,
  ) async {
    await _openSheet(tester);

    final today = DateTime.now();
    final expectedDate = DateTime(today.year, today.month, today.day);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_testItem.name).last);
    await tester.pumpAndSettle();
    await tester.enterText(_titleFieldFinder(), '護照到期');
    await _pickInitialDate(tester);
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    final schedules = await ScheduleLocalRepository(
      LocalStorageService(),
    ).loadSchedules();

    expect(schedules, hasLength(1));
    expect(schedules.single.itemId, _testItem.id);
    expect(schedules.single.cardId, 'manual-expiry-reminder');
    expect(schedules.single.title, '護照到期');
    expect(schedules.single.nextDueDate, expectedDate);
  });
}

final _testItem = Item(
  id: 'item-1',
  name: '護照',
  category: ItemCategory.other,
  createdAt: DateTime(2026, 7, 1),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showExpiryReminderPreviewSheet(context),
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _pickInitialDate(WidgetTester tester) async {
  await tester.tap(_dateFieldFinder());
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Finder _dateFieldFinder() {
  return find.widgetWithText(TextField, '提醒日期');
}

Finder _titleFieldFinder() {
  return find.widgetWithText(TextField, '事項名稱');
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
