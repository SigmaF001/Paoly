import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paoly/services/finance_store.dart';

String session(String id) => jsonEncode({
  'access_token': 'test-token',
  'token_type': 'bearer',
  'refresh_token': 'test-refresh',
  'expires_in': 3600,
  'user': {
    'id': id,
    'app_metadata': {},
    'user_metadata': {},
    'aud': 'authenticated',
    'created_at': '2026-10-02T00:00:00Z',
  },
});

void main() {
  test('cloud read filters owner and commits with loaded revision', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'snapshot': {'version': 1},
              'revision': 7,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        expect(jsonDecode(request.body)['expected_revision'], 7);
        expect(jsonDecode(request.body)['new_snapshot'], {'version': 1});
        return http.Response(
          '8',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    await client.auth.setInitialSession(session('user-a'));
    final store = SupabaseFinanceStore(client, 'user-a');
    expect(await store.read(), '{"version":1}');
    expect(requests.single.url.queryParameters['user_id'], 'eq.user-a');
    await store.write('{"version":1}');
    expect(requests.last.url.path, '/rest/v1/rpc/save_finance_state');
    await client.auth.setInitialSession(session('user-b'));
    await expectLater(store.write('{}'), throwsStateError);
    await expectLater(store.read(), throwsStateError);
    expect(requests, hasLength(2));
    await client.dispose();
  });

  test(
    'conflict is recoverable and is never retried as a blind overwrite',
    () async {
      final revisions = <int>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          revisions.add(jsonDecode(request.body)['expected_revision'] as int);
          return http.Response(
            '{"code":"40001","message":"conflict"}',
            409,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      await client.auth.setInitialSession(session('user-a'));
      final store = SupabaseFinanceStore(client, 'user-a');
      await expectLater(store.write('{}'), throwsA(isA<FinanceConflict>()));
      await expectLater(store.write('{}'), throwsA(isA<FinanceConflict>()));
      expect(revisions, [0, 0]);
      await client.dispose();
    },
  );
}
