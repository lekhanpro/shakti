/**
 * An illustration of the 5 km search the safety map runs. Place positions are
 * made up. Each place type has its own shape, so colour is never the only cue.
 */
const PLACES = [
  { kind: 'police', x: 150, y: 96 },
  { kind: 'police', x: 62, y: 190 },
  { kind: 'hospital', x: 236, y: 162 },
  { kind: 'hospital', x: 118, y: 52 },
  { kind: 'pharmacy', x: 196, y: 238 },
  { kind: 'pharmacy', x: 78, y: 120 },
  { kind: 'shelter', x: 252, y: 92 },
  { kind: 'shelter', x: 140, y: 260 },
] as const;

function Mark({ kind, x, y }: { kind: (typeof PLACES)[number]['kind']; x: number; y: number }) {
  const common = { fill: '#0b1220', stroke: '#6ee7b7', strokeWidth: 2 };
  if (kind === 'police') return <circle cx={x} cy={y} r={7} {...common} />;
  if (kind === 'hospital') return <rect x={x - 7} y={y - 7} width={14} height={14} {...common} />;
  if (kind === 'pharmacy') return <polygon points={`${x},${y - 8} ${x + 8},${y + 7} ${x - 8},${y + 7}`} {...common} />;
  return <polygon points={`${x},${y - 8} ${x + 8},${y} ${x},${y + 8} ${x - 8},${y}`} {...common} />;
}

export function SafetyRadar() {
  return (
    <svg
      viewBox="0 0 300 300"
      role="img"
      aria-label="Illustration: a map centred on you with rings out to 5 kilometres and marks for police stations, hospitals, pharmacies and shelters."
      className="mx-auto w-full max-w-md"
    >
      <circle cx={150} cy={150} r={140} fill="rgb(99 102 241 / 0.06)" stroke="#334155" />
      <circle cx={150} cy={150} r={93} fill="none" stroke="#334155" strokeDasharray="3 5" />
      <circle cx={150} cy={150} r={46} fill="none" stroke="#334155" strokeDasharray="3 5" />
      <g className="radar-sweep" style={{ transformOrigin: '150px 150px' }}>
        <path d="M150 150 L150 10 A140 140 0 0 1 249 51 Z" fill="rgb(165 180 252 / 0.16)" />
      </g>
      {PLACES.map((p, i) => (
        <Mark key={i} kind={p.kind} x={p.x} y={p.y} />
      ))}
      <circle cx={150} cy={150} r={7} fill="#a5b4fc" stroke="#fff" strokeWidth={2} />
      <text x={150} y={294} textAnchor="middle" fontSize={12} fill="#94a3b8">
        5 km
      </text>
    </svg>
  );
}
