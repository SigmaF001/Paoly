import 'package:flutter/material.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../models/transaction.dart';

Future<bool> confirmTransactionDeletion(
  BuildContext context,
  Transaction transaction,
  AppSettings settings,
) async {
  final th = settings.langCode == 'th';
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(th ? 'ลบรายการนี้?' : 'Delete this transaction?'),
          content: Text(transaction.title),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              child: Text(th ? 'ยกเลิก' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(th ? 'ลบรายการ' : 'Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> deleteTransactionWithUndo(
  BuildContext context,
  FinanceData data,
  Transaction transaction,
  AppSettings settings,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final index = data.transactions.indexWhere((t) => t.id == transaction.id);
  if (index < 0) return;
  data.removeTransaction(transaction.id);
  try {
    await data.flush();
  } catch (_) {
    // The persistent save banner offers retry; keep Undo available as well.
  }
  if (!context.mounted) return;
  final th = settings.langCode == 'th';
  messenger.showSnackBar(
    SnackBar(
      content: Text(th ? 'ลบรายการแล้ว' : 'Transaction deleted'),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: th ? 'เลิกทำ' : 'Undo',
        onPressed: () {
          data.addTransaction(transaction, index: index);
        },
      ),
    ),
  );
}

class FinanceSaveStatus extends StatelessWidget {
  const FinanceSaveStatus({
    super.key,
    required this.data,
    required this.settings,
  });
  final FinanceData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) {
      if (data.saveError == null) return const SizedBox.shrink();
      final th = settings.langCode == 'th';
      return MaterialBanner(
        content: Text(
          th
              ? 'ยังบันทึกข้อมูลไม่สำเร็จ กรุณาลองอีกครั้งก่อนปิดแอพ'
              : 'Changes have not been saved. Retry before closing the app.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await data.retrySave();
              } catch (_) {
                /* Banner stays visible. */
              }
            },
            child: Text(th ? 'ลองอีกครั้ง' : 'Retry'),
          ),
        ],
      );
    },
  );
}
