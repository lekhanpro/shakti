# Opus UI change review — 21 October 2026

Reviewed the app and website changes in `6e19b9d` against `480715c`.
The shared identity, settings groups, onboarding and lock-screen changes are
retained. This review corrects the following issues:

- **Contact capacity:** the home screen used active contacts for “of 5 added.”
  Five saved contacts with four paused now correctly shows “5 of 5 added ·
  1 active.” Only active contacts appear as connected guardian nodes.
- **Reduced motion:** the website CSS overhaul removed the static story layout.
  Restore its rules and enforce a readable three-step layout through the media
  query, including when the rendered DOM retains animated cards. Inline opacity
  and transform values can no longer conceal or overlap steps in this mode.
- **Large text:** constrain the new wordmark row, choose action and helpline
  columns using the available width and scaled text, and keep the SOS label on
  one line inside its existing large button. The SOS label overflow was already
  present before the reviewed change.
- **Screen-reader activation:** home quick actions and helpline controls now
  expose their tap callback on their labelled semantics node. The existing
  exclusion of child semantics had removed this action.
- **Build resources:** cap Next.js prerender workers at two. The default nine
  workers exceeded this machine's available committed memory. Ignore local
  Playwright CLI state.

## Verification

| Check | Result |
| --- | --- |
| New home regression tests | **4 passed:** scroll through the home screen at 320/400 dp and 200% text, paused-contact capacity, semantic tap actions |
| Existing critical-flow widget tests | **11 passed:** SOS, countdown cancellation, contacts, PIN/duress and fake calls |
| Existing feature-screen tests | **25 passed:** screens at 100/200% text and siren control |
| Flutter analysis | **No issues** |
| Website Vitest suite | **77 passed** across 9 files, with one worker |
| Website production build | **Passed**, including the separate `tsc --noEmit` check |
| Production browser smoke | **Passed:** desktop, desktop reduced motion, mobile reduced motion, simulated offline dispatch, demo tracker, no horizontal overflow or page errors, and fallback without WebGL |
| Story layout checks | Three visible cards with separate vertical bounds in both reduced-motion viewports; screenshots inspected |

Initial unrestricted test/build attempts hit Windows memory limits. Final app
checks ran one file at a time with the Flutter tool heap bounded; website tests
ran with `--maxWorkers=1 --no-file-parallelism`. No resource-related failures
remain in the final checks above.

Browser captures are local generated artifacts under `web/test-results/`.
This review did not repeat backend/native tests or rebuild the Android APK;
the prior full verification is recorded in
[`2026-10-21-validation.md`](2026-10-21-validation.md). Physical-device SMS,
locked-screen triggers, live backend integration and Play Console testing
remain separate acceptance gates. No Play release was uploaded.
