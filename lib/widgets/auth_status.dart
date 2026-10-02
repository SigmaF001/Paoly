import 'dart:async';
import '../services/auth_redirect.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_settings.dart';
import '../data/finance_data.dart';
import '../services/auth_scope.dart';

class AuthStatus extends StatelessWidget {
  const AuthStatus({super.key, required this.settings, required this.data});
  final AppSettings settings;
  final FinanceData data;

  @override
  Widget build(BuildContext context) {
    final client = AuthScope.clientOf(context);
    final user = client?.auth.currentUser;
    final th = settings.langCode == 'th';
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => ListTile(
        dense: true,
        leading: Icon(
          user == null ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
        ),
        title: Text(user?.email ?? (th ? 'โหมดผู้เยี่ยมชม' : 'Guest mode')),
        subtitle: Text(
          user == null
              ? (th
                    ? 'ข้อมูลจะหายเมื่อปิดแอป • เข้าสู่ระบบเพื่อเก็บข้อมูล'
                    : 'Data is lost when you close the app. Sign in to save.')
              : data.saveError != null
              ? (th ? 'ยังบันทึกไม่สำเร็จ' : 'Changes not saved')
              : data.isSaving
              ? (th ? 'กำลังบันทึก…' : 'Saving…')
              : (th ? 'บันทึกในบัญชีแล้ว' : 'Saved to your account'),
        ),
        trailing: TextButton(
          onPressed: () async {
            if (user == null) {
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => _EmailLogin(
                  client: client,
                  th: th,
                  name: settings.userName,
                ),
              );
            } else {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(th ? 'ออกจากระบบ?' : 'Sign out?'),
                  content: Text(
                    th
                        ? 'ข้อมูลที่บันทึกแล้วจะอยู่ในบัญชี และแอปจะเริ่มโหมดผู้เยี่ยมชมใหม่'
                        : 'Saved data stays in your account. A new guest session will start.',
                  ),
                  actions: [
                    TextButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(th ? 'ยกเลิก' : 'Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(th ? 'ออกจากระบบ' : 'Sign out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await data.flush();
                await client!.auth.signOut(scope: SignOutScope.local);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        th
                            ? 'ยังออกจากระบบไม่ได้ ตรวจสอบการเชื่อมต่อและการบันทึกข้อมูล แล้วลองใหม่'
                            : 'Could not sign out. Check connection and unsaved changes, then retry.',
                      ),
                    ),
                  );
                }
              }
            }
          },
          child: Text(
            user == null
                ? (th ? 'เข้าสู่ระบบ' : 'Sign in')
                : (th ? 'ออกจากระบบ' : 'Sign out'),
          ),
        ),
      ),
    );
  }
}

class _EmailLogin extends StatefulWidget {
  const _EmailLogin({
    required this.client,
    required this.th,
    required this.name,
  });
  final SupabaseClient? client;
  final bool th;
  final String name;
  @override
  State<_EmailLogin> createState() => _EmailLoginState();
}

class _EmailLoginState extends State<_EmailLogin> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  bool _sent = false;
  bool _completed = false;
  bool _busy = false;
  String? _error;
  String t(String th, String en) => widget.th ? th : en;
  @override
  void initState() {
    super.initState();
    _authSubscription = widget.client?.auth.onAuthStateChange.listen(
      (state) {
        if (state.session != null && mounted && !_completed) {
          _completed = true;
          Navigator.pop(context);
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(
            () => _error = t(
              'ลิงก์ไม่ถูกต้องหรือหมดอายุ กรุณาขอลิงก์ใหม่ แล้วเปิดบนอุปกรณ์และเบราว์เซอร์ที่ใช้เริ่มเข้าสู่ระบบ',
              'Link invalid or expired. Request a new link and open it on the same device and browser you used to sign in.',
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client!.auth
          .signInWithOtp(
            email: _email.text.trim(),
            emailRedirectTo: authRedirectUrl(),
            data: {'display_name': widget.name},
          )
          .timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = t(
            'ส่งลิงก์ไม่ได้ ตรวจสอบอีเมลและการเชื่อมต่อ แล้วลองใหม่',
            'Could not send link. Check your email and connection, then retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(t('เก็บบันทึกไว้กับคุณ', 'Keep your finance notebook')),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(
                    'กดลิงก์ยืนยันในอีเมลเพื่อเข้าสู่ระบบหรือสมัคร ข้อมูลทดลองในโหมดผู้เยี่ยมชมจะถูกแทนที่ด้วยข้อมูลในบัญชี',
                    'Click the confirmation link in your email to sign in or register. Guest entries will be replaced by your account data.',
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.client == null)
                  Text(
                    t(
                      'ยังไม่ได้เชื่อมต่อระบบบัญชี กรุณาใช้โหมดผู้เยี่ยมชมก่อน',
                      'Account service is unavailable. Continue as a guest.',
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: _email,
                    enabled: !_busy && !_sent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(labelText: t('อีเมล', 'Email')),
                    validator: (value) =>
                        RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(value?.trim() ?? '')
                        ? null
                        : t('กรอกอีเมลให้ถูกต้อง', 'Enter a valid email'),
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 12),
                    Text(
                      t(
                        'ส่งลิงก์แล้ว เปิดอีเมลแล้วกดยืนยันบนอุปกรณ์และเบราว์เซอร์ที่ใช้เริ่มเข้าสู่ระบบ หากไม่พบให้ตรวจสอบสแปม',
                        'Link sent. Open your email and confirm on the same device and browser you used to sign in. Check spam if needed.',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _sent = false;
                              _error = null;
                            }),
                      child: Text(t('เปลี่ยนอีเมล', 'Change email')),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(
            t('ใช้ต่อโดยไม่เข้าสู่ระบบ', 'Continue without signing in'),
          ),
        ),
        if (widget.client != null)
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: SizedBox(
              width: 120,
              height: 24,
              child: Center(
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _sent
                            ? t('ส่งลิงก์อีกครั้ง', 'Resend link')
                            : t('ส่งลิงก์ยืนยัน', 'Send link'),
                      ),
              ),
            ),
          ),
      ],
    ),
  );
}
