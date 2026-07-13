import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/repositories/schedule_local_repository.dart';
import 'package:life_maintenance/screens/today_screen.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:life_maintenance/services/maintenance_task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'completing a manual expiry reminder disables only the matching schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isFalse);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
    },
  );

  testWidgets(
    'completing a regular maintenance task advances schedule due date',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-maintenance'), isTrue);
      expect(
        _nextDueDateFor(schedules, 'schedule-maintenance'),
        DateTime(2026, 8, 10),
      );
      expect(
        _nextDueDateFor(schedules, 'schedule-maintenance').isAfter(dueDate),
        isTrue,
      );
    },
  );

  testWidgets('monthly maintenance clamps end of month', (tester) async {
    final dueDate = DateTime(2026, 1, 31);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.monthly,
          interval: 1,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2026, 2, 28));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('quarterly maintenance clamps end of month', (tester) async {
    final dueDate = DateTime(2026, 1, 31);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.quarterly,
          interval: 1,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2026, 4, 30));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('semi annual maintenance clamps end of month', (tester) async {
    final dueDate = DateTime(2026, 8, 31);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.semiAnnual,
          interval: 1,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2027, 2, 28));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('yearly maintenance clamps leap day', (tester) async {
    final dueDate = DateTime(2024, 2, 29);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.yearly,
          interval: 1,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2025, 2, 28));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('zero interval falls back to one cycle', (tester) async {
    final dueDate = DateTime(2026, 1, 31);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.monthly,
          interval: 0,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2026, 2, 28));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('negative interval falls back to one cycle', (tester) async {
    final dueDate = DateTime(2026, 1, 31);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-target',
          cardId: 'card-aircon-filter-cleaning',
          cycleType: CycleType.monthly,
          interval: -2,
          nextDueDate: dueDate,
        ),
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-target',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-target'), DateTime(2026, 2, 28));
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets(
    'regular maintenance completion sheet defaults to continue cycle',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _openCompletionSheet(tester);

      expect(find.text('後續安排'), findsOneWidget);
      expect(find.text('繼續原週期'), findsOneWidget);
      expect(find.text('保留但不排程'), findsOneWidget);
      expect(find.text('結束排程'), findsOneWidget);

      await tester.ensureVisible(find.text('取消'));
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'completing a regular maintenance task can pause matching schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-target',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
          _schedule(
            id: 'schedule-other',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-target',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTaskWithPauseSchedule(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
      final records = await _storedRecords();
      expect(records, hasLength(1));
      expect(records.single['taskId'], 'task-maintenance');
      final schedules = await _storedSchedules();
      expect(_scheduleStatusFor(schedules, 'schedule-target'), 'paused');
      expect(_enabledFor(schedules, 'schedule-target'), isFalse);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
      expect(_scheduleStatusFor(schedules, 'schedule-other'), 'active');
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets('pause schedule with empty scheduleId still completes', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-empty-schedule',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: '',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTaskWithPauseSchedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-empty-schedule'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-empty-schedule');
    final schedules = await _storedSchedules();
    expect(_scheduleStatusFor(schedules, 'schedule-other'), 'active');
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('pause schedule with missing schedule still completes', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-other',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-missing-schedule',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-missing',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTaskWithPauseSchedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(
      _statusFor(tasks, 'task-missing-schedule'),
      TaskStatus.completed.name,
    );
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-missing-schedule');
    final schedules = await _storedSchedules();
    expect(_scheduleStatusFor(schedules, 'schedule-other'), 'active');
    expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
  });

  testWidgets('pause schedule with card mismatch does not update schedule', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-mismatch',
          cardId: 'card-water-heater-check',
          scheduleId: 'schedule-maintenance',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTaskWithPauseSchedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-mismatch'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-mismatch');
    final schedules = await _storedSchedules();
    expect(_scheduleStatusFor(schedules, 'schedule-maintenance'), 'active');
    expect(_nextDueDateFor(schedules, 'schedule-maintenance'), dueDate);
  });

  testWidgets('pause schedule does not update already paused schedule', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
          status: ScheduleStatus.paused,
        ),
      ],
      tasks: [
        _task(
          id: 'task-paused',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-paused',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTaskWithPauseSchedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-paused'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-paused');
    final schedules = await _storedSchedules();
    expect(_scheduleStatusFor(schedules, 'schedule-paused'), 'paused');
    expect(_nextDueDateFor(schedules, 'schedule-paused'), dueDate);
  });

  testWidgets('pause schedule does not update already ended schedule', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-ended',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
          status: ScheduleStatus.ended,
        ),
      ],
      tasks: [
        _task(
          id: 'task-ended',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-ended',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTaskWithPauseSchedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-ended'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-ended');
    final schedules = await _storedSchedules();
    expect(_scheduleStatusFor(schedules, 'schedule-ended'), 'ended');
    expect(_nextDueDateFor(schedules, 'schedule-ended'), dueDate);
  });

  testWidgets('pause schedule load failure shows partial success', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    final schedule = _schedule(
      id: 'schedule-maintenance',
      cardId: 'card-aircon-filter-cleaning',
      nextDueDate: dueDate,
    );
    await _setLocalData(
      schedules: [schedule],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-maintenance',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );
    final scheduleRepository = _FailingScheduleLocalRepository(
      schedules: [schedule],
      failLoadAfterCalls: 1,
    );

    await _completeVisibleTaskWithPauseSchedule(
      tester,
      todayScreen: TodayScreen(scheduleRepository: scheduleRepository),
    );

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    expect(records.single['taskId'], 'task-maintenance');
  });

  testWidgets('pause schedule save failure shows partial success', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    final schedule = _schedule(
      id: 'schedule-maintenance',
      cardId: 'card-aircon-filter-cleaning',
      nextDueDate: dueDate,
    );
    await _setLocalData(
      schedules: [schedule],
      tasks: [
        _task(
          id: 'task-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-maintenance',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );
    final scheduleRepository = _FailingScheduleLocalRepository(
      schedules: [schedule],
      failSave: true,
    );

    await _completeVisibleTaskWithPauseSchedule(
      tester,
      todayScreen: TodayScreen(scheduleRepository: scheduleRepository),
    );

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records, hasLength(1));
    expect(records.single['taskId'], 'task-maintenance');
  });

  testWidgets(
    'completing a regular maintenance task updates only matching schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-target',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
          _schedule(
            id: 'schedule-other',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-target',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      final schedules = await _storedSchedules();
      expect(
        _nextDueDateFor(schedules, 'schedule-target'),
        DateTime(2026, 8, 10),
      );
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets(
    'completing a regular maintenance task can end matching schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-target',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
          _schedule(
            id: 'schedule-other',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-target',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTaskWithEndSchedule(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isFalse);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets('manual expiry reminder shows manual reminder action options', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [_schedule(id: 'schedule-target', nextDueDate: dueDate)],
      tasks: [
        _task(
          id: 'task-target',
          scheduleId: 'schedule-target',
          dueDate: dueDate,
        ),
      ],
    );

    await _openCompletionSheet(tester);

    expect(find.text('後續安排'), findsOneWidget);
    expect(find.text('繼續原週期'), findsNothing);
    expect(find.text('結束排程'), findsNothing);
    expect(find.text('結束提醒'), findsOneWidget);
    expect(find.text('保留但不排程'), findsOneWidget);
    expect(find.text('重新安排日期'), findsOneWidget);

    await tester.ensureVisible(find.text('取消'));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'manual expiry task pointing at maintenance schedule does not disable it',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-manual-bad-schedule',
            scheduleId: 'schedule-maintenance',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      final tasks = await _storedTasks();
      expect(
        _statusFor(tasks, 'task-manual-bad-schedule'),
        TaskStatus.completed.name,
      );
      final records = await _storedRecords();
      expect(records.single['taskId'], 'task-manual-bad-schedule');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-maintenance'), isTrue);
    },
  );

  testWidgets(
    'manual expiry reminder can pause matching enabled schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeManualReminderWithPause(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_scheduleStatusFor(schedules, 'schedule-target'), 'paused');
      expect(_enabledFor(schedules, 'schedule-target'), isFalse);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
      expect(_scheduleStatusFor(schedules, 'schedule-maintenance'), 'active');
      expect(_enabledFor(schedules, 'schedule-maintenance'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-maintenance'), dueDate);
    },
  );

  testWidgets(
    'manual expiry reminder can reschedule matching enabled schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final newDate = _tomorrowDate();
      await _setLocalData(
        schedules: [_schedule(id: 'schedule-target', nextDueDate: dueDate)],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      expect(find.text('已完成任務並建立紀錄，可到履歷查看'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-target'), newDate);
    },
  );

  testWidgets(
    'manual expiry reminder reschedule requires a new reminder date',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [_schedule(id: 'schedule-target', nextDueDate: dueDate)],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _openCompletionSheet(tester);
      await tester.ensureVisible(find.text('重新安排日期'));
      await tester.tap(find.text('重新安排日期'));
      await tester.pumpAndSettle();
      final sheetCompleteButton = find.text('完成').last;
      await tester.ensureVisible(sheetCompleteButton);
      await tester.tap(sheetCompleteButton);
      await tester.pumpAndSettle();

      expect(find.text('請選擇新的提醒日期'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.pending.name);
      final records = await _storedRecords();
      expect(records, isEmpty);
    },
  );

  testWidgets(
    'manual expiry reminder reschedule rejects conflicting unfinished task',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final newDate = _tomorrowDate();
      await _setLocalData(
        schedules: [_schedule(id: 'schedule-target', nextDueDate: dueDate)],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
          _task(
            id: 'task-conflict',
            scheduleId: 'schedule-target',
            dueDate: newDate,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      expect(find.text('這個日期已有待處理提醒，請選擇其他日期'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.pending.name);
      final records = await _storedRecords();
      expect(records, isEmpty);
      final schedules = await _storedSchedules();
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
    },
  );

  testWidgets('disabled manual schedule does not reschedule', (tester) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(id: 'schedule-target', nextDueDate: dueDate, enabled: false),
      ],
      tasks: [
        _task(
          id: 'task-target',
          scheduleId: 'schedule-target',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeManualReminderWithReschedule(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
    final records = await _storedRecords();
    _expectSingleExpiryRecord(records, 'task-target');
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-target'), isFalse);
    expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
  });

  testWidgets(
    'schedule follow-up load failure shows partial success',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final schedule = _schedule(
        id: 'schedule-maintenance',
        cardId: 'card-aircon-filter-cleaning',
        nextDueDate: dueDate,
      );
      await _setLocalData(
        schedules: [schedule],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );
      final scheduleRepository = _FailingScheduleLocalRepository(
        schedules: [schedule],
        failLoadAfterCalls: 1,
      );

      await _completeVisibleTask(
        tester,
        todayScreen: TodayScreen(scheduleRepository: scheduleRepository),
      );

      expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
      final records = await _storedRecords();
      expect(records, hasLength(1));
      expect(records.single['taskId'], 'task-maintenance');
    },
  );

  testWidgets(
    'schedule follow-up save failure shows partial success',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final schedule = _schedule(id: 'schedule-target', nextDueDate: dueDate);
      await _setLocalData(
        schedules: [schedule],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );
      final scheduleRepository = _FailingScheduleLocalRepository(
        schedules: [schedule],
        failSave: true,
      );

      await _completeManualReminderWithReschedule(
        tester,
        todayScreen: TodayScreen(scheduleRepository: scheduleRepository),
      );

      expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
    },
  );

  testWidgets(
    'manual reschedule with empty schedule id still completes without schedules',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(id: 'task-target', scheduleId: '', dueDate: dueDate),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
    },
  );

  testWidgets(
    'manual reschedule with missing schedule still completes',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-missing',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
    },
  );

  testWidgets(
    'manual reschedule with card mismatch does not update schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-target',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
    },
  );

  testWidgets(
    'manual reschedule ignores completed task on selected date',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final newDate = _tomorrowDate();
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
          _task(
            id: 'task-completed',
            scheduleId: 'schedule-target',
            dueDate: newDate,
            status: TaskStatus.completed,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-target'), newDate);
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets(
    'manual reschedule ignores canceled task on selected date',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      final newDate = _tomorrowDate();
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
          _task(
            id: 'task-canceled',
            scheduleId: 'schedule-target',
            dueDate: newDate,
            status: TaskStatus.canceled,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-target'), newDate);
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets(
    'manual reschedule does not treat current task as conflict',
    (tester) async {
      final dueDate = _tomorrowDate();
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeManualReminderWithReschedule(tester);

      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-target'), TaskStatus.completed.name);
      final records = await _storedRecords();
      _expectSingleExpiryRecord(records, 'task-target');
      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isTrue);
      expect(_nextDueDateFor(schedules, 'schedule-target'), dueDate);
      expect(_nextDueDateFor(schedules, 'schedule-other'), dueDate);
    },
  );

  testWidgets('completing a task with empty scheduleId still succeeds', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: const [],
      tasks: [
        _task(id: 'task-empty-schedule', scheduleId: '', dueDate: dueDate),
      ],
    );

    await _completeVisibleTask(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-empty-schedule'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-empty-schedule');
  });

  testWidgets('missing matching schedule does not block completion', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(id: 'schedule-unrelated', nextDueDate: DateTime(2027, 1, 1)),
      ],
      tasks: [
        _task(
          id: 'task-missing-schedule',
          scheduleId: 'schedule-missing',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(
      _statusFor(tasks, 'task-missing-schedule'),
      TaskStatus.completed.name,
    );
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-unrelated'), isTrue);
  });

  testWidgets('card id mismatch does not update schedule', (tester) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-maintenance',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
        ),
      ],
      tasks: [
        _task(
          id: 'task-mismatched-card',
          cardId: 'card-water-heater-check',
          scheduleId: 'schedule-maintenance',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(
      _statusFor(tasks, 'task-mismatched-card'),
      TaskStatus.completed.name,
    );
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-mismatched-card');
    final schedules = await _storedSchedules();
    expect(_nextDueDateFor(schedules, 'schedule-maintenance'), dueDate);
  });

  testWidgets('disabled schedule does not update', (tester) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-disabled',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: dueDate,
          enabled: false,
        ),
      ],
      tasks: [
        _task(
          id: 'task-disabled-schedule',
          cardId: 'card-aircon-filter-cleaning',
          scheduleId: 'schedule-disabled',
          title: '保養提醒',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    expect(find.text('已完成並建立紀錄，但後續安排未更新'), findsOneWidget);
    final tasks = await _storedTasks();
    expect(
      _statusFor(tasks, 'task-disabled-schedule'),
      TaskStatus.completed.name,
    );
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-disabled-schedule');
    final schedules = await _storedSchedules();
    expect(_nextDueDateFor(schedules, 'schedule-disabled'), dueDate);
  });

  testWidgets(
    'existing record does not create duplicate or run schedule follow-up',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
        records: [_recordJson(taskId: 'task-maintenance')],
      );

      await _completeVisibleTask(tester);

      expect(find.text('此任務已完成'), findsOneWidget);
      final tasks = await _storedTasks();
      expect(_statusFor(tasks, 'task-maintenance'), TaskStatus.completed.name);
      final records = await _storedRecords();
      expect(records, hasLength(1));
      expect(records.single['taskId'], 'task-maintenance');
      final schedules = await _storedSchedules();
      expect(_nextDueDateFor(schedules, 'schedule-maintenance'), dueDate);
    },
  );

  testWidgets(
    'advanced schedule can generate a future task when next due date arrives',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      final storedSchedules = await _storedSchedules();
      final storedTasks = await _storedTasks();
      final schedules = storedSchedules
          .cast<Map<String, dynamic>>()
          .map(Schedule.fromJson)
          .toList();
      final tasks = storedTasks
          .cast<Map<String, dynamic>>()
          .map(Task.fromJson)
          .toList();

      final generatedTasks = MaintenanceTaskService().generateDueTasks(
        schedules: schedules,
        existingTasks: tasks,
        today: DateTime(2026, 8, 10),
      );

      expect(generatedTasks, hasLength(1));
      expect(generatedTasks.single.scheduleId, 'schedule-maintenance');
      expect(generatedTasks.single.dueDate, DateTime(2026, 8, 10));
    },
  );
}

Future<void> _setLocalData({
  required List<Schedule> schedules,
  required List<Task> tasks,
  List<Map<String, dynamic>> records = const [],
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    'items': jsonEncode([_item().toJson()]),
    'schedules': jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    ),
    'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
    'maintenance_records': jsonEncode(records),
  });
}

Future<void> _completeVisibleTask(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await _openCompletionSheet(tester, todayScreen: todayScreen);

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<void> _completeVisibleTaskWithEndSchedule(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await _openCompletionSheet(tester, todayScreen: todayScreen);

  await tester.ensureVisible(find.text('結束排程'));
  await tester.tap(find.text('結束排程'));
  await tester.pumpAndSettle();

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<void> _completeVisibleTaskWithPauseSchedule(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await _openCompletionSheet(tester, todayScreen: todayScreen);

  await tester.ensureVisible(find.text('保留但不排程'));
  await tester.tap(find.text('保留但不排程'));
  await tester.pumpAndSettle();

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<void> _completeManualReminderWithReschedule(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await _openCompletionSheet(tester, todayScreen: todayScreen);

  await tester.ensureVisible(find.text('重新安排日期'));
  await tester.tap(find.text('重新安排日期'));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('選擇新的提醒日期'));
  await tester.tap(find.text('選擇新的提醒日期'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<void> _completeManualReminderWithPause(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await _openCompletionSheet(tester, todayScreen: todayScreen);

  await tester.ensureVisible(find.text('保留但不排程'));
  await tester.tap(find.text('保留但不排程'));
  await tester.pumpAndSettle();

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<void> _openCompletionSheet(
  WidgetTester tester, {
  Widget todayScreen = const TodayScreen(),
}) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: todayScreen)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('完成').first);
  await tester.pumpAndSettle();
}

DateTime _tomorrowDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1);
}

Future<List<dynamic>> _storedSchedules() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('schedules')!) as List<dynamic>;
}

Future<List<dynamic>> _storedTasks() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('tasks')!) as List<dynamic>;
}

Future<List<dynamic>> _storedRecords() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('maintenance_records')!)
      as List<dynamic>;
}

bool _enabledFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['enabled'] as bool;
}

DateTime _nextDueDateFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return DateTime.parse(schedule['nextDueDate'] as String);
}

String _scheduleStatusFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['status'] as String;
}

String _statusFor(List<dynamic> tasks, String id) {
  final task = tasks.cast<Map<String, dynamic>>().singleWhere(
    (task) => task['id'] == id,
  );
  return task['status'] as String;
}

Item _item() {
  return Item(
    id: 'item-1',
    name: '合約',
    category: ItemCategory.warrantyDocument,
    createdAt: DateTime(2026, 7, 1),
  );
}

Schedule _schedule({
  required String id,
  required DateTime nextDueDate,
  String cardId = 'manual-expiry-reminder',
  CycleType? cycleType,
  int interval = 1,
  bool enabled = true,
  ScheduleStatus? status,
}) {
  return Schedule(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    cycleType:
        cycleType ??
        (cardId == 'manual-expiry-reminder'
            ? CycleType.custom
            : CycleType.monthly),
    interval: interval,
    startDate: DateTime(2026, 7, 1),
    nextDueDate: nextDueDate,
    title: '合約續約',
    enabled: enabled,
    status: status,
  );
}

Task _task({
  required String id,
  required String scheduleId,
  required DateTime dueDate,
  String cardId = 'manual-expiry-reminder',
  String title = '合約續約',
  TaskStatus status = TaskStatus.pending,
}) {
  return Task(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    scheduleId: scheduleId,
    title: title,
    dueDate: dueDate,
    status: status,
  );
}

void _expectSingleExpiryRecord(List<dynamic> records, String taskId) {
  expect(records, hasLength(1));
  expect(records.single['taskId'], taskId);
  expect(records.single['recordType'], RecordType.expiryHandled.name);
}

Map<String, dynamic> _recordJson({required String taskId}) {
  final now = DateTime(2026, 7, 10);
  return {
    'id': 'record-$taskId',
    'itemId': 'item-1',
    'taskId': taskId,
    'recordType': RecordType.regularMaintenance.name,
    'date': now.toIso8601String(),
    'title': '保養提醒',
    'issueDescription': null,
    'workDescription': null,
    'partsChanged': <String>[],
    'cost': null,
    'vendorName': null,
    'warrantyUntil': null,
    'result': '已完成',
    'photos': <String>[],
    'note': '既有紀錄',
    'createdAt': now.toIso8601String(),
  };
}

class _FailingScheduleLocalRepository extends ScheduleLocalRepository {
  _FailingScheduleLocalRepository({
    required List<Schedule> schedules,
    this.failLoadAfterCalls,
    this.failSave = false,
  }) : _schedules = schedules,
       super(LocalStorageService());

  List<Schedule> _schedules;
  final int? failLoadAfterCalls;
  final bool failSave;
  int _loadCallCount = 0;

  @override
  Future<List<Schedule>> loadSchedules() async {
    _loadCallCount += 1;
    final failAfter = failLoadAfterCalls;
    if (failAfter != null && _loadCallCount > failAfter) {
      throw Exception('schedule load failed');
    }

    return _schedules;
  }

  @override
  Future<void> saveSchedules(List<Schedule> schedules) async {
    if (failSave) {
      throw Exception('schedule save failed');
    }

    _schedules = schedules;
  }
}
