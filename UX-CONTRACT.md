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

Finance snapshot writes are serialized and versioned. Rewards reconcile after finance persistence and again at startup so interrupted updates do not duplicate awards. Unreadable finance snapshots stop startup rather than overwrite stored data. Existing pet coins remain a legacy balance because historical finance data was not stored by prior versions.

Storage uses the existing shared_preferences dependency; this is local persistence, not backup, encryption, or a cross-device database. Native disk durability and kill/relaunch still require device validation. Native camera permission and OCR image accuracy are not proven by widget or parser tests.
