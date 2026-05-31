import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/year_month_selector.dart';
import 'accounts_screen.dart';
import 'pet_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

// ── Shell ──────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final FinanceData data;
  final AppSettings settings;
  const DashboardScreen({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // nav positions: 0=Home 1=Transactions 2=FAB(no page) 3=Reports 4=Accounts
  int _selectedNavIndex = 0;

  // maps nav positions to IndexedStack page index (skip position 2)
  int get _pageIndex =>
      _selectedNavIndex > 2 ? _selectedNavIndex - 1 : _selectedNavIndex;

  void _onNavTap(int i) {
    if (i == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            AddTransactionSheet(data: widget.data, settings: widget.settings),
      );
    } else {
      setState(() => _selectedNavIndex = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _pageIndex,
                children: [
                  _HomeTab(
                    data: widget.data,
                    settings: widget.settings,
                    onNavigate: (i) => setState(() => _selectedNavIndex = i),
                  ),
                  TransactionsScreen(
                    data: widget.data,
                    settings: widget.settings,
                  ),
                  ReportsScreen(data: widget.data, settings: widget.settings),
                  AccountsScreen(data: widget.data, settings: widget.settings),
                  const PetScreen(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final strings = AppStrings.of(widget.settings.langCode);
    final items = [
      {'icon': '🏠', 'label': strings.navHome},
      {'icon': '📋', 'label': strings.navTransactions},
      null,
      {'icon': '📊', 'label': strings.navReports},
      {'icon': '👛', 'label': strings.navAccounts},
      {'icon': '🐶', 'label': 'น้องหมา'},
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F7C6FC4),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;

          if (item == null) {
            return GestureDetector(
              onTap: () => _onNavTap(i),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            );
          }

          final selected = i == _selectedNavIndex;
          return GestureDetector(
            onTap: () => _onNavTap(i),
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: selected
                  ? BoxDecoration(
                      color: AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(14),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Home Tab ───────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final FinanceData data;
  final AppSettings settings;
  final void Function(int) onNavigate;

  const _HomeTab({
    required this.data,
    required this.settings,
    required this.onNavigate,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _cardShadow = BoxShadow(
    color: Color(0x1F7C6FC4),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.data, widget.settings]),
      builder: (context, _) {
        final strings = AppStrings.of(widget.settings.langCode);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(context, strings),
              const SizedBox(height: 16),
              YearMonthSelector(data: widget.data, settings: widget.settings),
              const SizedBox(height: 16),
              _buildBalanceCard(strings),
              const SizedBox(height: 24),
              _buildSectionHeader(
                strings.myAccounts,
                onViewAll: () => widget.onNavigate(4),
                strings: strings,
              ),
              const SizedBox(height: 12),
              _buildAccounts(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                strings.recentTx,
                onViewAll: () => widget.onNavigate(1),
                strings: strings,
              ),
              const SizedBox(height: 12),
              ...widget.data.transactions
                  .take(4)
                  .map((t) => _dismissibleTransactionItem(t, strings)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.greeting(widget.settings.userName),
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              strings.homeTitle,
              style: GoogleFonts.notoSansThai(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Language toggle
            GestureDetector(
              onTap: () => widget.settings.toggleLanguage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strings.langToggleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bell
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.noNotification,
                    style: GoogleFonts.notoSansThai(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [_cardShadow],
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(AppStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [_cardShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -52,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            left: -36,
            top: -12,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                strings.monthlyBalance,
                style: GoogleFonts.notoSansThai(
                  fontSize: 12,
                  color: const Color(0xFFEFE9FF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(widget.data.totalBalance),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _balanceSubCard(
                    strings.incomeLabel,
                    formatCurrency(widget.data.monthlyIncome),
                  ),
                  _balanceSubCard(
                    strings.expenseLabel,
                    formatCurrency(widget.data.monthlyExpense),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceSubCard(String label, String amount) {
    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              color: const Color(0xFFEFE9FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required VoidCallback onViewAll,
    required AppStrings strings,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            strings.viewAll,
            style: GoogleFonts.notoSansThai(
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccounts() {
    final accounts = widget.data.accounts;
    return Row(
      children: List.generate(accounts.length, (i) {
        final a = accounts[i];
        return Expanded(
          child: Container(
            height: 80,
            margin: EdgeInsets.only(right: i < accounts.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [_cardShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a.icon, style: const TextStyle(fontSize: 20)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatCurrency(a.balance),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _dismissibleTransactionItem(Transaction t, AppStrings strings) {
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
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      child: _buildTransactionItem(t, strings),
    );
  }

  Widget _buildTransactionItem(Transaction t, AppStrings strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              child: Text(t.icon, style: const TextStyle(fontSize: 18)),
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
                  formatDate(t.date, langCode: widget.settings.langCode),
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
