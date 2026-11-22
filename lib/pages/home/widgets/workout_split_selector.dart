import 'package:flutter/material.dart';

class WorkoutSplitSelector extends StatelessWidget {
  const WorkoutSplitSelector(
      {super.key,
      required this.name,
      required this.selected,
      required this.onSelect,
      required this.onOptions});
  final String name;
  final bool selected;
  final VoidCallback onSelect, onOptions;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
        color:
            selected ? colors.primary.withValues(alpha: .18) : colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSelect,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(name, overflow: TextOverflow.ellipsis)))),
          IconButton(
              tooltip: 'Opções de $name',
              onPressed: onOptions,
              icon: const Icon(Icons.more_horiz))
        ]));
  }
}
