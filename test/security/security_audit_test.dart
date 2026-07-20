import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';

const _sqliteWasmSha256 =
    '41cf968998241465d8b1dfffb1eb60dd10c35de5022a3647e14174ea3af84143';

void main() {
  test(
    'SQLite Web binary is pinned and corrupted content is rejected',
    () async {
      final wasm = File('web/sqlite3.wasm');
      expect(wasm.existsSync(), isTrue);
      expect(
        sha256.convert(await wasm.readAsBytes()).toString(),
        _sqliteWasmSha256,
      );

      final accepted = await Process.run('python3', [
        '-c',
        'from tool.prepare_drift_web_assets import _verify_asset; '
            "_verify_asset(open('web/sqlite3.wasm', 'rb').read())",
      ]);
      expect(accepted.exitCode, 0, reason: '${accepted.stderr}');

      final rejected = await Process.run('python3', [
        '-c',
        'from tool.prepare_drift_web_assets import _verify_asset; '
            "_verify_asset(b'corrupt')",
      ]);
      expect(rejected.exitCode, isNot(0));
    },
  );

  test('GitHub workflows keep write and OIDC permissions deployment-only', () {
    final quality = File(
      '.github/workflows/flutter-quality.yml',
    ).readAsStringSync();
    expect(quality, contains('permissions:\n  contents: read'));
    expect(quality, isNot(contains('pages: write')));
    expect(quality, isNot(contains('id-token: write')));

    final pages = File('.github/workflows/deploy-pages.yml').readAsStringSync();
    expect(pages, contains('permissions:\n  contents: read'));
    final buildJob = pages.split('\n  build:').last.split('\n  deploy:').first;
    expect(buildJob, contains('contents: read'));
    expect(buildJob, contains('pages: read'));
    expect(buildJob, isNot(contains('pages: write')));
    expect(buildJob, isNot(contains('id-token: write')));
    final deployJob = pages.split('\n  deploy:').last;
    expect(deployJob, contains('permissions:\n      pages: write'));
    expect(deployJob, contains('id-token: write'));
  });

  test('release platform manifests request no undeclared sensitive access', () {
    final android = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(android, isNot(contains('<uses-permission')));

    final ios = File('ios/Runner/Info.plist').readAsStringSync();
    expect(ios, isNot(contains('UsageDescription')));

    final macos = File('macos/Runner/Release.entitlements').readAsStringSync();
    expect(macos, contains('com.apple.security.app-sandbox'));
    expect(macos, isNot(contains('com.apple.security.network.client')));
    expect(macos, isNot(contains('com.apple.security.network.server')));
    expect(macos, isNot(contains('com.apple.security.files.')));
  });

  test('production and delivery files contain no committed secret pattern', () {
    final patterns = <RegExp>[
      RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
      RegExp(r'\bghp_[A-Za-z0-9]{30,}\b'),
      RegExp(r'\bgithub_pat_[A-Za-z0-9_]{30,}\b'),
      RegExp(r'\bAKIA[0-9A-Z]{16}\b'),
      RegExp(r'\bAIza[0-9A-Za-z_-]{30,}\b'),
    ];
    final violations = <String>[];
    for (final file in _securityTextFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in patterns) {
        if (pattern.hasMatch(source)) {
          violations.add('${file.path}: ${pattern.pattern}');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('SQLite repositories bind hostile text without executing it', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repositories = DriftSchemaV2Repositories(database);
    addTearDown(database.close);
    final now = DateTime.utc(2026, 7, 20);
    const hostileId = "item'; DROP TABLE items; --";
    await repositories.itemCategories.save(
      ItemCategoryRow(
        id: 'category-security',
        systemCode: 'other',
        displayName: '安全稽核',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.items.save(
      ItemRow(
        id: hostileId,
        name: "名稱'); DELETE FROM item_categories; --",
        categoryId: 'category-security',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect((await repositories.items.findById(hostileId))?.id, hostileId);
    expect(await repositories.itemCategories.listAll(), hasLength(1));
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(tables.map((row) => row.read<String>('name')), contains('items'));
  });
}

Iterable<File> _securityTextFiles() sync* {
  for (final root in const ['lib', 'tool', '.github/workflows']) {
    yield* Directory(root)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => _textExtensions.any(file.path.endsWith));
  }
  for (final path in const [
    'android/app/src/main/AndroidManifest.xml',
    'ios/Runner/Info.plist',
    'macos/Runner/Release.entitlements',
  ]) {
    yield File(path);
  }
}

const _textExtensions = <String>[
  '.dart',
  '.py',
  '.yml',
  '.yaml',
  '.xml',
  '.plist',
  '.entitlements',
];
