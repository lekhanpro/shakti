import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { BODY, CYAN, DISPLAY, INDIGO, INK, LILAC, MINT, PAPER, ROSE, YELLOW, hardShadow } from "../theme";
import { Block, CLAMP, Glass, Note, Stage, Tag } from "../ui";

const ROUTE: readonly (readonly [number, number])[] = [
  [70, 510],
  [190, 430],
  [330, 450],
  [420, 330],
  [540, 300],
  [620, 190],
  [760, 160],
];

const LENGTHS = ROUTE.slice(1).map((p, i) => Math.hypot(p[0] - ROUTE[i][0], p[1] - ROUTE[i][1]));
const TOTAL = LENGTHS.reduce((a, b) => a + b, 0);

const pointAt = (p: number): readonly [number, number] => {
  let d = p * TOTAL;
  for (let i = 0; i < LENGTHS.length; i++) {
    if (d <= LENGTHS[i]) {
      const k = d / LENGTHS[i];
      return [ROUTE[i][0] + (ROUTE[i + 1][0] - ROUTE[i][0]) * k, ROUTE[i][1] + (ROUTE[i + 1][1] - ROUTE[i][1]) * k];
    }
    d -= LENGTHS[i];
  }
  return ROUTE[ROUTE.length - 1];
};

const BLOCKS: readonly (readonly [number, number, number, number, string])[] = [
  [30, 40, 150, 120, "#fde68a"],
  [230, 40, 190, 90, "#bbf7d0"],
  [470, 70, 120, 150, "#fbcfe8"],
  [650, 40, 190, 80, "#bae6fd"],
  [30, 260, 130, 110, "#ddd6fe"],
  [220, 250, 140, 100, "#fed7aa"],
  [650, 260, 190, 130, "#bbf7d0"],
  [560, 400, 150, 90, "#fde68a"],
];

export const TrackerScene = () => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [8, 74], [0, 1], { ...CLAMP, easing: (x) => 1 - Math.pow(1 - x, 2) });
  const [hx, hy] = pointAt(p);
  const pulse = (frame % 30) / 30;
  const chip = (i: number) => interpolate(frame, [30 + i * 8, 40 + i * 8], [0, 1], CLAMP);
  const enter = interpolate(frame, [0, 14], [0, 1], CLAMP);

  return (
    <Stage from="#c9d4ff" to="#b8f5e8" blobs={[INDIGO, CYAN, MINT]}>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 120, gap: 20 }}>
        <Block delay={1} size={120} color={INDIGO} textColor={PAPER} rot={-2}>
          They follow
        </Block>
        <Block delay={6} size={120} color={YELLOW} rot={1.5}>
          you home.
        </Block>
        <div style={{ marginTop: 18 }}>
          <Note delay={16} size={34}>
            Route and battery in any browser.
            <br />
            No app, no sign-up.
          </Note>
        </div>
      </AbsoluteFill>

      <Glass
        radius={40}
        shadow={16}
        tint={0.5}
        style={{
          position: "absolute",
          left: 960,
          top: 170,
          width: 840,
          height: 700,
          overflow: "hidden",
          rotate: "2deg",
          translate: `${(1 - enter) * 200}px 0px`,
        }}
      >
        <div style={{ position: "absolute", left: 0, top: 86, width: 840, height: 520, background: "#f1ede0" }}>
          {BLOCKS.map(([x, y, w, h, c]) => (
            <div key={`${x}-${y}`} style={{ position: "absolute", left: x, top: y, width: w, height: h, background: c, border: `4px solid ${INK}` }} />
          ))}
          <svg width={840} height={520} viewBox="0 0 840 520" style={{ position: "absolute", inset: 0 }}>
            <polyline points={ROUTE.map((q) => q.join(",")).join(" ")} fill="none" stroke={INK} strokeWidth={24} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - p} />
            <polyline points={ROUTE.map((q) => q.join(",")).join(" ")} fill="none" stroke={INDIGO} strokeWidth={12} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - p} />
            <circle cx={hx} cy={hy} r={20 + pulse * 46} fill="none" stroke={ROSE} strokeWidth={6} opacity={1 - pulse} />
            <circle cx={hx} cy={hy} r={20} fill={ROSE} stroke={INK} strokeWidth={6} />
          </svg>
        </div>
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: 840,
            height: 86,
            background: PAPER,
            borderBottom: `5px solid ${INK}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "0 30px",
          }}
        >
          <div style={{ fontFamily: DISPLAY, fontWeight: 800, fontSize: 36, color: INK }}>Guardian view</div>
          <Tag size={20} color={YELLOW} style={{ boxShadow: hardShadow(4) }}>
            Demo, simulated data
          </Tag>
        </div>
        <div style={{ position: "absolute", left: 0, bottom: 0, width: 840, height: 94, background: PAPER, borderTop: `5px solid ${INK}`, display: "flex", alignItems: "center", gap: 18, padding: "0 26px" }}>
          {["Battery 61%", "Every 10 s", "No app needed"].map((t, i) => (
            <div
              key={t}
              style={{
                fontFamily: BODY,
                fontWeight: 700,
                fontSize: 27,
                color: INK,
                background: [MINT, LILAC, CYAN][i],
                border: `4px solid ${INK}`,
                boxShadow: hardShadow(5),
                padding: "8px 20px",
                opacity: chip(i),
                translate: `0px ${(1 - chip(i)) * 24}px`,
              }}
            >
              {t}
            </div>
          ))}
        </div>
      </Glass>
    </Stage>
  );
};
