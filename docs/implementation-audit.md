# Shakti implementation-plan audit

Reviewed: 21 October 2026 (IST). Baseline: `03b76190708bc21259c737ac24325603435095eb`.
Existing work branch: `docs/polished-project-readme`, head `f75d217c345f7cbcee9e497069d00ae751c24b4f`.
Scope is Android only. No iOS project, build or distribution is included.

## How to read this audit

The implementation plan and design spec are requirements, not proof of completion.
The rows below distinguish inspected source, test inventory and checks that need execution.
The last verified green run before these changes is [baseline CI](https://github.com/lekhanpro/shakti/actions/runs/39248683500).
It does **not** verify these PRs. Use each PR's checks and the combined Week 4 workflow
for current results. No local commands were run during this audit because the execution
environment was unavailable. No device, deployed-provider or signing result is invented.

## Feature traceability

Paths below are relative to the repository root. Existing test files are evidence of
test coverage intentions; only a successful run at the PR SHA establishes a pass.

| Spec ID | Requirement | Source / test evidence | Acceptance still requiring evidence |
|---|---|---|---|
| A1 | Triple power trigger | Kotlin PowerPressCounter and GuardService; app/test/unit/power_press_detector_test.dart; Android PowerPressCounterTest.kt | Locked screen, pocket behavior and OEM restrictions on real phones |
| A2 | 220dp SOS HUD, semantics | app/lib/features/home/presentation/home_screen.dart; app/test/widget/critical_flows_test.dart | TalkBack, 200% scaling and real-device ergonomics |
| A3 | Countdown, haptics, cancel | panic_controller.dart; countdown_ring.dart; critical_flows_test.dart; new panic_storage_failure_test.dart | New abort-completion regression must pass; real haptics |
| A4 | Shake filtering and debounce | app/lib/domain/engines/shake_filter.dart; shake_filter_test.dart; trigger_hub_test.dart | Physical walking/drop/false-trigger trials |
| A5 | Fuzzy voice keyword | voice_matcher.dart; PlatformVoiceTriggerService; voice_matcher_test.dart | Speech permission, recognition availability and lifecycle limits; no guaranteed screen-off microphone |
| B1 | Ten-second breadcrumbs and offline queue | PanicController; SyncServiceImpl; sync_service_test.dart | Actual upload freshness, reconnect and battery evidence |
| B2 | SMS to enabled contacts without internet gating | PlatformSmsService; panic_controller_test.dart; sms_composer_test.dart | SIM, denied permission, no network, actual receipt and latency |
| B3 | Telegram alert and tracker link | emergency-dispatch handler and handler_test.ts | Hosted secrets, configured destination and consenting recipient receipt |
| B4 | Escort timer, PIN and expiry SOS | EscortController; escort_timer_test.dart; supporting_controllers_test.dart; escort_lifecycle_test.dart | Stale PIN/expired-walk regression run; background hardware evidence |
| B5 | Safe-place arrival | EscortController.onFix and answerArrival; supporting_controllers_test.dart | Current behavior prompts and requires PIN before a safe-arrival SMS. Automatic arrival messages in the original wording are not implemented; retain this explicit deviation pending product review |
| C1 | AI chat and offline tips | AiController; SupabaseAiService; supporting_controllers_test.dart; ai-guard handler tests | Configured provider request, response length and failure behavior in deployment |
| C2 | AI/offline FIR and PDF sharing | fir_screen.dart; fir_pdf.dart; fir_template_test.dart | Real PDF export/share and reviewed legal wording |
| C3 | Crisis classification/banner | distress_classifier.dart; distress_classifier_test.dart; ai_guard_screen.dart | UI accessibility and contextual review; classification is not clinical assessment |
| D1 | Map and categorized havens | MapController; safety_map_screen.dart; supporting_controllers_test.dart | Device location/denial, map rendering and tile connectivity |
| D2 | Overpass 5km and 24/7 pharmacy filter | overpass_haven_service.dart; remote_test.dart; repositories_test.dart | Actual place accuracy/opening hours and one-tap dial on a handset |
| D3 | Scored walking alternatives | safe_route_scorer.dart; osrm_routing_service.dart; safe_route_scorer_test.dart | Provider support for walking alternatives and field route suitability |
| E1 | Fake call, presets and delay | fake_call_screen.dart; critical_flows_test.dart | Ringtone/vibration and screen behavior on physical hardware |
| E2 | Siren and strobe | PlatformSirenService; PlatformStrobeService | Playback volume follows device policy; system maximum-volume guarantee is not implemented. Torch/audio permissions and hardware behavior need tests |
| E3 | Encrypted 60s audio, vault/share | platform_evidence.dart; platform_evidence_test.dart; evidence_screen.dart | Actual microphone capture, storage interruption and replay/export |
| S1 | PIN hashing, biometrics and auto-lock | pin_hasher.dart; LockController; pin_hasher_test.dart; supporting_controllers_test.dart | Biometric device flows and background lock timing |
| S2 | Decoy PIN and silent immediate SOS | LockController; PanicController; critical_flows_test.dart; new storage-failure tests | No visible/sound side effects on a real handset; Android notifications and permissions |
| S3 | Four-step onboarding | onboarding_screen.dart; permission_gateway.dart; feature_screens_test.dart | Per-permission denial, contact setup and onboarding completion on hardware |

## Cross-system requirements

| Plan area | Existing implementation | Changes proposed across the review stack | Remaining gate |
|---|---|---|---|
| Domain / data | Pure Dart engines, Drift repositories and queue with tests | Preserve existing architecture; audit all acceptance IDs | Coverage >=80% for domain/data at exact tested SHA |
| SOS reliability | Independent channel dispatch, cached-location SMS | Settings failure fallback preserves known choices; unknown settings do not enable audio, sound or cloud; cancellation completes its pending operation; honest SMS status copy | New tests and device trials |
| Escort | Timer, arrival prompt and PIN | Generation-scoped pending work and deadline recheck | Regression tests, screen-off behavior |
| Guardian tracker | Token RPC, TTL and ten-second polling | Empty Realtime invalidation signals trigger token-checked refresh; polling fallback; stale-token responses ignored | SQL tests, hook tests and deployed WebSocket/reconnect verification |
| Web experience | Globe, city, guardian mesh, radar, triggers and AI demo | Retain original chapters, local Earth textures, added sculpture/walkthrough, motion controls, bounded intro and improved footer | Typecheck/tests/build and real browser smoke/screenshots |
| Database security | Core migration, RLS and token RPC assertions | Run migrations plus SQL assertions in disposable CI database; notification function adds no anonymous table grants | CI SQL result, then deployment check |
| Android builds | Signed release workflow exists but CI did not compile APK/native tests | Always compile debug APK and execute Kotlin tests in verification; release APK/AAB only after shared verification | Debug build CI; production keystore/configuration for signed release |
| Release | No GitHub releases were present at audit time | Private development-testing prerelease after every automated gate passes; SHA-256 checksum and clear configuration limitations | Actual successful publication, not merely workflow presence |
| Brand | Existing inline mark | Refined standalone logo and supporting README motion assets remain outstanding | Visual review; do not label current placeholder as finalized branding |

## Known specification differences

1. Public guardian links use `/track/[token]` and a restricted RPC, rather than mandatory guardian magic-link sign-in. Anonymous table grants remain revoked. Realtime signals contain no row data, and every refresh still uses token expiry checks.
2. Safe-place arrival requires a confirmed PIN before sending a safe-arrival message. Do not silently relabel detection as proof of safety.
3. A siren can play at the configured device volume; forced maximum system volume is not established.
4. Native power detection observes screen toggles. It does not directly intercept a power key.
5. Physical-device behavior, hosted service access, release signing, published Play alpha,
   community surveys and weekly review dates remain evidence gates.
6. Existing brand refinement is unfinished. The testing APK is a development build, not
   a claim that design, hardware validation or production readiness is complete.

## Verification and build matrix

| Gate | Workflow job / command | Evidence |
|---|---|---|
| Static app checks | flutter analyze | CI log at tested SHA |
| Unit/widget/data tests | flutter test --coverage --concurrency=1 | CI log and coverage artifact |
| Coverage | coverage_gate.awk, threshold 80% domain/data | CI output |
| Android compile | flutter build apk --debug | APK artifact |
| Kotlin detectors | gradlew :app:testDebugUnitTest | Native JUnit XML artifact |
| Backend | deno task check; deno task test | CI logs |
| SQL | fresh local migrations; rls_test.sql; realtime_test.sql | CI database log |
| Web | npm run typecheck; npm test; npm run build | CI logs |
| Browser | desktop/mobile, reduced motion, no-WebGL, walkthrough, demo route | Screenshots and Playwright assertions |
| Signed production packages | flutter build apk --release; flutter build appbundle --release | Release workflow, APK/AAB/mapping/symbols/checksums |
| Hardware/deployed integration | docs/qa-checklist.md | Actual model/OS/network/result/evidence, recorded separately |

A red, missing, cancelled or pending check blocks a claim of automated verification.
Workflow cleanup steps may run after failure, but are not substitutes for checks.
