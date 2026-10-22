# Shakti Implementation Plan

Scope update — 22 October 2026: the optional volume-key trigger and Android
accessibility service were removed at the project owner's request. Preserve
power, SOS, shake, voice, escort and duress triggers. Audit packaged APK permissions
using `scripts/verify_android_permissions.py`; ignore legacy volume settings.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Shakti personal-safety system (Flutter Android app, Supabase backend, Next.js guardian web) described in the spec.

**Architecture:** A clean-architecture Flutter app. Pure-Dart domain engines sit behind abstract ports (`lib/domain/services/services.dart`, `lib/domain/repositories/repositories.dart`), wired through Riverpod providers declared in `lib/core/di/providers.dart`. `lib/data` implements those ports with plugins and Drift. The features only consume providers. The backend is SQL migrations plus Deno edge functions. The web app is a Next.js guardian tracker.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13, flutter_riverpod 3.4, go_router 18, drift 2.35, supabase_flutter 2.17, flutter_map 8.3, another_telephony 0.4, record 7, cryptography 2.9, pdf/printing, Kotlin (Android API 36), Supabase Postgres + Deno, Next.js + Tailwind + Leaflet + Vitest.

**Spec:** `docs/specs/2026-09-29-shakti-design.md`

## Global Constraints

- Toolchain: Flutter `D:\tools\flutter\bin\flutter`. Set `PUB_CACHE=D:\tools\pub-cache`. JDK `D:\tools\jdk\jdk-21.0.12.1+1`. Android SDK `D:\tools\android-sdk`.
- The domain layer (`lib/domain/**`) must not import `package:flutter` or any plugin.
- Plugin imports are allowed only in `lib/data/**`, `lib/bootstrap.dart` and `android/`.
- Features read dependencies only through the providers in `lib/core/di/providers.dart`. Never construct `lib/data` classes in a feature.
- Riverpod 3 `Notifier`/`AsyncNotifier` written by hand. No code generation except Drift.
- Colours and type come only from `lib/core/theme/tokens.dart` (`ShaktiColors`, `ShaktiSpace`, `ShaktiRadius`, `ShaktiMotion`). No raw hex values in features.
- Minimum tap target is 48 dp. Every interactive widget gets a `Semantics` or tooltip label. Honour `MediaQuery.disableAnimationsOf`.
- Helplines: 112 (emergency), 181 (women helpline), 1091 (women police), 1098 (child).
- Secrets: the client holds only `SUPABASE_URL` and `SUPABASE_ANON_KEY`, passed with `--dart-define`. Groq, Telegram and FCM keys are edge-function secrets only.
- The SOS path must never await a network call before the SMS is handed to the carrier.
- Coverage: at least 80% on `lib/domain` and `lib/data`, excluding generated `*.g.dart`.

## Review Focus

1. No SIM, no SMS permission, or zero active contacts: the SOS still saves locally, the checklist shows SMS as failed with a reason, and the remaining channels continue. Tested in `panic_controller_test.dart`.
2. Location times out, or permission is denied: the SMS goes out with "location unavailable" and falls back to the last known fix. Tested in `panic_controller_test.dart`.
3. A double trigger (a second tap or shake during the countdown or an active SOS) is ignored, with no second incident. Tested in `panic_state_machine_test.dart` and the controller test.
4. The app restarts during an active incident: `latestOpen()` restores the active screen. Tested in `incident_repository_test.dart`.
5. A malformed or hostile edge-function body is rejected with 400 or 401, never 500, and Telegram text is escaped. Tested in the Deno tests.

---

## File Map

| Area | Files |
|------|-------|
| Contracts (done) | `lib/core/result.dart`, `lib/domain/entities/*`, `lib/domain/services/services.dart`, `lib/domain/repositories/repositories.dart`, `lib/core/di/providers.dart`, `lib/features/panic/application/panic_view_state.dart` |
| Core UI | `lib/core/theme/{tokens,app_theme}.dart`, `lib/core/widgets/*`, `lib/core/router/app_router.dart`, `lib/app.dart`, `lib/main.dart`, `lib/bootstrap.dart` |
| Domain engines | `lib/domain/engines/{panic_state_machine,shake_filter,power_press_detector,proximity,escort_timer,safe_route_scorer,distress_classifier,pin_hasher,sms_composer,phone_number,voice_matcher,fir_template}.dart` |
| Data | `lib/data/local/{app_database,tables}.dart` + generated code, `lib/data/repositories/*`, `lib/data/services/*`, `lib/data/remote/*` |
| Features | `lib/features/{onboarding,lock,panic,contacts,safety_map,escort,ai_guard,de_escalation,evidence_vault,settings,home}/**` |
| Native | `android/app/src/main/kotlin/in/shakti/shakti/{MainActivity,GuardService,PowerPressCounter,BootReceiver}.kt`, `AndroidManifest.xml` |
| Backend | `supabase/migrations/*.sql`, `supabase/functions/{_shared,ai-guard,emergency-dispatch,guardian-invite}/**`, `supabase/tests/*.sql` |
| Web | `web/**` |
| CI | `.github/workflows/{ci,release}.yml` |

## Workstreams (parallelisable after Task 0)

### Task 0: Contracts and core UI (lead, sequential)
- [x] Entities, ports, providers and the panic view state
- [ ] `tokens.dart`, `app_theme.dart`, the core widgets (`ShaktiCard`, `SectionHeader`, `PrimaryButton`, `StatusPill`, `EmptyState`) and `app_router.dart` with stub screens
- [ ] `flutter analyze` is clean. Commit.

### Task 1: Domain engines (TDD)
The API of each engine is pinned in its own file header. For each engine: write the failing test in `test/unit/<engine>_test.dart`, run it and watch it fail, implement, run it and watch it pass, then commit.
- `PanicStateMachine`: states idle, countdown, active, resolved. Methods `trigger()`, `abort()`, `activate()`, `resolve()`, `reset()`. Illegal transitions return false.
- `ShakeFilter.push(x,y,z,at) -> bool`: net value above 2.8 g, at least 3 zero-crossings within 750 ms, 3 s debounce. Walking traces (1.2 g) and a single drop spike are rejected.
- `PowerPressDetector.onToggle(at) -> bool`: 3 toggles within 1200 ms, then reset.
- `Proximity.haversineM`, `Proximity.sortByDistance`, `Proximity.within`
- `EscortTimer`: start, extend, checkIn, remaining, expired. Takes an injected Clock.
- `SafeRouteScorer.score(route, havens) -> double` and `best(routes, havens)`
- `DistressClassifier.classify(text) -> DistressLevel {none, concern, danger}`, covering English, Hindi and Kannada keywords.
- `PinHasher`: PBKDF2-HMAC-SHA256, 100k iterations, a 16 B salt, a constant-time verify. Encoded as `v1$iter$saltB64$hashB64`.
- `SmsComposer.sos(...)` and `.safe(...)`: each message fits in 3 SMS segments at most.
- `PhoneNumber.normalize` / `isValid` (Indian mobile and E.164)
- `VoiceMatcher.matches(transcript, phrases)`: token-based and fuzzy (edit distance ≤ 1 per token).
- `FirTemplate.render(FirInput) -> String`: the offline FIR text, citing BNS 2023 sections.

### Task 2: Data layer
- Drift tables: contacts, incidents, breadcrumbs, havens_cache, safe_places, chat_messages, sync_queue, kv. Run `dart run build_runner build`.
- Repositories implementing each port. Tests use `NativeDatabase.memory()`.
- `SyncServiceImpl`: a queue with backoff (`2^attempts` s, capped at 5 min) that is flushed on connectivity. Tested with a fake remote.
- Remote clients use Dio and are tested with a fake `HttpClientAdapter`: `OverpassHavenService` (the query builder and parser), `NominatimGeocoding`, `OsrmRoutingService`, `SupabaseAiService`, `SupabaseCloudDispatch`.
- Plugin services (thin, not unit-tested): location, SMS, connectivity, battery, haptics, siren (plays `assets/audio/siren.wav`), strobe, audio evidence (record then AES-GCM encrypt), secure store, biometrics, native guard (MethodChannel `shakti/guard` and EventChannel `shakti/guard/events`), voice, shake sensor.
- `lib/bootstrap.dart` builds every override.

### Task 3: Panic pipeline + triggers
- `PanicController` in `lib/features/panic/application/panic_controller.dart` implements the pipeline from spec §4, using `Future.wait` with a per-channel timeout. Tests use fakes for every port, one test for each Review Focus item.
- `TriggerHub` (`lib/features/panic/application/trigger_hub.dart`) subscribes to native, shake and voice sources according to the settings.

### Task 4: Native Android
- Manifest permissions. `GuardService` (foreground service of type `location`, with screen receivers). `PowerPressCounter`. `BootReceiver`. `MainActivity` channels and FLAG_SECURE. Release signing from `key.properties`, if present.
- Verify with `flutter build apk --debug`.

### Task 5: Feature UI
Onboarding (4 steps), lock screen (PIN pad, biometrics, decoy), home/shield HUD (breathing SOS, status, quick actions), countdown overlay (ring and swipe-to-cancel), active SOS screen (channel checklist, timer, "I'm safe"), contacts CRUD, safety map (flutter_map, havens, route), escort (duration picker, ring, check-in), AI guard chat (chips, crisis banner, FIR PDF), fake call (incoming and in-call), siren/strobe screen, evidence vault, settings, and the decoy notes UI. Widget tests cover the HUD, countdown, contacts form, lock and fake call.

### Task 6: Supabase
- Migrations: the plan's 6 tables plus `share_token`, `covert` and `updated_at`, `push_tokens`, `rate_limits`, and guardian SELECT policies. A `track_incident(token)` RPC (security definer) lets the web view an incident by share token. Realtime publication.
- Functions with `_shared` (cors, auth, validate, telegram escape, rate limit). Every function has `deno test`.

### Task 7: Web
- Next.js App Router: the landing page and `/track/[token]` (Leaflet map, polling plus Realtime). Vitest covers the utils. `npm run build` passes.

### Task 8: CI, docs, final verification
- `ci.yml`, `release.yml`, `README.md`, `CLAUDE.md`, `docs/qa-checklist.md`.
- Run the full `flutter analyze`, `flutter test --coverage` and `flutter build apk --release`, plus the Deno tests and the web build, then do a final code review.
