# Shakti landing-page direction

Reviewed 21 October 2026. These are design references; Shakti uses its own implementation, copy, geometry, and existing self-hosted fonts.

| Reference | Award source | Principle applied to Shakti |
| --- | --- | --- |
| [Lusion v3](https://lusion.co/) | [Awwwards Site of the Day, 2 October 2023](https://www.awwwards.com/sites/lusion-v3) | One memorable 3D focal point, responsive interaction, deliberate typography, and paced section transitions |
| [Bruno Simon](https://bruno-simon.com/) | [2019 portfolio award](https://www.awwwards.com/sites/bruno-simon-portfolio) and [2026 portfolio listing](https://www.awwwards.com/sites/brunos-portfolio) | Make interaction discoverable through explicit controls, including keyboard-operable alternatives |
| Immersive Garden | [Awwwards website listing](https://www.awwwards.com/sites/immersive-garden-website) | Give the full page a coherent visual narrative, rather than attaching isolated effects to unrelated sections |

The principles above are design interpretations, not claims that the references use Shakti's exact technical choices.

## The resulting experience

- A brief branded arrival transition waits for font readiness with a bounded fallback. It does not display invented loading percentages or wait for WebGL.
- The hero uses an original procedural phone/network sculpture. Three.js loads near the viewport; it makes no texture, location, or live-alert requests.
- Pointer movement adds restrained depth; explicit rotation and pause controls are keyboard accessible.
- A five-stage SOS walkthrough demonstrates how cloud connectivity changes channel availability. It never sends a message or records audio.
- The trigger and scripted AI demonstrations remain clearly labeled.
- A quieter guardian section, complete feature explanations, privacy boundaries, emergency calls, FAQs, honest download availability, and a large closing signature carry the story to the footer.
- Reduced motion bypasses the intro and decorative animation. A page-motion control pauses continuous illustration motion. Offscreen/hidden WebGL stops scheduling frames.
- The existing tracker route keeps its independent styling and behavior.

## Validation expectations

Use desktop, narrow mobile, keyboard-only, reduced-motion, and WebGL-unavailable checks. The browser smoke script captures screenshots and checks interaction/overflow; passing a production build alone does not establish visual quality.
