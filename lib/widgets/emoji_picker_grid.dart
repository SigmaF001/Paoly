import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmojiPickerGrid extends StatelessWidget {
  final String selected;
  final List<String> emojis;
  final void Function(String) onSelect;

  const EmojiPickerGrid({
    super.key,
    required this.selected,
    required this.emojis,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.lightPurple,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
