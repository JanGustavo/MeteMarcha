import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/decimal_input_formatter.dart';

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool disabled;

  const _CircleButton({
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: disabled
                ? context.surfaceColor.withValues(alpha: 0.6)
                : context.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: context.divider),
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: disabled
                  ? context.onSurface.withValues(alpha: 0.5)
                  : AppColors.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutNumberField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final bool decimal;
  final double step;

  const WorkoutNumberField({
    super.key,
    required this.ctrl,
    required this.label,
    this.decimal = false,
    required this.step,
  });

  @override
  State<WorkoutNumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<WorkoutNumberField> {
  double _value = 0.0;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _parseValue();
    widget.ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.ctrl.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      final text = widget.ctrl.text.trim();
      if (text == '0' || text == '0.0' || text == '0,' || text == '0.00') {
        widget.ctrl.clear();
      }
    } else {
      if (widget.ctrl.text.trim().isEmpty) {
        widget.ctrl.text = '0';
      }
    }
  }

  void _onTextChanged() {
    setState(() => _parseValue());
  }

  void _parseValue() {
    final text = widget.ctrl.text.replaceAll(',', '.');
    _value = double.tryParse(text) ?? 0.0;
    if (_value < 0) _value = 0;
  }

  void _adjustValue(double delta) {
    final newVal = (_value + delta).clamp(0.0, double.infinity);
    double val = newVal;
    if (widget.decimal) {
      if (val % 1 == 0) {
        widget.ctrl.text = val.toInt().toString();
      } else {
        if ((val * 2) % 1 == 0) {
          widget.ctrl.text = val.toStringAsFixed(1);
        } else {
          widget.ctrl.text = val.toStringAsFixed(2);
        }
      }
    } else {
      widget.ctrl.text = val.toInt().toString();
    }
    setState(() => _parseValue());
  }

  @override
  Widget build(BuildContext context) {
    final minusDisabled = _value <= 0.0;
    return Row(
      children: [
        Tooltip(
          message: 'Diminuir',
          child: _CircleButton(
            icon: Icons.remove_rounded,
            onPressed: minusDisabled ? null : () => _adjustValue(-widget.step),
            size: 44,
            disabled: minusDisabled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.ctrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimal,
            ),
            inputFormatters: [DecimalInputFormatter()],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.onBackground,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: const TextStyle(fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Aumentar',
          child: _CircleButton(
            icon: Icons.add_rounded,
            onPressed: () => _adjustValue(widget.step),
            size: 44,
          ),
        ),
      ],
    );
  }
}
