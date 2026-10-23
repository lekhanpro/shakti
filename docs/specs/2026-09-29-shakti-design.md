# Shakti: Personal Safety Network (Design Spec)

Update — 22 October 2026: the project owner removed the optional volume-key SOS
trigger and its Android accessibility service after a downloaded APK was blocked
by Play Protect. Legacy volume settings are ignored; historical incident types
remain readable. Other triggers and emergency SMS sending remain in scope.

VTU 1BCP308 Community Project, Topic #25. The source plan is `../AEGIS_SHAKTI_MASTER_IMPLEMENTATION_PLAN.tex` (v3.0). This spec replaces it wherever the two differ. Every change is listed under "Deviations".

## 1. Goal and success criteria

Shakti is an offline-first Android safety app for women. Its guardians are family, friends and campus security, and they need no app to receive alerts.

The work counts as done when all of these hold:
- `flutter analyze` reports 0 errors and 0 warnings.
- `flutter test --coverage` passes, with at least 80% line coverage on `lib/domain` and `lib/data`.
- `flutter build apk --release` succeeds.
- The edge functions pass `deno test`.
- The web app passes `npm run build` and its tests.
- The SOS path works with no network. The local write and the SMS never wait on a network call.
- Trigger latency is under 1.2 s from the end of the countdown to the SMS send call. Cold start is under 1.5 s on a mid-range device. These are checked on real hardware by QA.

Out of scope for automated verification: real SMS delivery, power-key behaviour on a physical device, and 24 h battery drain. Section 12 covers those manual checks.

## 2. Repository layout

```
Shakti/
  app/                Flutter 3.47 / Dart 3.13 Android app
  supabase/           migrations/, functions/ (Deno), tests
  web/                Next.js guardian tracker + landing page
  docs/specs, docs/plans
  .github/workflows/  ci.yml (PR) + release.yml (v*.*.* tags)
  CLAUDE.md
```

## 3. App architecture (clean architecture, feature-first)

```
lib/
  core/        theme/ (tokens, AppTheme), widgets/, router/, utils/, env/, result.dart
  domain/      entities/ (Incident, EmergencyContact, SafeZone, Breadcrumb, UserSafetyProfile)
               engines/  PanicStateMachine, ShakeFilter, PowerPressDetector, ProximityEngine,
                         EscortTimer, SafeRouteScorer, DistressClassifier, PinHasher
               repositories/ (abstract), usecases/
  data/        local/ (Drift AppDatabase + DAOs), remote/ (Supabase, Overpass, Nominatim, OSRM, AI),
               services/ (sms, location, audio evidence, siren, haptics, platform channel),
               repositories/ (impl)
  features/    onboarding, auth, lock, panic, contacts, safety_map, escort, ai_guard,
               de_escalation (fake call, siren), evidence_vault, settings
```

Rules:
- The domain layer is pure Dart with no Flutter or plugin imports. It is 100% unit-testable.
- Every plugin sits behind an interface in `data/services`, so tests use fakes.
- State management: Riverpod 3 (`Notifier`/`AsyncNotifier`, written by hand, no codegen). Routing: go_router with a `StatefulShellRoute` for the 5 tabs.
- Errors: a `Result<T>` sealed class at repository boundaries. No exceptions leak into the UI.

## 4. Emergency pipeline

```
trigger(source) -> PanicStateMachine: idle -> countdown(5s, haptic tick each second)
   abort (swipe or PIN) -> idle
   timeout -> active:
     1. Drift insert Incident(status=ACTIVE, synced=false)           [local, awaited]
     2. parallel, each isolated with its own try/catch and timeout:
        a. SMS to all active contacts (GPS link + address, if cached) [offline]
        b. AudioEvidence.start(60s, AES-GCM encrypted at rest)
        c. Siren (unless stealth, silent or decoy)
        d. if online: edge fn emergency-dispatch -> Telegram + FCM
     3. BreadcrumbStreamer every 10s -> Drift, then a sync queue -> Supabase live_breadcrumbs
   resolve (PIN) -> resolved | falseAlarm; send an "I am safe" SMS and Telegram message
```

Trigger sources: HUD tap, triple power press (native), shake/fall, voice keyword, escort timer expiry, decoy PIN entry.

The dispatch result records which channels succeeded. The UI shows each one as a live checklist.

## 5. Native Android (Kotlin)

- `ShaktiGuardService`: a foreground service of type `location` with a persistent low-priority notification. It registers `SCREEN_OFF`/`SCREEN_ON` receivers. 3 toggles within 1.2 s send `onPowerTrigger` over the `MethodChannel("shakti/guard")` and launch the app with an SOS intent.
- `FLAG_SECURE` is toggled by a method call. It is on by default.
- Receiving boot restarts the guard service if the user enabled it.

## 6. Data

Drift tables: `contacts`, `incidents`, `breadcrumbs`, `safe_zones_cache`, `chat_messages`, `sync_queue`, `settings_kv`.

Supabase: 6 tables from the plan, plus `push_tokens` and `rate_limits`. RLS is on for all of them. Guardians with an ACCEPTED invite can SELECT the owner's incidents and breadcrumbs. `live_breadcrumbs` allows INSERT by the incident owner. Realtime publication covers `live_breadcrumbs` and `incident_reports`.

Sync: the `sync_queue` rows (op, table, payload, attempts) drain on connectivity-regained with exponential backoff. The last write wins, keyed on `updated_at`.

## 7. Edge functions (Deno)

- `ai-guard`: verifies the JWT through `supabase.auth.getUser`. Allows 20 requests per minute per user through the `rate_limits` table. Proxies Groq `llama-3.3-70b-versatile`. Modes: `chat` and `fir`. Input is validated and capped at 20 messages of 2 000 characters each.
- `emergency-dispatch`: verifies the JWT and checks that the incident belongs to the caller. Sends Telegram messages with MarkdownV2 escaping, and FCM through the HTTP v1 API if a service account is set. Updates the `telegram_broadcast_sent` flag.
- `guardian-invite`: creates and accepts invite codes.
- Every function uses shared `_shared/` helpers (cors, auth, json, escape) and has `deno test` coverage.

## 8. Features and acceptance criteria

| ID | Feature | Acceptance |
|----|---------|------------|
| A1 | Triple power press | 3 screen toggles in 1.2 s trigger the countdown. Detector unit-tested. |
| A2 | SOS HUD | 220 dp breathing button. A tap starts the countdown. Semantics label present. |
| A3 | 5 s abort ring | Haptic tick each second. Swipe-to-cancel slider. Tested with a fake clock. |
| A4 | Shake/fall | >2.8 g, at least 3 zero-crossings in 750 ms, 3 s debounce. Walking and a dropped-phone trace are rejected in tests. |
| A5 | Voice keyword | `speech_to_text` listens while the app is open or an escort is active. Matching is fuzzy and case-insensitive. |
| B1 | Breadcrumbs | Every 10 s during an active incident. Queued offline. |
| B2 | SMS failover | `another_telephony`, multipart, all active contacts. |
| B3 | Telegram room | Via the edge function. The link goes to the web tracker. |
| B4 | Walk With Me | The user sets a duration. Check-in needs the PIN. Expiry triggers the timer source. |
| B5 | Safe-zone arrival | A geofence radius of 150 m pings guardians on entry. |
| C1 | AI chat | Chat UI with suggestion chips, answers under 150 words. Falls back to offline tips. |
| C2 | FIR generator | AI draft, then a PDF (`pdf` + `printing`), then a share sheet. Also works offline from a template. |
| C3 | Crisis handoff | `DistressClassifier` shows a 112/181/1091 banner on danger keywords. |
| D1 | Map | `flutter_map` with OSM tiles, user location, and POI markers by category. |
| D2 | Overpass | Police, hospitals and 24/7 pharmacies within 5 km. Cached in Drift for offline use. One-tap dial. |
| D3 | Safe route | OSRM walking alternatives are scored by haven proximity. The top route is drawn. |
| E1 | Fake call | Full-screen incoming-call UI, ringtone and vibration, a scheduled delay, and a caller preset. |
| E2 | Siren and strobe | A generated dual-tone siren at max volume, plus torch strobing. |
| E3 | Audio evidence | 60 s AAC, encrypted, listed in the Evidence Vault, shareable. |
| S1 | PIN and biometrics | PBKDF2-SHA256 with 100k iterations and a 16-byte salt, stored in secure storage. The app locks after 60 s in the background. |
| S2 | Decoy PIN | Shows a harmless "Notes" UI and silently fires an SOS with no siren or haptics. |
| S3 | Onboarding | 4 steps: welcome, permissions (explained one by one), contacts (at least 1), PIN. |

## 9. UI/UX design system

Updated 22 October 2026 for the owner's approved dark liquid-glass redesign.
Root `DESIGN.md` and `.impeccable/design.json` record the current Android system;
the website retains its separate design record.

- Tone: calm, confident, and dark-first. It will be used at night and under stress.
- Palette tokens: Rose `#E11D48` for SOS, indigo `#4F46E5` identity and lilac `#B6AAFF` primary controls. Emerald `#10B981` for safe states and amber `#F59E0B` for caution/countdown. Graphite ground `#080B15`, reflective surfaces `#151A2B`/`#20263D`, and legible bright text.
- Type: Manrope headings and Inter body/controls, bundled offline with OFL licenses (no runtime font fetch).
- Scale: a 4-pt grid, 24 dp grouped surfaces, 24 dp page inset, and a minimum tap target of 48 dp (the SOS button is 220 dp).
- Motion: 140 ms press feedback, 240 ms navigation, 300 ms state changes with ease-out. The SOS breathes over 1.6 s. Everything respects `MediaQuery.disableAnimations`; high-contrast/accessibility settings use opaque glass fallbacks.
- Accessibility: Semantics on every control, text scaling up to 200% without clipping, no information conveyed by colour alone (always an icon or label too), and haptics that mirror visual state.
- Stress-mode UX: during the countdown and an active incident, the screen strips down to one primary action and large type, and shows a live channel checklist.
- Stealth theme: the decoy UI uses a neutral grey "Notes" look.

## 10. Web (guardian tracker + landing)

- Next.js App Router, TypeScript and Tailwind.
- `/`: a landing page with the product story, feature grid, how-it-works steps and a download CTA.
- `/track/[incidentId]`: the guardian signs in with a magic link. The page shows a Leaflet map with a live breadcrumb polyline through Supabase Realtime, plus status, battery, last update and a call button.
- Vitest tests cover the formatting and geo utilities.

## 11. Security and privacy

- No secrets in the client except the Supabase URL and anon key. Groq, Telegram and FCM keys live only in edge function secrets.
- RLS is on for every table, and policies are tested through SQL assertions in `supabase/tests`.
- The PIN never leaves the device. Evidence is encrypted at rest with a key held in secure storage.
- Android permissions are requested just in time, each with a rationale screen: location (plus background, only for escort), SMS, microphone, notifications and foreground service.
- The app has no analytics or ad SDKs.

## 12. Testing

- Unit tests: every domain engine, the repositories with fakes, and the sync queue.
- Widget tests: panic HUD, countdown, contacts form, fake call, lock screen and onboarding.
- Deno tests: validation, escaping and auth rejection for each function.
- Web: Vitest.
- Manual hardware checklist (`docs/qa-checklist.md`): power press on Android 12, 13 and 14, SMS latency, and a 24 h battery run.

## 13. CI/CD

- `ci.yml` (on PR/push): Flutter analyze, test and coverage gate. Deno check and test. Web build and test.
- `release.yml` (on `v*.*.*` tags): the keystore comes from secrets. Builds a signed APK and an AAB, then uploads them as artifacts and to a GitHub Release.

## 14. Deviations from the source plan

1. The package versions in the plan are too old to resolve on Flutter 3.47. The swaps are `telephony` to `another_telephony`, `maplibre_gl` to `flutter_map`, Riverpod 2 to Riverpod 3 (no codegen), and Lottie to procedural animations (smaller APK).
2. A1 counts screen toggles, because an Accessibility Service can't intercept the power key on Android 10+.
3. A5 listens only in the foreground or during an escort, because of Android 14 microphone restrictions.
4. Firebase is optional, and the app runs without `google-services.json`. Auth uses Supabase (email OTP and Google through `signInWithIdToken`).
5. The helpline numbers are corrected: 112 national emergency, 181 women helpline, and 1091 women police.
6. Added: a sync queue, the guardian web tracker, the `guardian-invite` function, the evidence vault, onboarding, and rate limiting.
