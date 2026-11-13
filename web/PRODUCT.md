# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

The primary audience is young women using Android who want to understand whether Shakti can help in a stressful safety situation. Guardians and family members are a secondary audience.

## Product Purpose

Shakti is a university safety project that helps a person reach trusted guardians during an incident. The public website should make the SOS flow understandable within seconds and let a visitor try the trigger and tracker demonstrations.

## Positioning

Shakti presents safety as a connected response: one trigger starts a sequence that saves the incident locally, reaches guardians through the available channels, and keeps a live tracker available for the people who need it.

## Operating Context

The landing page is read on mobile and desktop, often at night or under stressful conditions. Visitors may arrive without knowing the project. A separate `/track/[token]` route lets guardians view a live tracker or demo tracker in a browser.

## Capabilities and Constraints

- Next.js 16.3.7, React 19.3, Tailwind 4, Motion, Three.js, and the existing dark-only Shakti token system.
- The landing page keeps the trigger demo, the five-stage SOS walkthrough, the safety map illustration, the AI/FIR scripted demo, helplines, FAQ, privacy content, the full trigger and feature inventory, and verified built/in-development status.
- Verified facts come from the Shakti code and claim ledger. Phone-service integrations are present in source; physical-device delivery, permissions, sensor reliability, and battery validation remain separate evidence requirements.
- The existing `/track/[token]` route remains intact.
- The site must remain keyboard accessible, preserve visible focus, respect reduced motion, and keep all critical copy available without WebGL.

## Brand Commitments

The name is Shakti. Indigo is the brand color, emerald communicates safe states, and rose is reserved for emergency meaning. The site remains dark-only and uses the self-hosted Bricolage Grotesque and Instrument Sans families.

## Evidence on Hand

Fact-checked landing content is in `components/landing/content.ts`. Interactive demonstrations are in `components/landing/ResponseLab.tsx`, `PressDemo.tsx`, `SafetyRadar.tsx`, and `AiDemo.tsx`. The hero globe is `components/landing/SignalGlobe.tsx` with its geometry in `lib/globe.ts` and its land mask in `lib/globe-land.ts`, baked from a local texture by `scripts/bake-globe-land.py`.

## Product Principles

1. Make the first action obvious before explaining the system.
2. Show the response as a sequence that can be understood under stress.
3. Label what is built and what is still in development.
4. Keep emergency meaning distinct from brand decoration.
5. Treat motion as an explanation of state, not as ambient spectacle.

## Accessibility & Inclusion

All interactive demos need keyboard paths and live status announcements where state changes. Reduced-motion visitors must see the full story without pinning, parallax, or typing animation. Essential copy must not depend on canvas or WebGL.


## 21 October 2026 landing update

The active page uses the Shakti Circle direction in `app/landing.css`: a procedural 3D phone/network, a bounded arrival transition, five-stage local SOS walkthrough, clear product requirements, explicit motion controls, and an honest alpha/download state. See [design references](docs/design-references.md). Existing tracker routes remain independent.
