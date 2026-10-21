# Shakti verification and brand handover

Verified on 21 October 2026 against the merged project (`8373ed9`) plus the emergency-isolation and brand changes in this chat. The four-week syllabus reviews remain in `docs/community-review/`; actual field activity, participant feedback and guide sign-off must be recorded separately.

## Automated evidence

| Check | Result |
|---|---|
| Flutter static analysis | No issues |
| App unit/widget/data tests | 214 committed tests passed |
| Local visual-authoring preview | One additional home-screen preview passed; excluded from Git because it uses machine-specific font paths |
| Final shared UI changes | 36 screen/critical-flow tests passed after the theme, home, settings and shared-logo updates; source hashes stayed unchanged during the run |
| Core coverage | 1003 / 1146 executable lines = 87.5%, using the repository's domain/data gate and excluding generated Drift files |
| Kotlin detector tests | 7 passed; zero failures/errors |
| Android debug packaging | Debug APK compiled successfully |
| Website unit/component tests | 77 passed across 9 test files |
| Website production build | Passed, including the explicit TypeScript check |
| Browser smoke | Desktop, mobile/reduced-motion, guardian demo, simulated offline dispatch, overflow and WebGL fallback passed |
| Deno functions | Type checks and 64 tests passed |
| Brand exports | 26 asset families; SVG outlines, PNG dimensions/alpha, embedded guide fonts, A4 size and ZIP integrity passed |
| Artwork rebuild | All 99 PNG/SVG/PDF visual exports retained identical SHA-256 hashes on a repeat build |

The earlier parallel Flutter run exhausted local memory. Serial execution completed successfully; no aborted run is counted as a pass. A shared-folder pull introduced merge conflicts during validation. Those were resolved while retaining the incoming settings-failure and escort-deadline protections, then analysis and the app suite were rerun. The website favicon was corrected to an RGBA ICO after the production decoder rejected an RGB ICO.

## Feature coverage and limits

| Requirement group | Evidence covered | Remaining real-world check |
|---|---|---|
| A1 / optional volume | Native detector windows, trigger routing, platform bridge | Physical power/volume keys, reboot, locked screen, OEM restrictions |
| A2–A3 | SOS semantics/size, countdown, cancellation, completion of the trigger future | Measured end-to-end latency on a real phone |
| A4–A5 | Shake traces, debounce, fuzzy voice matching and trigger routing | Sensor behaviour and speech recognition in noise / offline |
| B1–B3 | Local incident storage, outbox retry/batching, SMS composition, stalled-GPS isolation, cloud responses | Actual cellular delivery, Telegram/optional push delivery, background GPS |
| B4–B5 | Escort expiry, correct/wrong PIN, arrival checks, expiry during PIN verification | Screen-off timer reliability, actual destination/geofence accuracy |
| C1–C3 | AI/offline error state, retry, crisis classification, FIR templates and edge input/auth checks | Configured provider response quality, live service availability and user-reviewed FIR export |
| D1–D3 | Haven parsing, cache fallback, route scoring, API error handling; web tracker/demo tests | External tile, geocoding and walking-route service availability and physical accuracy |
| E1–E3 | Fake-call scheduling/answer/end, siren port, evidence encryption/decryption, tamper/path rejection | Phone volume/torch/microphone behaviour and share-sheet recipient flow |
| S1–S3 | PIN hashing/lockout, primary/duress unlock, silent SOS, contact/onboarding screens | OS permission prompts, device biometrics, background lifetime and secure-screen behaviour |
| Supporting UI | Settings, contacts, safe places, history, evidence and assistant screens; shared mark and network motif | Human accessibility and usability testing with consenting participants |

SMS status means Android accepted the send handoff; it does not establish carrier delivery. The late-result regression verifies that a previous incident's delayed SMS failure cannot alter a newer incident. Passing automated checks does not establish guaranteed rescue or safe routes.

## Reproduction

From `app/`, with the project's Flutter and `PUB_CACHE` configuration:

```text
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --coverage
```

From `app/android/`, with JDK 21 and the Android SDK configured:

```text
gradlew :app:testDebugUnitTest :app:assembleDebug --no-daemon --max-workers=1
```

This machine used a 1 GB Gradle heap and in-process Kotlin compilation for the successful run. Kotlin/AGP deprecation and compile-SDK support warnings remain; they did not prevent the build.

From `web/`: `npm test` and `npm run build`. The existing `scripts/browser-smoke.mjs` ran with isolated `@playwright/test@1.56.1` tooling under `tmp/browser-tools`. Browser captures are generated under ignored `web/test-results/`.

From `supabase/functions/`: `deno task check` and `deno task test`. From the repository: `python brand/tools/validate_brand.py`; rebuild the kit with `python brand/tools/build_brand.py` after installing `brand/tools/requirements.txt`.

## Handover and pending release gates

The brand kit is in `brand/`, including an offline `index.html`, editable outlines, bundled licensed typefaces, source generator, Play icon/feature graphic, social formats, presentation templates, A4 poster and a five-page guide. The download archive is `output/brand/shakti-brand-kit.zip`.

No Android device was connected during verification. A local Docker/Supabase daemon was unavailable, so fresh database migrations, SQL/RLS assertions and Realtime checks were not run locally. Live cloud integration was not verified using provider credentials. Keep these as explicit release gates rather than inferring them from mocked tests.

The APK is a debug testing build. No release AAB was signed or uploaded. Play Console access, upload signing, policy declarations, real-device QA and the eventual closed/open/production rollout remain pending as described in `docs/play-alpha-release.md`. No public release, community adoption or survey outcome is claimed.

Final UI APK: `output/android/shakti-debug.apk`. SHA-256: `9ef433f3c9324a378de9dd7520c0573f2fb97a05bebab18b7fd8909eb7c43f8a`.
