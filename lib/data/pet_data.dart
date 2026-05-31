import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dog_breed.dart';
import '../models/pet_items.dart';

/// The dog's overall emotional state, derived from hunger.
enum DogMood { happy, neutral, sad }

/// Persistent state for the pet-raising feature: chosen breed, coins,
/// hunger and owned/equipped accessories.
///
/// Hunger decays in real time. We store the hunger value at [_lastUpdate]
/// and compute the live value from elapsed time, so it keeps draining even
/// while the app is closed.
class PetData extends ChangeNotifier {
  static final PetData instance = PetData._internal();
  factory PetData() => instance;
  PetData._internal();

  static const _prefsKey = 'pet_state';

  /// 1 coin is earned per this much income (in account currency).
  static const double currencyPerCoin = 100;

  /// Hunger points lost per real-time hour.
  static const double decayPerHour = 3.5;
  static const double maxHunger = 100;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  String? _breedId;
  String _dogName = '';
  double _coins = 0;
  double _hungerStored = maxHunger;
  DateTime _lastUpdate = DateTime.now();
  final Set<String> _owned = {};
  final Set<String> _equipped = {};

  bool get hasPet => _breedId != null;
  DogBreed? get breed => _breedId == null ? null : DogBreed.byId(_breedId!);
  String get dogName => _dogName;
  int get coins => _coins.floor();
  Set<String> get owned => Set.unmodifiable(_owned);
  Set<String> get equipped => Set.unmodifiable(_equipped);

  /// Live hunger (0..100) after applying real-time decay.
  double get hunger {
    final elapsedHours =
        DateTime.now().difference(_lastUpdate).inSeconds / 3600.0;
    final h = _hungerStored - elapsedHours * decayPerHour;
    return h.clamp(0, maxHunger);
  }

  DogMood get mood {
    final h = hunger;
    if (h >= 60) return DogMood.happy;
    if (h >= 30) return DogMood.neutral;
    return DogMood.sad;
  }

  /// Bake the live hunger into storage and reset the decay clock.
  void _settle() {
    _hungerStored = hunger;
    _lastUpdate = DateTime.now();
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _breedId = m['breedId'] as String?;
        _dogName = (m['dogName'] as String?) ?? '';
        _coins = (m['coins'] as num?)?.toDouble() ?? 0;
        _hungerStored = (m['hunger'] as num?)?.toDouble() ?? maxHunger;
        _lastUpdate =
            DateTime.tryParse(m['lastUpdate'] as String? ?? '') ??
                DateTime.now();
        _owned
          ..clear()
          ..addAll((m['owned'] as List?)?.map((e) => e.toString()) ?? const []);
        _equipped
          ..clear()
          ..addAll(
              (m['equipped'] as List?)?.map((e) => e.toString()) ?? const []);
      } catch (_) {
        // Corrupted state: start fresh.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'breedId': _breedId,
        'dogName': _dogName,
        'coins': _coins,
        'hunger': _hungerStored,
        'lastUpdate': _lastUpdate.toIso8601String(),
        'owned': _owned.toList(),
        'equipped': _equipped.toList(),
      }),
    );
  }

  /// Adopt a dog of the given breed with a name.
  Future<void> choosePet(String breedId, String name) async {
    _breedId = breedId;
    final trimmed = name.trim();
    _dogName = trimmed.isEmpty ? 'น้องหมา' : trimmed;
    _settle();
    notifyListeners();
    await _persist();
  }

  /// Award coins for received income. Returns the number of coins earned.
  int awardForIncome(double amount) {
    if (amount <= 0) return 0;
    var earned = (amount / currencyPerCoin).floor();
    if (earned < 1) earned = 1;
    _coins += earned;
    notifyListeners();
    _persist();
    return earned;
  }

  /// Buy and immediately feed [food]. Returns false if not enough coins.
  Future<bool> buyFood(FoodItem food) async {
    if (_coins < food.price) return false;
    _settle();
    _coins -= food.price;
    _hungerStored = (_hungerStored + food.restore).clamp(0, maxHunger);
    notifyListeners();
    await _persist();
    return true;
  }

  /// Buy an accessory (and auto-equip it). Returns false if not enough coins.
  Future<bool> buyAccessory(Accessory acc) async {
    if (_owned.contains(acc.id)) return true;
    if (_coins < acc.price) return false;
    _coins -= acc.price;
    _owned.add(acc.id);
    _equipped.add(acc.id);
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> toggleEquip(String accId) async {
    if (!_owned.contains(accId)) return;
    if (_equipped.contains(accId)) {
      _equipped.remove(accId);
    } else {
      _equipped.add(accId);
    }
    notifyListeners();
    await _persist();
  }

  bool isOwned(String id) => _owned.contains(id);
  bool isEquipped(String id) => _equipped.contains(id);
}
