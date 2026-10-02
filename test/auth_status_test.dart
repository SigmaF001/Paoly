import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paoly/data/app_settings.dart';
import 'package:paoly/data/finance_data.dart';
import 'package:paoly/data/pet_data.dart';
import 'package:paoly/services/auth_scope.dart';
import 'package:paoly/widgets/auth_status.dart';

void main() {
  testWidgets(
    'magic link validates email, sends redirect, retries errors and completes without a code',
    (tester) async {
      SharedPreferences.setMockInitialValues({'lang_code': 'en'});
      final settings = AppSettings();
      await settings.load();
      final data = FinanceData(pet: PetData.detached());
      final requests = <http.Request>[];
      var failSend = false;
      final client = (await tester.runAsync(() async {
        final result = SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
          httpClient: MockClient((request) async {
            requests.add(request);
            return failSend
                ? http.Response(
                    '{"msg":"Try later","code":"over_email_send_rate_limit"}',
                    429,
                  )
                : http.Response('{}', 200);
          }),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return result;
      }))!;
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AuthScope(
          client: client,
          child: MaterialApp(
            home: Scaffold(
              body: AuthStatus(settings: settings, data: data),
            ),
          ),
        ),
      );
      expect(find.text('Guest mode'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(jsonDecode(requests.single.body)['email'], 'guest@example.com');
      expect(
        requests.single.url.queryParameters['redirect_to'],
        'com.paoly.app://login-callback/',
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Verification code'), findsNothing);
      expect(find.textContaining('Link sent.'), findsOneWidget);
      failSend = true;
      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not send link. Check your email and connection, then retry.',
        ),
        findsOneWidget,
      );
      expect(find.text('guest@example.com'), findsOneWidget);
      failSend = false;
      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(3));
      expect(requests.every((r) => r.url.path.endsWith('/otp')), isTrue);
      // Simulate the SDK completing the email callback: no typed OTP required.
      await client.auth.setInitialSession(
        jsonEncode({
          'access_token': 'test-token',
          'token_type': 'bearer',
          'refresh_token': 'test-refresh',
          'expires_in': 3600,
          'user': {
            'id': 'user-a',
            'app_metadata': {},
            'user_metadata': {},
            'aud': 'authenticated',
            'created_at': '2026-10-02T00:00:00Z',
          },
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
      settings.dispose();
      addTearDown(client.dispose);
    },
  );
}
