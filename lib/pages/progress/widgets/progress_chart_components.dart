import 'package:flutter/material.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProgressSectionLabel extends StatelessWidget {
  final String text;
  const ProgressSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.onSurface,
        fontSize: 10,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class ProgressEmptyChart extends StatelessWidget {
  final String msg;
  const ProgressEmptyChart({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.onSurface, height: 1.6),
        ),
      ),
    );
  }
}

class ProgressChartPlaceholder extends StatelessWidget {
  const ProgressChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Frequência Mensal ─────────────────────────────────────────────────────────
