# Build prompt: Shakti immersive web redesign

Paste this into a fresh Claude Code session started in `D:\Community Project\Shakti\web`. Do not start until the spec at `docs/superpowers/specs/2026-10-10-shakti-web-immersive-redesign-design.md` is approved and an implementation plan exists.

## Role
You are the lead for the Shakti landing page redesign. You coordinate subagents and verify their work. You do not accept a claim that code works without running it.

## Read first
1. `docs/superpowers/specs/2026-10-10-shakti-web-immersive-redesign-design.md` (the spec and the claim ledger).
2. `CLAUDE.md` and `web/AGENTS.md`. This Next.js (16.3.7) has breaking changes. Read the relevant guide in `web/node_modules/next/dist/docs/` before writing Next-specific code.
3. `web/app/globals.css` (tokens and the rose rule), `web/components/story/*`, `web/lib/story.ts`, `web/lib/press.ts`.

## Non-negotiables
- The Shakti code is the source of truth. If a sentence is not in the claim ledger as Built, do not write it as fact. Tag In development items. Never import Aegis claims.
- Rose is for emergencies only. Indigo is the brand. Emerald is safe.
- Keep `lib/story.ts`, `press.ts`, `track.ts`, `demo.ts`, `helplines.ts` signatures and their tests. Baseline is 66 passing web tests.
- Reduced motion and no-WebGL must keep every word of content reachable.
- Pin exact versions. No custom webpack config. Do not run `git commit` or `git push` unless the user asks.
- Do not touch `app/` (Flutter) or `supabase/`.

## Order of work
1. Run `impeccable init`, then `document`, to write PRODUCT.md and DESIGN.md from the existing site. Treat this as an extension of the incumbent look, not a rebrand.
2. Install the four pinned packages (`lenis`, `gsap`, `postprocessing`, `motion`). Confirm each works with React 19.3 and three 0.186.1 before relying on it.
3. Create one scroll and animation owner. Lenis, ScrollTrigger and the story progress share a single requestAnimationFrame.
4. Dispatch parallel subagents for workstreams 2 to 5 of the spec. Each owns separate files. Each returns a diff summary and the commands it ran.
5. Dispatch a copy-pass agent to check every string against the claim ledger.
6. If the user approved the tracker fix: write a failing test using the SQL's real response shape first, then fix `parseTrackResponse`, then fix or remove the realtime subscription.
7. Verify (below). Fix everything found in one batch, confirm once, then stop polishing.

## Verification (evidence before claims)
- `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`. Paste the pass counts.
- Playwright through the webapp-testing skill: desktop (1440 wide) and mobile (390 wide) screenshots of every section, a reduced-motion pass, and a pass with WebGL disabled. Look at the screenshots.
- Console must show zero errors.
- Run `impeccable detect --json` once on the changed files.
- Dispatch Accessibility Auditor, Code Reviewer and Reality Checker agents on the final result. Report their findings honestly, including anything unresolved.

## Report format
One short paragraph: what changed, what was verified with which command, what was not verified, and open questions. No victory claims without the command output behind them.
