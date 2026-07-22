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
      height: 54,
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
          offset: Offset(0, 10 * (1 - value)),
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
