# Google Play closed alpha release

Status: release preparation. A successful local build is not a Play rollout. Record the Console release ID, signed bundle hash, review outcome and tester opt-in URL before marking the alpha live.

## Release gates

1. Run Flutter analyze and tests (use `flutter test --concurrency=1` on memory-constrained machines), native `./gradlew :app:testDebugUnitTest`, backend checks/tests, and web typecheck/tests/build. Keep the logs with the review evidence.
2. Complete physical-device checks in `docs/qa-checklist.md`, including denied permissions, no internet with cellular SMS, no cellular service, locked/background behavior, SOS cancellation, silent duress, resolution, evidence replay and guardian token expiry. Use consenting test contacts; record handset/Android version and observed results. Unit tests cannot certify SMS delivery or background survival.
3. Deploy migrations and Edge Functions to the alpha Supabase project; configure server-only provider keys. Deploy the website and test an actual incident token from a consenting device. Confirm privacy/support/deletion URLs are reachable and match actual behavior.
4. Configure the permanent application ID `in.shakti.shakti` and an increasing `versionCode`. Preserve the upload key securely. Do not regenerate it for weekly academic review snapshots.
5. Create ignored `app/android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. `storeFile` resolves relative to `app/android/app`. Never commit this file or the keystore. Release packaging now fails if signing is absent; local debug builds remain available.
6. Build using Flutter's release AAB command with `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `TRACK_BASE_URL` defines. Only client-safe public Supabase configuration belongs in the app. Keep obfuscation symbols and R8 mapping files privately for crash diagnosis.

```powershell
# From app/, after securely configuring signing and public alpha configuration:
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=alpha-config.json
```

Keep `alpha-config.json` outside source control. Its three keys are `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `TRACK_BASE_URL`. The bundle is `app/build/app/outputs/bundle/release/app-release.aab`. Inspect its certificate, package ID, version and merged permissions before uploading. The GitHub release workflow requires signing and endpoint secrets, builds artifacts, and does not submit them to Play automatically.

## Console setup and policy declarations

Use **Testing > Closed testing**, create an alpha track, select countries, add consenting tester email lists or a Google Group and publish the opt-in link after the release is available. Complete store listing, content rating, target audience, app access instructions, privacy policy, Data safety and account/data-deletion disclosures from the actual app and backend behavior.

The current manifest requests SMS, precise/background location, microphone, camera, notifications, foreground services, accessibility binding and full-screen intent. Review the final merged manifest and remove any permission the release does not actually need. Supply prominent in-app disclosure and consent where required. Do not label the accessibility service as a disability accessibility tool unless that is its actual primary purpose. Document hardware-trigger behavior and manual fallback accurately. Full-screen intent and background microphone behavior need real-device validation and policy review; a fake-call feature alone does not prove eligibility.

Google lists physical-safety/emergency alerts as a possible `SEND_SMS` exception, subject to the declaration and review. Permission approval is not automatic. Explain cellular/SIM/plan requirements; avoid claiming SMS works without cellular coverage. Do not claim police integration, guaranteed rescue, or guaranteed safe routes.

For personal developer accounts created after 13 November 2023, Google currently requires at least 12 opted-in closed testers for 14 continuous days before applying for production access. This does not prevent preparing a closed alpha now and cannot be shortened by implementing all four academic weeks at once. Follow the requirements actually displayed for the account.

## Controlled rollout and recovery

- Upload the signed AAB, review pre-launch findings, add release notes describing tested features and limitations, then submit the closed-track release for review.
- Record reviewer status, approved version, SHA-256, opt-in URL and a screenshot of track availability. Until these exist, report the release as prepared or under review, not live.
- Collect tester feedback with device/version and sanitized reproduction steps. Never include PINs, guardian tokens, precise locations or audio in public issue reports.
- If a serious defect occurs, halt further distribution using available Console controls and distribute a fixed bundle with a higher version code. Do not expect an older version code or Git checkout to downgrade installed apps. Use forward-compatible database migrations and tested backups.
- Lekhan owns signing/builds, Vikat backend recovery, Manas web/store presentation and Hemanth physical QA/tester evidence. These are project responsibilities, not evidence of Console access.

## Official references (checked 19 October 2026)

- [Set up internal, closed or open tests](https://support.google.com/googleplay/android-developer/answer/9845334)
- [Testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Declare permissions](https://support.google.com/googleplay/android-developer/answer/9214102)
- [SMS permission exceptions](https://support.google.com/googleplay/android-developer/answer/10208820)
- [Sensitive permissions and APIs](https://support.google.com/googleplay/android-developer/answer/16558241)
