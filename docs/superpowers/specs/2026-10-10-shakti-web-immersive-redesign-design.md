# Shakti web: immersive redesign

Status: DRAFT for review. Nothing in `web/` has been changed yet.
Date: 2026-10-10.

## 1. Intent

Make the Shakti landing page feel like a top-tier immersive Next.js site: scroll-driven 3D, purposeful motion, and tactile interaction. The page is also the public face of the VTU 1BCP308 project, so every claim must match what the Shakti code does.

**Source of truth:** `Shakti/app`, `Shakti/supabase`, `Shakti/web/lib`. The Aegis site (`aegis-safety/`) is a content and idea source only. A claim from Aegis is used only if the Shakti code backs it.

**Success looks like**
- A first-time visitor understands in 10 seconds what happens when she presses the power button.
- The page has at least five distinct interactive or 3D moments, each tied to a real app behaviour.
- No sentence on the page overstates the app (see section 3).
- Reduced-motion and no-WebGL visitors get every word of content.
- Lighthouse performance 85+ on a mid-range phone profile, LCP under 2.5 s.

## 2. Constraints that stay

- Brand: indigo is the brand colour, emerald means safe, rose is only for emergency meaning (SOS affordance, active incident, helplines). Aegis's rose-as-brand look is not imported.
- Fonts: Bricolage Grotesque and Instrument Sans (local woff2 in `app/fonts`). Not Poppins or Nunito.
- Dark theme only. Tokens stay in `app/globals.css` and mirror `app/lib/core/theme/tokens.dart`.
- Next.js 16.3.7 with Turbopack, React 19.3, Tailwind 4. No custom `webpack` config. Read `node_modules/next/dist/docs` before any Next-specific code.
- Pure logic keeps its signatures and tests: `lib/story.ts`, `lib/press.ts`, `lib/track.ts`, `lib/demo.ts`, `lib/helplines.ts`. Baseline: 66 web tests pass.
- Exact version pins, as the repo already does.

## 3. Claim ledger (what the page may say)

Audit date 2026-10-10. Status comes from reading the code, not the docs.

Important finding: `app/lib/bootstrap.dart` returns `const []` and every platform port in `core/di/providers.dart` throws until overridden. Concrete SMS, location, siren, strobe, audio-evidence, battery, voice, shake-sensor, secure-store and biometric services do not exist in `lib/data` yet. Domain logic, UI and tests (on fakes) exist.

Policy proposed for review: **three tiers.**
- **Built:** written and tested in the repo. May be stated plainly.
- **In development:** domain logic exists, the platform service does not. State with a small "In development" tag, or leave it out of headlines.
- **Dropped:** not backed by Shakti code. Not on the page.

| Claim | Tier | Page wording |
|---|---|---|
| Power button x3 within 1.2 s | Built (native guard) | State plainly. |
| Volume x3 (opt-in) | Built | "Optional." |
| Shake 2.8 g | In development | Logic only, no sensor service. |
| Voice phrase | In development | Drop "never uploaded". Off by default. |
| Walk with me, PIN check-in | Built | State plainly. |
| Duress PIN | Built at the lock screen | "Opens a decoy and sends a silent SOS." Do not say "if someone forces you to cancel". |
| 5 s countdown, range 3 to 15 s | Built | Say "swipe to cancel", not "one tap". |
| SMS with no internet | In development | Composer exists, sender does not. Tag it. |
| Telegram | Built via edge function | Needs a chat ID set up, and a connection. |
| Push (FCM) | Dropped | No firebase dependency. Remove "and push". |
| Siren, strobe, torch | In development | Interface only. Drop "115 dB". |
| Fake call | Built (UI) | Delays 0, 10, 30, 60 s. |
| Encrypted audio evidence, 60 s | In development | Drop "key only it holds" until implemented. |
| Safety map | Built | Overpass: police, hospital, 24/7 pharmacy, shelter, 5 km. Drop "lit corridors". |
| AI guardian and FIR draft | Built | Groq `llama-3.3-70b-versatile`, offline fallback, crisis banner, FIR PDF. |
| Geofence arrival ping | Dropped | Only an escort-destination check exists. |
| Live tracker | Built, with a bug | See section 6. Polls every 10 s. Shows route, battery, distance, accuracy, speed. Address is resolved once, not every 10 s. |
| Tracker link expiry | Fix | The link stays valid for 24 h after the incident is resolved. Say that. |
| PIN hashing | Built | PBKDF2-SHA256, 100,000 iterations. |
| Min Android | Fix | Code says API 24 (Android 7.0). Page says 8. Use 7.0 or higher unless QA only covers 8. |
| Battery use, lock-screen reliability | Fix | Spec marks both as unverified hardware QA. Drop "No" and "works from the lock screen" as guarantees. |
| "The text goes first" | Fix | Local save and up to 3 s of GPS wait come first. Say "within seconds". |
| 12-feature "arsenal", competitor table, "Aegis Red", Android 9+, 18 MB, GPLv3 | Dropped | Not backed by Shakti. |
| Story HUD clock 0:00 to 0:54 | Label | Mark as "demo timeline". |

## 4. Page architecture

One route (`/`) plus the existing `/track/[token]`. Sections in order:

1. **Story (hero).** Keep the five-beat pinned night-street scene. Extend, do not replace.
2. **Triggers.** Keep `PressDemo`, upgrade it with a 3D-tilting phone and haptic-style feedback. Beneath it, the other triggers as a horizontally pinned rail, each tagged Built or In development.
3. **Guardian mesh.** A canvas of instanced points: the phone, then SMS, Telegram and the tracker link reaching guardians. Illustrative and captioned as such.
4. **Safety map.** A stylised, tilting map with the four place types and the 5 km radius. No live data on the landing page.
5. **AI guardian and FIR.** A scripted chat labelled "Demo", then the FIR draft sliding out. Facts from section 3.
6. **Privacy.** Only claims from the ledger.
7. **Helplines.** 112, 181, 1091, 1098. The one rose surface.
8. **FAQ.** Corrected answers.
9. **Download.** Same CTA and env var `NEXT_PUBLIC_DOWNLOAD_URL`.

## 5. Motion and 3D system

- **Scene:** keep `components/story/cityScene.ts` (vanilla three.js). Add bloom on lamps and the beacon through `postprocessing`, tiered: off on low-power devices, DPR capped at 1.5.
- **Scroll:** add Lenis. A single requestAnimationFrame owner drives Lenis, ScrollTrigger and the story progress, so they cannot fight. `ScrollStory` keeps reading `getBoundingClientRect`.
- **Text:** split-line and word reveals through CSS and IntersectionObserver. Plain text is the default and animation is an enhancement.
- **Pointer:** magnetic buttons and card tilt, fine-pointer only. No custom cursor on touch. The cursor is neutral, never rose.
- **Counters and progress:** count-up on real numbers only (1.2 s, 5 s, 10 s, 100,000, 4 helplines).
- **Not used:** React Three Fiber, shader-distortion heroes, heavy GLB models. The existing scene is tuned and adding a second renderer gains nothing.
- **Packages to add (pinned):** `lenis@1.3.26`, `gsap@3.15.0`, `postprocessing@6.39.5`, `motion@14.1.0`. Verify each against React 19.3 and three 0.186.1 at install time.
- **Reuse from Aegis, ported:** `Magnet`, `Tilt`, `Reveal`, `Count`, and the guardian-mesh canvas idea. The mesh pulse becomes indigo.

## 6. Tracker (separate decision)

The audit found `parseTrackResponse` expects `{incident, breadcrumbs[{latitude, longitude, battery_percentage}]}`. The real `track_incident` RPC returns a flat object with `last_address`, `latitude`, `longitude` and `breadcrumbs[{lat, lng, battery}]`. Against a real backend every token would read as "not found", and only `/track/demo` works. The realtime subscription also names `incidents`, but the table is `incident_reports`.

Proposed: fix the parser to match the RPC, add a test that uses the SQL's real shape, and remove or correct the dead realtime subscription. This is outside a visual redesign, so it is flagged for explicit approval at spec review.

## 7. Accessibility and performance

- `prefers-reduced-motion`: no pinning, no smooth scroll, no parallax. All beats are readable in order, and the scene draws one still frame.
- No WebGL: the CSS poster stands in, and copy never depends on the canvas.
- Keyboard: every interactive demo is operable without a pointer. Focus ring stays.
- Contrast: ink steps stay at 4.5:1 or better.
- Budget: JS for the first view under 200 kB gzip excluding the lazily loaded three.js chunk. Pause rendering when off-screen or the tab is hidden, as the scene already does.
- Full WCAG conformance needs manual testing with assistive technologies and an accessibility specialist. This work targets the practices above and does not claim conformance.

## 8. Testing

- Existing 66 vitest tests stay green.
- New unit tests for any new pure logic, for example mesh timing and rail progress.
- Playwright (via the webapp-testing skill): desktop and mobile screenshots of each section, a reduced-motion pass, and a no-WebGL pass.
- `npm run typecheck`, `npm run lint`, `npm run build` before completion.
- Impeccable detector once on the finished UI.

## 9. Execution

Workstreams (each a subagent, implementer plus reviewer):
1. Foundations: PRODUCT.md and DESIGN.md through impeccable init and document, dependency pins, Lenis and ticker owner.
2. Story and scene upgrade (bloom, extra beats, camera).
3. Triggers section and rail.
4. Guardian mesh and safety map.
5. AI and FIR demo.
6. Copy pass against the claim ledger (content.ts, page.tsx, ScrollStory.tsx).
7. Tracker parser fix, only if approved.
8. Verification: Playwright, accessibility audit, performance, code review.

Skills and agents: `impeccable`, `taste`, `ui-ux-pro-max`, `vercel:nextjs`, `webapp-testing`, `frontend-design`; agents Frontend Developer, UI Designer, Accessibility Auditor, Code Reviewer, Reality Checker, Technical Writer. The `storytold` plugin may help produce 3D and illustration assets, but its skills are unreviewed, so they are optional.

## 10. Open decisions for the reviewer

1. Approve the three-tier policy (Built, In development, Dropped), or hide unbuilt features entirely.
2. Approve the tracker parser fix as part of this work.
3. Minimum Android wording: 7.0 or 8.
4. Whether to install the `storytold` skills into the asset workflow.

## 11. Out of scope

Flutter app changes, Supabase changes, new routes, authentication, analytics, live map data on the landing page, iOS.
