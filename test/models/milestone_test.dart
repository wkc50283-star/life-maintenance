import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';

void main() {
  group('Milestone', () {
    test('round trips a sixth-year major service milestone', () {
      final milestone = Milestone(
        id: 'milestone-major-6y',
        itemId: 'item-aircon',
        title: '第六年全面檢查與大修評估',
        description: '使用滿六年後安排專業人員進行全面檢查。',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.usageYears,
        sourcePlanId: 'plan-aircon-service',
        thresholdValue: 6,
        thresholdUnit: 'years',
        status: MilestoneStatus.pending,
        createdAt: DateTime(2026, 7, 18, 8),
        updatedAt: DateTime(2026, 7, 18, 8),
      );

      final decoded = Milestone.fromJson(milestone.toJson());

      expect(decoded.schemaVersion, Milestone.currentSchemaVersion);
      expect(decoded.id, milestone.id);
      expect(decoded.itemId, milestone.itemId);
      expect(decoded.kind, MilestoneKind.majorService);
      expect(decoded.triggerType, MilestoneTriggerType.usageYears);
      expect(decoded.sourcePlanId, 'plan-aircon-service');
      expect(decoded.thresholdValue, 6);
      expect(decoded.thresholdUnit, 'years');
      expect(decoded.hasCompleteTriggerDefinition, isTrue);
      expect(decoded.isReached, isFalse);
      expect(decoded.isClosed, isFalse);
    });

    test('supports mileage, completion-count and anomaly triggers', () {
      final now = DateTime(2026, 7, 18);
      final mileage = Milestone(
        id: 'mileage',
        itemId: 'scooter',
        title: '兩萬公里大保養',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.mileage,
        thresholdValue: 20000,
        thresholdUnit: 'km',
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final count = mileage.copyWith(
        id: 'count',
        title: '完成十二次後深度檢查',
        triggerType: MilestoneTriggerType.completionCount,
        thresholdValue: 12.0,
        thresholdUnit: 'times',
      );
      final anomaly = mileage.copyWith(
        id: 'anomaly',
        title: '異常累積三次後評估汰換',
        triggerType: MilestoneTriggerType.anomalyCount,
        thresholdValue: 3.0,
        thresholdUnit: 'events',
      );

      expect(mileage.hasCompleteTriggerDefinition, isTrue);
      expect(count.hasCompleteTriggerDefinition, isTrue);
      expect(anomaly.hasCompleteTriggerDefinition, isTrue);
    });

    test('supports date, dependency, life-stage and manual triggers', () {
      final now = DateTime(2026, 7, 18);
      final date = Milestone(
        id: 'date',
        itemId: 'document',
        title: '換發前完整檢查',
        kind: MilestoneKind.renewal,
        triggerType: MilestoneTriggerType.specificDate,
        triggerDate: DateTime(2030, 1, 1),
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final dependency = date.copyWith(
        id: 'dependency',
        triggerType: MilestoneTriggerType.dependencyCompleted,
        triggerDate: null,
        dependencyMilestoneId: 'milestone-before-this',
      );
      final lifeStage = date.copyWith(
        id: 'life-stage',
        triggerType: MilestoneTriggerType.lifeStage,
        triggerDate: null,
        lifeStageCode: 'retirement-preparation',
      );
      final manual = date.copyWith(
        id: 'manual',
        triggerType: MilestoneTriggerType.manual,
        triggerDate: null,
      );

      expect(date.hasCompleteTriggerDefinition, isTrue);
      expect(dependency.hasCompleteTriggerDefinition, isTrue);
      expect(lifeStage.hasCompleteTriggerDefinition, isTrue);
      expect(manual.hasCompleteTriggerDefinition, isTrue);
    });

    test('rejects incomplete trigger definitions without throwing', () {
      final now = DateTime(2026, 7, 18);
      final missingUnit = Milestone(
        id: 'incomplete',
        itemId: 'item-1',
        title: '未完成條件',
        kind: MilestoneKind.custom,
        triggerType: MilestoneTriggerType.usageValue,
        thresholdValue: 100,
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final missingDate = missingUnit.copyWith(
        triggerType: MilestoneTriggerType.specificDate,
        thresholdValue: null,
      );
      final unknown = missingUnit.copyWith(
        triggerType: MilestoneTriggerType.unknown,
        thresholdValue: null,
      );

      expect(missingUnit.hasCompleteTriggerDefinition, isFalse);
      expect(missingDate.hasCompleteTriggerDefinition, isFalse);
      expect(unknown.hasCompleteTriggerDefinition, isFalse);
    });

    test('unknown enums and missing optional fields use safe fallbacks', () {
      final createdAt = DateTime(2026, 7, 18, 9);
      final decoded = Milestone.fromJson({
        'id': 'legacy-milestone',
        'itemId': 'item-1',
        'title': '未來格式階段性重點',
        'kind': 'futureKind',
        'triggerType': 'futureTrigger',
        'status': 'futureStatus',
        'createdAt': createdAt.toIso8601String(),
      });

      expect(decoded.schemaVersion, Milestone.currentSchemaVersion);
      expect(decoded.kind, MilestoneKind.custom);
      expect(decoded.triggerType, MilestoneTriggerType.unknown);
      expect(decoded.status, MilestoneStatus.pending);
      expect(decoded.updatedAt, createdAt);
      expect(decoded.hasCompleteTriggerDefinition, isFalse);
      expect(decoded.workCaseId, isNull);
    });

    test('reached milestone can link to a work case and preserve timestamps', () {
      final createdAt = DateTime(2026, 7, 18, 8);
      final reachedAt = DateTime(2032, 7, 18, 8);
      final startedAt = DateTime(2032, 7, 20, 10);
      final milestone = Milestone(
        id: 'major-service',
        itemId: 'item-aircon',
        title: '第六年大修',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.usageYears,
        thresholdValue: 6,
        thresholdUnit: 'years',
        status: MilestoneStatus.inProgress,
        createdAt: createdAt,
        updatedAt: startedAt,
        reachedAt: reachedAt,
        acknowledgedAt: reachedAt,
        startedAt: startedAt,
        workCaseId: 'case-major-service',
      );

      final decoded = Milestone.fromJson(milestone.toJson());

      expect(decoded.isReached, isTrue);
      expect(decoded.isClosed, isFalse);
      expect(decoded.reachedAt, reachedAt);
      expect(decoded.startedAt, startedAt);
      expect(decoded.workCaseId, 'case-major-service');
    });

    test('completed and canceled milestones are closed', () {
      final now = DateTime(2026, 7, 18);
      final completed = Milestone(
        id: 'completed',
        itemId: 'item-1',
        title: '已完成大修',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.completed,
        createdAt: now,
        updatedAt: now,
        completedAt: now,
      );
      final canceled = completed.copyWith(
        id: 'canceled',
        title: '取消汰換評估',
        status: MilestoneStatus.canceled,
        completedAt: null,
        canceledAt: now,
        cancellationReason: '使用者決定延後並持續觀察',
      );

      expect(completed.isClosed, isTrue);
      expect(canceled.isClosed, isTrue);
      expect(canceled.cancellationReason, isNotEmpty);
    });

    test('copyWith can explicitly clear optional trigger and case fields', () {
      final now = DateTime(2026, 7, 18);
      final original = Milestone(
        id: 'clearable',
        itemId: 'item-1',
        title: '可重新設定的階段性重點',
        kind: MilestoneKind.custom,
        triggerType: MilestoneTriggerType.specificDate,
        triggerDate: DateTime(2027, 1, 1),
        status: MilestoneStatus.inProgress,
        createdAt: now,
        updatedAt: now,
        workCaseId: 'case-1',
      );

      final cleared = original.copyWith(
        triggerType: MilestoneTriggerType.manual,
        triggerDate: null,
        workCaseId: null,
      );

      expect(cleared.triggerType, MilestoneTriggerType.manual);
      expect(cleared.triggerDate, isNull);
      expect(cleared.workCaseId, isNull);
      expect(cleared.hasCompleteTriggerDefinition, isTrue);
    });
  });
}
