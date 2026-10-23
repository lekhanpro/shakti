# Connect Google Gemini to Shakti

The Android app calls the authenticated Supabase `ai-guard` function. That
function calls Google Gemini using a server-side key. The APK contains only
public Supabase configuration. Local SOS and carrier SMS do not wait for AI.

Gemini is the default provider. The pinned stable model is
`gemini-3.8-flash`, verified against Google's
[model catalogue](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash)
on 23 October 2026. The adapter uses Google's documented
[`generateContent` REST API](https://ai.google.dev/api/generate-content), with
server system instructions, user/model turns, and the key in `x-goog-api-key`.
No provider key is placed in a URL or returned to the phone.

## Set up the backend

1. Select the owner's Supabase development project. Apply the existing
   migrations following [the development guide](development-guide.md#2-configure-a-hosted-supabase-backend).
   In **Authentication → Sign In / Providers**, enable anonymous sign-ins;
   the app lazily obtains a user session for authenticated function calls.
2. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
   In **Supabase → Edge Functions → Secrets**, set `GEMINI_API_KEY` there.
   Set `AI_PROVIDER=gemini` and optionally `GEMINI_MODEL=gemini-3.8-flash`.
   Do not paste the key into chat, the Android build JSON, or source control.
3. Deploy the reviewed `ai-guard` function to that same development project.
   JWT verification remains enabled; the handler also verifies the user and
   applies its per-user rate limit. Deployment is an explicit operator action:

   ```powershell
   & 'D:/tools/supabase-cli/supabase.exe' login
   & 'D:/tools/supabase-cli/supabase.exe' functions deploy ai-guard --project-ref YOUR_PROJECT_REF
   ```

For CLI secret configuration, copy
[`supabase/functions/.env.ai.example`](../supabase/functions/.env.ai.example)
to a private path outside this repository, replace the placeholder there,
then run `supabase secrets set --project-ref YOUR_PROJECT_REF --env-file PRIVATE_PATH`.
The hosted project supplies its own Supabase server credentials. Do not add
service-role keys to the phone's configuration.

## Configure the Android build

The tracked example is [`app/.env.build.json.example`](../app/.env.build.json.example).
Its local counterpart `app/.env.build.json` is gitignored. Populate that local
file with the project's public URL and **publishable** key from Supabase's
Connect/API settings. `SUPABASE_ANON_KEY` is also accepted for legacy projects.
Use the same project for the deployed function and the app.

From the repository root:

```powershell
node scripts/check-ai.mjs --config app/.env.build.json
```

From `app/`, build or run with:

```powershell
flutter run --dart-define-from-file=.env.build.json
flutter build apk --release --dart-define-from-file=.env.build.json
```

The checker rejects provider/private credentials in app configuration. A valid
configuration check only validates public build values; it does not establish
that the backend is deployed or that Gemini has available quota.

## Verify the real connection

Use a configured app with internet access. In Guardian, leave location sharing
off and send a harmless test message. A successful response proves the app's
Auth → Edge Function → Gemini → app path for that request. Do not describe AI
as connected based only on the presence of build values.

For an automated hosted smoke check, put an **existing consenting test user's**
short-lived Supabase access token into the current process environment as
`SHAKTI_AI_TEST_ACCESS_TOKEN` using your private token workflow, then run:

```powershell
node scripts/check-ai.mjs --config app/.env.build.json --live
Remove-Item Env:SHAKTI_AI_TEST_ACCESS_TOKEN
```

The tool sends one synthetic chat message. It does not create users, acquire
GPS, send an SOS, or dispatch guardian alerts. It reports success only for a
nonempty authenticated AI response and never prints tokens or provider error
bodies. This invocation consumes a small amount of the project's AI quota.

Acceptance checks:

- The configured app receives a real reply; an unconfigured build clearly
  offers offline safety tips and the offline complaint template.
- A failed/expired session, quota limit, offline request, or provider failure
  leaves a retry option and local emergency tools available.
- Long conversations retain at most 20 recent turns per request. New messages
  are limited to 2,000 characters.
- Chat does not read GPS unless the user enables approximate location sharing.
  It rounds shared coordinates to two decimal degrees (roughly a kilometre).
- Online FIR generation requires consent in the UI. It sends the provided
  name, narrative, accused description, incident time/place, and an evidence
  summary. It does not send the tracker share token, audio file, or full trail.
- A user reviews every FIR draft before export/submission. Incomplete or
  provider-filtered output is treated as a failed AI response.

## Server configuration reference

| Server-only value | Purpose |
| --- | --- |
| `AI_PROVIDER` | `gemini` by default; `groq` only by explicit legacy opt-in |
| `GEMINI_API_KEY` | Google AI Studio API key; required for Gemini |
| `GEMINI_MODEL` | Optional stable-model override; defaults to `gemini-3.8-flash` |
| `GROQ_API_KEY`, `GROQ_MODEL` | Existing Groq deployment support when `AI_PROVIDER=groq` |

An invalid provider/model setting fails closed with HTTP 503. Provider request
and body reads have a 20-second timeout; the phone caps the full Auth/function
operation at 35 seconds. Provider quota errors return HTTP 429 without exposing
the provider response. The UI distinguishes client configuration from a verified
live reply.

No hosted project was connected or deployed as part of the source changes.
Local dependency-injected tests do not verify a real Gemini key or account quota.
