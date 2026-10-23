---
name: Shakti Android
description: Dark liquid glass with lilac highlights for a personal safety network
colors:
  primary: "#B6AAFF"
  identity: "#4F46E5"
  emergency: "#E11D48"
  emergency-deep: "#BE123C"
  emergency-highlight: "#FB7185"
  safe: "#10B981"
  warning: "#F59E0B"
  info: "#38BDF8"
  ground: "#080B15"
  ambient: "#25203F"
  surface: "#151A2B"
  surface-high: "#20263D"
  outline: "#363B55"
  glass-edge: "#E7E0FF26"
  text-primary: "#F7F6FF"
  text-secondary: "#D0CDE3"
  text-muted: "#AAA7C0"
typography:
  display:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: -1px
  headline:
    fontFamily: Manrope
    fontSize: 28px
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
  card: 24px
  lg: 28px
  dock: 32px
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
    textColor: "{colors.ground}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: 56px
  button-outlined:
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    height: 56px
  input:
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: 18px 16px
  chip-selected:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.ground}"
    rounded: "{rounded.pill}"
  glass-surface:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: 16px
  navigation-dock:
    backgroundColor: "{colors.surface-high}"
    rounded: "{rounded.dock}"
    padding: 6px
  sos:
    backgroundColor: "{colors.emergency}"
    textColor: "{colors.text-primary}"
    size: 220px
---

# Design System: Shakti Android

## Overview

**Creative North Star: "Dark liquid glass with lilac highlights"**

The owner selected this direction on 22 October 2026. Quiet graphite content
surfaces sit beneath reflective floating controls. Lilac carries ordinary actions;
the Shakti shield and indigo identity connect the app to its existing brand.
Emergency rose gives SOS a clear, separate priority.

This is an Android task interface built in Flutter. The design supports night use,
stress and large text through clear hierarchy, readable labels and restrained
motion. Scope is `app/`; `web/DESIGN.md` governs the website. Runtime source is
normative, while this file and `.impeccable/design.json` record its reusable rules.
Frontmatter pixel values correspond to Flutter logical dp; OS text scaling applies.

**Key Characteristics:**

- Dark graphite with a static lilac ambient field.
- Bounded translucent chrome and reflective grouped content.
- Bundled Manrope headings and Inter controls/body text.
- A gliding five-destination dock and immediate emergency activation.

## Colors

### Primary

Lilac is the primary action and selection color. Dark ink is used on filled lilac
controls, including onboarding and selected chips. Indigo remains the identity
color in marks and selected switches.

### Semantic

Emergency rose identifies SOS and destructive actions. Emerald, amber and blue
identify safe/resolved, caution and information states. Pair state color with an
icon or text; a configured contact or trigger is not a guarantee of protection.

### Neutral

Ground and ambient form the static page field. Surface and surface-high separate
content groups; outline and glass-edge describe boundaries. Primary, secondary
and muted text provide the hierarchy. High contrast/accessibility navigation uses
opaque, blended materials.

**The Emergency Priority Rule.** Keep SOS clearly labeled and visually dominant;
decoration and navigation never delay an emergency callback.

## Typography

Manrope is bundled for headings, Inter for body text and controls. Both use their
variable font files with SIL OFL licenses available offline through Settings.
Platform fallback renders characters outside their coverage.

The runtime ramp uses display sizes 48/36/30, headlines 28/24/20, title sizes
18/16/14, body sizes 16/14/12, and labels 15/13/11. Large display line heights are
1.05/1.1; other headings use 1.18, body 1.5 and labels 1.2. Headlines use restrained
negative tracking; body text uses normal tracking.

Below 360 dp, when scaled 28 dp type exceeds 40 dp, shared page headings and the
home greeting use the 20 dp role. This preserves whole-word wrapping. The app's
existing text-scale cap is 2×; body text continues to scale within that range.

## Layout

Spacing follows the frontmatter scale. Pages normally use a 24 dp side inset.
Lists beneath the floating dock reserve 128 dp at the end. Native safe areas and
keyboard insets govern usable space; focused input hides the phone dock.

The phone shell preserves branch state across five destinations: Shield, Map,
Escort, Guardian and Settings. At 760 dp it becomes a navigation rail. Large-text
dock labels yield to icons with semantic destination names.

The home **FIRST VIEWPORT** contract is a compact brand row, greeting, truthful
readiness, real-contact preview and large SOS lens, followed by walk/fake-call
actions. These elements remain a scrollable composition; the dock floats above
content. Large text shortens readiness to the active-contact count, with detailed
trigger controls in Settings.

## Elevation & Depth

Tonal layering and reflective edges carry ordinary content depth. `GlassSurface`
uses a 90% to 70% surface gradient, clipped before an optional sigma-16 backdrop
filter. Its default has no blur; the dock and selected floating map controls opt
in. High-contrast or accessible-navigation settings remove that filter and blend
the surface opaque. The ambient backdrop is static.

The SOS orb uses offset rose shadows: 32 dp blur at (0, 12), and 12 dp blur at
(0, 8). Its inner bevel and expanding rings are specific to the emergency control.

**The Bounded Material Rule.** Keep backdrop filters clipped to the controls that
need separation from moving content; content rows use the reflective material
without a filter by default.

## Shapes

Controls use the medium radius, grouped content the card radius, and sheets the
large radius. The floating dock uses its own rounder outer shape with a 26 dp
selection lens. Pills identify compact state or selection. The SOS remains a
220 dp circle within a 275 dp ripple canvas.

## Components

### Buttons and chips

Primary buttons have a 56 dp minimum height and dark labels on lilac. Outlined
buttons use bright text and a restrained edge. Interactive targets are at least
48 dp. Selected choice chips use lilac with dark text and checkmarks; map filters
retain category icons and colors. Preserve native focus, disabled and error states.

### Glass groups and fields

Glass groups default to 16 dp padding, a clipped reflective edge and no filter.
Pressable groups compress to 0.985 over 140 ms with ease-out. Fields use raised
fill, 18 dp vertical/16 dp horizontal content padding and a 1.5 dp lilac focus
border. Errors retain their text and emergency color.

### Navigation and motion

The **SIGNATURE INTERACTION** is the dock's gliding selection lens: 240 ms
`easeOutCubic`, with immediate destination callbacks. Icons change over 140 ms.
Onboarding uses the same navigation timing for its spatial transition. SOS press
feedback uses 0.94 scale over 150 ms, with a 1600 ms breathing cycle. Shared state
changes use 300 ms. Sheets and dialogs retain Flutter's platform defaults; no
custom 280 ms sheet timing is specified.

Reduced motion removes spatial transitions and stops continuous breathing.
Navigation keeps existing branch state. SOS routing has no page transition;
countdown keeps a fixed cancellation footer. The fake call begins before optional
preference persistence. Its ringing screen stays a believable dialer, and the
decoy Notes interface stays neutral.

### Supporting states

Keep truthful empty, error and loading states. Contacts show real initials and
explicit SOS switches. Guardian has a keyboard-aware composer and persistent
draft. Map credits provide a visible attribution action. Evidence and history
describe stored data and dispatch status without implying verified delivery.

## Do's and Don'ts

### Do

- Do use bundled fonts, shared tokens and the existing shield mark.
- Do preserve 48 dp targets, semantic actions and the visible SOS cancellation control.
- Do keep ordinary content legible when glass becomes opaque.
- Do test narrow screens, 200% text and real populated data.
- Do distinguish Flutter-rendered checks from native-device performance evidence.

### Don't

- Don't delay emergency actions for animation, network access or optional preferences.
- Don't add backdrop blur to every content row.
- Don't invent contacts, readiness, delivery confirmations or map results.
- Don't reintroduce the removed volume/accessibility trigger.
- Don't treat static screenshots as proof of handset smoothness or Play Protect approval.
