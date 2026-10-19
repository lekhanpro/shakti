import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Block, CLAMP, Glass, Note, Phone, Stage, Tag } from "../ui";
import { BODY, CYAN, DISPLAY, INK, MONO, ORANGE, PAPER, YELLOW } from "../theme";

const R = 128;
const CIRC = 2 * Math.PI * R;

export const CountdownScene = () => {
  const frame = useCurrentFrame();
  const left = interpolate(frame, [0, 150], [1, 0], CLAMP);
  const n = Math.max(1, 5 - Math.floor(frame / 30));
  const k = (frame % 30) / 30;
  const knob = interpolate(Math.sin(frame / 7), [-1, 1], [0, 90]);
  const settle = interpolate(k, [0, 0.15, 1], [1.18, 1, 1], CLAMP);

  return (
    <Stage from="#ffd9a0" to="#fff2a8" blobs={[ORANGE, YELLOW, CYAN]}>
      <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 120, gap: 22 }}>
        <Block delay={2} size={150} color={ORANGE} rot={-2}>
          5 seconds
        </Block>
        <Block delay={9} size={96} rot={1.5}>
          to change
        </Block>
        <Block delay={15} size={96} color={YELLOW} rot={-1}>
          your mind.
        </Block>
        <div style={{ marginTop: 16, display: "flex", gap: 20, alignItems: "center" }}>
          <Note delay={28} size={36}>
            It vibrates every second.
            <br />
            Swipe to cancel.
          </Note>
          <Tag delay={38} rot={4} color={CYAN} size={26}>
            3 to 15 s
          </Tag>
        </div>
      </AbsoluteFill>

      <div style={{ position: "absolute", left: 1210, top: 90, rotate: "-3deg" }}>
        <Phone width={470} height={900}>
          <AbsoluteFill style={{ alignItems: "center", paddingTop: 150 }}>
            <div style={{ fontFamily: MONO, fontWeight: 700, fontSize: 30, color: "#fcd34d", letterSpacing: 3 }}>
              SENDING SOS IN
            </div>
            <div style={{ position: "relative", width: 330, height: 330, marginTop: 40 }}>
              <svg width={330} height={330} viewBox="0 0 330 330" style={{ rotate: "-90deg" }}>
                <circle cx={165} cy={165} r={R} fill="none" stroke="#1e293b" strokeWidth={26} />
                <circle
                  cx={165}
                  cy={165}
                  r={R}
                  fill="none"
                  stroke={ORANGE}
                  strokeWidth={26}
                  strokeLinecap="round"
                  strokeDasharray={CIRC}
                  strokeDashoffset={CIRC * (1 - left)}
                />
              </svg>
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  display: "grid",
                  placeItems: "center",
                  fontFamily: DISPLAY,
                  fontWeight: 800,
                  fontSize: 200,
                  color: PAPER,
                  scale: settle,
                }}
              >
                {n}
              </div>
            </div>
            <Glass
              radius={999}
              shadow={0}
              tint={0.16}
              style={{
                position: "absolute",
                bottom: 70,
                width: 340,
                height: 92,
                borderColor: "#475569",
                boxShadow: "none",
              }}
            >
              <div
                style={{
                  position: "absolute",
                  left: 12 + knob,
                  top: 10,
                  width: 64,
                  height: 64,
                  borderRadius: "50%",
                  background: PAPER,
                  border: `4px solid ${INK}`,
                }}
              />
              <div
                style={{
                  position: "absolute",
                  inset: 0,
                  display: "grid",
                  placeItems: "center",
                  paddingLeft: 70,
                  fontFamily: BODY,
                  fontWeight: 600,
                  fontSize: 28,
                  color: "#cbd5e1",
                }}
              >
                Swipe to cancel
              </div>
            </Glass>
          </AbsoluteFill>
        </Phone>
      </div>

      <div style={{ position: "absolute", left: 130, top: 930 }}>
        <Tag delay={20} rot={-3} color={PAPER} size={26}>
          Haptic tick each second
        </Tag>
      </div>
    </Stage>
  );
};
