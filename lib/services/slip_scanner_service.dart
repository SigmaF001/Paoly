import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class SlipData {
  final double? amount;
  final DateTime? date;
  final String? receiver;
  final String rawText;

  SlipData({this.amount, this.date, this.receiver, required this.rawText});
}

class SlipScannerService {
  TextRecognizer? _textRecognizer;
  BarcodeScanner? _barcodeScanner;

  TextRecognizer get textRecognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  BarcodeScanner get barcodeScanner =>
      _barcodeScanner ??= BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  Future<SlipData> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    double? qrAmount;
    DateTime? qrDate;
    String? qrReceiver;

    final barcodes = await barcodeScanner.processImage(inputImage);
    for (var barcode in barcodes) {
      if (barcode.format == BarcodeFormat.qrCode &&
          barcode.displayValue != null) {
        final parsed = _parseQR(barcode.displayValue!);
        if (parsed != null) {
          qrAmount = parsed.amount;
          qrDate = parsed.date;
          qrReceiver = parsed.receiver;
          break;
        }
      }
    }

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    final String fullText = recognizedText.text;

    return SlipData(
      amount: qrAmount ?? _extractAmount(fullText),
      date: qrDate ?? _extractDate(fullText),
      receiver: qrReceiver ?? _extractReceiver(fullText),
      rawText: fullText,
    );
  }

  // ─── QR / EMVCo Parser ───────────────────────────────────────────────────

  /// Parses a nested EMVCo TLV value and returns the value of [targetTag].
  String? _parseNestedTLV(String data, String targetTag) {
    int i = 0;
    while (i + 4 <= data.length) {
      final tag = data.substring(i, i + 2);
      final length = int.tryParse(data.substring(i + 2, i + 4));
      if (length == null) break;
      if (i + 4 + length > data.length) break;
      final value = data.substring(i + 4, i + 4 + length);
      if (tag == targetTag) return value;
      i += 4 + length;
    }
    return null;
  }

  SlipData? _parseQR(String raw) {
    if (!raw.startsWith('000201')) return null;

    double? amount;
    String? receiver;

    try {
      int i = 0;
      while (i < raw.length) {
        if (i + 4 > raw.length) break;
        final tag = raw.substring(i, i + 2);
        final length = int.tryParse(raw.substring(i + 2, i + 4));
        if (length == null) break;
        if (i + 4 + length > raw.length) break;
        final value = raw.substring(i + 4, i + 4 + length);

        if (tag == '54') {
          amount = double.tryParse(value);
        } else if (tag == '59') {
          // Merchant Name — plain string (UOB, CIMB, Krungsri merchant)
          final v = value.trim();
          if (v.isNotEmpty) receiver ??= v;
        } else if (tag == '26' || tag == '29' || tag == '30') {
          // PromptPay Merchant Account Info (KBank, SCB, BBL, Krungthai, GSB, TTB)
          // Sub-tag '01' = phone number, national ID, or proxy account
          final sub = _parseNestedTLV(value, '01');
          if (sub != null && sub.trim().isNotEmpty) {
            receiver ??= sub.trim();
          }
        }

        i += 4 + length;
      }
    } catch (e) {
      debugPrint('[SlipScanner] QR parse error: $e');
    }

    if (amount != null || receiver != null) {
      return SlipData(
        amount: amount,
        date: null,
        receiver: receiver,
        rawText: raw,
      );
    }
    return null;
  }

  // ─── Amount Extraction ───────────────────────────────────────────────────

  bool _isYearLike(int v) => v >= 1900 && v <= 2600;

  double? _extractAmount(String text) {
    // Amount with exactly 2 decimal places: 1,234.56 or 1234.56
    final decimalRx = RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})');
    // Thousands-separated integer with no trailing decimal: 1,000
    final thousandsRx = RegExp(r'(\d{1,3}(?:,\d{3})+)');
    // Standalone 2–7 digit integer
    final intRx = RegExp(r'(?<!\d)(\d{2,7})(?!\d)');

    final keywordRx = RegExp(
      r'Amount|Total|Net|Payment|ยอดเงิน|เงินโอน|ยอดโอน|ยอดรวม|ยอดชำระ|ยอดสุทธิ|จำนวนเงิน|จำนวน',
      caseSensitive: false,
    );

    final lines = text.split('\n');

    // Tier 1: decimal on a keyword line or the next non-empty line
    for (int i = 0; i < lines.length; i++) {
      if (!keywordRx.hasMatch(lines[i])) continue;

      final sameLine = decimalRx.firstMatch(lines[i]);
      if (sameLine != null) {
        final v = double.tryParse(sameLine.group(1)!.replaceAll(',', ''));
        if (v != null && v > 0) return v;
      }

      for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
        if (lines[j].trim().isEmpty) continue;
        final next = decimalRx.firstMatch(lines[j]);
        if (next != null) {
          final v = double.tryParse(next.group(1)!.replaceAll(',', ''));
          if (v != null && v > 0) return v;
        }
        break;
      }
    }

    // Tier 2: largest decimal amount anywhere in text, capped at 9,999,999
    double? bestDecimal;
    for (final m in decimalRx.allMatches(text)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v != null && v > 0 && v <= 9999999) {
        if (bestDecimal == null || v > bestDecimal) bestDecimal = v;
      }
    }
    if (bestDecimal != null) return bestDecimal;

    // Tier 3: number with thousands separator (round amounts like 1,000)
    for (final m in thousandsRx.allMatches(text)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v != null && v > 0) return v;
    }

    // Tier 4: standalone integer, excluding year-like values
    for (final m in intRx.allMatches(text)) {
      final v = int.tryParse(m.group(1)!);
      if (v != null && v > 0 && !_isYearLike(v)) return v.toDouble();
    }

    return null;
  }

  // ─── Date Extraction ─────────────────────────────────────────────────────

  DateTime? _extractDate(String text) {
    // Pattern 1: ISO — yyyy-MM-dd or yyyy/MM/dd (TTB and some API-generated slips)
    final isoRx = RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})');
    final isoMatch = isoRx.firstMatch(text);
    if (isoMatch != null) {
      int y = int.parse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y > 2500) y -= 543;
      if (m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    // Pattern 2: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy (KBank, SCB, BBL, Krungthai, GSB, Krungsri)
    final dmyRx = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    final dmyMatch = dmyRx.firstMatch(text);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      int y = int.tryParse(dmyMatch.group(3)!) ?? 0;
      if (y < 100) {
        if (y >= 50) {
          y += 1457; // Thai BE two-digit year (e.g. 69 -> BE 2569 -> 2026 CE)
        } else {
          y += 2000; // CE two-digit year (e.g. 26 -> 2026 CE)
        }
      }
      if (y > 2500) y -= 543;
      if (d != null && m != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    // Pattern 3: long format — "10 May 2025", "10 พ.ค. 2568", "29 พ.ค. 69" (UOB, CIMB, some KBank)
    final longRx = RegExp(
      r'(\d{1,2})\s+([ก-ฮa-zA-Z][ก-ฮa-zA-Z.]{1,10})\s+(\d{2,4})',
    );
    final longMatch = longRx.firstMatch(text);
    if (longMatch != null) {
      final d = int.tryParse(longMatch.group(1)!);
      final monthStr = longMatch.group(2)!;
      int y = int.tryParse(longMatch.group(3)!) ?? 0;
      if (y < 100) {
        if (y >= 50) {
          y += 1457; // Thai BE two-digit year (e.g. 69 -> BE 2569 -> 2026 CE)
        } else {
          y += 2000; // CE two-digit year (e.g. 26 -> 2026 CE)
        }
      }
      if (y > 2500) y -= 543;
      final m = _parseThaiMonth(monthStr) ?? _parseEnglishMonth(monthStr);
      if (d != null && m != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    return null;
  }

  // ─── Receiver Extraction ─────────────────────────────────────────────────

  String? _extractReceiverSequential(String text) {
    final lines = text.split('\n');
    final nameCandidates = <String>[];

    // Filter out obviously non-name lines
    final avoidKeywords = [
      'สำเร็จ', 'successful', 'success',
      'บาท', 'baht',
      'fee', 'ค่าธรรมเนียม',
      'เลขที่', 'รายการ', 'อ้างอิง', 'ref',
      'จำนวน', 'ยอดเงิน', 'เงินโอน', 'ยอดโอน', 'total', 'amount',
      'วันที่', 'เวลา', 'date', 'time',
      'ธนาคาร', 'ธ.', 'bank', 'กสิกร', 'กรุงไทย', 'กรุงเทพ', 'ไทยพาณิชย์', 'ทหารไทย',
      'ttb', 'kbank', 'scb', 'bbl', 'krungthai', 'uob', 'cimb', 'gsb', 'bay', 'กรุงศรี',
      'พร้อมเพย์', 'promptpay',
      'จาก', 'ไปยัง', 'to', 'from',
      'บัญชี', 'account', 'no.',
      'โอน', 'transfer', 'payment', 'make by', 'make'
    ];

    final dateMonthRx = RegExp(
      r'(พ.ค.|ม.ค.|ก.พ.|มี.ค.|เม.ย.|มิ.ย.|ก.ค.|ส.ค.|ก.ย.|ต.ค.|พ.ย.|ธ.ค.|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
      caseSensitive: false,
    );
    final timeRx = RegExp(r'\d{1,2}:\d{2}');
    final accountRx = RegExp(r'[xX\-\d]{7,}');
    final hasLetterRx = RegExp(r'[a-zA-Zก-๙]');

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.length < 3) continue;

      // Skip lines with special characters like arrows alone
      if (line == '↓' || line == 'v' || line == '|') continue;

      // Must contain at least one letter
      if (!hasLetterRx.hasMatch(line)) continue;

      // Check avoid keywords
      bool avoid = false;
      for (final kw in avoidKeywords) {
        if (line.toLowerCase().contains(kw)) {
          avoid = true;
          break;
        }
      }
      if (avoid) continue;

      // Check dates/times
      if (dateMonthRx.hasMatch(line) || timeRx.hasMatch(line)) continue;

      // Check account pattern
      if (accountRx.hasMatch(line)) continue;

      // If it passes all checks, it's a candidate!
      nameCandidates.add(line);
    }

    if (nameCandidates.length >= 2) {
      // The second name is the receiver (first is sender)
      return nameCandidates[1];
    }
    return null;
  }

  String? _extractReceiver(String text) {
    // 1. Try sequential heuristic first (sender -> receiver)
    final seqReceiver = _extractReceiverSequential(text);
    if (seqReceiver != null) return seqReceiver;

    // 2. Fallback to keyword search
    final keywordRx = RegExp(
      r'Receiver|Payee|Beneficiary|Account\s*Name|To|ถึง|ผู้รับ|ไปยัง',
      caseSensitive: false,
    );

    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!keywordRx.hasMatch(line)) continue;

      // Value may appear after ':' on the same line (e.g. "To: John Doe")
      final colonIdx = line.indexOf(':');
      if (colonIdx != -1) {
        final afterColon = line.substring(colonIdx + 1).trim();
        if (afterColon.isNotEmpty) return afterColon;
      }

      // Otherwise scan forward for the next non-empty line
      for (int j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isNotEmpty) return next;
      }
    }
    return null;
  }

  // ─── Month Helpers ───────────────────────────────────────────────────────

  int? _parseThaiMonth(String m) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    const fullMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    for (int i = 0; i < months.length; i++) {
      if (m.contains(months[i]) || m.contains(fullMonths[i])) return i + 1;
    }
    return null;
  }

  int? _parseEnglishMonth(String m) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final lower = m.toLowerCase();
    for (int i = 0; i < months.length; i++) {
      if (lower.startsWith(months[i])) return i + 1;
    }
    return null;
  }

  void dispose() {
    _textRecognizer?.close();
    _barcodeScanner?.close();
  }
}
