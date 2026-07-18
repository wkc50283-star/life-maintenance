import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/work_case_closure.dart';

void main() {
  test('round trips a complete work case closure', () {
    final closure = WorkCaseClosure(
      id: 'closure-1',
      workCaseId: 'case-1',
      completedAt: DateTime(2026, 7, 18, 16),
      finalResult: '已完成修理並恢復正常運作',
      completionSummary: '更換室內機風扇軸承並完成運轉測試',
      totalCost: 3200,
      followUpNotes: '三個月後再確認異音是否復發',
      followUpType: WorkCaseFollowUpType.scheduleAndReminder,
      nextScheduleId: 'schedule-2',
      nextReminderTaskId: 'task-2',
      createdAt: DateTime(2026, 7, 18, 16, 5),
    );

    final decoded = WorkCaseClosure.fromJson(closure.toJson());

    expect(decoded.schemaVersion, WorkCaseClosure.currentSchemaVersion);
    expect(decoded.id, closure.id);
    expect(decoded.workCaseId, closure.workCaseId);
    expect(decoded.completedAt, closure.completedAt);
    expect(decoded.finalResult, closure.finalResult);
    expect(decoded.completionSummary, closure.completionSummary);
    expect(decoded.totalCost, 3200);
    expect(decoded.followUpNotes, closure.followUpNotes);
    expect(decoded.followUpType, WorkCaseFollowUpType.scheduleAndReminder);
    expect(decoded.nextScheduleId, 'schedule-2');
    expect(decoded.nextReminderTaskId, 'task-2');
    expect(decoded.needsFollowUp, isTrue);
    expect(decoded.createsSchedule, isTrue);
    expect(decoded.createsReminder, isTrue);
  });

  test('no follow-up remains explicit and does not infer new work', () {
    final closure = WorkCaseClosure(
      id: 'closure-2',
      workCaseId: 'case-2',
      completedAt: DateTime(2026, 7, 18),
      finalResult: '問題已排除',
      completionSummary: '重新固定鬆脫零件',
      totalCost: 0,
      createdAt: DateTime(2026, 7, 18),
    );

    expect(closure.followUpType, WorkCaseFollowUpType.none);
    expect(closure.needsFollowUp, isFalse);
    expect(closure.createsSchedule, isFalse);
    expect(closure.createsReminder, isFalse);
  });

  test('unknown follow-up type and invalid cost use safe fallbacks', () {
    final decoded = WorkCaseClosure.fromJson({
      'id': 'closure-legacy',
      'workCaseId': 'case-legacy',
      'completedAt': '2026-07-18T10:00:00.000',
      'finalResult': '已完成',
      'completionSummary': '舊格式結案資料',
      'totalCost': -500,
      'followUpType': 'futureFollowUpType',
      'createdAt': '2026-07-18T10:05:00.000',
    });

    expect(decoded.schemaVersion, WorkCaseClosure.currentSchemaVersion);
    expect(decoded.totalCost, 0);
    expect(decoded.followUpType, WorkCaseFollowUpType.unknown);
    expect(decoded.needsFollowUp, isTrue);
    expect(decoded.nextScheduleId, isNull);
    expect(decoded.nextReminderTaskId, isNull);
  });

  test('copyWith can explicitly clear optional follow-up references', () {
    final closure = WorkCaseClosure(
      id: 'closure-3',
      workCaseId: 'case-3',
      completedAt: DateTime(2026, 7, 18),
      finalResult: '已完成',
      completionSummary: '已完成全部處理',
      totalCost: 1200,
      followUpNotes: '下次保養時再確認',
      followUpType: WorkCaseFollowUpType.schedule,
      nextScheduleId: 'schedule-3',
      createdAt: DateTime(2026, 7, 18),
    );

    final cleared = closure.copyWith(
      followUpNotes: null,
      followUpType: WorkCaseFollowUpType.none,
      nextScheduleId: null,
      nextReminderTaskId: null,
    );

    expect(cleared.followUpNotes, isNull);
    expect(cleared.followUpType, WorkCaseFollowUpType.none);
    expect(cleared.nextScheduleId, isNull);
    expect(cleared.nextReminderTaskId, isNull);
    expect(cleared.needsFollowUp, isFalse);
  });

  test('negative total cost is rejected for newly created closures', () {
    expect(
      () => WorkCaseClosure(
        id: 'closure-invalid',
        workCaseId: 'case-invalid',
        completedAt: DateTime(2026, 7, 18),
        finalResult: '已完成',
        completionSummary: '測試',
        totalCost: -1,
        createdAt: DateTime(2026, 7, 18),
      ),
      throwsAssertionError,
    );
  });
}
