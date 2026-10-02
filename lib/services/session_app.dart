import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../data/pet_data.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'auth_scope.dart';
import 'finance_store.dart';

/// Replaces the entire navigator and model on identity changes, so open forms
/// and Undo callbacks cannot transfer data between accounts.
class SessionApp extends StatefulWidget {
  const SessionApp({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<SessionApp> createState() => _SessionAppState();
}

class _SessionAppState extends State<SessionApp> {
  StreamSubscription<AuthState>? _subscription;
  FinanceData? _data;
  AppSettings? _settings;
  String? _userId;
  bool _loading = true;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.client?.auth.currentUser?.id;
    _load();
    _subscription = widget.client?.auth.onAuthStateChange.listen(
      (state) {
        final nextId = state.session?.user.id;
        if (nextId == _userId) return;
        _userId = nextId;
        _load();
      },
      onError: (Object error) {
        /* Operations expose recoverable UI errors. */
      },
    );
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final user = widget.client?.auth.currentUser;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final old = _data;
    _data = null;
    old?.dispose();
    if (old != null) {
      try {
        await old.flush();
      } catch (_) {
        /* Never transfer failed writes. */
      }
    }
    if (!mounted || generation != _generation) return;
    PetData.instance.resetSession();
    final settings = AppSettings();
    final data = FinanceData(
      store: user == null
          ? GuestFinanceStore()
          : SupabaseFinanceStore(widget.client!, user.id),
    );
    _data = data;
    try {
      await settings.load();
      if (user != null) {
        await settings.completeOnboarding(
          user.userMetadata?['display_name'] as String? ?? user.email ?? '',
        );
      }
      await data.load();
      if (!mounted || generation != _generation) {
        data.dispose();
        settings.dispose();
        return;
      }
      data.seedDefaultAccount();
      await data.flush();
      if (!mounted || generation != _generation) {
        data.dispose();
        settings.dispose();
        return;
      }
      setState(() {
        _data = data;
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      data.dispose();
      settings.dispose();
      if (mounted && generation == _generation) {
        _data = null;
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _data?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _failed) {
      return MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'โหลดข้อมูลบัญชีไม่ได้ กรุณาตรวจสอบการเชื่อมต่อ\nCould not load account data. Check your connection.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('ลองใหม่ / Retry'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await widget.client?.auth.signOut(
                                  scope: SignOutScope.local,
                                );
                              } catch (_) {
                                /* Keep error screen with retry. */
                              }
                            },
                            child: const Text('ออกจากระบบ / Sign out'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return AuthScope(
      client: widget.client,
      child: PaolyApp(
        key: ValueKey(_generation),
        settings: _settings!,
        data: _data!,
      ),
    );
  }
}
