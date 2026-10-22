# Android test APK permission change — 22 October 2026

The owner reported that Play Protect blocked an APK downloaded from GitHub
Actions and approved removing the optional volume-button trigger. The old APK
declared an accessibility service. Google identifies accessibility declarations
as a reason Internet-sideloaded apps can be blocked in supported markets; the
phone's exact warning/classification has not been independently inspected.

## Change

- Removed the Android accessibility service, manifest entry, key interception,
  resources, native-channel methods and volume-trigger settings/UI.
- Old saved `volumeTrigger` options are ignored. Historical `VOLUME_TRIPLE`
  incidents still decode; unsupported native events cannot start an SOS.
- Kept on-screen SOS, power, shake, voice, escort and duress flows, including
  emergency `SEND_SMS`. Updated website copy and current release/QA guidance.
- Added an APK permission audit to Android CI and signed packaging. It checks
  the binary manifest as well as requested permissions, since service bindings
  do not appear in a simple permission list.

## Verification

- Flutter analysis: no issues. Full suite: **219 passed**.
- Domain/data coverage: **87.4%**, 994/1137 lines; 80% gate passed.
- Kotlin detector tests: **7 passed**, no failures/errors.
- Android debug build and APK signature verification: passed (debug certificate).
- Old APK: audit correctly rejected its accessibility declaration.
- New APK: audit passed. No accessibility service/binding, notification listener,
  SMS-reading/receiving or call-log-reading permissions; `SEND_SMS` retained.
- Website: **77 tests passed** and production build/typecheck passed.
- Production browser smoke: desktop/mobile, reduced-motion story, tracker demo,
  simulated offline dispatch and fallback without WebGL passed.

## Test package

File: `output/android/shakti-test-2026-10-22.apk` (201,907,926 bytes).

SHA-256:

```text
6684d12c995d71e7f341416e91683e1b2e8f37c47547b73f1f967b0910632a45
```

This is a debug-signed development APK with the existing offline configuration,
not a Google-approved or Play-distributed release. Installation with Play Protect
enabled still needs checking on the owner's phone. No phone was attached, and
live SMS/provider delivery was not verified in this run. Old GitHub Actions
artifacts retain their original APK; a new workflow run requires these changes
to be pushed. No remote push or Play upload was performed.

Official references:

- [Play Protect developer warning guidance](https://developers.google.com/android/play-protect/warning-dev-guidance)
- [SMS permissions and emergency exception](https://support.google.com/googleplay/android-developer/answer/10208820)
