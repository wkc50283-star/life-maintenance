import 'package:flutter/material.dart';

import 'app/app_composition_root.dart';
import 'app/app_shell.dart';
import 'app/app_theme.dart';

void main() {
  runApp(const LifeMaintenanceApp());
}

class LifeMaintenanceApp extends StatefulWidget {
  const LifeMaintenanceApp({super.key, this.compositionRoot});

  final AppCompositionRoot? compositionRoot;

  @override
  State<LifeMaintenanceApp> createState() => _LifeMaintenanceAppState();
}

class _LifeMaintenanceAppState extends State<LifeMaintenanceApp> {
  late final AppCompositionRoot _compositionRoot =
      widget.compositionRoot ?? AppCompositionRoot.production();
  late final bool _ownsCompositionRoot = widget.compositionRoot == null;

  @override
  void dispose() {
    if (_ownsCompositionRoot) {
      _compositionRoot.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCompositionScope(
      root: _compositionRoot,
      child: MaterialApp(
        title: '生活管理',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AppShell(compositionRoot: _compositionRoot),
      ),
    );
  }
}
