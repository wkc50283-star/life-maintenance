import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/item_custom_management_period.dart';
import 'package:life_maintenance/models/item_management_period.dart';

void main() {
  ItemCustomManagementPeriod period(
    int value,
    ItemManagementIntervalUnit unit,
  ) => ItemCustomManagementPeriod(intervalValue: value, intervalUnit: unit);

  test('normalizes duration and calendar equivalence families separately', () {
    expect(
      period(14, ItemManagementIntervalUnit.day).equivalenceKey,
      period(2, ItemManagementIntervalUnit.week).equivalenceKey,
    );
    expect(
      period(3, ItemManagementIntervalUnit.month).equivalenceKey,
      period(1, ItemManagementIntervalUnit.quarter).equivalenceKey,
    );
    expect(
      period(6, ItemManagementIntervalUnit.month).equivalenceKey,
      period(2, ItemManagementIntervalUnit.quarter).equivalenceKey,
    );
    expect(
      period(6, ItemManagementIntervalUnit.month).equivalenceKey,
      period(1, ItemManagementIntervalUnit.halfYear).equivalenceKey,
    );
    expect(
      period(12, ItemManagementIntervalUnit.month).equivalenceKey,
      period(1, ItemManagementIntervalUnit.year).equivalenceKey,
    );
    expect(
      period(30, ItemManagementIntervalUnit.day).equivalenceKey,
      isNot(period(1, ItemManagementIntervalUnit.month).equivalenceKey),
    );
    expect(
      period(90, ItemManagementIntervalUnit.day).equivalenceKey,
      isNot(period(1, ItemManagementIntervalUnit.quarter).equivalenceKey),
    );
    expect(
      period(365, ItemManagementIntervalUnit.day).equivalenceKey,
      isNot(period(1, ItemManagementIntervalUnit.year).equivalenceKey),
    );
  });

  test('N equals one maps to the existing fixed enum', () {
    for (final unit in ItemManagementIntervalUnit.values) {
      expect(period(1, unit).fixedPeriod?.name, unit.name);
    }
    expect(period(2, ItemManagementIntervalUnit.day).fixedPeriod, isNull);
    expect(ItemManagementPeriod.values, hasLength(6));
  });

  test(
    'calendar addition clamps to the last valid day and respects leap year',
    () {
      expect(
        period(
          1,
          ItemManagementIntervalUnit.month,
        ).addTo(DateTime.utc(2025, 1, 31, 8, 30)),
        DateTime.utc(2025, 2, 28, 8, 30),
      );
      expect(
        period(
          1,
          ItemManagementIntervalUnit.month,
        ).addTo(DateTime.utc(2024, 1, 31)),
        DateTime.utc(2024, 2, 29),
      );
      expect(
        period(
          1,
          ItemManagementIntervalUnit.year,
        ).addTo(DateTime.utc(2024, 2, 29)),
        DateTime.utc(2025, 2, 28),
      );
      expect(
        period(
          1,
          ItemManagementIntervalUnit.quarter,
        ).addTo(DateTime.utc(2026, 1, 31)),
        DateTime.utc(2026, 4, 30),
      );
    },
  );

  test('invalid and unsafe values fail instead of truncating', () {
    expect(
      () => period(0, ItemManagementIntervalUnit.day),
      throwsArgumentError,
    );
    expect(
      () => period(-1, ItemManagementIntervalUnit.month),
      throwsArgumentError,
    );
    expect(
      () => period(
        ItemCustomManagementPeriod.maxStoredInteger,
        ItemManagementIntervalUnit.year,
      ),
      throwsArgumentError,
    );
    expect(
      () => period(
        ItemCustomManagementPeriod.maxStoredInteger,
        ItemManagementIntervalUnit.day,
      ).addTo(DateTime.utc(2026)),
      throwsRangeError,
    );
  });
}
