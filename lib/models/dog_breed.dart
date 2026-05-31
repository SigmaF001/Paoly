import 'package:flutter/material.dart';

/// Ear silhouette used by the procedural dog painter.
enum DogEar { floppy, erect, bat, semiErect }

/// Overall body proportion hints.
enum DogBodyShape { normal, long, short }

/// A selectable dog breed. Colours and silhouette flags drive the
/// procedural [DogPainter] so we don't need image assets.
class DogBreed {
  final String id;
  final String nameTh;
  final Color primary; // main coat colour
  final Color secondary; // light areas: belly, muzzle, blaze
  final Color patch; // dark patch / saddle / mask
  final Color eyeColor;
  final DogEar ear;
  final DogBodyShape body;
  final bool curlyCoat; // poodle fluff
  final bool curlTail; // shiba / husky curled tail
  final bool faceMask; // lighter muzzle + markings

  const DogBreed({
    required this.id,
    required this.nameTh,
    required this.primary,
    required this.secondary,
    required this.patch,
    required this.eyeColor,
    required this.ear,
    this.body = DogBodyShape.normal,
    this.curlyCoat = false,
    this.curlTail = false,
    this.faceMask = false,
  });

  static const golden = DogBreed(
    id: 'golden',
    nameTh: 'โกลเด้น รีทรีฟเวอร์',
    primary: Color(0xFFE6B25E),
    secondary: Color(0xFFF5DCA8),
    patch: Color(0xFFD49A45),
    eyeColor: Color(0xFF5A3A1A),
    ear: DogEar.floppy,
  );

  static const frenchBulldog = DogBreed(
    id: 'frenchie',
    nameTh: 'เฟรนช์ บูลด็อก',
    primary: Color(0xFF3B3B40),
    secondary: Color(0xFFF4EEE2),
    patch: Color(0xFF2A2A2E),
    eyeColor: Color(0xFF2A2017),
    ear: DogEar.bat,
    body: DogBodyShape.short,
    faceMask: true,
  );

  static const shibaInu = DogBreed(
    id: 'shiba',
    nameTh: 'ชิบะ อินุ',
    primary: Color(0xFFE0883A),
    secondary: Color(0xFFF8E6C8),
    patch: Color(0xFFC9742B),
    eyeColor: Color(0xFF4A2E12),
    ear: DogEar.erect,
    curlTail: true,
  );

  static const husky = DogBreed(
    id: 'husky',
    nameTh: 'ไซบีเรียน ฮัสกี้',
    primary: Color(0xFF35353B),
    secondary: Color(0xFFF2F2F4),
    patch: Color(0xFF26262B),
    eyeColor: Color(0xFF59B7E0),
    ear: DogEar.erect,
    curlTail: true,
    faceMask: true,
  );

  static const poodle = DogBreed(
    id: 'poodle',
    nameTh: 'พุดเดิ้ล',
    primary: Color(0xFFC98F5C),
    secondary: Color(0xFFDDAE7E),
    patch: Color(0xFFB67C49),
    eyeColor: Color(0xFF3A2A18),
    ear: DogEar.floppy,
    curlyCoat: true,
  );

  static const beagle = DogBreed(
    id: 'beagle',
    nameTh: 'บีเกิล',
    primary: Color(0xFF9A6433),
    secondary: Color(0xFFF5EFE6),
    patch: Color(0xFF2E2A26),
    eyeColor: Color(0xFF3A2A18),
    ear: DogEar.floppy,
    faceMask: true,
  );

  static const corgi = DogBreed(
    id: 'corgi',
    nameTh: 'เพมโบรค เวลช์ คอร์กี้',
    primary: Color(0xFFD98C4A),
    secondary: Color(0xFFF6ECDD),
    patch: Color(0xFFC2783A),
    eyeColor: Color(0xFF4A2E12),
    ear: DogEar.erect,
    body: DogBodyShape.short,
  );

  static const dachshund = DogBreed(
    id: 'dachshund',
    nameTh: 'ดัชชุน',
    primary: Color(0xFF2C2C2E),
    secondary: Color(0xFFB5702E),
    patch: Color(0xFFB5702E),
    eyeColor: Color(0xFF3A2A18),
    ear: DogEar.floppy,
    body: DogBodyShape.long,
    faceMask: true,
  );

  static const germanShepherd = DogBreed(
    id: 'gsd',
    nameTh: 'เยอรมัน เชเพิร์ด',
    primary: Color(0xFFB5793B),
    secondary: Color(0xFFE8C99A),
    patch: Color(0xFF2B2723),
    eyeColor: Color(0xFF3A2A18),
    ear: DogEar.erect,
    faceMask: true,
  );

  static const borderCollie = DogBreed(
    id: 'collie',
    nameTh: 'บอร์เดอร์ คอลลี่',
    primary: Color(0xFF2C2C2E),
    secondary: Color(0xFFF5EFE6),
    patch: Color(0xFF1F1F21),
    eyeColor: Color(0xFF5A3A1A),
    ear: DogEar.semiErect,
    faceMask: true,
  );

  static const all = <DogBreed>[
    golden,
    frenchBulldog,
    shibaInu,
    husky,
    poodle,
    beagle,
    corgi,
    dachshund,
    germanShepherd,
    borderCollie,
  ];

  static DogBreed byId(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => golden);
}
