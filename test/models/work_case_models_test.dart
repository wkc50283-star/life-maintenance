import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';

void main() {
  group('WorkCase', () {
    test('round trips all case fields', () {
      final workCase = WorkCase(
        id: 'case-1',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.maintenanceTask,
        sourceId: 'task-1',
        caseType: WorkCaseType.repair,
        title: '冷氣異音檢查',
        description: '運轉時出現間歇異音',
        occurredAt: DateTime(2026, 7, 18, 9, 30),
        startedAt: DateTime(2026, 7, 18, 10),
        status: WorkCaseStatus.inProgress,
        createdAt: DateTime(2026, 7, 18, 9, 35),
        updatedAt: DateTime(2026, 7, 18, 10),
      );

      final decoded = WorkCase.fromJson(workCase.toJson());

      expect(decoded.schemaVersion, WorkCase.currentSchemaVersion);
      expect(decoded.id, workCase.id);
      expect(decoded.itemId, workCase.itemId);
      expect(decoded.sourceType, WorkCaseSourceType.maintenanceTask);
      expect(decoded.sourceId, 'task-1');
      expect(decoded.caseType, WorkCaseType.repair);
      expect(decoded.title, workCase.title);
      expect(decoded.description, workCase.description);
      expect(decoded.occurredAt, workCase.occurredAt);
      expect(decoded.startedAt, workCase.startedAt);
      expect(decoded.status, WorkCaseStatus.inProgress);
      expect(decoded.createdAt, workCase.createdAt);
      expect(decoded.updatedAt, workCase.updatedAt);
      expect(decoded.isOpen, isTrue);
      expect(decoded.isClosed, isFalse);
    });

    test('unknown enums and missing optional values use safe fallbacks', () {
      final createdAt = DateTime(2026, 7, 18, 12);
      final decoded = WorkCase.fromJson({
        'id': 'case-legacy',
        'itemId': 'item-1',
        'sourceType': 'futureSource',
        'caseType': 'futureCaseType',
        'title': '未知格式案件',
        'status': 'futureStatus',
        'createdAt': createdAt.toIso8601String(),
      });

      expect(decoded.schemaVersion, WorkCase.currentSchemaVersion);
      expect(decoded.sourceType, WorkCaseSourceType.unknown);
      expect(decoded.caseType, WorkCaseType.other);
      expect(decoded.status, WorkCaseStatus.notStarted);
      expect(decoded.updatedAt, createdAt);
      expect(decoded.sourceId, isNull);
      expect(decoded.closedAt, isNull);
    });

    test('copyWith supports closure and explicit nullable field clearing', () {
      final createdAt = DateTime(2026, 7, 18, 8);
      final closedAt = DateTime(2026, 7, 19, 17);
      final workCase = WorkCase(
        id: 'case-2',
        itemId: 'item-2',
        sourceType: WorkCaseSourceType.generalReminder,
        sourceId: 'task-reminder-1',
        caseType: WorkCaseType.administrative,
        title: '辦理證件換發',
        status: WorkCaseStatus.waiting,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      final completed = workCase.copyWith(
        sourceId: null,
        status: WorkCaseStatus.completed,
        closedAt: closedAt,
        closeResult: '已領取新證件',
        updatedAt: closedAt,
      );

      expect(completed.sourceId, isNull);
      expect(completed.status, WorkCaseStatus.completed);
      expect(completed.closedAt, closedAt);
      expect(completed.closeResult, '已領取新證件');
      expect(completed.isClosed, isTrue);
      expect(completed.isOpen, isFalse);
    });

    test('canceled cases can preserve a cancellation reason', () {
      final now = DateTime(2026, 7, 18);
      final canceled = WorkCase(
        id: 'case-3',
        itemId: 'item-3',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.construction,
        title: '陽台修繕評估',
        status: WorkCaseStatus.canceled,
        cancellationReason: '房東決定改由其他廠商統一處理',
        createdAt: now,
        updatedAt: now,
        closedAt: now,
      );

      final decoded = WorkCase.fromJson(canceled.toJson());

      expect(decoded.status, WorkCaseStatus.canceled);
      expect(decoded.cancellationReason, isNotEmpty);
      expect(decoded.isClosed, isTrue);
    });
  });

  group('WorkCaseUpdate', () {
    test('round trips a complete append-only progress entry', () {
      final update = WorkCaseUpdate(
        id: 'update-1',
        workCaseId: 'case-1',
        occurredAt: DateTime(2026, 7, 18, 14),
        description: '聯絡冷氣行並完成現場檢查',
        contactOrVendor: '安心冷氣行',
        result: '風扇軸承磨損',
        cost: 500,
        partsOrItems: const ['室內機風扇軸承'],
        photoIdentifiers: const ['photo-1', 'photo-2'],
        waitingReason: '等待零件到貨',
        note: '預計三個工作天',
        nextAction: '零件到貨後安排更換',
        createdAt: DateTime(2026, 7, 18, 14, 5),
      );

      final decoded = WorkCaseUpdate.fromJson(update.toJson());

      expect(decoded.schemaVersion, WorkCaseUpdate.currentSchemaVersion);
      expect(decoded.id, update.id);
      expect(decoded.workCaseId, update.workCaseId);
      expect(decoded.occurredAt, update.occurredAt);
      expect(decoded.description, update.description);
      expect(decoded.contactOrVendor, '安心冷氣行');
      expect(decoded.result, '風扇軸承磨損');
      expect(decoded.cost, 500);
      expect(decoded.partsOrItems, ['室內機風扇軸承']);
      expect(decoded.photoIdentifiers, ['photo-1', 'photo-2']);
      expect(decoded.waitingReason, '等待零件到貨');
      expect(decoded.nextAction, '零件到貨後安排更換');
      expect(
        () => decoded.partsOrItems.add('不應修改'),
        throwsUnsupportedError,
      );
    });

    test('missing optional lists remain empty and numeric cost is normalized', () {
      final decoded = WorkCaseUpdate.fromJson({
        'id': 'update-legacy',
        'workCaseId': 'case-1',
        'occurredAt': '2026-07-18T15:00:00.000',
        'description': '補充處理狀態',
        'cost': 250.0,
        'createdAt': '2026-07-18T15:05:00.000',
      });

      expect(decoded.schemaVersion, WorkCaseUpdate.currentSchemaVersion);
      expect(decoded.cost, 250);
      expect(decoded.partsOrItems, isEmpty);
      expect(decoded.photoIdentifiers, isEmpty);
      expect(decoded.nextAction, isNull);
    });
  });
}
