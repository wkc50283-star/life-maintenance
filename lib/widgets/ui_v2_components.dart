import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';

class UiCompactPageHeader extends StatelessWidget {
  const UiCompactPageHeader({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: UiSpace.xs, bottom: UiSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: UiType.pageTitle),
        const SizedBox(height: UiSpace.xs),
        Text(description, style: UiType.pageIntro),
      ],
    ),
  );
}

class UiSurfaceCard extends StatelessWidget {
  const UiSurfaceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: UiColors.surface,
      borderRadius: BorderRadius.circular(UiRadius.card),
      border: Border.all(color: UiColors.border),
      boxShadow: UiShadow.card,
    ),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(UiSpace.md),
      child: child,
    ),
  );
}

class UiActionCard extends StatelessWidget {
  const UiActionCard({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: UiSpace.sm),
    child: UiPressFeedback(
      enabled: onTap != null,
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    ),
  );
}

class UiPrimaryButton extends StatelessWidget {
  const UiPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => UiPressFeedback(
    enabled: !loading && onPressed != null,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      ),
    ),
  );
}

class UiSecondaryButton extends StatelessWidget {
  const UiSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => UiPressFeedback(
    enabled: onPressed != null,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    ),
  );
}

class UiFormField extends StatelessWidget {
  const UiFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    validator: validator,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}

enum UiStatusTone { neutral, info, success, warning, danger }

class UiStatusTag extends StatelessWidget {
  const UiStatusTag({
    super.key,
    required this.label,
    this.tone = UiStatusTone.neutral,
  });

  final String label;
  final UiStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      UiStatusTone.neutral => (UiColors.textSupporting, UiColors.surfaceWarm),
      UiStatusTone.info => (UiColors.info, UiColors.infoSurface),
      UiStatusTone.success => (UiColors.success, UiColors.successSurface),
      UiStatusTone.warning => (UiColors.warning, UiColors.warningSurface),
      UiStatusTone.danger => (UiColors.danger, UiColors.dangerSurface),
    };
    return Semantics(
      label: '狀態：$label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(UiRadius.pill),
          border: Border.all(color: foreground.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UiSpace.sm,
            vertical: UiSpace.xs,
          ),
          child: Text(label, style: UiType.caption.copyWith(color: foreground)),
        ),
      ),
    );
  }
}

class UiStepIndicator extends StatelessWidget {
  const UiStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(totalSteps > 0),
       assert(currentStep > 0 && currentStep <= totalSteps);

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '第 $currentStep 步，共 $totalSteps 步',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var step = 1; step <= totalSteps; step++) ...[
              Expanded(
                child: AnimatedContainer(
                  height: UiSpace.xs,
                  duration: UiMotion.durationOf(context, UiMotion.standard),
                  curve: UiMotion.standardCurve,
                  decoration: BoxDecoration(
                    color: step <= currentStep
                        ? UiColors.accent
                        : UiColors.border,
                    borderRadius: BorderRadius.circular(UiRadius.control),
                  ),
                ),
              ),
              if (step != totalSteps) const SizedBox(width: UiSpace.xs),
            ],
          ],
        ),
        const SizedBox(height: UiSpace.xs),
        Text('第 $currentStep 步，共 $totalSteps 步', style: UiType.caption),
      ],
    ),
  );
}

class UiNavigationItem {
  const UiNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class UiBottomNavigation extends StatelessWidget {
  const UiBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
    this.navigationKey,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<UiNavigationItem> items;
  final Key? navigationKey;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: UiColors.surface,
      border: Border(top: BorderSide(color: UiColors.border)),
      boxShadow: UiShadow.navigation,
    ),
    child: SafeArea(
      top: false,
      child: NavigationBar(
        key: navigationKey,
        height: 68,
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    ),
  );
}

class UiMotionEntrance extends StatelessWidget {
  const UiMotionEntrance({
    super.key,
    required this.child,
    this.duration = UiMotion.standard,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = UiMotion.durationOf(context, duration);
    if (effectiveDuration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: effectiveDuration,
      curve: UiMotion.standardCurve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, UiSpace.sm * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class UiPressFeedback extends StatefulWidget {
  const UiPressFeedback({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<UiPressFeedback> createState() => _UiPressFeedbackState();
}

class _UiPressFeedbackState extends State<UiPressFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _setPressed(true),
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: UiMotion.durationOf(context, UiMotion.quick),
      curve: UiMotion.standardCurve,
      child: widget.child,
    ),
  );
}
