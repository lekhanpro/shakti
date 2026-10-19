import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Block, CLAMP, Glass, Person, Stage, Tag, useSpring } from "../ui";
import { BODY, CYAN, INK, LILAC, MINT, ORANGE, PAPER, ROSE, YELLOW, hardShadow } from "../theme";

const ROWS = [
  { label: "Saved on the phone", at: 10 },
  { label: "SMS to guardians", at: 24 },
  { label: "Telegram alert", at: 40 },
  { label: "Live tracking link", at: 56 },
] as const;

const GUARDIANS = [
  { a: -155, c: YELLOW },
  { a: -92, c: LILAC },
  { a: -25, c: MINT },
  { a: 42, c: CYAN },
  { a: 128, c: ORANGE },
] as const;

const CX = 450;
const CY = 380;

const Tick = ({ p }: { p: number }) => (
  <svg width={34} height={34} viewBox="0 0 34 34">
    <path
      d="M6 18 L14 26 L29 8"
      fill="none"
      stroke={INK}
      strokeWidth={5}
      strokeLinecap="round"
      strokeLinejoin="round"
      pathLength={1}
      strokeDasharray={1}
      strokeDashoffset={1 - p}
    />
  </svg>
);

export const AlertScene = () => {
  const frame = useCurrentFrame();
  const shake = frame < 8 ? Math.sin(frame * 3) * (8 - frame) : 0;

  return (
    <Stage from="#ffc2cf" to="#ffe9a8" blobs={[ROSE, YELLOW, ORANGE]}>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 120, gap: 20, translate: `${shake}px 0px` }}>
        <Block delay={1} size={140} color={ROSE} textColor={PAPER} rot={-2}>
          The alert
        </Block>
        <Block delay={7} size={140} rot={1.5}>
          goes out.
        </Block>
        <Glass radius={30} shadow={10} style={{ marginTop: 20, width: 700, padding: "26px 34px" }}>
          {ROWS.map((r) => {
            const done = frame >= r.at;
            const active = !done && frame >= r.at - 14;
            const p = interpolate(frame, [r.at, r.at + 8], [0, 1], CLAMP);
            const o = interpolate(frame, [r.at - 18, r.at - 12], [0.4, 1], CLAMP);
            return (
              <div key={r.label} style={{ display: "flex", alignItems: "center", gap: 22, padding: "9px 0", opacity: o }}>
                <div
                  style={{
                    width: 50,
                    height: 50,
                    borderRadius: "50%",
                    border: `5px solid ${INK}`,
                    background: done ? MINT : active ? YELLOW : PAPER,
                    display: "grid",
                    placeItems: "center",
                    scale: done ? 1 + Math.max(0, 0.3 - (frame - r.at) * 0.05) : 1,
                  }}
                >
                  {done ? <Tick p={p} /> : null}
                </div>
                <div style={{ fontFamily: BODY, fontWeight: 700, fontSize: 40, color: INK }}>{r.label}</div>
              </div>
            );
          })}
        </Glass>
      </AbsoluteFill>

      <div style={{ position: "absolute", left: 980, top: 150, width: 900, height: 760 }}>
        <svg width={900} height={760} viewBox="0 0 900 760" style={{ position: "absolute", inset: 0 }}>
          {GUARDIANS.map((g, i) => {
            const x = CX + Math.cos((g.a * Math.PI) / 180) * 330;
            const y = CY + Math.sin((g.a * Math.PI) / 180) * 290;
            const p = interpolate(frame, [34 + i * 5, 54 + i * 5], [0, 1], CLAMP);
            const dot = (frame * 0.035 + i * 0.23) % 1;
            return (
              <g key={g.a}>
                <line x1={CX} y1={CY} x2={x} y2={y} stroke={INK} strokeWidth={9} strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - p} />
                {p >= 1 ? (
                  <circle cx={CX + (x - CX) * dot} cy={CY + (y - CY) * dot} r={13} fill={PAPER} stroke={INK} strokeWidth={4} />
                ) : null}
              </g>
            );
          })}
        </svg>

        {[0, 1, 2].map((i) => {
          const k = ((frame + i * 14) % 42) / 42;
          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: CX - 120,
                top: CY - 120,
                width: 240,
                height: 240,
                borderRadius: "50%",
                border: `7px solid ${ROSE}`,
                opacity: (1 - k) * 0.8,
                scale: 0.6 + k * 1.5,
              }}
            />
          );
        })}

        <div
          style={{
            position: "absolute",
            left: CX - 62,
            top: CY - 105,
            width: 124,
            height: 210,
            borderRadius: 32,
            background: PAPER,
            border: `6px solid ${INK}`,
            boxShadow: hardShadow(10),
            display: "grid",
            placeItems: "center",
          }}
        >
          <div style={{ width: 46, height: 46, borderRadius: "50%", background: ROSE, border: `5px solid ${INK}` }} />
        </div>

        {GUARDIANS.map((g, i) => (
          <GuardianBubble key={g.a} angle={g.a} color={g.c} delay={22 + i * 5} />
        ))}
      </div>

      <div style={{ position: "absolute", left: 1500, top: 930 }}>
        <Tag delay={30} rot={3} color={PAPER} size={24}>
          Demo timeline
        </Tag>
      </div>
    </Stage>
  );
};

const GuardianBubble = ({ angle, color, delay }: { angle: number; color: string; delay: number }) => {
  const s = useSpring(delay, 9);
  const x = CX + Math.cos((angle * Math.PI) / 180) * 330;
  const y = CY + Math.sin((angle * Math.PI) / 180) * 290;
  return (
    <div
      style={{
        position: "absolute",
        left: x - 62,
        top: y - 62,
        width: 124,
        height: 124,
        borderRadius: "50%",
        background: color,
        border: `6px solid ${INK}`,
        boxShadow: hardShadow(8),
        display: "grid",
        placeItems: "center",
        scale: s,
      }}
    >
      <Person size={70} />
    </div>
  );
};
