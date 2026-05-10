import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/slip_scanner_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../utils/sounds.dart';
import 'emoji_picker_grid.dart';

const List<String> _categoryEmojis = [
  '🍔', '🚗', '🛍️', '🎮', '💡', '💊', '📌', '💰',
  '🎁', '📈', '🏠', '✈️', '🎯', '📱', '🍽️', '📚',
  '🎵', '🐶', '💪', '🌿',
];

class AddTransactionSheet extends StatefulWidget {
  final FinanceData data;
  final AppSettings settings;
  const AddTransactionSheet({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  bool _isExpense = true;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _scanner = SlipScannerService();
  bool _isScanning = false;

  bool get _isThai => widget.settings.langCode == 'th';

  List<TxCategory> _categoriesForType(bool isExpense) =>
      widget.data.categories.where((c) => c.isExpense == isExpense).toList();

  @override
  void initState() {
    super.initState();
    final cats = _categoriesForType(true);
    if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
    if (widget.data.accounts.isNotEmpty) {
      _selectedAccountId = widget.data.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _scanSlip() async {
    final strings = AppStrings.of(widget.settings.langCode);
    final ImagePicker picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(strings.camera, style: GoogleFonts.notoSansThai()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(strings.gallery, style: GoogleFonts.notoSansThai()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final slipData = await _scanner.processImage(image.path);
      
      setState(() {
        _isExpense = true; // Slips are usually expenses
        if (slipData.amount != null) {
          _amountController.text = slipData.amount!.toStringAsFixed(2);
        }
        if (slipData.date != null) {
          _selectedDate = slipData.date!;
        }
        if (slipData.receiver != null) {
          _titleController.text = slipData.receiver!;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.scanError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _save() {
    AppSounds.playSoftClick();
    final strings = AppStrings.of(widget.settings.langCode);
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorNoAmount,
              style: GoogleFonts.notoSansThai(color: Colors.white)),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorBadAmount,
              style: GoogleFonts.notoSansThai(color: Colors.white)),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final cats = _categoriesForType(_isExpense);
    final selectedCat = cats.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => cats.first,
    );

    final title = _titleController.text.trim().isEmpty
        ? (_isThai ? selectedCat.nameTh : selectedCat.nameEn)
        : _titleController.text.trim();

    final accountId = _selectedAccountId ??
        (widget.data.accounts.isNotEmpty
            ? widget.data.accounts.first.id
            : '');

    widget.data.addTransaction(Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: selectedCat.icon,
      title: title,
      category: selectedCat.nameTh,
      date: _selectedDate,
      amount: amount,
      isExpense: _isExpense,
      accountId: accountId,
    ));

    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddCategoryDialog(AppStrings strings) {
    final thCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    String selectedEmoji = '📌';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(strings.addCategoryTitle,
              style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
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
                  emojis: _categoryEmojis,
                  onSelect: (e) => setDialogState(() => selectedEmoji = e),
                ),
                const SizedBox(height: 12),
                _dialogTextField(thCtrl, strings.categoryNameHint),
                const SizedBox(height: 8),
                _dialogTextField(enCtrl, strings.categoryNameEnHint),
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
                final th = thCtrl.text.trim();
                final en = enCtrl.text.trim();
                if (th.isNotEmpty && en.isNotEmpty) {
                  final id =
                      'custom_${DateTime.now().millisecondsSinceEpoch}';
                  widget.data.addCategory(TxCategory(
                    id: id,
                    icon: selectedEmoji,
                    nameTh: th,
                    nameEn: en,
                    isExpense: _isExpense,
                  ));
                  setState(() => _selectedCategoryId = id);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(strings.confirm,
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((_) {
      thCtrl.dispose();
      enCtrl.dispose();
    });
  }

  void _showEditCategoryDialog(AppStrings strings, TxCategory cat) {
    final thCtrl = TextEditingController(text: cat.nameTh);
    final enCtrl = TextEditingController(text: cat.nameEn);
    String selectedEmoji = cat.icon;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(strings.editCategoryTitle,
              style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold)),
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
                  emojis: _categoryEmojis,
                  onSelect: (e) => setDialogState(() => selectedEmoji = e),
                ),
                const SizedBox(height: 12),
                _dialogTextField(thCtrl, strings.categoryNameHint),
                const SizedBox(height: 8),
                _dialogTextField(enCtrl, strings.categoryNameEnHint),
              ],
            ),
          ),
          actions: [
            if (!cat.isDefault)
              TextButton(
                onPressed: () {
                  widget.data.deleteCategory(cat.id);
                  final remaining = _categoriesForType(_isExpense);
                  if (remaining.isNotEmpty) {
                    setState(
                        () => _selectedCategoryId = remaining.first.id);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(strings.deleteCategory,
                    style: GoogleFonts.notoSansThai(
                        color: AppColors.expense)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.cancel,
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                widget.data.updateCategory(
                  cat.id,
                  icon: selectedEmoji,
                  nameTh: thCtrl.text.trim().isEmpty
                      ? cat.nameTh
                      : thCtrl.text.trim(),
                  nameEn: enCtrl.text.trim().isEmpty
                      ? cat.nameEn
                      : enCtrl.text.trim(),
                );
                Navigator.of(ctx).pop();
              },
              child: Text(strings.confirm,
                  style: GoogleFonts.notoSansThai(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((_) {
      thCtrl.dispose();
      enCtrl.dispose();
    });
  }

  Widget _dialogTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.notoSansThai(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.notoSansThai(fontSize: 14, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.lightPurple,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.settings.langCode);
    final cats = _categoriesForType(_isExpense);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.addTransaction,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      onPressed: _isScanning ? null : _scanSlip,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      tooltip: strings.scanSlip,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
            // Type toggle
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildTypeBtn(strings.txTypeExpense, true),
                  _buildTypeBtn(strings.txTypeIncome, false),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Account selector
            if (widget.data.accounts.isNotEmpty) ...[
              Text(
                strings.selectAccount,
                style: GoogleFonts.notoSansThai(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.data.accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = widget.data.accounts[i];
                    final selected = a.id == _selectedAccountId;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedAccountId = a.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.icon,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              a.name,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
            // Category chips
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == cats.length) {
                    return GestureDetector(
                      onTap: () => _showAddCategoryDialog(strings),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('+',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text(
                              strings.addNewCategory,
                              style: GoogleFonts.notoSansThai(
                                  fontSize: 9,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final cat = cats[i];
                  final selected = cat.id == _selectedCategoryId;
                  final displayName =
                      _isThai ? cat.nameTh : cat.nameEn;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategoryId = cat.id),
                    onLongPress: () =>
                        _showEditCategoryDialog(strings, cat),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 9,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Title field
            TextField(
              controller: _titleController,
              style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: strings.txNameHint,
                hintStyle: GoogleFonts.notoSansThai(
                    fontSize: 14, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.lightPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightPurple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      formatDate(_selectedDate,
                          langCode: widget.settings.langCode),
                      style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Amount field
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_DecimalFormatter()],
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: strings.amountHint,
                hintStyle: GoogleFonts.notoSansThai(
                    fontSize: 14, color: AppColors.textMuted),
                prefixText: '฿  ',
                prefixStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.lightPurple,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  strings.save,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_isScanning)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Center(

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    strings.scanning,
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  ),
);
  }

  Widget _buildTypeBtn(String label, bool isExpense) {
    final selected = _isExpense == isExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSounds.playSoftClick();
          setState(() {
            _isExpense = isExpense;
            final cats = _categoriesForType(isExpense);
            _selectedCategoryId =
                cats.isNotEmpty ? cats.first.id : null;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 14,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecimalFormatter extends TextInputFormatter {
  static final _regex = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    return _regex.hasMatch(newValue.text) ? newValue : old;
  }
}
