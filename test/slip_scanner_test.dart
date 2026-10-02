// Parser regressions: native OCR channels return controlled text.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paoly/services/slip_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var ocrText = '';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('google_mlkit_barcode_scanning'),
      (_) async => [],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('google_mlkit_text_recognizer'),
      (_) async => {'text': ocrText, 'blocks': []},
    );
  });
  test('Unseparated amount retains all digits', () async {
    ocrText = 'Amount 1234.56';
    expect(
      (await SlipScannerService().processImage('/tmp/mock.png')).amount,
      1234.56,
    );
  });
  test('Thai short year 69 becomes 2026', () async {
    ocrText = '29/05/69';
    expect(
      (await SlipScannerService().processImage('/tmp/mock.png')).date,
      DateTime(2026, 5, 29),
    );
  });
  test('Impossible dates are rejected', () async {
    ocrText = '31/02/2026';
    expect(
      (await SlipScannerService().processImage('/tmp/mock.png')).date,
      isNull,
    );
  });
  test('Thai month with combining vowel is parsed', () async {
    ocrText = '10 มิ.ย. 2569';
    expect(
      (await SlipScannerService().processImage('/tmp/mock.png')).date,
      DateTime(2026, 6, 10),
    );
  });
  test('comma amount and English date are preserved', () async {
    ocrText = 'Amount 12,345.67\n10 October 2026';
    final slip = await SlipScannerService().processImage('/tmp/mock.png');
    expect(slip.amount, 12345.67);
    expect(slip.date, DateTime(2026, 10, 10));
  });
  test('dates and reference numbers alone do not become amounts', () async {
    ocrText = '02/10/2026\nRef 1234567';
    expect(
      (await SlipScannerService().processImage('/tmp/mock.png')).amount,
      isNull,
    );
  });
}
