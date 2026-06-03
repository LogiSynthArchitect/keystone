import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/ks_colors.dart';
import '../theme/app_text_styles.dart';
import 'ks_numpad_key.dart';

/// Shared numeric keypad with 6-dot indicator and shake-on-error animation.
///
/// Used by: PinSetupScreen, PinEntryScreen, LockOverlay.
/// Fires [onCompleted] with the full PIN when length reaches 6.
/// Fires [onChanged] with the current partial PIN on each digit/delete.
///
/// To control shake/clear externally, pass [onReady] to receive a
/// [KsNumpadControls] instance:
/// ```dart
/// KsNumpadControls? _controls;
/// KsNumpad(onReady: (c) => _controls = c, onCompleted: ...)
/// // then: _controls?.shakeAndClear()
/// ```
class KsNumpad extends StatefulWidget {
  final int pinLength;
  final String? title;
  final String? subtitle;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final ValueChanged<KsNumpadControls>? onReady;
  final bool hasError;

  const KsNumpad({
    super.key,
    this.pinLength = 6,
    this.title,
    this.subtitle,
    required this.onCompleted,
    this.onChanged,
    this.onReady,
    this.hasError = false,
  });

  @override
  State<KsNumpad> createState() => _KsNumpadState();
}

/// Public controls for [KsNumpad] — allows parent widgets to trigger
/// shake/clear actions without coupling to the private state type.
class KsNumpadControls {
  final void Function() _shakeAndClear;
  final void Function() _clear;

  KsNumpadControls(this._shakeAndClear, this._clear);

  void shakeAndClear() => _shakeAndClear();
  void clear() => _clear();
}

class _KsNumpadState extends State<KsNumpad>
    with SingleTickerProviderStateMixin {
  final _pin = StringBuffer();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String get _currentPin => _pin.toString();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: 400.ms,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(_shakeController);
    widget.onReady?.call(KsNumpadControls(shakeAndClear, clear));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin.write(digit));
    widget.onChanged?.call(_currentPin);
    if (_pin.length == widget.pinLength) {
      widget.onCompleted(_currentPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      final str = _pin.toString();
      _pin.clear();
      _pin.write(str.substring(0, str.length - 1));
    });
    widget.onChanged?.call(_currentPin);
  }

  /// Triggers the shake animation and clears PIN after.
  void shakeAndClear() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
      if (mounted) {
        setState(() {
          _pin.clear();
          widget.onChanged?.call('');
        });
      }
    });
  }

  /// Clears without animation.
  void clear() {
    setState(() {
      _pin.clear();
      widget.onChanged?.call('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.title!,
                style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          // Subtitle
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                widget.subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.ksc.neutral400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (i) {
              final filled = i < _pin.length;
              final colorFilled = widget.hasError
                  ? context.ksc.error500
                  : context.ksc.accent500;
              final borderColor = widget.hasError
                  ? context.ksc.error500
                  : context.ksc.neutral500.withValues(alpha: 0.5);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? colorFilled
                      : context.ksc.neutral600,
                  border: filled
                      ? (widget.hasError
                          ? Border.all(color: context.ksc.error500, width: 2)
                          : null)
                      : Border.all(color: borderColor),
                ),
                child: filled && !widget.hasError
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : null,
              ).animate().scale(
                    duration: 150.ms,
                    begin: filled ? const Offset(0.5, 0.5) : const Offset(1, 1),
                    end: const Offset(1, 1),
                  );
            }),
          ),
          const SizedBox(height: 24),
          // Numpad — edge-to-edge connected grid with thin line separators
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.ksc.primary600.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConnectedGridRow('1', '2', '3', onDigit: _onDigit, onDelete: _onDelete),
                  _gridDivider(context),
                  _ConnectedGridRow('4', '5', '6', onDigit: _onDigit, onDelete: _onDelete),
                  _gridDivider(context),
                  _ConnectedGridRow('7', '8', '9', onDigit: _onDigit, onDelete: _onDelete),
                  _gridDivider(context),
                  _ConnectedGridRow('', '0', '', onDigit: _onDigit, onDelete: _onDelete,
                      isLastRow: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedGridRow extends StatelessWidget {
  final String leftKey;
  final String middleKey;
  final String rightKey;
  final bool isLastRow;
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _ConnectedGridRow(this.leftKey, this.middleKey, this.rightKey,
      {required this.onDigit, required this.onDelete, this.isLastRow = false});

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.ksc.primary600.withValues(alpha: 0.4);
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          Expanded(
            child: leftKey.isEmpty
                ? Container(height: 68, color: context.ksc.primary800)
                : KsNumpadKey(label: leftKey, onTap: () => onDigit(leftKey)),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: KsNumpadKey(label: middleKey, onTap: () => onDigit(middleKey)),
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: isLastRow
                ? KsNumpadKey(icon: Icons.backspace_outlined, onTap: onDelete)
                : rightKey.isEmpty
                    ? Container(height: 68, color: context.ksc.primary800)
                    : KsNumpadKey(label: rightKey, onTap: () => onDigit(rightKey)),
          ),
        ],
      ),
    );
  }
}

Widget _gridDivider(BuildContext context) {
  return Container(
    height: 1,
    color: context.ksc.primary600.withValues(alpha: 0.4),
  );
}
