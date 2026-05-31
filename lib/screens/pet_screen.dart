import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/pet_catalog.dart';
import '../data/pet_data.dart';
import '../models/dog_breed.dart';
import '../models/pet_items.dart';
import '../theme/app_theme.dart';
import '../widgets/dog_view.dart';

/// Entry point for the dog-raising feature. Shows breed selection on the
/// first visit, then the pet home screen.
class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PetData.instance,
      builder: (context, _) {
        final pet = PetData.instance;
        if (!pet.hasPet) return const _BreedSelectionView();
        return const _PetHomeView();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────── breed select

class _BreedSelectionView extends StatefulWidget {
  const _BreedSelectionView();

  @override
  State<_BreedSelectionView> createState() => _BreedSelectionViewState();
}

class _BreedSelectionViewState extends State<_BreedSelectionView> {
  String? _selectedId;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _adopt() async {
    if (_selectedId == null) return;
    FocusScope.of(context).unfocus();
    await PetData.instance.choosePet(_selectedId!, _nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text(
              'เลือกน้องหมาของคุณ 🐾',
              style: GoogleFonts.notoSansThai(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'แตะเพื่อเลือกสายพันธุ์ที่อยากเลี้ยง',
              style: GoogleFonts.notoSansThai(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: DogBreed.all.length,
                itemBuilder: (context, i) {
                  final breed = DogBreed.all[i];
                  final selected = breed.id == _selectedId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = breed.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F7C6FC4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              child: DogView(
                                breed: breed,
                                mood: DogMood.happy,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 6, right: 6),
                            child: Text(
                              breed.nameTh,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedId != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _adopt(),
                style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'ตั้งชื่อน้องหมา (ไม่บังคับ)',
                  hintStyle: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.pets, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _adopt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'รับเลี้ยง 🐶',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── pet home

class _PetHomeView extends StatefulWidget {
  const _PetHomeView();

  @override
  State<_PetHomeView> createState() => _PetHomeViewState();
}

class _PetHomeViewState extends State<_PetHomeView> {
  int _celebrate = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the hunger bar / mood as real time passes.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Color _moodColor(DogMood mood) {
    switch (mood) {
      case DogMood.happy:
        return AppColors.income;
      case DogMood.neutral:
        return const Color(0xFFE0A23B);
      case DogMood.sad:
        return AppColors.expense;
    }
  }

  String _moodText(DogMood mood) {
    switch (mood) {
      case DogMood.happy:
        return 'อิ่มหนำสำราญ มีความสุขมาก! 😊';
      case DogMood.neutral:
        return 'เริ่มหิวแล้วนะ...';
      case DogMood.sad:
        return 'หิวมากเลย 😢 ให้อาหารหน่อย';
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.notoSansThai(color: Colors.white)),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pet = PetData.instance;
    final breed = pet.breed ?? DogBreed.golden;
    final mood = pet.mood;
    final hunger = pet.hunger;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header: name + coins
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.dogName,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        breed.nameTh,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _coinChip(pet.coins),
              ],
            ),
            const SizedBox(height: 12),
            // Stage
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEAF4FF), Color(0xFFEFE9FF)],
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  children: [
                    // grass / floor
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFCDEBC2),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(27),
                          ),
                        ),
                      ),
                    ),
                    // mood bubble
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F7C6FC4),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _moodText(mood),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _moodColor(mood),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // the dog
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 8),
                      child: DogView(
                        breed: breed,
                        mood: mood,
                        equipped: pet.equipped,
                        celebrateTick: _celebrate,
                        onTap: () => _snack('โฮ่ง! 🐶'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _hungerBar(hunger, mood),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'ให้อาหาร',
                    icon: '🍖',
                    filled: true,
                    onTap: _openFoodSheet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'แต่งตัว / ร้านค้า',
                    icon: '🛍️',
                    filled: false,
                    onTap: _openShopSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _coinChip(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2D58A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF8A6A12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hungerBar(double hunger, DogMood mood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ความอิ่ม',
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '${hunger.round()}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _moodColor(mood),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (hunger / 100).clamp(0.0, 1.0),
            minHeight: 14,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(_moodColor(mood)),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required String icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x147C6FC4),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: filled ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────── food shop

  Future<void> _buyFood(FoodItem food) async {
    final pet = PetData.instance;
    if (pet.hunger >= PetData.maxHunger) {
      _snack('${pet.dogName} อิ่มเต็มที่แล้ว 🐶');
      return;
    }
    final ok = await pet.buyFood(food);
    if (!mounted) return;
    if (ok) {
      setState(() => _celebrate++);
      _snack('${food.emoji} อร่อยจัง! อิ่มขึ้น +${food.restore}');
    } else {
      _snack('coin ไม่พอ 🪙 (ต้องการ ${food.price})');
    }
  }

  void _openFoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _sheetContainer(
        title: 'ร้านอาหาร 🍽️',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: PetCatalog.foods.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.nameTh,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'อิ่ม +${f.restore}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _priceButton(
                    price: f.price,
                    affordable: PetData.instance.coins >= f.price,
                    onTap: () => _buyFood(f),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────── accessory shop

  Future<void> _onAccessoryTap(Accessory acc) async {
    final pet = PetData.instance;
    if (pet.isOwned(acc.id)) {
      await pet.toggleEquip(acc.id);
      if (!mounted) return;
      setState(() {});
    } else {
      final ok = await pet.buyAccessory(acc);
      if (!mounted) return;
      if (ok) {
        setState(() => _celebrate++);
        _snack('${acc.emoji} ซื้อ ${acc.nameTh} แล้ว!');
      } else {
        _snack('coin ไม่พอ 🪙 (ต้องการ ${acc.price})');
      }
    }
  }

  void _openShopSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _sheetContainer(
        title: 'แต่งตัวน้องหมา 🛍️',
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: PetCatalog.accessories.map((acc) {
            final pet = PetData.instance;
            final owned = pet.isOwned(acc.id);
            final equipped = pet.isEquipped(acc.id);
            return GestureDetector(
              onTap: () => _onAccessoryTap(acc),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: equipped ? AppColors.primary : AppColors.border,
                    width: equipped ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(acc.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text(
                      acc.nameTh,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owned
                          ? (equipped ? 'ใส่อยู่ ✓' : 'แตะเพื่อใส่')
                          : '🪙 ${acc.price}',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: owned
                            ? (equipped ? AppColors.primary : AppColors.textMuted)
                            : const Color(0xFF8A6A12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Sheet shell that rebuilds when PetData changes (coins / ownership).
  Widget _sheetContainer({required String title, required Widget child}) {
    return AnimatedBuilder(
      animation: PetData.instance,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    _coinChip(PetData.instance.coins),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _priceButton({
    required int price,
    required bool affordable,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: affordable ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: affordable ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
