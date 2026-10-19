/** Mirrors the app's PowerPressDetector: three presses inside 1200 ms raise an SOS. */
export const PRESS_COUNT = 3;
export const PRESS_WINDOW_MS = 1200;

export interface PressResult {
  history: number[];
  triggered: boolean;
}

/** Record a press at time `at` (ms). Returns the new history and whether this press completed the run. */
export function pushPress(history: readonly number[], at: number): PressResult {
  const recent = history.filter((t) => at - t <= PRESS_WINDOW_MS);
  recent.push(at);
  if (recent.length >= PRESS_COUNT) return { history: [], triggered: true };
  return { history: recent, triggered: false };
}
