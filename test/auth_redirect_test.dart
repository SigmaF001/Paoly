import 'package:flutter_test/flutter_test.dart';
import 'package:paoly/services/auth_redirect.dart';

void main() {
  test('local web callback retains its configured port', () {
    expect(
      authRedirectUrl(
        web: true,
        base: Uri.parse('http://localhost:3000/?code=secret'),
      ),
      'http://localhost:3000/',
    );
  });
  test('native email link returns to the registered application scheme', () {
    expect(authRedirectUrl(web: false), 'com.paoly.app://login-callback/');
  });
  test(
    'web link preserves deployment path but excludes callback credentials',
    () {
      expect(
        authRedirectUrl(
          web: true,
          base: Uri.parse(
            'https://example.com/paoly/?code=secret#access_token=secret',
          ),
        ),
        'https://example.com/paoly/',
      );
    },
  );
}
