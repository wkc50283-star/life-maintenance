import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';

void main() {
  group('legacy JSON compatibility', () {
    test('Item keeps legacy data when status or category is unknown', () {
      final item = Item.fromJson({
        'id': 'item-1',
        'name': '舊冷氣',
        'category': 'legacyCategory',
        'createdAt': '2025-01-01T00:00:00.000',
      });

      expect(item.category, ItemCategory.other);
      expect(item.status, ItemStatus.active);
    });

    test('Schedule accepts legacy enabled flag and missing strict mode', () {
      final schedule = Schedule.fromJson({
        'id': 'schedule-1',
        'itemId': 'item-1',
        'cardId': 'card-1',
        'cycleType': 'monthly',
        'interval': 1,
        'startDate': '2025-01-01T00:00:00.000',
        'nextDueDate': '2025-02-01T00:00:00.000',
        'enabled': false,
      });

      expect(schedule.status, ScheduleStatus.ended);
      expect(schedule.strictPeriodMode, isFalse);
    });

    test('Schedule preserves unknown cycle values as custom', () {
      final schedule = Schedule.fromJson({
        'id': 'schedule-2',
        'itemId': 'item-1',
        'cardId': 'card-1',
        'cycleType': 'legacyCycle',
        'interval': 1,
        'startDate': '2025-01-01T00:00:00.000',
        'nextDueDate': '2025-02-01T00:00:00.000',
      });

      expect(schedule.cycleType, CycleType.custom);
      expect(schedule.status, ScheduleStatus.active);
    });

    test('Task tolerates missing legacy links, status, and overdue flag', () {
      final task = Task.fromJson({
        'id': 'task-1',
        'itemId': 'item-1',
        'title': '一般提醒',
        'dueDate': '2025-02-01T00:00:00.000',
      });

      expect(task.cardId, isEmpty);
      expect(task.scheduleId, isEmpty);
      expect(task.status, TaskStatus.pending);
      expect(task.overdue, isFalse);
    });

    test('MaintenanceRecord defaults missing lists and createdAt safely', () {
      final record = MaintenanceRecord.fromJson({
        'id': 'record-1',
        'itemId': 'item-1',
        'recordType': 'legacyRecordType',
        'date': '2025-02-01T00:00:00.000',
        'title': '舊維修紀錄',
      });

      expect(record.recordType, RecordType.other);
      expect(record.partsChanged, isEmpty);
      expect(record.photos, isEmpty);
      expect(record.createdAt, record.date);
    });
  });
}
