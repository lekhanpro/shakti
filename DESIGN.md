---
name: Shakti Android
description: Warm ivory and deep plum with clear glass for floating safety controls
colors:
  primary: "#6C3B5D"
  identity: "#6C3B5D"
  on-primary: "#FFFFFF"
  accent-container: "#EFE1E8"
  emergency: "#E11D48"
  emergency-deep: "#BE123C"
  emergency-highlight: "#FB7185"
  safe: "#176A4E"
  warning: "#855900"
  info: "#286683"
  ground: "#F8F5EF"
  ambient: "#F8F5EF"
  surface: "#FFFDFA"
  surface-high: "#F0EAE4"
  outline: "#E1D7D4"
  field-outline: "#94818C"
  glass-edge: "#E1D7D4"
  text-primary: "#29232A"
  text-secondary: "#615760"
  text-muted: "#756A73"
  dark-primary: "#D8B9D0"
  dark-accent-container: "#473244"
  dark-ground: "#17131C"
  dark-surface: "#231E29"
  dark-surface-high: "#302837"
  dark-outline: "#514451"
  dark-text-primary: "#F8F2F5"
  dark-text-secondary: "#D4C7D1"
  dark-text-muted: "#BDAEBA"
  dark-safe: "#8ED0B3"
  dark-warning: "#E6B963"
  dark-info: "#89C6DB"
typography:
  display:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: -1px
  headline:
    fontFamily: Manrope
    fontSize: 26px
    fontWeight: 700
    lineHeight: 1.18
    letterSpacing: -0.4px
  title:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.18
    letterSpacing: 0px
  body:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: 700
    lineHeight: 1.2
rounded:
  sm: 12px
  md: 16px
  card: 20px
  lg: 28px
  dock: 24px
  pill: 999px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: 56px
  button-outlined:
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: 56px
  input:
    backgroundColor: "{colors.surface-high}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: 18px 16px
  chip-selected:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.pill}"
  glass-surface:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: 16px
  navigation-dock:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.dock}"
    padding: 6px
  sos:
    backgroundColor: "{colors.emergency}"
    textColor: "{colors.on-primary}"
    size: 220px
---

# Design System: Shakti Android

## Overview

**Creative North Star: "Warm ivory, deep plum, clear glass"**

On 23 October 2026 the owner replaced the earlier dark-first direction with warm
ivory and deep plum, then requested the clear Liquid Glass appearance seen in
current iOS references. The Android app retains this light layout and uses optical
glass for floating controls. Plum carries ordinary actions; rose keeps SOS distinct.
The shield-and-flame mark and bundled typography retain the Shakti identity.

This is a Flutter Android task interface. Material 3 controls, system navigation,
safe areas and readable instructions govern its behavior. Apple materials inform
its optical treatment; the Flutter rendering is a project implementation with a
blur fallback. It does not establish Apple rendering parity or handset performance.
Runtime source is normative. This file and `.impeccable/design.json` describe
`app/`; `web/DESIGN.md` governs the website. Frontmatter pixel values represent
Flutter logical dp, with system text scaling applied separately.

**Key Characteristics:**

- Warm ivory light mode by default, with persisted Light, Dark and System choices.
- Clear floating navigation and map controls above solid, quiet content surfaces.
- Bundled Manrope headings and Inter body text, with restrained hierarchy.
- Immediate safety actions, readable state labels and reduced-motion alternatives.

## Colors

### Primary

Deep plum is the light-mode action, focus and selection color. Filled primary
buttons use white text; pale plum containers carry quieter selections and icon
fields. The dark appearance uses pale plum actions against warm charcoal, with
charcoal text on filled primary controls. Features resolve roles through
`context.shakti` and the Material color scheme. Legacy `lilac` and `brand` getters
are aliases of the current primary role.

### Semantic

Dark green, amber and blue support safe/resolved, caution and information states
in light mode; their lighter dark-mode counterparts preserve legibility. Pair
state color with text or an icon. A configured contact or trigger does not promise
protection. SOS uses rose with white labels; emergency text uses deep rose in
light mode and the bright rose highlight in dark mode.

### Neutral

The page field is solid warm ivory, with warm white and pale stone surfaces.
Dark mode uses warm charcoal surfaces. Hairline group boundaries and stronger
field outlines serve different purposes. Content ink stays opaque. Glass veils
and specular light are restricted to floating material, preserving clear text.

**The Emergency Priority Rule.** Keep SOS clearly labeled and visually dominant;
decoration and navigation never delay an emergency callback.

## Typography

Manrope headings and Inter body/controls are bundled as variable fonts with SIL
OFL licenses available offline through Settings. Platform fallback renders
characters outside their coverage.

The runtime ramp uses display sizes 48/36/30, headlines 26/23/20, title sizes
18/16/14, body sizes 16/14/12, and labels 15/13/11. Display line heights are
1.05/1.1; other headings use 1.18, body 1.5 and labels 1.2. Headlines use restrained
negative tracking; body text uses normal tracking.

Shared page headings, the home greeting and onboarding use smaller heading roles
on narrow layouts with large text. The app caps text scaling at 2x; body copy
continues to scale within that range. Decorative avatar initials and the SOS
wordmark may fit within their fixed shapes without changing body-text scaling.

## Layout

Pages normally use a 24 dp side inset and the spacing scale above. Lists below the
floating dock reserve 128 dp at the end. Native safe areas and keyboard insets keep
controls usable; focused input hides the phone dock.

Five destinations retain branch state: Shield, Map, Escort, Guardian and Settings.
The shell becomes a Material navigation rail at 760 dp. The phone dock uses five
48 dp-or-larger semantic targets. When scaled 11 dp labels exceed 15 dp, visible
labels yield to icons while destination names remain available to assistive tools.

Home presents the brand, greeting, truthful contact status, real-contact preview
and prominent SOS, then walk/fake-call actions. Supporting lists and instructions
remain scrollable. Contacts, evidence and safe places use plain introductions and
grouped records rather than putting every paragraph inside a card.

## Elevation & Depth

Ordinary groups are solid tonal surfaces. `GlassSurface` enables optical material
only when `blur: true`, as used by the dock, rail and selected floating map
controls. Text-rich overlays use an 88% surface veil. Explicit `clear: true`
controls, including the dock and home quick actions, use 57% in light mode and 76%
in dark mode, with a further gradient for ink contrast, a curved specular rim,
local touch light and a soft outside-only offset shadow. Dark touch light peaks at 6% white;
light touch light peaks at 38%. The dock additionally enables `protectText`,
grading from its clear rim veil to 94% opacity across the central band at stops
0/0.22/0.8/1. Scrolling words therefore soften beneath the icon and label area.
Home clear controls keep their uniform veil. These stronger veils adapt the
clear-glass reference to Shakti's opaque ink and safety controls.

The bounded backdrop path uses an Impeller fragment shader for refraction when
supported, with a clipped sigma-7 blur fallback. Its fixed 25-tap Gaussian softens
the underlying scene at approximately 3 dp sigma, with up to 2.5 dp rim refraction.
Foreground labels remain sharp. This static cost stays confined to clipped
floating controls. The outside-only shadow avoids feeding a filled shadow plane
back through the lens.

Host GPU tests with `--enable-impeller` have exercised the shader and asserted an
active shader filter. Separate software renders exercise the fallback. Android
device rendering, platform-view composition and GPU frame timing still need
physical verification. High contrast or accessible navigation removes optical effects and
uses opaque material. Reduced motion removes press scaling and lensing, while
retaining readable static separation. There is no full-screen glass animation.

The solid SOS circle uses a rose-to-deep-rose fill and one deep-rose shadow with
24 dp blur, a (0, 10) offset and 16% opacity. Its quiet ripple is local to the
emergency control.

**The Bounded Material Rule.** Keep refraction and blur clipped to floating controls;
ordinary content groups stay solid, and accessibility fallbacks stay opaque.

## Shapes

Controls use 16 dp corners, grouped content 20 dp and sheets 28 dp. The phone dock
uses a 24 dp outer radius and 18 dp selection shape. Pills identify compact state
and choice. SOS remains a 220 dp circle within a 253 dp ripple canvas. Preserve
native Material switch, dialog and input structure.

## Components

### Buttons and choices

Primary buttons have a 56 dp minimum height with white text on plum in light mode.
Outlined buttons use opaque ink and a restrained boundary. Every interactive
control has a minimum 48 dp target. Selected duration/caller chips use primary and
on-primary roles; relationship choices use a plum container with a checkmark.
Map filters retain their category icons. Appearance uses full-width Material radio
rows with an explicit selected state for Light, Dark and System.

### Content groups and fields

Groups default to 16 dp padding and solid surfaces. Pressable groups may compress
to 0.985 over 140 ms with ease-out when motion is enabled. Fields use raised fill,
18 dp vertical/16 dp horizontal padding, a stronger neutral outline and a 1.5 dp
primary focus border. Labels, disabled controls and validation errors retain their
Material states.

### Navigation and motion

The **SIGNATURE INTERACTION** is the dock's 240 ms `easeOutCubic` selection glide
inside bounded optical glass. Navigation callbacks run immediately. Icons change
over 140 ms; onboarding uses the 240 ms page transition. Touch light follows local
pointer position without a continuous animation loop. SOS press feedback uses
0.94 scale over 150 ms and a 1600 ms local breathing cycle. Shared state changes
use 300 ms; sheets and dialogs retain Flutter platform defaults.

Reduced motion removes spatial transitions, press scaling, lensing and continuous
breathing. SOS routing has no page transition, and the countdown keeps a fixed
cancellation footer. Fake-call ringing starts before optional preference saving;
the call stays a believable dialer and the decoy Notes interface stays neutral.

### Supporting states

Keep loading, error and empty states truthful. Guardian keeps its draft and a
keyboard-aware composer. The map exposes attribution and uses standard OSM tiles
when no CARTO key is configured; keyed CARTO selects matching light/dark artwork.
Evidence and history describe storage and dispatch status without implying
confirmed delivery. AI errors offer recovery and do not claim hosted service
availability without a successful deployed check.

## Do's and Don'ts

### Do

- Do resolve feature colors through semantic roles in both appearances.
- Do preserve 48 dp targets, semantic actions and the visible SOS cancellation control.
- Do keep content ink opaque and accessibility glass fallbacks solid.
- Do verify narrow screens, 200% text, dark appearance and real populated data.
- Do distinguish software fallback renders, host Impeller renders and Android device verification.

### Don't

- Don't delay emergency actions for animation, network access or optional preferences.
- Don't extend backdrop refraction or blur to ordinary content rows or the whole page.
- Don't invent contacts, readiness, delivery confirmations or live service results.
- Don't reintroduce the removed volume/accessibility trigger.
- Don't treat static screenshots as proof of smoothness, Apple parity or Play Protect approval.
