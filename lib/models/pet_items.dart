import 'package:flutter/material.dart';

/// A consumable food bought with coins. Buying it immediately feeds the dog,
/// restoring [restore] hunger points.
class FoodItem {
  final String id;
  final String nameTh;
  final String emoji;
  final int restore; // hunger points restored
  final int price; // cost in coins

  const FoodItem({
    required this.id,
    required this.nameTh,
    required this.emoji,
    required this.restore,
    required this.price,
  });
}

/// Where an accessory is drawn on the dog.
enum AccessoryType { hat, crown, glasses, bowtie, bandana }

/// A wearable accessory. Owned permanently once bought and can be
/// equipped / unequipped.
class Accessory {
  final String id;
  final String nameTh;
  final String emoji;
  final AccessoryType type;
  final int price;
  final Color color;

  const Accessory({
    required this.id,
    required this.nameTh,
    required this.emoji,
    required this.type,
    required this.price,
    required this.color,
  });
}
