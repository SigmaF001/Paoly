import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/emoji_picker_grid.dart';

const List<String> _accountEmojis = [
  '🏦', '💳', '💰', '🪙', '💵', '🏧', '🛒', '🏡',
  '✈️', '🎯', '📱', '🎮', '🍽️', '🚗', '💊', '📚',
];

class AccountsScreen extends StatelessWidget {
  final FinanceData data;
  final AppSettings settings;
  const AccountsScreen({
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
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                strings.accountsTitle,
                style: GoogleFonts.notoSansThai(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _totalCard(strings),
              const SizedBox(height: 20),
              ...data.accounts
                  .map((a) => _accountCard(a, context, strings)),
              const SizedBox(height: 8),
              _addAccountButton(context, strings),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _totalCard(AppStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.totalAllAccounts,
            style: GoogleFonts.notoSansThai(
                fontSize: 13, color: AppColors.lightPurple),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(data.totalBalance),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            strings.accountCount(data.accounts.length),
            style: GoogleFonts.notoSansThai(
                fontSize: 12, color: AppColors.lightPurple),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(
      Account a, BuildContext context, AppStrings strings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_cardShadow],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showEditDialog(context, strings, a),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.lightPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(a.icon,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a.name,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                formatCurrency(a.balance),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditDialog(context, strings, a),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addAccountButton(BuildContext context, AppStrings strings) {
    return GestureDetector(
      onTap: () => _showAddDialog(context, strings),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          strings.addAccount,
          style: GoogleFonts.notoSansThai(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppStrings strings) {
    final ctrl = TextEditingController();
    String selectedEmoji = '🏦';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            strings.addAccountTitle,
            style:
                GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.selectEmoji,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                EmojiPickerGrid(
                  selected: selectedEmoji,
                  emojis: _accountEmojis,
                  onSelect: (e) =>
                      setDialogState(() => selectedEmoji = e),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: false,
                  style: GoogleFonts.notoSansThai(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: strings.accountNameHint,
                    hintStyle: GoogleFonts.notoSansThai(
                        color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.lightPurple,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.cancel,
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  data.addAccount(ctrl.text.trim(),
                      icon: selectedEmoji);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(
                strings.confirm,
                style: GoogleFonts.notoSansThai(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  void _showEditDialog(
      BuildContext context, AppStrings strings, Account account) {
    final nameCtrl = TextEditingController(text: account.name);
    final balanceCtrl = TextEditingController(
        text: account.balance == 0
            ? ''
            : account.balance.toStringAsFixed(
                account.balance.truncateToDouble() == account.balance ? 0 : 2));
    String selectedEmoji = account.icon;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            strings.editAccountTitle,
            style:
                GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.selectEmoji,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                EmojiPickerGrid(
                  selected: selectedEmoji,
                  emojis: _accountEmojis,
                  onSelect: (e) =>
                      setDialogState(() => selectedEmoji = e),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: false,
                  style: GoogleFonts.notoSansThai(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: strings.accountNameHint,
                    hintStyle: GoogleFonts.notoSansThai(
                        color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.lightPurple,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: strings.balanceHint,
                    hintStyle: GoogleFonts.notoSansThai(
                        color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.lightPurple,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.cancel,
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  data.renameAccount(
                    account.id,
                    nameCtrl.text.trim(),
                    newIcon: selectedEmoji,
                  );
                }
                final newBalance =
                    double.tryParse(balanceCtrl.text.trim());
                if (newBalance != null) {
                  data.setAccountBalance(account.id, newBalance);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(
                strings.confirm,
                style: GoogleFonts.notoSansThai(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      balanceCtrl.dispose();
    });
  }
}
