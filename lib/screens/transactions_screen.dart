import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/year_month_selector.dart';

class TransactionsScreen extends StatefulWidget {
  final FinanceData data;
  final AppSettings settings;
  const TransactionsScreen({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filter = 0; // 0=all 1=income 2=expense

  static const _cardShadow = BoxShadow(
    color: Color(0x1F7C6FC4),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  List<Transaction> get _filtered {
    final base = widget.data.filteredTransactions;
    switch (_filter) {
      case 1:
        return base.where((t) => !t.isExpense).toList();
      case 2:
        return base.where((t) => t.isExpense).toList();
      default:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.data, widget.settings]),
      builder: (context, _) {
        final strings = AppStrings.of(widget.settings.langCode);
        final list = _filtered;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                strings.allTransactions,
                style: GoogleFonts.notoSansThai(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: YearMonthSelector(
                  data: widget.data, settings: widget.settings),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _filterChip(strings.filterAll, 0),
                  const SizedBox(width: 8),
                  _filterChip(strings.filterIncome, 1),
                  const SizedBox(width: 8),
                  _filterChip(strings.filterExpense, 2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📭',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            strings.noTransactions,
                            style: GoogleFonts.notoSansThai(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _dismissibleItem(list[i], strings),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, int value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _dismissibleItem(Transaction t, AppStrings strings) {
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.data.removeTransaction(t.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 22),
      ),
      child: _transactionItem(t, strings),
    );
  }

  Widget _transactionItem(Transaction t, AppStrings strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [_cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(t.icon,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(t.date,
                      langCode: widget.settings.langCode),
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${t.isExpense ? "- " : "+ "}${formatCurrency(t.amount)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: t.isExpense ? AppColors.expense : AppColors.income,
            ),
          ),
        ],
      ),
    );
  }
}
