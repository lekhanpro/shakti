---
name: Shakti / Signal Globe
description: One quiet dark field, hairline structure, and a dot-matrix globe that explains the alert instead of decorating it.
colors:
  night: "#070b14"
  deep: "#0f172a"
  panel: "#1e293b"
  line: "#334155"
  ink: "#f1f5f9"
  ink-2: "#cbd5e1"
  ink-3: "#94a3b8"
  brand: "#a5b4fc"
  signal: "#6ee7b7"
  urgent: "#fb7185"
  warn: "#fcd34d"
  globe-land: "#e7ecf3"
typography:
  display:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.5rem, 4.9vw, 4.5rem)"
    fontWeight: 700
    lineHeight: 1.03
    letterSpacing: "-0.04em"
  heading:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(1.95rem, 3.4vw, 3rem)"
    fontWeight: 700
    lineHeight: 1.07
    letterSpacing: "-0.035em"
  body:
    fontFamily: "Instrument Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.65
  label:
    fontFamily: "ui-monospace, SFMono-Regular, Cascadia Mono, Menlo, monospace"
    fontSize: "0.6875rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.12em"
  wordmark:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.5rem, 10vw, 6rem)"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-0.04em"
rounded:
  sm: "10px"
  md: "14px"
  card: "20px"
  xl: "28px"
  pill: "999px"
spacing:
  gutter: "clamp(1.25rem, 5vw, 4rem)"
  rhythm: "clamp(4.5rem, 8vw, 7.5rem)"
  measure: "66ch"
components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "#0b1220"
    rounded: "{rounded.pill}"
    height: "48px"
    padding: "0 1.4rem"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    borderColor: "rgb(226 232 240 / 0.16)"
    rounded: "{rounded.pill}"
    height: "48px"
  chip:
    backgroundColor: "transparent"
    textColor: "{colors.ink-2}"
    selectedBorderColor: "{colors.signal}"
    selectedBackgroundColor: "rgb(110 231 183 / 0.1)"
    rounded: "{rounded.pill}"
    height: "44px"
  globe:
    landColor: "{colors.globe-land}"
    signalColor: "{colors.signal}"
    maxWidth: "31rem"
    aspectRatio: "1"
---

# Design System: Shakti / Signal Globe

## Overview

**Creative North Star: "One quiet field, one object that moves"**

This page is read at night, often by someone who is uneasy. Everything on it is
either a fact or a demonstration of a fact. The art direction is therefore one
near-black field, structure drawn in hairlines, and a single object that earns
its weight: a dot-matrix globe that shows one press in Bengaluru reaching five
guardians.

The globe is the argument, not the ornament. Dropping its simulated internet
connection leaves every arc lit and stops only the travelling tracker dot,
because carrier SMS does not depend on an internet request. That is the
product's central claim, rendered in the thing the visitor is already dragging.

Restraint here is about how much gets used, not about a second palette. Colour,
type and radius come from the `@theme` tokens in `app/globals.css`, so the
Tailwind-built demonstrations (`AiDemo`, `PressDemo`) and the SVG radar sit in
the same world as everything authored in `app/landing.css`.

**Key Characteristics:**

- One dark ground. No second surface colour, no filled cards, no glass.
- Structure is hairlines and space: three rule weights do all the dividing.
- Bricolage Grotesque for headings, Instrument Sans for reading, mono only for
  sequence and measurement.
- One signature object, built from data already in the repository.
- Emerald means reaching and safe; rose is emergency only; indigo marks the
  product itself.

## Colors

### Primary

**Indigo** (`#a5b4fc`) marks the product: the logo, the scroll progress line,
the caret and the focus ring. It is deliberately quiet, because the page's
loudest colour belongs to the helplines rather than the brand.

### Semantic

**Emerald** (`#6ee7b7`) means a channel reached, a requirement met, a state
that is safe. It carries the globe's arcs, the guardian markers, the check
lists and the confirmed rows in the walkthrough.

**Amber** (`#fcd34d`) means queued or waiting: the dropped tracker link, the
countdown stage, the in-development column.

**Rose** (`#fb7185`) is emergency meaning and nothing else. It borders the four
helpline numbers and colours the alerting stage of the walkthrough. It never
decorates.

### Neutral

The ground is `#070b14`, a single near-black field for the whole page. Ink runs
in three steps (`#f1f5f9`, `#cbd5e1`, `#94a3b8`), each at or above 4.5:1 on
that ground. Edges are translucent ink rather than a grey: `rgb(226 232 240 /
0.09)` for ordinary division, `0.16` where a boundary has to hold a group, and
`0.035` as the only raised fill on the page.

The globe's land is slightly warmer and brighter than body ink (`#e7ecf3`) so
the dot matrix reads as a lit object rather than as text.

**The Single Field Rule.** One ground colour carries the whole page. A section
is separated by a rule and space, never by a second background. If a region
needs to feel distinct, it earns that through what is in it.

**The Emergency Reserve Rule.** Rose appears only where someone could place a
real call or where an alert is actually firing. Any other use spends the one
colour the page cannot afford to make ambiguous.

## Typography

**Display:** Bricolage Grotesque, self-hosted (600/700/800, latin subset).
**Body:** Instrument Sans, self-hosted (400/500/600/700, latin subset).
**Label:** the platform mono stack.

Display tops out at 4.5rem and is sized so "One signal away." holds one line in
the hero's left column; a third line would orphan a single word. Tracking never
goes tighter than -0.04em, and every heading balances. Emphasis inside a heading
is a colour and weight shift to `--ink-3`, never a gradient.

One step sits above the page ramp: the arrival wordmark, capped at 6rem. It is
the only type on screen during a ~1.4s overlay on an empty field, so it is set
as a brand moment rather than as a heading. 6rem is also the ceiling; nothing on
this surface is larger.

Body copy holds a 66ch measure and a 1.65 line height. Mono is used for the
walkthrough's stage numbers and the trigger caption, where the number is
information; it is never used to make something look technical.

## Layout

A 1180px field with a fluid gutter. Sections are a shared vertical rhythm
(`clamp(4.5rem, 8vw, 7.5rem)`) and a single top rule, with more space above a
heading than below it.

The hero is copy left, globe right, and keeps DOM order equal to reading order
at every width: the primary action stays ahead of the globe's own controls in
the tab sequence. Below 1024px every split becomes one column. The globe's stage
is capped at 31rem so its readout, guardian chips and controls stay above the
fold at 1440x900 — a signature interaction nobody scrolls to find is not a
signature interaction.

Twelve sections carry the page: hero, principles, the response walkthrough, the
trigger demonstration, the guardian tracker, the capability inventory, the
safety map, the AI and FIR demonstration, privacy, helplines, questions and
download. Three separate "your circle is connected" illustrations collapsed
into the globe, and the scroll story and toolkit disclosure folded into the
walkthrough and the inventory: 13,379px of scroll at 1440px became 11,001px,
with no documented fact lost.

## Elevation & Depth

There is almost none, and that is the point. Depth comes from the globe's own
occlusion and from one translucent raise (`rgb(226 232 240 / 0.035)`) used for
the walkthrough's handset and the innermost radar ring. No shadows on panels, no
blur as decoration. The two blurs on the page are both functional: the sticky
header and the floating motion toggle, each so text passing beneath stays
readable.

**The Hairline Rule.** If something needs separating, draw a 1px rule. A border
above 1px, a filled card, or a shadow where a rule would do is the page
reaching for weight it has not earned.

## Shapes

Controls are pills, surfaces are 20px, sheets 28px, and the globe is a circle.
Every interactive target is at least 44px, and primary actions are 48px.

## Components

### The signal globe

The signature object, in `components/landing/SignalGlobe.tsx`.

Land is a Fibonacci sphere of 3,712 dots decoded from 1,625 bytes of packed
bits in `lib/globe-land.ts`, baked from `public/textures/earth-specular.jpg` by
`scripts/bake-globe-land.py`. The page therefore requests no Earth texture at
run time, where the old globe fetched five.

The camera is orthographic and the stage is square, so screen position is a pure
function of latitude and longitude. That is what lets the city markers be
ordinary DOM elements glued to the sphere, and the limb ring derive its inset
from the same `VIEW_HALF` constant the camera uses.

**The signature interaction:** choosing a guardian eases the globe round to face
them, names both endpoints, brightens that arc and dims the rest. The tracker
toggle then demonstrates channel independence — arcs stay lit, the travelling
dot stops.

Five labelled chips are the real control, because at hero scale Mumbai,
Bengaluru and Chennai land within a few pixels of each other and five tap
targets there would overlap. The markers are `aria-hidden`; a polite live region
announces each change once.

Fallbacks are first-class. The server renders the visible hemisphere as one SVG
path, which is the first paint and the permanent no-WebGL design; WebGL is
probed before three.js is fetched at all. Reduced motion keeps the framing
change without the travel. The render loop is self-terminating and gated on
`inView && visible`, honours the page's `shakti:motion` event, and disposes
every geometry, material and the renderer on unmount.

### Buttons and chips

One pill shape. Primary is ink on near-black; outline is a hairline; the icon
button is a 48px circle. Chips use a hairline at rest and an emerald border with
a 10% emerald wash when pressed, with `aria-pressed` carrying the state rather
than colour alone.

### Content groups

Lists are hairline-separated rows, not grids of equal cards. The capability
inventory shows all thirteen triggers and features directly, each with its
built-or-in-development tag, rather than folding them behind a disclosure the
way the previous page did.

## Do's and Don'ts

### Do

- Do let the globe explain something; every state it shows is a real product behaviour.
- Do keep one ground colour and divide with rules and space.
- Do reserve rose for emergency meaning and emerald for reached-and-safe.
- Do keep every claim checkable against `components/landing/content.ts`.
- Do verify at 1440x900 and 390x844, with reduced motion, with WebGL disabled, and by keyboard.

### Don't

- Don't put an eyebrow or kicker above a heading. The heading carries itself.
- Don't add a second surface colour, a filled card, or a shadow where a hairline works.
- Don't let decoration imply a capability: no live location, no delivery confirmation.
- Don't reintroduce a photographic globe texture; the dot matrix is 1.6 KB and needs no request.
- Don't use mono as texture, or section numbers where the sequence carries no information.

## Verification

`qa/review.py` captures the batched review round: desktop and mobile, plus
reduced-motion and WebGL-disabled passes, and drives the globe's interactions.
`qa/v2_check.py` is the assertion gate.

Both load **localhost**, not 127.0.0.1. `next dev` binds localhost, and
127.0.0.1 fails the HMR websocket handshake, which blocks hydration — captures
taken that way are pictures of an un-hydrated page, which is how the previous
goldens were produced.

Outstanding: physical Android device rendering and frame timing for the globe
remain unverified, as does everything in PRODUCT.md's in-development list.
