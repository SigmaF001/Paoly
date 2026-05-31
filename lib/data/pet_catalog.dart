import 'package:flutter/material.dart';
import '../models/pet_items.dart';

/// Static shop catalogue for foods and accessories.
class PetCatalog {
  static const foods = <FoodItem>[
    FoodItem(id: 'bone', nameTh: 'ขนมกระดูก', emoji: '🦴', restore: 15, price: 5),
    FoodItem(
        id: 'kibble', nameTh: 'อาหารเม็ด', emoji: '🥣', restore: 25, price: 10),
    FoodItem(
        id: 'chicken', nameTh: 'ไก่ทอด', emoji: '🍗', restore: 40, price: 20),
    FoodItem(id: 'meat', nameTh: 'เนื้อย่าง', emoji: '🍖', restore: 55, price: 28),
    FoodItem(
        id: 'steak', nameTh: 'สเต็กพรีเมียม', emoji: '🥩', restore: 80, price: 45),
  ];

  static const accessories = <Accessory>[
    Accessory(
      id: 'bowtie',
      nameTh: 'หูกระต่าย',
      emoji: '🎀',
      type: AccessoryType.bowtie,
      price: 25,
      color: Color(0xFFE5484D),
    ),
    Accessory(
      id: 'bandana',
      nameTh: 'ผ้าพันคอ',
      emoji: '🧣',
      type: AccessoryType.bandana,
      price: 30,
      color: Color(0xFF2F7DD1),
    ),
    Accessory(
      id: 'glasses',
      nameTh: 'แว่นกันแดด',
      emoji: '🕶️',
      type: AccessoryType.glasses,
      price: 40,
      color: Color(0xFF222226),
    ),
    Accessory(
      id: 'hat',
      nameTh: 'หมวกทรงสูง',
      emoji: '🎩',
      type: AccessoryType.hat,
      price: 60,
      color: Color(0xFF2B2B33),
    ),
    Accessory(
      id: 'crown',
      nameTh: 'มงกุฎทองคำ',
      emoji: '👑',
      type: AccessoryType.crown,
      price: 150,
      color: Color(0xFFF5C543),
    ),
  ];

  static Accessory? accessoryById(String id) {
    for (final a in accessories) {
      if (a.id == id) return a;
    }
    return null;
  }
}
