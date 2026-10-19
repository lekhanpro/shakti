// Scene lengths in frames at 30 fps. Six 12-frame transitions overlap the cuts,
// so the total is the sum minus 72: 672 - 72 = 600 frames = 20 seconds.
export const SCENE_FRAMES = {
  hook: 75,
  presses: 90,
  countdown: 150,
  alert: 105,
  tracker: 90,
  safe: 60,
  outro: 102,
} as const;

export const TRANSITION_FRAMES = 12;
export const TRANSITION_COUNT = 6;

export const TOTAL_FRAMES =
  SCENE_FRAMES.hook +
  SCENE_FRAMES.presses +
  SCENE_FRAMES.countdown +
  SCENE_FRAMES.alert +
  SCENE_FRAMES.tracker +
  SCENE_FRAMES.safe +
  SCENE_FRAMES.outro -
  TRANSITION_FRAMES * TRANSITION_COUNT;
