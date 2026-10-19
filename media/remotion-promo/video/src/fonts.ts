import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

const DISPLAY_WEIGHTS = ["600", "700", "800"];
const BODY_WEIGHTS = ["400", "500", "600", "700"];

// loadFont holds the render until each file is ready, so no frame uses a fallback.
export const fontsReady = Promise.all([
  ...DISPLAY_WEIGHTS.map((weight) =>
    loadFont({
      family: "Bricolage",
      url: staticFile(`fonts/bricolage-grotesque-latin-${weight}-normal.woff2`),
      weight,
      format: "woff2",
    }),
  ),
  ...BODY_WEIGHTS.map((weight) =>
    loadFont({
      family: "Instrument",
      url: staticFile(`fonts/instrument-sans-latin-${weight}-normal.woff2`),
      weight,
      format: "woff2",
    }),
  ),
]);
