import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class SlipData {
  final double? amount;
  final DateTime? date;
  final String? receiver;
  final String rawText;

  SlipData({
    this.amount,
    this.date,
    this.receiver,
    required this.rawText,
  });
}

class SlipScannerService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  Future<SlipData> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    // Try QR first
    double? qrAmount;
    DateTime? qrDate;
    String? qrReceiver;
    
    final barcodes = await _barcodeScanner.processImage(inputImage);
    for (var barcode in barcodes) {
      if (barcode.format == BarcodeFormat.qrCode && barcode.displayValue != null) {
        final parsed = _parseQR(barcode.displayValue!);
        if (parsed != null) {
          qrAmount = parsed.amount;
          qrDate = parsed.date;
          qrReceiver = parsed.receiver;
          break;
        }
      }
    }

    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    String fullText = recognizedText.text;
    
    return SlipData(
      amount: qrAmount ?? _extractAmount(fullText),
      date: qrDate ?? _extractDate(fullText),
      receiver: qrReceiver ?? _extractReceiver(fullText),
      rawText: fullText,
    );
  }

  // Thai QR / EMVCo Slip Verification Parser (Mini QR)
  SlipData? _parseQR(String raw) {
    if (!raw.startsWith('000201')) return null;

    double? amount;
    DateTime? date;
    String? receiver;

    try {
      int i = 0;
      while (i < raw.length) {
        if (i + 4 > raw.length) break;
        String tag = raw.substring(i, i + 2);
        int length = int.parse(raw.substring(i + 2, i + 4));
        if (i + 4 + length > raw.length) break;
        String value = raw.substring(i + 4, i + 4 + length);
        
        if (tag == '54') {
          amount = double.tryParse(value);
        } else if (tag == '00') {
          // Payload Format Indicator
        } else if (tag == '51' || tag == '30' || tag == '31') {
          // Merchant Account Information - often contains bank/receiver info
          // Tag 30/31 subtag 01 often has account/name info in some implementations
        }
        
        i += 4 + length;
      }
    } catch (e) {
      // Parsing error
    }

    if (amount != null) {
      return SlipData(amount: amount, date: date, receiver: receiver, rawText: raw);
    }
    return null;
  }

  double? _extractAmount(String text) {
    // Regex for matching amounts like 1,234.56 or 1234.56
    final amountRegExp = RegExp(r'(\d{1,3}(,\d{3})*(\.\d{2})?)');
    
    final lines = text.split('\n');
    double? detectedAmount;

    for (var line in lines) {
      if (line.contains(RegExp(r'จำนวนเงิน|Amount|Total|Net|ยอดเงิน|เงินโอน', caseSensitive: false))) {
        final match = amountRegExp.firstMatch(line);
        if (match != null) {
          detectedAmount = double.tryParse(match.group(0)!.replaceAll(',', ''));
          if (detectedAmount != null) break;
        }
      }
    }

    // Fallback: search the whole text
    if (detectedAmount == null) {
      final matches = amountRegExp.allMatches(text);
      for (var match in matches) {
        final val = double.tryParse(match.group(0)!.replaceAll(',', ''));
        if (val != null && val > 0) {
          if (detectedAmount == null || val > detectedAmount) {
            detectedAmount = val;
          }
        }
      }
    }

    return detectedAmount;
  }

  DateTime? _extractDate(String text) {
    // Standard formats: dd/MM/yyyy, dd/MM/yy, dd MMM yyyy
    final dateRegExp = RegExp(r'(\d{1,2})[\/\-\. ](\d{1,2}|[ก-ฮa-zA-Z]{3,})[\/\-\. ](\d{2,4})');
    final match = dateRegExp.firstMatch(text);
    
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final monthStr = match.group(2) ?? '';
      final yearStr = match.group(3) ?? '';
      
      int? month = int.tryParse(monthStr);
      month ??= _parseThaiMonth(monthStr) ?? _parseEnglishMonth(monthStr);
      
      int year = int.tryParse(yearStr) ?? 0;
      if (year < 100) year += 2000;
      if (year > 2500) year -= 543; // Convert Buddhist year to AD
      
      if (day != null && month != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  String? _extractReceiver(String text) {
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(RegExp(r'To|ถึง|ผู้รับ|ไปยัง', caseSensitive: false))) {
        if (i + 1 < lines.length) {
          return lines[i+1].trim();
        }
      }
    }
    return null;
  }

  int? _parseThaiMonth(String m) {
    const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    const fullMonths = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    
    for (int i = 0; i < months.length; i++) {
      if (m.contains(months[i]) || m.contains(fullMonths[i])) return i + 1;
    }
    return null;
  }

  int? _parseEnglishMonth(String m) {
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final lower = m.toLowerCase();
    for (int i = 0; i < months.length; i++) {
      if (lower.startsWith(months[i])) return i + 1;
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}
