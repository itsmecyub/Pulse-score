import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          style: AppText.meta.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          cursorColor: AppColors.green,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.meta.copyWith(fontSize: 15),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.7),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: BorderSide(
                color: AppColors.green.withValues(alpha: 0.7),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The ALL / LIVE / FAVORITES selector.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // The three chips need about 406pt at their natural size, which is wider
    // than an iPhone SE — and every translated label is longer than the
    // English one. Scrolling keeps the row intact at any width in any
    // language instead of overflowing it.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _Chip(
                label: labels[i],
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: AppText.sectionLabel.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF04210F) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
