import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_theme.dart';
import 'package:life_maintenance/app/ui_tokens.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/widgets/add_entry_card.dart';
import 'package:life_maintenance/widgets/history_record_card.dart';
import 'package:life_maintenance/widgets/product_item_card.dart';
import 'package:life_maintenance/widgets/ui_v2_components.dart';

void main() {
  test('UI v3 tokens match the approved visual foundation', () {
    expect(UiColors.canvas, const Color(0xFFFAF8F4));
    expect(UiColors.primary, const Color(0xFF173B63));
    expect(UiColors.accent, const Color(0xFF2F80ED));
    expect(UiColors.success, isNot(equals(UiColors.warning)));
    expect(UiColors.warning, isNot(equals(UiColors.danger)));
    expect(UiType.caption.fontSize, 12);
    expect(UiType.body.fontSize, 13);
    expect(UiType.button.fontSize, 13);
    expect(UiType.pageIntro.fontSize, 13);
    expect(UiType.cardTitle.fontSize, 14);
    expect(UiType.sectionTitle.fontSize, 15);
    expect(UiType.pageTitle.fontSize, 18);
    expect(AppTheme.light.appBarTheme.titleTextStyle?.fontSize, 17);
    expect(
      AppTheme.light.navigationBarTheme.labelTextStyle?.resolve({})?.fontSize,
      12,
    );
    expect(
      [UiSpace.xs, UiSpace.sm, UiSpace.md, UiSpace.lg, UiSpace.xl],
      const [8, 12, 16, 24, 32],
    );
    expect(UiRadius.control, 12);
    expect(UiRadius.card, 16);
    expect(UiMotion.quick.inMilliseconds, inInclusiveRange(120, 300));
    expect(UiMotion.standard.inMilliseconds, inInclusiveRange(120, 300));
    expect(UiMotion.emphasized.inMilliseconds, inInclusiveRange(120, 300));
  });

  testWidgets('UI v3 exposes every required common component', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(UiSpace.md),
            children: [
              const UiCompactPageHeader(
                title: '生活項目',
                description: '整理需要長期管理的生活內容。',
              ),
              const UiSurfaceCard(child: Text('卡片內容')),
              UiPrimaryButton(
                label: '主要操作',
                icon: Icons.check,
                onPressed: () {},
              ),
              const SizedBox(height: UiSpace.sm),
              UiSecondaryButton(
                label: '次要操作',
                icon: Icons.tune,
                onPressed: () {},
              ),
              const SizedBox(height: UiSpace.sm),
              UiFormField(controller: controller, label: '名稱', hint: '輸入名稱'),
              const SizedBox(height: UiSpace.sm),
              const Wrap(
                spacing: UiSpace.xs,
                children: [
                  UiStatusTag(label: '正常', tone: UiStatusTone.success),
                  UiStatusTag(label: '留意', tone: UiStatusTone.warning),
                ],
              ),
              const SizedBox(height: UiSpace.md),
              const UiStepIndicator(currentStep: 2, totalSteps: 3),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(UiCompactPageHeader), findsOneWidget);
    expect(find.byType(UiSurfaceCard), findsOneWidget);
    expect(find.byType(UiPrimaryButton), findsOneWidget);
    expect(find.byType(UiSecondaryButton), findsOneWidget);
    expect(find.byType(UiFormField), findsOneWidget);
    expect(find.byType(UiStatusTag), findsNWidgets(2));
    expect(find.byType(UiStepIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formal Shell removes the duplicate heavy header', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('生活管理'), findsNothing);
    expect(find.byType(UiBottomNavigation), findsOneWidget);
    final navigation = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('primary-navigation')),
    );
    expect(
      navigation.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      const ['生活總覽', '生活項目', '新增', '履歷', '設定'],
    );
  });

  testWidgets('Shell is safe at phone sizes, 200 percent text and SafeArea', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final scale in const [1.0, 1.5, 2.0, 3.2]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(428, 926),
      ]) {
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(
          left: 10,
          right: 10,
          bottom: 24,
        );
        final root = AppCompositionRoot(
          database: AppDatabase(NativeDatabase.memory()),
        );
        await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
        await tester.pumpAndSettle();

        final shellRect = tester.getRect(
          find.byKey(const ValueKey('app-shell')),
        );
        final navRect = tester.getRect(
          find.byKey(const ValueKey('primary-navigation')),
        );
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byKey(const ValueKey('app-shell'))),
          ).scale(1),
          scale,
          reason: '$size / $scale',
        );
        expect(shellRect.left, greaterThanOrEqualTo(0), reason: '$size');
        expect(navRect.left, greaterThanOrEqualTo(10), reason: '$size');
        expect(
          navRect.right,
          lessThanOrEqualTo(size.width - 10),
          reason: '$size',
        );
        expect(
          navRect.bottom,
          lessThanOrEqualTo(size.height - 24),
          reason: '$size',
        );

        for (final label in const ['生活項目', '新增', '履歷', '設定', '生活總覽']) {
          await tester.tap(
            find.descendant(
              of: find.byKey(const ValueKey('primary-navigation')),
              matching: find.text(label),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$size / $scale / $label',
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await root.database.close();
      }
    }
  });

  testWidgets(
    'content cards remain readable and operable at dynamic type sizes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final scale in const [1.0, 1.5, 2.0, 3.2]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        for (final size in const [
          Size(320, 568),
          Size(390, 844),
          Size(428, 926),
        ]) {
          tester.view.physicalSize = size;
          var itemTapped = false;
          var entryTapped = false;
          var historyTapped = false;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      ProductItemCard(
                        title: '測試冷氣與極長生活項目名稱',
                        categoryLabel: '家電',
                        statusLabel: '正常追蹤',
                        location: '客廳與主要生活空間',
                        dateLine: '建立日期：2026/08/02　購買日期：2020/01/15',
                        icon: Icons.ac_unit_outlined,
                        onTap: () => itemTapped = true,
                      ),
                      AddEntryCard(
                        icon: Icons.category_outlined,
                        title: '分類',
                        description: '用自己熟悉的名稱整理生活項目。',
                        onTap: () => entryTapped = true,
                      ),
                      HistoryRecordCard(
                        date: '2026/08/02',
                        title: '建立生活項目',
                        itemName: '測試冷氣與極長生活項目名稱',
                        recordType: '生活項目履歷',
                        description: '建立時的正式資料快照。',
                        result: '已建立',
                        costLabel: null,
                        photoLabel: null,
                        icon: Icons.history_rounded,
                        onTap: () => historyTapped = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final date = tester.widget<Text>(
            find.byKey(const ValueKey('product-item-date')),
          );
          expect(date.overflow, isNot(TextOverflow.ellipsis));
          expect(date.maxLines, isNull);
          expect(tester.takeException(), isNull, reason: '$size / $scale');

          final itemTitle = find.text('測試冷氣與極長生活項目名稱').first;
          await tester.ensureVisible(itemTitle);
          await tester.tap(itemTitle);
          final category = find.text('分類');
          await tester.ensureVisible(category);
          await tester.tap(category);
          final historyTitle = find.text('建立生活項目');
          await tester.ensureVisible(historyTitle);
          await tester.tap(historyTitle);
          expect(itemTapped, isTrue);
          expect(entryTapped, isTrue);
          expect(historyTapped, isTrue);
          expect(tester.takeException(), isNull, reason: '$size / $scale');
        }
      }
    },
  );

  testWidgets('Reduce Motion disables Shell and common motion components', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.byKey(const ValueKey('shell-tab-transition')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .every((animation) => animation.duration == Duration.zero),
      isTrue,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UiStepIndicator(currentStep: 1, totalSteps: 3)),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .every((animation) => animation.duration == Duration.zero),
      isTrue,
    );
  });
}
