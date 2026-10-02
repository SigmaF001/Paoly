import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FinanceStore {
  Future<String?> read();
  Future<void> write(String snapshot);
}

/// No disk or network access for guests.
class GuestFinanceStore implements FinanceStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String snapshot) async {}
}

/// Retained for explicit legacy import tooling and regression tests only.
class LocalFinanceStore implements FinanceStore {
  static const key = 'finance_state_v1';
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> write(String snapshot) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      snapshot,
    )) {
      throw StateError('Could not save finance');
    }
  }
}

class FinanceConflict implements Exception {}

class SupabaseFinanceStore implements FinanceStore {
  SupabaseFinanceStore(this.client, this.userId);
  final SupabaseClient client;
  final String userId;
  int _revision = 0;

  void _checkOwner() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Session changed');
    }
  }

  @override
  Future<String?> read() async {
    _checkOwner();
    final row = await client
        .from('finance_states')
        .select('snapshot, revision')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 20));
    _checkOwner();
    _revision = (row?['revision'] as num?)?.toInt() ?? 0;
    return row == null ? null : jsonEncode(row['snapshot']);
  }

  @override
  Future<void> write(String snapshot) async {
    _checkOwner();
    try {
      final result = await client
          .rpc(
            'save_finance_state',
            params: {
              'expected_revision': _revision,
              'new_snapshot': jsonDecode(snapshot),
            },
          )
          .timeout(const Duration(seconds: 20));
      _checkOwner();
      _revision = (result as num).toInt();
    } on PostgrestException catch (error) {
      if (error.code == '40001') throw FinanceConflict();
      rethrow;
    }
  }
}
