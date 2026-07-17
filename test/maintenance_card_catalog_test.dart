import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/data/maintenance_card_catalog.dart';
import 'package:life_maintenance/models/enums.dart';

void main() {
  test('known card template binds to the real life item', () {
    final card = MaintenanceCardCatalog.resolve(
      cardId: 'card-aircon-filter-cleaning',
      itemId: 'real-item-42',
    );

    expect(card, isNotNull);
    expect(card!.itemId, 'real-item-42');
    expect(card.title, '冷氣濾網清洗');
    expect(card.type, MaintenanceType.cleaning);
    expect(card.riskLevel, RiskLevel.low);
    expect(card.estimatedMinutes, 20);
    expect(card.steps, hasLength(3));
  });

  test('different resolutions do not share a fake item association', () {
    final first = MaintenanceCardCatalog.resolve(
      cardId: 'card-scooter-tire-pressure',
      itemId: 'scooter-a',
    );
    final second = MaintenanceCardCatalog.resolve(
      cardId: 'card-scooter-tire-pressure',
      itemId: 'scooter-b',
    );

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first!.itemId, 'scooter-a');
    expect(second!.itemId, 'scooter-b');
  });

  test('unknown card id remains safely unresolved', () {
    final card = MaintenanceCardCatalog.resolve(
      cardId: 'unknown-card',
      itemId: 'real-item-42',
    );

    expect(card, isNull);
  });
}
