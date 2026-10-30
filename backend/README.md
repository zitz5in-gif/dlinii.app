# Dlinii: public places

The web Firebase configuration supplied by the project owner is wired in
`lib/firebase_bootstrap.dart`. Firebase Analytics is intentionally not initialized.
Email and password authentication, password reset, public reads, and owner-only
edit/delete calls are implemented. Credentials are handled by Firebase Auth,
not stored in SharedPreferences or in public place documents.

## Before enabling public publishing

1. Enable Email/Password in Firebase Authentication for project `dlinii`.
2. Replace the old expiring allow-all rules with the complete `firestore.rules`.
   This includes authenticated reports and atomic per-account votes; deploy the
   updated Flutter source alongside the rules. Older clients cannot write reports.
3. Test these cases in the rules emulator: unauthenticated reads succeed;
   unauthenticated writes fail; user A creates their own place; user B cannot
   edit/delete A's place; A can edit/delete it; A cannot change ownerUid;
   invalid coordinates, oversized fields, or unknown fields are rejected.
4. Deploy the reviewed rules and verify with two separate accounts.
5. Build with `--dart-define=PUBLIC_PLACES_ENABLED=true` only after that check.

Until then, public publishing is disabled and Add Place retains explicit
device-only saving. Existing local places are not uploaded automatically.
To publish a local place, open its details and select Publish after activation.

Published listings are streamed separately from personal history. Removing a
history entry does not delete its public listing. Only the owner sees the public
delete action, which asks for confirmation; Firestore rules enforce ownership
independently of the interface. Public data includes the creator UID but not
their email address. The current map stream loads the latest 1,000 places; a
geospatial viewport index/pagination is needed before scaling beyond that.

## Current verification limits

Eight voice-selection cases and the sheet regression test pass.
Dependencies have now restored successfully. home_screen.dart analysis has no
errors, one warning and 33 deprecation infos. Release web build passed, including the guest and account deletion controls.
Two account UI tests pass; no real account was deleted during testing.

## Local verification


```powershell
flutter pub get
flutter analyze
flutter test test/sheet_regression_test.dart
flutter run -d edge
```

The offline panel now describes the actual implementation: mobile downloads of
an area near the province centre. It does not claim full-province offline maps,
web persistence, or a new offline routing engine.

The local `third_party/flutter_map_vector_tiles` dependency retains its original
license and fixes font-family application and Arabic paragraph direction.
Do not remove it when copying these updated source files.

## Report votes

Reports are public to read. Creating requires email/password sign-in and an owner UID.
Each account can cast one immutable vote per report, atomically incrementing its counter.
At three end votes the app hides the report; it does not delete stored data automatically.
Existing legacy reports remain readable and votable; they have no owner UID for client deletion.
The five-minute report cooldown remains client-side, not server-enforced anti-spam.
No rules emulator or production two-account test has run; rules are prepared, not deployed.

Guest access closes the sign-in sheet without creating a Firebase identity.
Account deletion reauthenticates by password, deletes owned public places in
batches, then deletes the Auth user. Reports/votes and local history remain,
as disclosed in the confirmation. Cleanup is retryable but not atomic across
Firestore and Auth; production verification still requires deployed rules.
