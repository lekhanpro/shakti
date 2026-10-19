# Core feature coverage

Page numbers refer to the eight-page PDF, including its cover. This is a document-content check, not evidence that the app features already pass hardware testing.

| Spec ID | Capability | Plan coverage | Acceptance described |
|---|---|---|---|
| A1 | Triple power trigger | Pages 4, 6, 7 | Three toggles / 1.2 s; device and locked-screen verification. |
| A2 | SOS HUD | Pages 4, 5, 7 | Starts countdown; accessible 220 dp target and widget checks. |
| A3 | Abort countdown | Pages 4, 6, 7 | Default five seconds; swipe cancellation; fake-clock tests. |
| A4 | Shake/fall detector | Pages 4, 6, 7 | 2.8 g, zero crossings, debounce and false-trigger traces. |
| A5 | Voice keyword | Pages 2, 4, 7 | Foreground/permitted escort operation; real adapter and permission handling. |
| B1 | Location breadcrumbs | Pages 3, 4, 6, 7 | Ten-second interval, durable queue, freshness, reconnect and restart. |
| B2 | Carrier SMS | Pages 2, 4, 6, 7 | All active contacts; no network gate; cached/missing GPS; real SIM test. |
| B3 | Telegram | Pages 3, 4, 6, 7 | Authenticated owned-incident dispatch, escaping and online/queued results. |
| B4 | Walk With Me | Pages 5, 6, 7 | Persisted deadline, PIN check-in, expiry to SOS and timer tests. |
| B5 | Destination proximity | Pages 5, 6 | Active-escort 150 m arrival check, PIN confirmation and arrival-case check. |
| C1 | AI guardian chat | Pages 3, 5, 6, 7 | Validated/rate-limited server proxy, bounded responses and offline tips. |
| C2 | FIR drafting/PDF | Pages 5, 6 | User-reviewable draft and PDF export, with offline fallback. |
| C3 | Crisis handoff | Pages 5, 6 | Crisis-call actions and helpline numbers; exercise in guidance tests. |
| D1 | Safety map | Pages 3, 5, 6 | Location, haven markers and cached/unavailable-data states. |
| D2 | Nearby havens | Pages 3, 5, 6 | 5 km search; tagged 24/7 pharmacies; timestamps and contact actions. |
| D3 | Suggested walking routes | Pages 3, 5, 6 | Walking-capable routing, proximity scoring and timeout handling. |
| E1 | Fake call | Pages 5, 6, 7 | Presets, delay choices, ringtone/UI and device/widget verification. |
| E2 | Siren and strobe | Pages 4, 5, 6, 7 | Device adapters, explicit controls, capability checks and silence in duress. |
| E3 | Audio evidence | Pages 4, 5, 6, 7 | 60 s maximum, AES-GCM, secure key, playback/export/deletion and cleanup. |
| S1 | PIN/biometrics | Pages 4, 5, 7 | PBKDF2 parameters, lock timing, wrong-PIN lockout and local secrets. |
| S2 | Duress PIN | Pages 4, 5, 6, 7 | Notes decoy, immediate silent SOS and no revealing deterrence/haptics. |
| S3 | Onboarding | Pages 2, 5, 6, 7 | Four steps, explained permissions, contact/PIN setup and validation. |

The guardian tracker, web landing page, privacy controls, team ownership, risk mitigations, CI/release, costs, rollback, backups and maintenance appear on pages 2-8. Optional FCM, iOS, wearables, mesh and community heatmaps are explicitly future scope on page 6.
