# Shakti: personal safety network

VTU 1BCP308 Community Project, Topic #25 (Project Shakti). Shakti is an offline-first Android safety app. When a user raises an SOS, it texts her trusted contacts even with no internet, alerts a Telegram group, streams live location to a web tracker, records encrypted audio evidence and sounds a siren. Guardians don't need to install anything.

| Folder | What it is |
|--------|------------|
| `app/` | Flutter 3.47 Android app (Riverpod, go_router, Drift, Kotlin native guard) |
| `supabase/` | Postgres schema with RLS, and Deno edge functions (`ai-guard`, `emergency-dispatch`, `guardian-invite`) |
| `web/` | Next.js landing page and the guardian live tracker (`/track/<token>`) |
| `docs/` | Design spec, implementation plan, hardware QA checklist |
| `.github/workflows/` | CI (analyze, test, coverage gate, Deno, web) and release (signed APK + AAB on `v*.*.*` tags) |

## How an SOS works

1. **Trigger.** The user can raise an SOS by tapping the SOS button, pressing power ×3 (works with the screen off), pressing volume ×3, shaking the phone hard, saying a voice phrase, letting the walk-with-me timer run out, or entering the duress PIN (a silent SOS).
2. **Cancel window.** A 5-second countdown gives her time to cancel an accidental SOS. Duress-PIN alerts skip it.
3. **Fan-out.** The incident is saved on the phone first. Then these channels run in parallel, each isolated so one failure never blocks the others:
   - carrier SMS with a maps link (needs no internet)
   - 60-second encrypted audio recording
   - siren
   - Telegram and push alerts through Supabase, queued when offline
4. **Tracking.** GPS breadcrumbs go out every 10 seconds, and guardians follow them live on the web tracker.
5. **End.** The user confirms "I'm safe" with her PIN, and contacts get a follow-up SMS and Telegram message.

## Quick start

These steps use Windows paths. On other systems, adjust the paths.

```bash
# App
cd app
export PUB_CACHE="D:\\tools\\pub-cache"          # avoid spaces in the pub cache path
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon>
```

With no `SUPABASE_*` defines, the app runs fully offline: SMS, siren, evidence, map (live Overpass data) and fake call all work. Cloud alerts stay queued and the AI guardian shows an offline notice.

Backend and web setup are in `supabase/README.md` and `web/README.md`.

## Security notes

- The client only holds the Supabase URL and anon key. Groq, Telegram and FCM secrets live only in edge-function secrets.
- Row-Level Security is on for every table. The guardian tracker reads through a `security definer` RPC keyed by a random 24-character share token.
- The PIN is hashed with PBKDF2-SHA256 (100k iterations) and never leaves the device. Evidence is AES-GCM encrypted at rest. Screenshots are blocked, and Android backup is disabled.

## Team

Lekhan (lead architect), Manas (frontend), Vikat (backend and data), Hemanth (QA, tuning, presentation).
