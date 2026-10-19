import { AbsoluteFill, useCurrentFrame } from "remotion";
import { Block, Glass, Note, Stage, Tag, useFade, useSpring } from "../ui";
import { BODY, CYAN, DISPLAY, INDIGO, INK, LILAC, MINT, PAPER, ROSE, YELLOW, hardShadow } from "../theme";

const LINES = [
  { n: "112", label: "Emergency" },
  { n: "181", label: "Women helpline" },
  { n: "1091", label: "Women police" },
  { n: "1098", label: "Childline" },
] as const;

const HelplineChip = ({ n, label, delay }: { n: string; label: string; delay: number }) => {
  const s = useSpring(delay, 12);
  const o = useFade(delay, delay + 5);
  return (
    <Glass radius={26} shadow={8} tint={0.5} style={{ width: 380, padding: "18px 24px", display: "flex", alignItems: "center", gap: 20, opacity: o, scale: 0.7 + 0.3 * s }}>
      <div style={{ width: 62, height: 62, borderRadius: "50%", background: ROSE, border: `5px solid ${INK}`, flex: "none" }} />
      <div>
        <div style={{ fontFamily: DISPLAY, fontWeight: 800, fontSize: 54, color: INK, lineHeight: 1 }}>{n}</div>
        <div style={{ fontFamily: BODY, fontWeight: 700, fontSize: 24, color: INK, marginTop: 4 }}>{label}</div>
      </div>
    </Glass>
  );
};

export const OutroScene = () => {
  const frame = useCurrentFrame();
  const logo = useSpring(0, 9);

  return (
    <Stage from="#4f46e5" to="#7c3aed" blobs={[CYAN, LILAC, MINT]} angle={150}>
      <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", gap: 20 }}>
        <div style={{ position: "relative", width: 190, height: 190, scale: logo, rotate: `${(1 - logo) * -90}deg` }}>
          {[0, 1].map((i) => {
            const k = ((frame + i * 20) % 40) / 40;
            return (
              <div
                key={i}
                style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `6px solid ${PAPER}`, opacity: (1 - k) * 0.7, scale: 1 + k * 0.9 }}
              />
            );
          })}
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: INDIGO, border: `8px solid ${INK}`, boxShadow: hardShadow(12), display: "grid", placeItems: "center" }}>
            <div style={{ width: 50, height: 50, borderRadius: "50%", background: PAPER, border: `5px solid ${INK}` }} />
          </div>
        </div>
        <Block delay={6} size={210} color={YELLOW} rot={-1.5} style={{ alignSelf: "center" }}>
          Shakti
        </Block>
        <Note delay={16} size={40}>
          A safety network for Android.
        </Note>
        <div style={{ display: "flex", gap: 22, marginTop: 26 }}>
          {LINES.map((l, i) => (
            <HelplineChip key={l.n} n={l.n} label={l.label} delay={28 + i * 5} />
          ))}
        </div>
        <div style={{ marginTop: 22 }}>
          <Tag delay={52} color={MINT} size={24} rot={-1}>
            A VTU university project. Some features are still in development.
          </Tag>
        </div>
      </AbsoluteFill>
    </Stage>
  );
};
