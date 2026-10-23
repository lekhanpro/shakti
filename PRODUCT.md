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

Retain the Shakti shield/flame and emergency rose. On 23 October 2026 the owner
replaced the earlier dark-first treatment with warm ivory and deep plum, then
requested clear Liquid Glass inspired by current iOS references. Light is the
default; Dark and System remain saved appearance choices. Optical material belongs
to floating controls, with solid content surfaces, bundled Manrope/Inter type and
native Android behavior. The reference does not imply Apple rendering parity.

## Accessibility

Keep controls at least 48 dp, semantic actions, readable contrast, 200% text,
reduced-motion support, and unobscured emergency controls. Use solid emergency
surfaces where translucency would impair clarity.

## Evidence

Implementation lives in `app/`, requirements in `docs/specs/`, and the identity in
`brand/`. Automated verification is documented under `docs/verification/`.
The current light/glass revision and its remaining device/service checks are
recorded in `docs/ui/light-glass-verification-2026-10-23.md`. The website has
separate product and design records in `web/`.
