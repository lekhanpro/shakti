import type { CSSProperties, FC, ReactNode } from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { BODY, DISPLAY, INK, MONO, PAPER, YELLOW, hardShadow } from "./theme";

export const CLAMP = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** A snappy overshooting spring that starts at `delay` frames. */
export const useSpring = (delay = 0, damping = 11): number => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config: { damping, stiffness: 170, mass: 0.8 } });
};

export const useFade = (from: number, to: number): number => {
  const frame = useCurrentFrame();
  return interpolate(frame, [from, to], [0, 1], CLAMP);
};

/* ---------- background: gradient, drifting blobs, moving dot grid ---------- */
type StageProps = {
  from: string;
  to: string;
  blobs: readonly [string, string, string];
  angle?: number;
  children?: ReactNode;
};

export const Stage: FC<StageProps> = ({ from, to, blobs, angle = 135, children }) => {
  const frame = useCurrentFrame();
  const t = frame / 30;
  const blob = (color: string, x: number, y: number, size: number, phase: number, opacity: number) => (
    <div
      style={{
        position: "absolute",
        left: x + Math.sin(t * 0.9 + phase) * 80,
        top: y + Math.cos(t * 0.7 + phase) * 70,
        width: size,
        height: size,
        borderRadius: "50%",
        background: color,
        opacity,
        filter: "blur(80px)",
      }}
    />
  );
  return (
    <AbsoluteFill style={{ background: `linear-gradient(${angle}deg, ${from}, ${to})`, overflow: "hidden" }}>
      {blob(blobs[0], -250, -200, 950, 0, 0.75)}
      {blob(blobs[1], 1050, 450, 1050, 2, 0.65)}
      {blob(blobs[2], 650, -350, 750, 4, 0.55)}
      <AbsoluteFill
        style={{
          backgroundImage: "radial-gradient(rgba(11,11,18,0.24) 2.5px, transparent 2.5px)",
          backgroundSize: "40px 40px",
          backgroundPosition: `${frame * 0.7}px ${frame * 0.7}px`,
        }}
      />
      {children}
    </AbsoluteFill>
  );
};

/* ---------- glass panel with a brutalist edge ---------- */
type GlassProps = {
  children?: ReactNode;
  style?: CSSProperties;
  radius?: number;
  shadow?: number;
  tint?: number;
};

export const Glass: FC<GlassProps> = ({ children, style, radius = 32, shadow = 10, tint = 0.4 }) => (
  <div
    style={{
      background: `linear-gradient(140deg, rgba(255,255,255,${tint}), rgba(255,255,255,0.12))`,
      backdropFilter: "blur(22px) saturate(170%)",
      border: `4px solid ${INK}`,
      borderRadius: radius,
      boxShadow: `${hardShadow(shadow)}, inset 0 3px 0 rgba(255,255,255,0.7)`,
      ...style,
    }}
  >
    {children}
  </div>
);

/* ---------- headline block that slams in ---------- */
type BlockProps = {
  children: string;
  color?: string;
  textColor?: string;
  size?: number;
  delay?: number;
  rot?: number;
  style?: CSSProperties;
};

export const Block: FC<BlockProps> = ({
  children,
  color = PAPER,
  textColor = INK,
  size = 110,
  delay = 0,
  rot = 0,
  style,
}) => {
  const s = useSpring(delay);
  const o = useFade(delay, delay + 4);
  return (
    <div
      style={{
        display: "inline-block",
        alignSelf: "flex-start",
        background: color,
        color: textColor,
        border: `5px solid ${INK}`,
        boxShadow: hardShadow(Math.round(size * 0.08) + 4),
        padding: `${size * 0.04}px ${size * 0.2}px ${size * 0.1}px`,
        fontFamily: DISPLAY,
        fontWeight: 800,
        fontSize: size,
        lineHeight: 1.02,
        letterSpacing: -size * 0.025,
        textTransform: "uppercase",
        whiteSpace: "nowrap",
        opacity: o,
        translate: `0px ${(1 - s) * 80}px`,
        scale: 0.7 + 0.3 * s,
        rotate: `${rot * Math.min(1, s)}deg`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/* ---------- body copy on glass ---------- */
type NoteProps = { children: ReactNode; delay?: number; size?: number; style?: CSSProperties };

export const Note: FC<NoteProps> = ({ children, delay = 0, size = 38, style }) => {
  const s = useSpring(delay, 16);
  const o = useFade(delay, delay + 6);
  return (
    <Glass
      radius={26}
      shadow={8}
      style={{
        display: "inline-block",
        padding: `${size * 0.45}px ${size * 0.75}px`,
        fontFamily: BODY,
        fontWeight: 600,
        fontSize: size,
        lineHeight: 1.3,
        color: INK,
        opacity: o,
        translate: `0px ${(1 - s) * 40}px`,
        ...style,
      }}
    >
      {children}
    </Glass>
  );
};

/* ---------- mono sticker ---------- */
type TagProps = {
  children: ReactNode;
  color?: string;
  textColor?: string;
  size?: number;
  rot?: number;
  delay?: number;
  style?: CSSProperties;
};

export const Tag: FC<TagProps> = ({
  children,
  color = YELLOW,
  textColor = INK,
  size = 26,
  rot = 0,
  delay = 0,
  style,
}) => {
  const s = useSpring(delay, 12);
  const o = useFade(delay, delay + 4);
  return (
    <div
      style={{
        display: "inline-block",
        background: color,
        color: textColor,
        border: `4px solid ${INK}`,
        boxShadow: hardShadow(6),
        padding: `${size * 0.3}px ${size * 0.6}px`,
        fontFamily: MONO,
        fontWeight: 700,
        fontSize: size,
        letterSpacing: 1.5,
        textTransform: "uppercase",
        whiteSpace: "nowrap",
        opacity: o,
        scale: 0.6 + 0.4 * s,
        rotate: `${rot}deg`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/* ---------- phone with a pressable side key ---------- */
type PhoneProps = {
  children?: ReactNode;
  keyPress?: number;
  width?: number;
  height?: number;
  style?: CSSProperties;
};

export const Phone: FC<PhoneProps> = ({ children, keyPress = 0, width = 470, height = 900, style }) => (
  <div style={{ position: "relative", width, height, ...style }}>
    <div
      style={{
        position: "absolute",
        right: -16 + keyPress * 10,
        top: height * 0.26,
        width: 18,
        height: 130,
        background: INK,
        borderRadius: 9,
      }}
    />
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: PAPER,
        border: `8px solid ${INK}`,
        borderRadius: 70,
        boxShadow: hardShadow(16),
      }}
    />
    <div
      style={{
        position: "absolute",
        inset: 24,
        borderRadius: 48,
        overflow: "hidden",
        border: `4px solid ${INK}`,
        background: "linear-gradient(180deg, #131c31, #070b14)",
      }}
    >
      {children}
    </div>
    <div
      style={{
        position: "absolute",
        top: 38,
        left: "50%",
        width: 120,
        height: 22,
        marginLeft: -60,
        borderRadius: 12,
        background: INK,
      }}
    />
  </div>
);

/* ---------- starburst sticker ---------- */
type BurstProps = {
  size: number;
  fill: string;
  points?: number;
  rotate?: number;
  children?: ReactNode;
  style?: CSSProperties;
};

export const Burst: FC<BurstProps> = ({ size, fill, points = 14, rotate = 0, children, style }) => {
  const pts: string[] = [];
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 === 0 ? 46 : 37;
    const a = (Math.PI * i) / points;
    pts.push(`${(50 + Math.cos(a) * r).toFixed(2)},${(50 + Math.sin(a) * r).toFixed(2)}`);
  }
  const poly = pts.join(" ");
  return (
    <div style={{ position: "relative", width: size, height: size, ...style }}>
      <svg
        viewBox="0 0 100 100"
        width={size}
        height={size}
        style={{ position: "absolute", inset: 0, overflow: "visible", rotate: `${rotate}deg` }}
      >
        <polygon points={poly} fill={INK} transform="translate(4 4)" />
        <polygon points={poly} fill={fill} stroke={INK} strokeWidth={3} strokeLinejoin="round" />
      </svg>
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "grid",
          placeItems: "center",
          textAlign: "center",
          fontFamily: DISPLAY,
          fontWeight: 800,
          color: INK,
          fontSize: size * 0.16,
          lineHeight: 1,
        }}
      >
        {children}
      </div>
    </div>
  );
};

/* ---------- person glyph for guardian bubbles ---------- */
export const Person: FC<{ size: number }> = ({ size }) => (
  <svg width={size} height={size} viewBox="0 0 40 40">
    <circle cx="20" cy="14" r="7" fill={INK} />
    <path d="M6 36c0-8 6-13 14-13s14 5 14 13z" fill={INK} />
  </svg>
);
