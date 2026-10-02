# Optional Supabase login

Project: `mdmbgilrssqypanvnddp`. Its public URL/key are configured in `lib/main.dart` and `config/supabase.json`. No service-role credential belongs in the app.

## Activate the backend

1. Open the project's **SQL Editor** and run `supabase/migrations/202610020001_optional_auth.sql` once. It creates the per-user finance snapshot table, RLS and an atomic revision-checked save function. The table cannot be directly written by clients; anonymous clients have no access.
2. In **Authentication → Email Templates**, replace **Confirm signup** and **Magic Link** with `supabase/templates/magic_link.html`. The button must use `{{ .ConfirmationURL }}`, not `{{ .Token }}` or a plain redirect URL. This is Supabase's verification link, which verifies the email before returning to Paoly.
3. In **Authentication → URL Configuration → Redirect URLs**, add:
   - `com.paoly.app://login-callback/` for Android, iOS, macOS and packaged desktop apps.
   - Your exact web app URL (including deployment path/trailing slash), and `http://localhost:3000/` for local web testing. Set **Site URL** to the production web URL. Run local web with `flutter run -d chrome --web-port=3000` so the callback port stays fixed.
4. Keep Email provider/signup enabled and configure SMTP for production delivery. Users enter their email, tap **Send link**, then click the confirmation button in the email. There is no OTP field. The SDK uses PKCE, so open the link on the same device and, for web, the same browser where sign-in started. The app automatically loads the account after the SDK exchanges the callback code.
5. Run `flutter run` (uses the supplied project), or override with `flutter run --dart-define-from-file=config/supabase.json`. To test without an account service, pass empty `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` defines.

Android/iOS/macOS URL handlers are configured in the project. Windows MSIX declares the protocol and forwards callbacks to the existing instance; unpackaged Windows builds need an installer to register the same scheme. Linux uses GTK single-instance command-line forwarding; its installer must register a `.desktop` entry with `Exec=/absolute/path/to/paoly %u` and `MimeType=x-scheme-handler/com.paoly.app;` and set it as the scheme handler. Desktop/mobile OS activation still needs testing on each target platform.

Official references: [Magic links](https://supabase.com/docs/guides/auth/auth-email-passwordless), [Flutter deep links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter), [email templates](https://supabase.com/docs/guides/auth/auth-email-templates).

## Data behavior

- Guests use only in-memory finance, name and pet state. Closing/reloading the app drops new guest data. Language preference remains a device preference.
- Signing in replaces the guest notebook with the selected account's saved notebook; the login dialog explains this. No automatic guest/legacy upload or merging occurs.
- Supabase Auth owns email, identity and `display_name` metadata. `finance_states` holds accounts, balances, transactions and categories as one versioned JSON snapshot so each change is atomic.
- Signed-in auth sessions are restored by Supabase. Finance is fetched at login/startup and saved after edits; this is not offline storage or live multi-device subscription. Save failures retain the current in-memory edits and offer Retry. A conflicting device revision requires confirmed reload, never blind overwrite.
- Signing out waits for successful saves and resets the navigator and notebook. Old user data is not shown in guest mode. Pet gameplay is session-only in this version, including when signed in; finance-derived rewards are recalculated when finance loads.
- Existing legacy `finance_state_v1`, `user_name`, `onboarded` and `pet_state` preference values are left untouched and ignored by the production app. This avoids silently destroying or uploading old personal data. `LocalFinanceStore` is only an explicit legacy/test adapter.

## Verification before production

Unit/widget tests exercise guest no-persistence, storage ownership, revision requests, conflicts, save retry and magic-link request, resend, redirect selection and authentication-event handling using mocked HTTP. They do not prove deployed RLS or email delivery.

After applying SQL/templates, test a real email link on both a running and closed app, plus an expired/reused link: guest → sign in → create/edit/delete account entries → restart → same data; sign out → empty guest notebook; second user → isolated notebook. Use two sessions of the same account to verify the conflict banner and confirmed reload. Verify an anonymous request and user B cannot read/write user A's row. Test network failure/retry. Do not close the app while unsaved changes are indicated.
