# Paoly shared behavior

Visual context: [DESIGN.md](DESIGN.md). Scope: the finance and slip bug fixes from the October 2026 audit.

| Capability | Canonical owner | Behavior | Evidence |
|---|---|---|---|
| Entry | AddTransactionSheet | Positive finite amount; save awaits persistence; busy disables submission; retry reuses the same transaction identity and current input | finance_data_test.dart |
| Date | Flutter showDatePicker, PaolyApp localization delegates | Thai/English follows app locale; valid Gregorian dates in 1900–2100 | slip_scanner_test.dart |
| Delete | transaction_actions.dart | Confirm with transaction title, Cancel receives focus, removal offers 8-second Undo | transaction_actions_test.dart |
| Save feedback | FinanceSaveStatus | Persistent error banner with Retry; memory is retained on write failure | finance_data_test.dart |
| Categories | FinanceData.categoryFor | Store category ID; resolve current name by locale; deleted categories retain their saved fallback label | transaction_actions_test.dart |
| Rewards | FinanceData + PetData.syncIncomeRewards | One coin per cumulative 100 THB, calculated in cents; delete and Undo reconcile; already-spent reversals offset future rewards | finance_data_test.dart |
| Scanning | SlipScannerService | Enabled on Android/iOS only; picker and OCR errors handled; check widget lifecycle after awaits | slip_scanner_test.dart (parser only) |

Finance snapshot writes are serialized and versioned. Production defaults to memory-only guest storage; authenticated sessions use Supabase. The user request for optional login and non-persistent guest data supersedes the previous local-storage behavior. See [backend/data contract](docs/SUPABASE_SETUP.md).

| Capability | Canonical owner | Behavior | Evidence |
|---|---|---|---|
| Identity | SessionApp + AuthScope | Reset navigator/models on identity changes; block account UI until load succeeds; retry failed load | session_app.dart |
| Sign in | AuthStatus | Optional email confirmation link; Thai/English; field validation, pending, inline failure and guest exit; explain replacement of guest data | auth_status_test.dart |
| Storage | FinanceStore | Guest performs no personal-data disk/network writes; authenticated requests bind to user ID; RLS enforced server-side | guest_mode_test.dart, supabase_finance_store_test.dart, SQL migration |
| Conflict | FinanceSaveStatus | Refuse stale revision; explicit confirmation before replacing unsaved edits with cloud data | save_finance_state RPC |

Legacy on-device personal values are ignored and retained untouched. Language preference and authenticated session restoration are separate from finance persistence. Pet state is session-only. Native OCR accuracy, email delivery and deployed RLS require integration validation.
