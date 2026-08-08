import '../../models/item_custom_management_period.dart';
import '../../models/item_management_period.dart';
import '../repository_constraint_exception.dart';

NormalizedItemManagementPeriods normalizeItemManagementPeriods({
  required Iterable<ItemManagementPeriod> fixed,
  required Iterable<ItemCustomManagementPeriod> custom,
}) {
  final normalizedFixed = <ItemManagementPeriod>{...fixed};
  final normalizedCustom = <ItemCustomManagementPeriod>[];
  final seen = <String>{
    for (final period in normalizedFixed)
      itemManagementPeriodEquivalenceKey(period),
  };
  for (final period in custom) {
    if (!seen.add(period.equivalenceKey)) {
      throw RepositoryConstraintException(
        'Equivalent management period is already selected: '
        '${period.equivalenceKey}.',
      );
    }
    final fixedPeriod = period.fixedPeriod;
    if (fixedPeriod == null) {
      normalizedCustom.add(period);
    } else {
      normalizedFixed.add(fixedPeriod);
    }
  }
  return NormalizedItemManagementPeriods(
    Set.unmodifiable(normalizedFixed),
    List.unmodifiable(normalizedCustom),
  );
}

class NormalizedItemManagementPeriods {
  const NormalizedItemManagementPeriods(this.fixed, this.custom);

  final Set<ItemManagementPeriod> fixed;
  final List<ItemCustomManagementPeriod> custom;
}
