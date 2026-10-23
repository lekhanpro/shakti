# Shakti

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users and purpose

Shakti is a personal safety network for people who want to alert trusted contacts
and coordinate a walk or emergency. Guardians can receive messages and open the
web tracker. It is DBIT's VTU community project by Lekhan, Manas, Vikat and Hemanth.

## Operating context

The Flutter Android app is used on a phone, including at night and under stress.
Its main flows are SOS, contacts, safety map, Walk with me, AI guidance, evidence,
onboarding, PIN/biometrics and settings. Local data and SMS do not depend on an
internet request. Carrier SMS still needs cellular service, permission and a plan.

## Constraints

Preserve existing behavior and truthful channel status. SOS activation is immediate
and retains the cancellation window; visual transitions must never delay alerts.
The volume/accessibility trigger was removed at the owner's request. No Play
Console rollout or physical-device safety certification has been completed.

## Brand commitments

Retain the Shakti shield/flame and indigo identity. On 22 October 2026 the owner
requested a complete app UI revamp with fluid, Apple-style liquid glass, new
typography and layouts, and selected dark glass with lilac highlights.

## Accessibility

Keep controls at least 48 dp, semantic actions, readable contrast, 200% text,
reduced-motion support, and unobscured emergency controls. Use solid emergency
surfaces where translucency would impair clarity.

## Evidence

Implementation lives in `app/`, requirements in `docs/specs/`, and the identity in
`brand/`. Automated verification is documented under `docs/verification/`.
The website has separate product and design records in `web/`.
