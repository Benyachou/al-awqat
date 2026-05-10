import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../core/constants.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

class PrayerRow extends StatefulWidget {
  const PrayerRow({
    super.key,
    required this.slot,
    required this.time,
    required this.isCurrent,
    required this.isNext,
    this.isFresh = false,
    this.isJumuah = false,
  });

  final PrayerSlot slot;
  final DateTime time;
  final bool isCurrent;
  final bool isNext;

  /// True when the prayer time was just reached (within the last 5 min).
  /// Triggers a blinking highlight to draw attention.
  final bool isFresh;

  /// When true and slot == dhuhr, display "Jumu'ah" instead of "Dhuhr".
  final bool isJumuah;

  @override
  State<PrayerRow> createState() => _PrayerRowState();
}

class _PrayerRowState extends State<PrayerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PrayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFresh != oldWidget.isFresh) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isFresh) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isJumuahSlot = widget.isJumuah && widget.slot == PrayerSlot.dhuhr;
    final french = isJumuahSlot
        ? 'Jumu\'ah'
        : PrayerNames.french[widget.slot.name]!;
    final arabic =
        isJumuahSlot ? 'الجمعة' : PrayerNames.arabic[widget.slot.name]!;
    final formatted = DateFormat('HH:mm').format(widget.time);

    final highlightColor = widget.isCurrent
        ? AppTheme.highlight
        : (widget.isNext ? AppTheme.accent : null);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = widget.isFresh ? _controller.value : 0.0;
        final blinkBg = widget.isFresh
            ? Color.lerp(
                AppTheme.highlight.withValues(alpha: 0.15),
                AppTheme.highlight.withValues(alpha: 0.5),
                pulse,
              )
            : null;
        final blinkBorder = widget.isFresh
            ? Color.lerp(
                AppTheme.highlight,
                Colors.white,
                pulse,
              )
            : null;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: blinkBg ??
                highlightColor?.withValues(alpha: 0.15) ??
                AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: (blinkBorder != null || highlightColor != null)
                ? Border.all(
                    color: blinkBorder ?? highlightColor!,
                    width: widget.isFresh ? 3 : 2,
                  )
                : null,
            boxShadow: widget.isFresh
                ? [
                    BoxShadow(
                      color: AppTheme.highlight
                          .withValues(alpha: 0.3 + 0.4 * pulse),
                      blurRadius: 16 + 12 * pulse,
                      spreadRadius: 1 + 2 * pulse,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  french,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: (widget.isCurrent || widget.isFresh)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: highlightColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formatted,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: highlightColor ?? AppTheme.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    arabic,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: (widget.isCurrent || widget.isFresh)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: highlightColor ?? AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
