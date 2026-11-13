'use client';

import { useCallback, useEffect, useId, useMemo, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Pause, Play, Wifi, WifiOff } from 'lucide-react';
import {
  GUARDIANS,
  LIMB_INSET,
  ORIGIN,
  POSTER_DOT,
  POSTER_RADIUS,
  POSTER_SPIN,
  POSTER_TILT,
  VIEW_HALF,
  arcVectors,
  landDotVectors,
  placeVector,
  posterPath,
  projectUnit,
  reachDetail,
  spinToFace,
} from '@/lib/globe';

/**
 * The signal globe: a dot-matrix Earth that carries the product's thesis.
 *
 * One press in Bengaluru reaches a circle of guardians. Carrier SMS does not
 * depend on an internet request, so dropping the simulated connection leaves
 * every arc lit and only stops the travelling tracker dot.
 *
 * The visual channel carries the geography; the readout beside it carries the
 * channel behaviour. Both are needed, which is why the readout is not optional
 * decoration under the object.
 *
 * Architecture notes:
 * - The camera is orthographic and the stage is square, so WebGL's projection
 *   is exactly `projectUnit`. The DOM markers therefore sit precisely on the
 *   rendered sphere without hit-testing inside the canvas.
 * - Land comes from lib/globe-land.ts (about 1.6 KB of packed bits), so the
 *   page requests no Earth texture at all.
 * - Without WebGL the hemisphere is a server-rendered SVG that still turns:
 *   the arrows and the guardian chips re-derive its path. Pointer-drag is the
 *   one thing that path cannot afford, so it is disabled there.
 * - Markers are aria-hidden. The labelled chip row below is the real control,
 *   because at hero scale the Indian cities land within a few pixels of each
 *   other and tap targets there would overlap.
 */

const TILT_MIN = -32;
const TILT_MAX = 56;
/** Degrees per second of idle drift: slow enough to read, not to distract. */
const DRIFT_RATE = 2.4;
/** Degrees per press of an arrow button. Twenty presses is a full turn. */
const NUDGE_STEP = 18;

interface Pose {
  spin: number;
  tilt: number;
  /** Set while easing toward a selected guardian; null when free. */
  targetSpin: number | null;
  targetTilt: number | null;
}

function shortestDelta(from: number, to: number): number {
  return ((((to - from) % 360) + 540) % 360) - 180;
}

function clampTilt(tilt: number): number {
  return Math.min(TILT_MAX, Math.max(TILT_MIN, tilt));
}

/**
 * Probed on a throwaway canvas before three.js is fetched. With no WebGL there
 * is no reason to download 184 KB, and handing a renderer a canvas that cannot
 * produce a context makes three.js log an error of its own.
 */
function webglAvailable(): boolean {
  try {
    const probe = document.createElement('canvas');
    return Boolean(probe.getContext('webgl2') || probe.getContext('webgl'));
  } catch {
    return false;
  }
}

export function SignalGlobe() {
  const stageRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const originRef = useRef<HTMLSpanElement>(null);
  const markersRef = useRef<(HTMLSpanElement | null)[]>([]);
  const poseRef = useRef<Pose>({ spin: POSTER_SPIN, tilt: POSTER_TILT, targetSpin: null, targetTilt: null });
  const scheduleRef = useRef<(() => void) | null>(null);
  /** Mirrors React state for the render loop, which must not re-subscribe. */
  const flagsRef = useRef({ paused: false, online: true, selected: -1, dragging: false });
  /** Tears down the listeners of a drag in progress. */
  const dragRef = useRef<AbortController | null>(null);

  const [live, setLive] = useState(false);
  const [paused, setPaused] = useState(false);
  const [online, setOnline] = useState(true);
  const [selected, setSelected] = useState(-1);
  /** Drives the static hemisphere. Only read while WebGL is absent. */
  const [posterPose, setPosterPose] = useState({ spin: POSTER_SPIN, tilt: POSTER_TILT });
  const readoutId = useId();

  // Rendered on the server, so the hemisphere ships inside the HTML.
  const posterDots = useMemo(() => posterPath(posterPose.spin, posterPose.tilt), [posterPose]);

  /** Place the DOM markers for a pose. Also the placement before WebGL loads. */
  const placeMarkers = useCallback((spin: number, tilt: number) => {
    const origin = projectUnit(ORIGIN.lat, ORIGIN.lon, spin, tilt);
    const originEl = originRef.current;
    if (originEl) {
      originEl.style.left = `${50 + origin.x * POSTER_RADIUS}%`;
      originEl.style.top = `${50 - origin.y * POSTER_RADIUS}%`;
      originEl.dataset.face = origin.z > 0 ? 'front' : 'back';
    }
    GUARDIANS.forEach((place, index) => {
      const el = markersRef.current[index];
      if (!el) return;
      const point = projectUnit(place.lat, place.lon, spin, tilt);
      el.style.left = `${50 + point.x * POSTER_RADIUS}%`;
      el.style.top = `${50 - point.y * POSTER_RADIUS}%`;
      el.dataset.face = point.z > 0 ? 'front' : 'back';
      el.style.setProperty('--depth', (0.4 + 0.6 * Math.max(0, point.z)).toFixed(3));
    });
  }, []);

  /**
   * Turn the static hemisphere. Without WebGL the land is an SVG path, so the
   * path itself has to be re-derived or the markers would walk across a frozen
   * Earth. Discrete steps only: rebuilding a ~27 KB path per frame is why
   * pointer-drag stays off in this mode.
   */
  const applyStatic = useCallback((spin: number, tilt: number) => {
    const pose = poseRef.current;
    pose.spin = spin;
    pose.tilt = clampTilt(tilt);
    pose.targetSpin = null;
    pose.targetTilt = null;
    setPosterPose({ spin: pose.spin, tilt: pose.tilt });
    placeMarkers(pose.spin, pose.tilt);
  }, [placeMarkers]);

  useEffect(() => { flagsRef.current.paused = paused; scheduleRef.current?.(); }, [paused]);
  useEffect(() => { flagsRef.current.online = online; scheduleRef.current?.(); }, [online]);

  useEffect(() => { placeMarkers(POSTER_SPIN, POSTER_TILT); }, [placeMarkers]);

  /** A drag in progress must not outlive the component. */
  useEffect(() => () => dragRef.current?.abort(), []);

  /** Selecting a guardian turns the globe to face them. */
  useEffect(() => {
    flagsRef.current.selected = selected;
    const pose = poseRef.current;

    if (selected < 0) {
      pose.targetSpin = null;
      pose.targetTilt = null;
      scheduleRef.current?.();
      return;
    }

    const place = GUARDIANS[selected];
    const spin = pose.spin + shortestDelta(pose.spin, spinToFace(place.lon));
    // Lean the pole so the chosen latitude sits near the middle of the face.
    const tilt = clampTilt(place.lat);

    if (!live) {
      applyStatic(spin, tilt);
      return;
    }
    pose.targetSpin = spin;
    pose.targetTilt = tilt;
    scheduleRef.current?.();
  }, [selected, live, applyStatic]);

  useEffect(() => {
    const stage = stageRef.current;
    const canvas = canvasRef.current;
    if (!stage || !canvas) return;

    let disposed = false;
    let teardown: (() => void) | undefined;
    const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

    // three.js is ~184 KB gzipped, so it waits until the globe is near view.
    const gate = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) return;
      gate.disconnect();
      void start();
    }, { rootMargin: '240px' });
    gate.observe(stage);

    async function start() {
      // The poster is the design where WebGL is missing, not an error state.
      if (!webglAvailable()) return;

      let THREE: typeof import('three');
      try {
        THREE = await import('three');
      } catch {
        return; // Keep the server-rendered poster.
      }
      if (disposed) return;

      let renderer: import('three').WebGLRenderer;
      try {
        renderer = new THREE.WebGLRenderer({ canvas: canvas!, antialias: true, alpha: true, powerPreference: 'low-power' });
      } catch {
        return;
      }
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
      renderer.setClearColor(0x000000, 0);

      const scene = new THREE.Scene();
      // Orthographic, so screen position is a pure function of the unit vector
      // and the DOM markers land exactly where WebGL draws.
      const camera = new THREE.OrthographicCamera(-VIEW_HALF, VIEW_HALF, VIEW_HALF, -VIEW_HALF, 0.01, 100);
      camera.position.set(0, 0, 10);

      // Two nested groups keep rotation order explicit: yaw, then pitch,
      // matching projectUnit. One Euler would depend on its rotation order.
      const tiltGroup = new THREE.Group();
      const spinGroup = new THREE.Group();
      tiltGroup.add(spinGroup);
      scene.add(tiltGroup);

      const styles = getComputedStyle(stage!);
      const ink = new THREE.Color(styles.getPropertyValue('--globe-land').trim() || '#e7ecf3');
      const signal = new THREE.Color(styles.getPropertyValue('--globe-signal').trim() || '#34d399');

      // An invisible sphere just inside the dots writes depth only, so the far
      // side occludes itself without painting a body over the ground. The
      // radius sits very close to 1: under an orthographic camera a dot is only
      // hidden when its tangent ray meets the sphere, so a smaller occluder
      // leaves a band of far-side dots visible around the silhouette.
      const occluder = new THREE.Mesh(
        new THREE.SphereGeometry(0.9995, 64, 48),
        new THREE.MeshBasicMaterial({ colorWrite: false }),
      );
      spinGroup.add(occluder);

      const landGeometry = new THREE.BufferGeometry();
      landGeometry.setAttribute('position', new THREE.BufferAttribute(landDotVectors(), 3));
      // `size` is in framebuffer pixels, not world units: three.js only applies
      // size attenuation under a perspective matrix. resize() sets the real
      // value from the rendered globe.
      const landMaterial = new THREE.PointsMaterial({
        color: ink,
        size: 2.4,
        sizeAttenuation: false,
        transparent: true,
        opacity: 0.92,
      });
      spinGroup.add(new THREE.Points(landGeometry, landMaterial));

      // One arc per guardian. The arc is the alert itself, which is why it
      // stays lit with the connection dropped: carrier SMS is independent.
      const arcs = GUARDIANS.map((place, index) => {
        const points: import('three').Vector3[] = [];
        const flat = arcVectors(ORIGIN, place, 56, 0.2 + index * 0.012);
        for (let i = 0; i < flat.length; i += 3) {
          points.push(new THREE.Vector3(flat[i], flat[i + 1], flat[i + 2]));
        }
        const curve = new THREE.CatmullRomCurve3(points);
        const mesh = new THREE.Mesh(
          // Radius in world units, where the globe is 1. Thin enough to stay
          // quiet, thick enough not to fall under a pixel at mobile scale.
          new THREE.TubeGeometry(curve, 56, 0.009, 6, false),
          new THREE.MeshBasicMaterial({ color: signal, transparent: true, opacity: 0.5 }),
        );
        spinGroup.add(mesh);

        // The travelling dot is the tracker link, so it is what stops when the
        // simulated internet goes away.
        const packet = new THREE.Mesh(
          new THREE.SphereGeometry(0.014, 10, 10),
          new THREE.MeshBasicMaterial({ color: signal }),
        );
        packet.visible = false;
        spinGroup.add(packet);
        return { curve, material: mesh.material as import('three').MeshBasicMaterial, packet };
      });

      const originDot = new THREE.Mesh(
        new THREE.SphereGeometry(0.02, 14, 14),
        new THREE.MeshBasicMaterial({ color: ink }),
      );
      originDot.position.set(...placeVector(ORIGIN));
      spinGroup.add(originDot);

      let raf = 0;
      let last = 0;
      let clock = 0;
      let inView = true;
      let visible = !document.hidden;
      let reduced = motionQuery.matches;
      let contextLost = false;
      let pagePaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';

      function schedule() {
        if (!disposed && !contextLost && !raf && inView && visible) raf = requestAnimationFrame(draw);
      }

      function draw(now: number) {
        raf = 0;
        if (disposed || contextLost || !inView || !visible) return;

        const pose = poseRef.current;
        const flags = flagsRef.current;
        const delta = Math.min((now - (last || now)) / 1000, 0.05);
        last = now;

        const easing = pose.targetSpin !== null;
        const settled = !pagePaused && !flags.paused;
        const drifting = settled && !reduced && !flags.dragging && !easing;

        // Packets keep their cadence through a turn or a drag. Only an explicit
        // pause or reduced motion stops them.
        if (settled && !reduced) clock += delta;

        if (easing) {
          const spinGap = pose.targetSpin! - pose.spin;
          const tiltGap = (pose.targetTilt ?? pose.tilt) - pose.tilt;
          // Exponential ease out, except under reduced motion, which gets the
          // same framing without the travel.
          const step = reduced ? 1 : 1 - Math.exp(-delta * 7);
          pose.spin += spinGap * step;
          pose.tilt += tiltGap * step;
          if (reduced || (Math.abs(spinGap) < 0.05 && Math.abs(tiltGap) < 0.05)) {
            pose.spin = pose.targetSpin!;
            pose.tilt = pose.targetTilt ?? pose.tilt;
            pose.targetSpin = null;
            pose.targetTilt = null;
          }
        } else if (drifting) {
          pose.spin -= DRIFT_RATE * delta;
        }

        spinGroup.rotation.y = (pose.spin * Math.PI) / 180;
        tiltGroup.rotation.x = (pose.tilt * Math.PI) / 180;

        arcs.forEach((arc, index) => {
          const isSelected = flags.selected === index;
          const dimmed = flags.selected >= 0 && !isSelected;
          arc.material.opacity = isSelected ? 0.95 : dimmed ? 0.18 : 0.5;
          // Offline: the arc stays, the tracker packet stops.
          arc.packet.visible = flags.online && !reduced && !dimmed;
          if (arc.packet.visible) {
            arc.packet.position.copy(arc.curve.getPoint((clock * 0.26 + index / GUARDIANS.length) % 1));
          }
        });

        placeMarkers(pose.spin, pose.tilt);
        renderer.render(scene, camera);

        if (drifting || easing || (settled && !reduced && flags.online)) schedule();
      }
      scheduleRef.current = schedule;

      function resize() {
        const bounds = stage!.getBoundingClientRect();
        if (bounds.width <= 0 || bounds.height <= 0) return;
        const size = Math.min(bounds.width, bounds.height);
        // `false`: CSS owns the canvas box, three.js must not write inline size.
        renderer.setSize(size, size, false);
        // Dot size scales with the rendered sphere, so the matrix neither
        // coarsens on a phone nor thins out at hero scale. three.js already
        // multiplies this by the renderer's pixel ratio, so doing it here too
        // would overshoot on a high-density screen.
        const diameter = size / VIEW_HALF;
        landMaterial.size = Math.min(3, Math.max(1.35, diameter * 0.0062));
        schedule();
      }

      function onVisibility() {
        visible = !document.hidden;
        last = 0;
        if (visible) schedule();
        else { cancelAnimationFrame(raf); raf = 0; }
      }
      function onReduced() { reduced = motionQuery.matches; last = 0; schedule(); }
      function onPageMotion(event: Event) {
        pagePaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail?.paused);
        last = 0;
        schedule();
      }
      function onLost(event: Event) {
        event.preventDefault();
        contextLost = true;
        cancelAnimationFrame(raf);
        raf = 0;
        // Hand the static hemisphere the orientation the scene had, so the
        // fallback appears where the globe was rather than snapping to rest.
        const pose = poseRef.current;
        setPosterPose({ spin: pose.spin, tilt: pose.tilt });
        setLive(false);
      }

      const sizing = new ResizeObserver(resize);
      sizing.observe(stage!);
      const inner = new IntersectionObserver(([entry]) => {
        inView = entry.isIntersecting;
        last = 0;
        if (inView) schedule();
        else { cancelAnimationFrame(raf); raf = 0; }
      });
      inner.observe(stage!);
      document.addEventListener('visibilitychange', onVisibility);
      document.addEventListener('shakti:motion', onPageMotion);
      motionQuery.addEventListener('change', onReduced);
      canvas!.addEventListener('webglcontextlost', onLost);

      teardown = () => {
        cancelAnimationFrame(raf);
        scheduleRef.current = null;
        sizing.disconnect();
        inner.disconnect();
        document.removeEventListener('visibilitychange', onVisibility);
        document.removeEventListener('shakti:motion', onPageMotion);
        motionQuery.removeEventListener('change', onReduced);
        canvas!.removeEventListener('webglcontextlost', onLost);

        const geometries = new Set<import('three').BufferGeometry>();
        const materials = new Set<import('three').Material>();
        scene.traverse((object) => {
          const mesh = object as import('three').Mesh;
          if (mesh.geometry) geometries.add(mesh.geometry);
          if (mesh.material) {
            (Array.isArray(mesh.material) ? mesh.material : [mesh.material]).forEach((m) => materials.add(m));
          }
        });
        geometries.forEach((geometry) => geometry.dispose());
        materials.forEach((material) => material.dispose());
        // Releases the GL context itself, so a StrictMode remount builds on a
        // fresh one instead of the context this renderer just disposed.
        renderer.forceContextLoss();
        renderer.dispose();
      };

      resize();
      setLive(true);
      schedule();
    }

    return () => {
      disposed = true;
      gate.disconnect();
      teardown?.();
    };
  }, [placeMarkers]);

  /**
   * Yaw only. Pitch is reachable through the guardian chips, which every input
   * class can use, so the pointer is not given a capability the keyboard lacks.
   */
  const nudge = useCallback((degrees: number) => {
    const pose = poseRef.current;
    if (!live) {
      applyStatic(pose.spin + degrees, pose.tilt);
      return;
    }
    pose.targetSpin = null;
    pose.targetTilt = null;
    pose.spin += degrees;
    scheduleRef.current?.();
  }, [live, applyStatic]);

  const onPointerDown = useCallback((event: React.PointerEvent<HTMLDivElement>) => {
    // Dragging the static hemisphere would rebuild its whole path per frame.
    if (!live) return;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    const stage = stageRef.current;
    if (!stage) return;
    const bounds = stage.getBoundingClientRect();
    // Degrees per pixel, so one drag across the stage is about half a turn.
    const rate = 180 / Math.max(240, bounds.width);
    const pointerId = event.pointerId;
    let lastX = event.clientX;

    // One drag at a time, and every listener dies with this controller.
    dragRef.current?.abort();
    const drag = new AbortController();
    dragRef.current = drag;
    flagsRef.current.dragging = true;
    stage.dataset.dragging = 'true';
    // Capture keeps the events coming while the pointer is outside the stage.
    // It is an optimisation, not the guarantee: the listeners below sit on
    // window, so a release off-element still ends the drag even where capture
    // is refused. Without that, dragging would stick and drift never resume.
    try { stage.setPointerCapture(pointerId); } catch { /* not essential */ }

    function move(moveEvent: PointerEvent) {
      if (moveEvent.pointerId !== pointerId) return;
      nudge((moveEvent.clientX - lastX) * rate);
      lastX = moveEvent.clientX;
    }
    function release(upEvent: PointerEvent) {
      if (upEvent.pointerId !== pointerId) return;
      flagsRef.current.dragging = false;
      stage!.dataset.dragging = 'false';
      drag.abort();
      if (dragRef.current === drag) dragRef.current = null;
      scheduleRef.current?.();
    }

    const options = { signal: drag.signal };
    window.addEventListener('pointermove', move, options);
    window.addEventListener('pointerup', release, options);
    window.addEventListener('pointercancel', release, options);
  }, [live, nudge]);

  const current = selected >= 0 ? GUARDIANS[selected] : null;

  return (
    <figure className="globe">
      <div
        ref={stageRef}
        className="globe-stage"
        data-live={live ? 'true' : 'false'}
        onPointerDown={onPointerDown}
      >
        <span className="globe-limb" style={{ inset: `${LIMB_INSET}%` }} aria-hidden="true" />

        {/* The first paint, and the design where WebGL is unavailable. It turns
            with the arrows and the chips; CSS hides it once the scene is live. */}
        <svg className="globe-poster" viewBox="0 0 100 100" aria-hidden="true">
          <path
            d={posterDots}
            stroke="var(--globe-land)"
            strokeWidth={POSTER_DOT}
            strokeLinecap="round"
            fill="none"
            opacity="0.92"
          />
        </svg>

        <canvas ref={canvasRef} className="globe-canvas" aria-hidden="true" />

        <span ref={originRef} className="globe-origin" aria-hidden="true">
          <span className="globe-origin-ring" />
          <b>{ORIGIN.city}</b>
        </span>

        {GUARDIANS.map((place, index) => (
          <span
            key={place.id}
            ref={(node) => { markersRef.current[index] = node; }}
            className="globe-marker"
            data-selected={selected === index ? 'true' : 'false'}
            aria-hidden="true"
          >
            <i />
            <b>{place.city}</b>
          </span>
        ))}
      </div>

      <figcaption className="globe-caption">
        <p className="globe-readout" id={readoutId} aria-live="polite">
          {current
            ? <><strong>{current.relation}, {current.city}.</strong> {reachDetail(online)}</>
            : <><strong>{GUARDIANS.length} guardians, one press.</strong> {reachDetail(online)}</>}
        </p>

        {/* Directly under the claim it qualifies, so a fold can never separate
            the two. The disclaimer leads the sentence for the same reason. */}
        <p className="globe-note">
          Illustrative guardian connections: no live location, and no alert is sent from this page.
          Drag or use the arrows to turn.
        </p>

        {/* The labelled control. Markers on the sphere are too close together
            at hero scale to be tap targets of their own. */}
        <div className="globe-circle" role="group" aria-label="Your circle">
          {GUARDIANS.map((place, index) => (
            <button
              key={place.id}
              type="button"
              className="globe-chip"
              aria-pressed={selected === index}
              onClick={() => setSelected(selected === index ? -1 : index)}
            >
              {place.relation}
              {/* The city rides along for assistive tech; on screen it appears
                  on the globe's own label and in the readout once chosen, which
                  keeps the row to one line. The reach state is not repeated
                  here: it is identical for all five and the live readout
                  already announces it once. */}
              <span className="sr-only"> in {place.city}</span>
            </button>
          ))}
        </div>

        <div className="globe-controls">
          <div className="globe-nudge" role="group" aria-label="Turn the globe">
            <button type="button" aria-label="Turn the globe west" onClick={() => nudge(-NUDGE_STEP)}>
              <ArrowLeft size={15} aria-hidden="true" />
            </button>
            {/* One stable name, with aria-pressed carrying the state. A name
                that flipped to "Resume" would announce "Resume, pressed". */}
            <button
              type="button"
              aria-pressed={paused}
              aria-label="Hold the globe still"
              onClick={() => setPaused((value) => !value)}
            >
              {paused ? <Play size={14} aria-hidden="true" /> : <Pause size={14} aria-hidden="true" />}
            </button>
            <button type="button" aria-label="Turn the globe east" onClick={() => nudge(NUDGE_STEP)}>
              <ArrowRight size={15} aria-hidden="true" />
            </button>
          </div>

          {/* Named apart from the walkthrough's own connection control, so the
              two never read as the same thing. */}
          <button
            type="button"
            className="globe-link"
            aria-pressed={!online}
            onClick={() => setOnline((value) => !value)}
          >
            {online ? <Wifi size={14} aria-hidden="true" /> : <WifiOff size={14} aria-hidden="true" />}
            {online ? 'Tracker link on' : 'Tracker link queued'}
          </button>
        </div>
      </figcaption>
    </figure>
  );
}
