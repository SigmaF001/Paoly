import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class YearMonthSelector extends StatelessWidget {
  final FinanceData data;
  final AppSettings settings;

  const YearMonthSelector({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(settings.langCode);
    final year = data.selectedYear;
    final month = data.selectedMonth;
    final months = strings.months;
    final isThai = settings.langCode == 'th';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => data.setYear(year - 1),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.chevron_left, color: AppColors.primary, size: 22),
              ),
            ),
            Text(
              isThai ? 'ปี ${year + 543}' : '$year',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => data.setYear(year + 1),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.chevron_right, color: AppColors.primary, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, index) {
              final selected = (index + 1) == month;
              return GestureDetector(
                onTap: () => data.setMonth(index + 1),
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    months[index],
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
