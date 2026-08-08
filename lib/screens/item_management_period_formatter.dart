import '../models/item_custom_management_period.dart';
import '../models/item_management_period.dart';

String formatItemManagementPeriods({
  required Iterable<ItemManagementPeriod> fixed,
  required Iterable<ItemCustomManagementPeriod> custom,
  String emptyLabel = '尚未設定',
}) {
  final fixedPeriods = fixed.toList()
    ..sort((left, right) => left.index.compareTo(right.index));
  final customPeriods = custom.toList()
    ..sort((left, right) {
      final family = left.canonicalFamily.index.compareTo(
        right.canonicalFamily.index,
      );
      if (family != 0) return family;
      final value = left.canonicalValue.compareTo(right.canonicalValue);
      if (value != 0) return value;
      final unit = left.intervalUnit.index.compareTo(right.intervalUnit.index);
      if (unit != 0) return unit;
      return left.intervalValue.compareTo(right.intervalValue);
    });
  final labels = <String>[
    ...fixedPeriods.map(itemManagementPeriodLabel),
    ...customPeriods.map(itemCustomManagementPeriodLabel),
  ];
  return labels.isEmpty ? emptyLabel : labels.join('、');
}

String itemManagementPeriodLabel(ItemManagementPeriod value) => switch (value) {
  ItemManagementPeriod.year => '年',
  ItemManagementPeriod.halfYear => '半年',
  ItemManagementPeriod.quarter => '季',
  ItemManagementPeriod.month => '月',
  ItemManagementPeriod.week => '週',
  ItemManagementPeriod.day => '日',
};

String itemCustomManagementPeriodLabel(ItemCustomManagementPeriod value) =>
    '每 ${value.intervalValue} ${itemManagementIntervalUnitLabel(value.intervalUnit)}';

String itemManagementIntervalUnitLabel(ItemManagementIntervalUnit value) =>
    switch (value) {
      ItemManagementIntervalUnit.day => '天',
      ItemManagementIntervalUnit.week => '週',
      ItemManagementIntervalUnit.month => '月',
      ItemManagementIntervalUnit.quarter => '季',
      ItemManagementIntervalUnit.halfYear => '半年',
      ItemManagementIntervalUnit.year => '年',
    };
