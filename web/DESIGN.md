---
name: Shakti / Pulse Motion
description: A motion-graphic safety network that turns one physical trigger into a visible response.
colors:
  black: "#0c0c0e"
  black-soft: "#141419"
  bone: "#f3f0e8"
  violet: "#635bff"
  violet-soft: "#a49dff"
  acid: "#d8ff45"
  coral: "#ff5a4f"
  coral-light: "#ffd1c9"
typography:
  display:
    fontFamily: "Bricolage Grotesque, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(3.6rem, 7.6vw, 8.2rem)"
    fontWeight: 800
    lineHeight: 0.84
    letterSpacing: "-0.085em"
  body:
    fontFamily: "Instrument Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "ui-monospace, SFMono-Regular, Cascadia Mono, Menlo, monospace"
    fontSize: "0.63rem"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.1em"
rounded:
  panel: "0px"
  control: "999px"
  phone: "28px"
spacing:
  page: "max(1.5rem, calc((100vw - 100rem) / 2))"
  section: "clamp(6rem, 10vw, 10rem)"
components:
  button-acid:
    backgroundColor: "{colors.acid}"
    textColor: "{colors.black}"
    rounded: "{rounded.control}"
    padding: "0 22px"
    height: "52px"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.bone}"
    rounded: "{rounded.control}"
    padding: "0 22px"
    height: "52px"
---

# Design System: Shakti / Pulse Motion

## Overview

**Creative North Star: “Pulse Motion”**

This is a motion-graphic experience before it is a conventional marketing page. It borrows the discipline of motion design studies: oversized type, hard cuts between color fields, visible timing markers, negative space, offset layers, and objects that move with a reason. The opening is a black field with a luminous signal object; the story then moves through bone, violet, acid-lime, black, and coral chapters.

The product remains calm and readable underneath the art direction. The motion does not invent safety claims; it gives the verified trigger, tracker, map, guardian, AI, privacy, and helpline content a memorable spatial rhythm. Every high-energy section is paired with a clear label and a concrete action.

**Key Characteristics:**
- Black and bone provide the base contrast; violet carries the product signal.
- Acid-lime means ready, safe, and confirmed; coral is reserved for urgent helplines and emergency meaning.
- Bricolage Grotesque is used as an oversized kinetic display voice; Instrument Sans carries explanation.
- Full-viewport chapters change composition instead of repeating card grids.
- The signature object is a luminous signal field built from rings, depth particles, a ribbon, and a responsive core.

## Colors

Color is used in whole visual chapters, not scattered as decorative accents.

### Primary
- **Electric Violet** (#635bff): the product signal, trigger chapter, and focused interactive state.
- **Acid Lime** (#d8ff45): readiness, connectedness, safe state, and primary action.

### Secondary
- **Bone** (#f3f0e8): editorial reading field and high-contrast text surface.
- **Soft Violet** (#a49dff): display emphasis over black and signal glow.

### Tertiary
- **Emergency Coral** (#ff5a4f): direct helpline surface and emergency meaning only.
- **Coral Light** (#ffd1c9): readable supporting copy on emergency coral.

### Neutral
- **Motion Black** (#0c0c0e): default page field and final CTA.
- **Black Soft** (#141419): AI and supporting product scenes.

### Named Rules
**The Chapter Color Rule.** A color owns a scene. Violet belongs to the trigger, acid-lime belongs to connection, bone belongs to editorial clarity, and coral belongs to urgent help.

## Typography

**Display Font:** Bricolage Grotesque
**Body Font:** Instrument Sans
**Label/Mono Font:** ui-monospace / Cascadia Mono / Menlo

Display type is intentionally oversized, tight, and allowed to break across short lines. Body copy remains below 65ch. Mono labels describe timing, chapter, status, or coordinates; it is never used as costume body text.

## Layout

The desktop surface uses a 100rem maximum field with asymmetric editorial splits. The first viewport is a black signal field with copy on the left and the animated object on the right. The manifesto is a bone-color full-width interruption. The story is a 360vh scroll choreography with a sticky three.js scene. Later chapters alternate between full-bleed color fields and two-column proof layouts.

Below 900px, the nav collapses and each chapter becomes a single-column composition. Below 560px, all primary actions become full width, chapter labels remain visible, and the object is scaled rather than removed.

## Elevation & Depth

Depth is primarily produced by animation, scale, opacity, perspective, and masking. Panels are mostly flat at rest. The hero signal field uses 2.5D canvas layers, the city chapter uses the existing three.js scene, and the trigger scene uses the physical phone as its tactile object. Shadows are intentionally quiet and tinted by the chapter.

## Shapes

The page is mostly sharp-edged and poster-like. Chapter panels use square edges; controls use a full pill radius; the phone retains its physical rounded silhouette. Thin 1px lines act as the structural grid. Decorative rings are circular and belong only to motion fields.

## Components

### Buttons
- **Primary:** acid-lime pill with near-black text, 52px minimum height, short action labels.
- **Outline:** transparent pill with a bone or black line depending on the chapter.
- **Interaction:** transform and color feedback; visible Soft Violet focus ring.

### Navigation
- **Desktop:** fixed black rail with wordmark, chapter count, one-line principle, and two actions.
- **Mobile:** compact wordmark/action row and a full-width chapter list.

### Earth Signal Globe
The signature hero component is a local Three.js Earth scene using official Three.js planet textures with a procedural atlas fallback. It combines day/night surface detail, normal/specular relief, city lights, cloud cover, a violet atmosphere, orbit rings, and arcs between Bengaluru and trusted guardian locations. It is decorative proof of a connected world; the adjacent copy carries the complete meaning.

### Motion Story
The story uses a sticky stage, three scenes, a progress line, and a live state strip. Scene copy fades and translates with scroll progress, while the city scene continues as a restrained loop. Reduced motion renders the scenes in order as ordinary content.

## Do's and Don'ts

### Do:
- **Do** make the first viewport memorable through scale, object, and timing.
- **Do** use easing, offset, fade, morph-like shape changes, parallax, and zoom when they explain the response.
- **Do** keep content readable without canvas, WebGL, or motion.
- **Do** preserve the verified “Built” and “In development” language.
- **Do** use real product interactions inside the composed art direction.

### Don't:
- **Don't** use a generic dark dashboard as the visual language.
- **Don't** turn every feature into an identical rounded card.
- **Don't** use acid-lime or coral as random decoration.
- **Don't** use gradient text or a second display typeface.
- **Don't** let the motion hide the action, the helplines, or the fact that a demo is scripted.
