import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/sasta_theme.dart';
import '../theme/sasta_tokens.dart';
import 'sasta_mascot.dart';

class SastaBackButton extends StatelessWidget {
  const SastaBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: palette.iconButtonBg,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: SastaSizes.iconButton,
            height: SastaSizes.iconButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.iconButtonBg,
              boxShadow: SastaShadows.float(context),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 26,
              color: palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class SastaCircleIconButton extends StatelessWidget {
  const SastaCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badgeCount;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Container(
                width: SastaSizes.iconButton,
                height: SastaSizes.iconButton,
                decoration: BoxDecoration(
                  color: palette.iconButtonBg,
                  shape: BoxShape.circle,
                  boxShadow: SastaShadows.float(context),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor ?? palette.ink,
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: SastaColors.unreadCoral,
                  shape: badgeCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      badgeCount < 10 ? null : BorderRadius.circular(10),
                  border: Border.all(color: palette.screen, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SastaHeaderBar extends StatelessWidget {
  const SastaHeaderBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SastaSizes.iconButton,
      child: Row(
        children: [
          if (showBack)
            SastaBackButton(onPressed: onBack)
          else
            const SizedBox(width: SastaSizes.iconButton),
          Expanded(
            child: title != null
                ? Text(
                    title!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SastaText.body(
                      context,
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          trailing ?? const SizedBox(width: SastaSizes.iconButton),
        ],
      ),
    );
  }
}

/// Primary pill CTA with subtle periodic light sheen.
class SastaPrimaryButton extends StatefulWidget {
  const SastaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
    this.height = SastaSizes.button,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? width;

  @override
  State<SastaPrimaryButton> createState() => _SastaPrimaryButtonState();
}

class _SastaPrimaryButtonState extends State<SastaPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bg = widget.backgroundColor ?? palette.primaryCtaBg;
    final fg = widget.foregroundColor ?? palette.primaryCtaFg;

    return AnimatedOpacity(
      duration: SastaMotion.fast,
      opacity: widget.onPressed == null ? 0.55 : 1,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: widget.onPressed != null ? SastaShadows.cta(context) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!disabled && widget.onPressed != null)
              AnimatedBuilder(
                animation: _sheen,
                builder: (context, _) {
                  // Sweep during first 45% of 3.4s cycle
                  final t = (_sheen.value / 0.45).clamp(0.0, 1.0);
                  if (_sheen.value > 0.45) return const SizedBox.shrink();
                  return FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Align(
                      alignment: Alignment(-1.6 + t * 3.2, 0),
                      child: Transform.rotate(
                        angle: 0.25,
                        child: Container(
                          width: 48,
                          height: widget.height * 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SastaText.body(
                              context,
                              size: 16,
                              weight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SastaOutlineButton extends StatelessWidget {
  const SastaOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.height = SastaSizes.button,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double height;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final fg = textColor ?? palette.ink;
    final border = borderColor ?? palette.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: border, width: 2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SastaText.body(
                    context,
                    size: 16,
                    weight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SastaSearchPill extends StatelessWidget {
  const SastaSearchPill({
    super.key,
    this.hintText = 'Search groceries, brands, products…',
    this.controller,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onMicTap,
    this.readOnly = false,
    this.autofocus = false,
    this.showClear = false,
    this.showMic = true,
  });

  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onMicTap;
  final bool readOnly;
  final bool autofocus;
  final bool showClear;
  final bool showMic;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final decoration = BoxDecoration(
      color: palette.field,
      borderRadius: BorderRadius.circular(SastaRadius.pill),
    );

    if (readOnly && controller == null) {
      return Semantics(
        button: true,
        label: hintText,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SastaRadius.pill),
            child: Container(
              height: SastaSizes.input,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: decoration,
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 22, color: palette.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SastaText.body(
                        context,
                        size: 15,
                        weight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  if (showMic) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.mic_none_rounded, size: 21, color: palette.muted),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: SastaSizes.input,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: decoration,
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: palette.muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: SastaText.body(
                context,
                size: 16,
                weight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: SastaText.body(
                  context,
                  size: 15,
                  weight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
            ),
          ),
          if (showClear)
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, size: 20, color: palette.muted),
              tooltip: 'Clear search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (showMic)
            IconButton(
              onPressed: onMicTap ??
                  () => showSastaToast(
                        context,
                        'Voice search works best on mobile microphone permission.',
                      ),
              icon: Icon(Icons.mic_none_rounded, size: 21, color: palette.muted),
              tooltip: 'Voice search',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

class SastaChip extends StatelessWidget {
  const SastaChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.backgroundColor,
    this.height = SastaSizes.chipMin,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final bg = selected
        ? palette.primaryCtaBg
        : (backgroundColor ?? palette.field);
    final fg = selected ? palette.primaryCtaFg : palette.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: AnimatedContainer(
          duration: SastaMotion.fast,
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 16),
                  child: leading!,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SastaText.body(
                    context,
                    size: 13,
                    weight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SastaTag extends StatelessWidget {
  const SastaTag({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.leading,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(SastaRadius.tag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SastaText.body(
                context,
                size: 11,
                weight: FontWeight.w700,
                color: textColor,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SastaCard extends StatelessWidget {
  const SastaCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = SastaRadius.card,
    this.shadow = true,
    this.border,
    this.dashedBorderColor,
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool shadow;
  final BoxBorder? border;
  final Color? dashedBorderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? palette.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadow && gradient == null && color == null
            ? SastaShadows.card(context)
            : (shadow && gradient != null ? SastaShadows.card(context) : null),
      ),
      child: child,
    );

    if (dashedBorderColor != null) {
      content = CustomPaint(
        painter: _DashedBorderPainter(
          color: dashedBorderColor!,
          radius: borderRadius,
        ),
        child: content,
      );
    }

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dashLen = 7.0;
    const gapLen = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class SastaSwitch extends StatelessWidget {
  const SastaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Semantics(
      toggled: value,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: AnimatedContainer(
            duration: SastaMotion.fast,
            width: SastaSizes.toggleW,
            height: SastaSizes.toggleH,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value
                  ? palette.primaryCtaBg
                  : (palette.isDark ? palette.divider : const Color(0xFFE0DCEB)),
              borderRadius: BorderRadius.circular(SastaSizes.toggleH / 2),
            ),
            child: AnimatedAlign(
              duration: SastaMotion.fast,
              curve: SastaMotion.curve,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? palette.primaryCtaFg : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SastaStepper extends StatelessWidget {
  const SastaStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    Widget roundBtn(IconData icon, String label, VoidCallback onTap) {
      return Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: SastaSizes.stepper,
            height: SastaSizes.stepper,
            decoration: BoxDecoration(
              color: palette.iconButtonBg,
              shape: BoxShape.circle,
              boxShadow: SastaShadows.float(context),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: palette.ink),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          roundBtn(Icons.remove_rounded, 'Decrease quantity', onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: SastaText.body(
                context,
                size: 15,
                weight: FontWeight.w800,
                tabular: true,
              ),
            ),
          ),
          roundBtn(Icons.add_rounded, 'Increase quantity', onIncrement),
        ],
      ),
    );
  }
}

class PriceGradientText extends StatelessWidget {
  const PriceGradientText(
    this.text, {
    super.key,
    this.size = 44,
    this.weight = FontWeight.w800,
  });

  final String text;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: SastaColors.priceGradient,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: SastaText.display(
          context,
          size: size,
          weight: weight,
          color: Colors.white,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class RetailerAvatar extends StatelessWidget {
  const RetailerAvatar({
    super.key,
    required this.retailer,
    this.size = 24,
    this.showBorder = false,
    this.expression = MascotExpression.happy,
  });

  final RetailerId retailer;
  final double size;
  final bool showBorder;
  final MascotExpression expression;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: retailer.color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: palette.surface, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: SastaMascot(
        size: size * 0.88,
        color: retailer.color,
        expression: expression,
      ),
    );
  }
}

class OverlappingRetailerAvatars extends StatelessWidget {
  const OverlappingRetailerAvatars({
    super.key,
    required this.retailers,
    this.avatarSize = 24,
  });

  final List<RetailerId> retailers;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    if (retailers.isEmpty) return const SizedBox.shrink();
    final step = avatarSize - 7;
    final totalW = avatarSize + (retailers.length - 1) * step;
    return SizedBox(
      width: totalW,
      height: avatarSize,
      child: Stack(
        children: [
          for (var i = 0; i < retailers.length; i++)
            Positioned(
              left: i * step,
              child: RetailerAvatar(
                retailer: retailers[i],
                size: avatarSize,
                showBorder: true,
              ),
            ),
        ],
      ),
    );
  }
}

class SastaListRow extends StatelessWidget {
  const SastaListRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.badgeBackground,
    required this.badgeForeground,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color badgeBackground;
  final Color badgeForeground;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: SastaSizes.listRowMin),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(SastaRadius.iconBadge),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 21, color: badgeForeground),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: SastaText.body(
                      context,
                      size: 15,
                      weight: FontWeight.w700,
                      color: titleColor ?? palette.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: SastaText.muted(context, size: 13),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              Icon(Icons.chevron_right_rounded, size: 22, color: palette.ink),
          ],
        ),
      ),
    );
  }
}

/// Floating pill bottom navigation bar rendered on the 4 top-level tabs only.
class SastaBottomNav extends StatelessWidget {
  const SastaBottomNav({
    super.key,
    required this.activeIndex,
    required this.onSelect,
    this.basketCount = 0,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;
  final int basketCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.shopping_cart_outlined, label: 'Basket'),
      (icon: Icons.favorite_border_rounded, label: 'Saved'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      height: SastaSizes.navHeight,
      margin: const EdgeInsets.fromLTRB(
        SastaSpace.page,
        0,
        SastaSpace.page,
        20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.navSurface,
        borderRadius: BorderRadius.circular(SastaRadius.nav),
        boxShadow: SastaShadows.nav(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = i == activeIndex;
          final item = items[i];
          return Semantics(
            selected: isSelected,
            button: true,
            label: item.label,
            child: InkWell(
              onTap: () => onSelect(i),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: SastaMotion.fast,
                width: SastaSizes.navItem,
                height: SastaSizes.navItem,
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.primaryCtaBg
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      i == 2 && isSelected
                          ? Icons.favorite_rounded
                          : (i == 3 && isSelected
                              ? Icons.person_rounded
                              : (i == 1 && isSelected
                                  ? Icons.shopping_cart_rounded
                                  : item.icon)),
                      size: 24,
                      color: isSelected
                          ? palette.primaryCtaFg
                          : palette.muted,
                    ),
                    if (i == 1 && basketCount > 0 && !isSelected)
                      Positioned(
                        right: 9,
                        top: 9,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: SastaColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.navSurface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dark floating compare action bar hovering above BottomNav on Smart Basket.
class BasketFloatingBar extends StatelessWidget {
  const BasketFloatingBar({
    super.key,
    required this.productCount,
    required this.estimateTotal,
    required this.onCompare,
  });

  final int productCount;
  final int estimateTotal;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(SastaSpace.page, 0, SastaSpace.page, 10),
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: BoxDecoration(
        color: SastaColors.ink,
        borderRadius: BorderRadius.circular(32),
        boxShadow: SastaShadows.cta(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$productCount products · estimate',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                Text(
                  '~₹$estimateTotal',
                  style: SastaText.display(
                    context,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: SastaColors.gold,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onCompare,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                child: Text(
                  'Compare basket',
                  style: SastaText.body(
                    context,
                    size: 14,
                    weight: FontWeight.w800,
                    color: SastaColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showSastaToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final palette = context.sasta;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        backgroundColor: palette.primaryCtaBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(milliseconds: 2200),
        content: Text(
          message,
          style: SastaText.body(
            context,
            size: 14,
            weight: FontWeight.w600,
            color: palette.primaryCtaFg,
          ),
        ),
      ),
    );
}
