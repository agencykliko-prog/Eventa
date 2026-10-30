import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Tout élément pressable se tasse légèrement (0.97) : l'interface
/// confirme qu'elle a entendu le doigt, sans effet d'encre.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap == null
              ? null
              : () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: Motion.press,
            curve: Motion.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
