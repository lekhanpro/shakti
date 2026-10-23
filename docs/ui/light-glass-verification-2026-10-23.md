# Light layout and optical glass — 23 October 2026

This revision replaces the earlier dark-first Android treatment with the owner's
approved warm ivory/deep plum light layout. Light is the saved default; Dark and
System remain available in Settings. The owner then requested the clear Liquid
Glass appearance from current iOS references. The website keeps its separate
visual system.

## Research and interpretation

Apple describes Liquid Glass as a separate floating control/navigation layer with
lensing, specular light and interaction feedback. Its Clear variant is intended
for media-rich backgrounds, a dimming layer and bold bright foregrounds. Shakti
adapts these ideas to opaque ink, stronger veils and Android controls; it does not
claim native Apple rendering parity. The optical guidance comes from Apple's
[Meet Liquid Glass presentation](https://developer.apple.com/videos/play/wwdc2025/219/)
and [Materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials).

Apple's [iOS 27 user guide](https://support.apple.com/en-euro/guide/iphone/iphfed2c4091/ios)
describes a transparency slider ranging from clear to tinted. That is reference
context for the owner's request. No Apple images or implementation assets were
copied into Shakti.

## Implemented source

- `app/lib/core/theme/tokens.dart` and `app_theme.dart` define warm ivory,
  deep plum, warm charcoal and appearance-specific status colors. Features read
  semantic roles from `context.shakti`.
- `SafetySettings.appearance` persists Light, Dark or System. Missing preferences
  resolve to Light, and `app/lib/app.dart` selects the matching Material theme.
- `GlassSurface` keeps ordinary content solid. Floating overlays opt into optical
  material with `blur: true`. Text-rich overlays use an 88% surface veil; explicit
  clear controls use 57% in light mode and 76% in dark mode, plus a contrast
  gradient and a curved specular rim. The dock adds `protectText: true`: its rim
  veil grades to a 94% central band at stops 0/0.22/0.8/1 to separate scrolling
  words from navigation ink. Home clear actions retain the uniform clear veil.
- Local touch light peaks at 38% white in light mode and 6% in dark mode. The
  material has an outside-only offset shadow and no continuous full-screen
  animation. Keeping the shadow out of the pane prevents a second shadow plane
  from being sampled by its own backdrop filter.
- `app/lib/core/widgets/glass_refraction.dart` and
  `app/shaders/liquid_glass.frag` implement bounded backdrop refraction on
  shader-filter-capable renderers. Shader loading is cached; an unsupported
  renderer or load failure uses sigma-7 blur. The shader now uses a fixed 25-tap
  Gaussian at approximately 3 dp sigma and up to 2.5 dp rim refraction. Foreground
  labels are painted afterward and remain sharp. This greater sample cost is
  confined to bounded controls; physical GPU profiling remains pending.
- High contrast and accessible navigation bypass the optical filter and use
  opaque surfaces. Reduced motion removes lens distortion, spatial transitions
  and press scaling. The fallback keeps readable static separation.
- Manrope/Inter remain bundled offline. Targets stay at least 48 dp, body text
  scales up to the existing 200% cap, and decorative avatar initials fit their
  fixed circles without suppressing body scaling. Selected appearance choices
  expose native radio semantics.
- Emergency callbacks retain their existing timing and cancellation window.
  SOS stays solid rose with white labels; its lock-screen label uses themed rose
  for contrast. The decoy Notes screen remains neutral.

## Verification status

The final source passed the full default Flutter test suite and static analysis.
The latest Android packaging attempt hit a local memory limit; a separate rebuild
is waiting for another Flutter command to release the SDK startup lock.

| Check | Recorded result | Evidence and scope |
| --- | --- | --- |
| Flutter full suite | 252 passed | `tmp/clear-glass-full-tests.log` |
| Domain/data line coverage | 88.7%: 1071/1208 lines, above the 80% gate | Coverage from the full Flutter run |
| Flutter analysis | No issues | `tmp/clear-glass-analyze.log`; no issues after the material refinements |
| Material/navigation/render checks | 9 passed | `tmp/clear-glass-final-render.log` |
| Flutter software renders | 60 earlier fallback captures completed | Fifteen screens in light/dark at 400 x 850 and 320 x 850 with 200% text; `output/light-review/` |
| Deno tests | 74 passed, 0 failed | Full backend suite and type checks rerun with the project Deno tasks |
| Node tests | 5 passed | Public AI configuration checks rerun; no live provider request |
| Flutter debug assembly | All three Android architectures passed | Shader included in Flutter debug assembly |
| Host Impeller rendering | 2 tests passed; 60 screen captures plus 2 synthetic material studies | `tmp/impeller-screen-render.log`; active shader asserted; final dock text band included in `output/impeller-review/` |
| Android rendering and frame timing | Unverified | Requires Android device checks and physical profiling |
| Native unit tests | 7 passed, 0 failed | Completed Gradle `testDebugUnitTest` run |
| Android debug packaging | Earlier Gradle `testDebugUnitTest` and `assembleDebug` passed | Final package rebuild is blocked by local memory and an SDK startup lock; no new final APK hash is claimed |
| Package permissions and signature | Audit passed; APK Signer v2 debug signature verified on the completed build | Final rebuilt artifact still needs its own final record |

Independent review checked all 60 fallback captures and closed the identified
contrast/layout findings within that scope. Final contrast
refinements include opaque white SOS supporting text, themed rose for countdown
cancel/history/contacts actions, adaptive form errors, and fitting decorative
caller initials. The first host GPU review revealed background text ghosting in
the weaker softening path. The 25-tap Gaussian and outside-only shadow replaced
that path, and the new GPU capture run passed. The dock now adds its graded
text-protection band. The final GPU rerender and independent focused review passed:
background words no longer compete with navigation labels, the inset second-pane
artifact is gone, and scene transmission remains visible in the material studies.
This approval covers the host-rendered UI, not physical Android frame timing.

The software harness uses fixture data, real bundled fonts, reduced motion and
disabled map tiles. The separate host GPU harness runs with `--enable-impeller`
and `disableAnimations: false`. Its material probe asserts
`ImageFilter.isShaderFilterSupported` and verifies that the active backdrop
filters are shader filters. It therefore exercises the real shader path rather
than merely its fallback. The two synthetic artwork studies are explicitly demo
backgrounds.

These captures establish host rendering evidence. They do not verify Android GPU
frame timing, real map/platform-view composition, TalkBack, system bars, the live
keyboard, carrier SMS or provider delivery. No phone-level safety, Apple parity
or Play Protect certification is implied.

## Maps and hosted services

The coordinator recorded these live HTTP checks separately from fixture-backed UI
renders:

| Capability | Evidence | Remaining limit |
| --- | --- | --- |
| Basemap | Standard OSM tile request succeeded | CARTO styles require an owner-provided public basemap key; keyed rendering is not established by the OSM check |
| Walking route | FOSSGIS walking request succeeded | This does not certify every route or device journey |
| Place lookup | Nominatim request succeeded | Availability and coverage remain provider-dependent |
| Nearby havens | Overpass request timed out | No successful live POI result is claimed from that attempt |
| Guardian AI/FIR | Gemini 3.8 Flash routing and error handling are implemented/tested in code | Hosted AI has not been verified |

Hosted AI still requires the owner's public backend configuration, server-side
Gemini secret, authenticated deployment CLI and deployment. No hosted response or
new deployed function is claimed here. Credentials and secret files were not read
for this documentation update.

## Design records and follow-up evidence

Root `DESIGN.md`, `.impeccable/design.json`, `PRODUCT.md` and design-spec section 9
record the current surface. The sidecar retains schema version 2 and seven
self-contained catalog components; its CSS is a light-mode documentation
approximation, not the native shader.

The 22 October record under `docs/verification/` remains historical. Final checks,
artifact paths and package hashes belong to this revision only after their results
are available. Device review should cover light/dark, large text, high contrast,
reduced motion, scroll beneath glass, press/cancel states and real safety flows.
