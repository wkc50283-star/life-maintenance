import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_shell.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/repositories/formal_planning_editor.dart';

void main() {
  testWidgets('formal shell is safe at phone, tablet and desktop sizes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const viewports = <String, Size>{
      'small iPhone': Size(320, 568),
      'modern iPhone': Size(390, 844),
      'Android phone': Size(360, 800),
      'iPad portrait': Size(1024, 1366),
      'desktop web': Size(1366, 768),
    };

    for (final entry in viewports.entries) {
      tester.view.physicalSize = entry.value;
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget, reason: entry.key);
      for (final label in const ['生活項目', '新增', '史略', '設定', '生活總覽']) {
        final destination = find.descendant(
          of: find.byKey(const ValueKey('primary-navigation')),
          matching: find.text(label),
        );
        expect(destination, findsOneWidget, reason: '${entry.key}: $label');
        await tester.tap(destination);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key}: $label');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    }
  });

  testWidgets(
    'small phone keeps Unicode input and save reachable by keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final root = AppCompositionRoot(database: database);

      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('primary-navigation')),
          matching: find.text('新增'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('分類'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-entry')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('category-name')),
        '家中證件・跨平台',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('save-form')), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();
      expect(find.text('家中證件・跨平台'), findsOneWidget);
      expect(
        (await FormalPlanningEditor.from(
          root,
        )!.loadCategories()).single.customName,
        '家中證件・跨平台',
      );
    },
  );

  test('platform projects preserve the supported runtime contracts', () {
    final androidProperties = File(
      'android/gradle.properties',
    ).readAsStringSync();
    expect(androidProperties, contains('android.useAndroidX=true'));
    expect(androidProperties, contains('android.builtInKotlin=false'));
    expect(androidProperties, contains('android.newDsl=false'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('<key>UIApplicationSceneManifest</key>'));
    expect(iosInfo, contains('<string>FlutterSceneDelegate</string>'));
    expect(
      iosInfo,
      contains('<key>UISupportedInterfaceOrientations~ipad</key>'),
    );
    expect(File('ios/Podfile.lock').existsSync(), isTrue);

    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(iosProject, contains('FlutterGeneratedPluginSwiftPackage'));
    expect(iosProject, contains('TARGETED_DEVICE_FAMILY = "1,2"'));

    final webIndex = File('web/index.html').readAsStringSync();
    expect(webIndex, contains('width=device-width'));
    final databaseSource = File(
      'lib/database/app_database.dart',
    ).readAsStringSync();
    expect(databaseSource, contains("Uri.parse('sqlite3.wasm')"));
    expect(databaseSource, contains("Uri.parse('drift_worker.dart.js')"));

    final productionDart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(productionDart, isNot(contains("import 'dart:html'")));
    expect(productionDart, isNot(contains('window.localStorage')));
    expect(productionDart, isNot(contains('navigator.userAgent')));
  });
}
