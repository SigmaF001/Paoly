import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/year_month_selector.dart';

class ReportsScreen extends StatelessWidget {
  final FinanceData data;
  final AppSettings settings;
  const ReportsScreen({
    super.key,
    required this.data,
    required this.settings,
  });

  static const _cardShadow = BoxShadow(
    color: Color(0x1F7C6FC4),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([data, settings]),
      builder: (context, _) {
        final strings = AppStrings.of(settings.langCode);
        final categoryTotals = <String, Map<String, dynamic>>{};
        for (final t
            in data.filteredTransactions.where((t) => t.isExpense)) {
          categoryTotals.putIfAbsent(
            t.category,
            () => {'icon': t.icon, 'name': t.category, 'total': 0.0},
          );
          categoryTotals[t.category]!['total'] =
              (categoryTotals[t.category]!['total'] as double) +
                  t.amount;
        }
        final categories = categoryTotals.values.toList()
          ..sort((a, b) =>
              (b['total'] as double).compareTo(a['total'] as double));
        final maxExpense = categories.isEmpty
            ? 1.0
            : (categories.first['total'] as double);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                strings.reportsTitle,
                style: GoogleFonts.notoSansThai(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              YearMonthSelector(data: data, settings: settings),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(strings.incomeSummary,
                        data.monthlyIncome, AppColors.income, '↑'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(strings.expenseSummary,
                        data.monthlyExpense, AppColors.expense, '↓'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _netCard(strings),
              const SizedBox(height: 24),
              Text(
                strings.byCategory,
                style: GoogleFonts.notoSansThai(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.noExpenses,
                      style: GoogleFonts.notoSansThai(
                          color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...categories.map((cat) => _categoryBar(cat, maxExpense)),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(
      String label, double amount, Color color, String arrow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$arrow  $label',
            style: GoogleFonts.notoSansThai(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(amount),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _netCard(AppStrings strings) {
    final net = data.monthlyIncome - data.monthlyExpense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.netCashFlow,
            style: GoogleFonts.notoSansThai(
                fontSize: 12, color: AppColors.lightPurple),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(net),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(Map<String, dynamic> cat, double maxExpense) {
    final total = cat['total'] as double;
    final ratio = maxExpense > 0 ? total / maxExpense : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [_cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(cat['icon'] as String,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                formatCurrency(total),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.lightPurple,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
