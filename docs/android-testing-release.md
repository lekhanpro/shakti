# Android testing and signed release delivery

Android only. No iOS artifacts are generated.

## Verification before publication

CI runs Flutter analysis/tests/coverage, debug APK compilation, Kotlin detector tests,
Deno checks/tests, fresh migrations plus SQL/RLS checks, and web typecheck/tests/build
plus Chromium interaction checks. A failed or missing dependency prevents the testing
publication job. No build/test step uses continue-on-error.

The Week 4 PR head is the combined checkpoint. CI may publish a private testing
prerelease only from the same-repository review/week-4-release branch after all five
verification jobs pass. The tag embeds the exact head commit SHA. It is labelled a
debug-signed, development-only, offline-configured APK; it does not claim production
signing or configured hosted services. Re-running a SHA replaces only its same-SHA
assets. SHA256SUMS accompanies the APK.

Download the APK from the private repository's Releases page, verify its checksum,
then sideload it on a test Android handset. Use informed test contacts, never real
emergency numbers. Different CI debug certificates may require uninstalling an
earlier APK; export test evidence before uninstalling because local data is removed.
For repeatable update installation use the signed release workflow with the same
project upload key.

## Signed release APK and AAB

The existing Release workflow now depends on the reusable full CI workflow before
packaging. Trigger it manually or by a v*.*.* tag only after reviewing the target
commit. It builds both release APK and release AAB, retains obfuscation symbols and
mapping, computes checksums, and attaches the packages to a tag release. Prerelease
tags remain labelled prerelease.

Required repository secrets:

- ANDROID_KEYSTORE_BASE64
- ANDROID_STORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD
- SUPABASE_URL
- SUPABASE_ANON_KEY
- TRACK_BASE_URL

Missing values fail explicitly; there is no debug-signing fallback masquerading as a
production release. Secrets are restored only in the packaging job and are never
committed. This audit did not inspect secret values or confirm they exist.

Supabase runtime provider secrets (AI/Telegram/optional FCM), migrations, anonymous
Auth and the web configuration must also be deployed and checked independently.
Creating a GitHub Release does not deploy the backend, configure Play Console,
prove message delivery or establish real-world safety.

## Required physical-device record

For each run record model, Android version, permissions, SIM/network state,
commit/package checksum, observed result and evidence. Follow docs/qa-checklist.md
for locked-screen power/volume triggers, real SMS receipt/latency, offline recovery,
duress side effects, recording/export, lock/biometric behavior and battery tests.

## Source references for the new verification work

- https://supabase.com/docs/guides/deployment/ci/testing
- https://supabase.com/docs/guides/realtime/broadcast
- https://docs.flutter.dev/deployment/android
