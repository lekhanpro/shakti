import { cameraAt, stageAt } from '@/lib/story';

/**
 * The night street behind the scroll story. Plain three.js, no React: the
 * component hands over a canvas and a progress ref, and every frame derives
 * the whole scene from that one number (see lib/story.ts). three is imported
 * here, inside a dynamic import, so it never reaches the server bundle.
 *
 * Colour follows meaning. Warm lamps are the city, amber is the cancel
 * window, rose is the alert, indigo is guardians watching, emerald is safe.
 */

export interface SceneOptions {
  canvas: HTMLCanvasElement;
  holder: HTMLElement;
  progress: { current: number };
  /** Draw one still frame at this progress and stop (reduced motion). */
  staticAt?: number;
}

const FOG = 0x0a1020;
const WALK_DISTANCE = 16;

function rng(seed: number) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const BUILDING_VS = /* glsl */ `
  varying vec3 vWorld;
  varying vec3 vN;
  void main() {
    vec4 wp = modelMatrix * instanceMatrix * vec4(position, 1.0);
    vWorld = wp.xyz;
    vN = normal;
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

// Windows are computed from world position, so any building size tiles
// correctly with no texture and no stretching.
const BUILDING_FS = /* glsl */ `
  precision highp float;
  uniform float uSafe;
  uniform float uTime;
  uniform vec3 uCam;
  uniform vec3 uFog;
  varying vec3 vWorld;
  varying vec3 vN;
  float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
  void main() {
    vec3 n = abs(vN);
    vec3 base = vec3(0.04, 0.058, 0.1) + vec3(0.02, 0.025, 0.04) * clamp(vWorld.y / 30.0, 0.0, 1.0);
    vec3 col = base;
    if (n.y < 0.5) {
      bool xFace = n.x > 0.5;
      vec2 uv = xFace ? vec2(vWorld.z, vWorld.y) : vec2(vWorld.x, vWorld.y);
      float face = xFace ? 1.0 : 2.0;
      vec2 cell = floor(uv / vec2(1.1, 1.6));
      vec2 f = fract(uv / vec2(1.1, 1.6));
      float win = step(0.2, f.x) * step(f.x, 0.8) * step(0.24, f.y) * step(f.y, 0.7);
      float h = hash(cell + face * 17.0);
      float lit = step(0.66, h);
      float tone = hash(cell + 41.0);
      vec3 warm = mix(vec3(1.0, 0.78, 0.42), vec3(1.0, 0.9, 0.7), tone);
      vec3 safeTone = vec3(0.43, 0.91, 0.72);
      warm = mix(warm, safeTone, uSafe * step(0.55, hash(cell + 9.0)));
      col += win * lit * warm * 0.85;
    }
    float d = distance(vWorld, uCam);
    col = mix(col, uFog, smoothstep(24.0, 118.0, d));
    gl_FragColor = vec4(col, 1.0);
  }
`;

const POINT_VS = /* glsl */ `
  uniform float uSize;
  uniform float uDpr;
  void main() {
    vec4 mv = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = clamp(uSize * uDpr / -mv.z, 1.0, 150.0 * uDpr);
    gl_Position = projectionMatrix * mv;
  }
`;
const POINT_FS = /* glsl */ `
  uniform vec3 uColor;
  uniform float uAlpha;
  void main() {
    float d = length(gl_PointCoord - 0.5) * 2.0;
    float a = pow(max(0.0, 1.0 - d), 2.2);
    gl_FragColor = vec4(uColor, a * uAlpha);
  }
`;

const DISC_VS = /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;
// The cancel-window ring: a faint track with an arc that closes as the
// countdown runs out.
const DISC_FS = /* glsl */ `
  varying vec2 vUv;
  uniform float uArc;
  uniform vec3 uColor;
  uniform float uAlpha;
  void main() {
    vec2 p = vUv - 0.5;
    float r = length(p) * 2.0;
    float a = atan(p.x, p.y) / 6.2831853 + 0.5;
    float ring = smoothstep(0.84, 0.87, r) * (1.0 - smoothstep(0.95, 0.98, r));
    float on = step(a, uArc);
    gl_FragColor = vec4(uColor, (ring * on + ring * 0.16) * uAlpha);
  }
`;

export async function startCityScene(opts: SceneOptions): Promise<() => void> {
  const THREE = await import('three');
  const { canvas, holder, progress, staticAt } = opts;

  let renderer: import('three').WebGLRenderer;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'high-performance' });
  } catch {
    return () => {}; // No WebGL: the CSS poster behind the canvas is the scene.
  }
  const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
  renderer.setPixelRatio(dpr);
  renderer.setClearColor(0x000000, 0);

  const scene = new THREE.Scene();
  scene.fog = new THREE.Fog(FOG, 30, 125);
  const camera = new THREE.PerspectiveCamera(46, 1, 0.1, 300);

  const disposables: { dispose(): void }[] = [];
  const own = <T extends { dispose(): void }>(d: T): T => {
    disposables.push(d);
    return d;
  };

  const uniforms = {
    uTime: { value: 0 },
    uSafe: { value: 0 },
    uCam: { value: new THREE.Vector3() },
    uFog: { value: new THREE.Color(FOG) },
    uDpr: { value: dpr },
  };

  // Buildings -----------------------------------------------------------
  const rand = rng(7);
  const spots: { x: number; z: number; w: number; h: number; d: number }[] = [];
  for (const side of [-1, 1]) {
    let z = 16;
    while (z > -150) {
      const w = 4 + rand() * 3.5;
      const d = 4 + rand() * 3.5;
      const h = 7 + rand() * rand() * 30 + (rand() < 0.15 ? 10 : 0);
      spots.push({ x: side * (6.3 + w / 2 + rand() * 0.8), z: z - d / 2, w, h, d });
      z -= d + 0.4 + rand() * 1.2;
    }
  }
  const boxGeo = own(new THREE.BoxGeometry(1, 1, 1));
  boxGeo.translate(0, 0.5, 0);
  const buildingMat = own(
    new THREE.ShaderMaterial({ uniforms, vertexShader: BUILDING_VS, fragmentShader: BUILDING_FS }),
  );
  const buildings = new THREE.InstancedMesh(boxGeo, buildingMat, spots.length);
  const m = new THREE.Matrix4();
  const q = new THREE.Quaternion();
  spots.forEach((s, i) => {
    m.compose(new THREE.Vector3(s.x, 0, s.z), q, new THREE.Vector3(s.w, s.h, s.d));
    buildings.setMatrixAt(i, m);
  });
  buildings.frustumCulled = false;
  scene.add(buildings);

  // Street -----------------------------------------------------------------
  const ground = new THREE.Mesh(
    own(new THREE.PlaneGeometry(40, 260)),
    own(new THREE.MeshBasicMaterial({ color: 0x090e1b })),
  );
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(0, 0, -110);
  scene.add(ground);

  const dashMat = own(new THREE.MeshBasicMaterial({ color: 0x2b3756 }));
  const dashes = new THREE.InstancedMesh(own(new THREE.BoxGeometry(0.14, 0.02, 1.6)), dashMat, 60);
  for (let i = 0; i < 60; i++) dashes.setMatrixAt(i, m.makeTranslation(0, 0.012, 14 - i * 4));
  scene.add(dashes);

  const curbGeo = own(new THREE.BoxGeometry(0.1, 0.03, 260));
  const curbMat = own(new THREE.MeshBasicMaterial({ color: 0x1c2644 }));
  for (const x of [-5.7, 5.7]) {
    const curb = new THREE.Mesh(curbGeo, curbMat);
    curb.position.set(x, 0.015, -110);
    scene.add(curb);
  }

  // Lamps ---------------------------------------------------------------------
  const LAMPS = 14;
  const poleGeo = own(new THREE.CylinderGeometry(0.04, 0.05, 4.4, 6));
  poleGeo.translate(0, 2.2, 0);
  const poles = new THREE.InstancedMesh(poleGeo, own(new THREE.MeshBasicMaterial({ color: 0x1a2238 })), LAMPS * 2);
  const lampPos = new Float32Array(LAMPS * 2 * 3);
  for (let i = 0; i < LAMPS; i++) {
    [-1, 1].forEach((side, k) => {
      const z = 12 - i * 11;
      const idx = i * 2 + k;
      poles.setMatrixAt(idx, m.makeTranslation(side * 5.0, 0, z));
      lampPos.set([side * 4.5, 4.5, z], idx * 3);
    });
  }
  scene.add(poles);

  const makePoints = (pos: Float32Array, size: number, color: import('three').Color, alpha: number) => {
    const geo = own(new THREE.BufferGeometry());
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    const mat = own(
      new THREE.ShaderMaterial({
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        uniforms: { uDpr: uniforms.uDpr, uSize: { value: size }, uColor: { value: color }, uAlpha: { value: alpha } },
        vertexShader: POINT_VS,
        fragmentShader: POINT_FS,
      }),
    );
    const pts = new THREE.Points(geo, mat);
    pts.frustumCulled = false;
    scene.add(pts);
    return { pts, geo, mat };
  };

  const WARM = new THREE.Color(1, 0.78, 0.42);
  const SAFE_LAMP = new THREE.Color(0.43, 0.91, 0.72);
  const lamps = makePoints(lampPos, 260, new THREE.Color().copy(WARM), 0.85);

  // Walker -------------------------------------------------------------------------
  const IDLE = new THREE.Color(0xa5b4fc);
  const AMBER = new THREE.Color(0xf59e0b);
  const ROSE = new THREE.Color(0xfb7185);
  const INDIGO = new THREE.Color(0xa5b4fc);
  const EMERALD = new THREE.Color(0x6ee7b7);
  const accent = new THREE.Color();

  const walker = new THREE.Group();
  const figure = new THREE.Group();
  walker.add(figure);
  const bodyMat = own(new THREE.MeshBasicMaterial({ color: 0xcfd8e8 }));
  const headMat = own(new THREE.MeshBasicMaterial({ color: 0xe6ecf5 }));
  const phoneMat = own(new THREE.MeshBasicMaterial({ color: 0xfcd34d }));
  const body = new THREE.Mesh(own(new THREE.CapsuleGeometry(0.23, 0.95, 6, 14)), bodyMat);
  body.position.y = 0.95;
  const head = new THREE.Mesh(own(new THREE.SphereGeometry(0.17, 20, 16)), headMat);
  head.position.y = 1.86;
  const phone = new THREE.Mesh(own(new THREE.BoxGeometry(0.09, 0.16, 0.012)), phoneMat);
  phone.position.set(0.27, 1.15, -0.14);
  figure.add(body, head, phone);
  scene.add(walker);

  const aura = makePoints(new Float32Array([0, 1.15, 0]), 520, new THREE.Color(), 0.5);
  aura.pts.position.set(0, 0, 0);

  const discMat = own(
    new THREE.ShaderMaterial({
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      uniforms: { uArc: { value: 0 }, uColor: { value: new THREE.Color() }, uAlpha: { value: 0 } },
      vertexShader: DISC_VS,
      fragmentShader: DISC_FS,
    }),
  );
  const disc = new THREE.Mesh(own(new THREE.PlaneGeometry(3.4, 3.4)), discMat);
  disc.rotation.x = -Math.PI / 2;
  disc.position.y = 0.04;
  scene.add(disc);

  const ringGeo = own(new THREE.RingGeometry(0.9, 1.0, 72));
  const rings = [0, 1, 2].map((i) => {
    const mat = own(
      new THREE.MeshBasicMaterial({
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide,
        opacity: 0,
      }),
    );
    const mesh = new THREE.Mesh(ringGeo, mat);
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.y = 0.05;
    scene.add(mesh);
    return { mesh, mat, phase: i / 3 };
  });

  const beaconMat = own(
    new THREE.MeshBasicMaterial({
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide,
      opacity: 0,
    }),
  );
  const beacon = new THREE.Mesh(own(new THREE.CylinderGeometry(0.05, 0.4, 30, 20, 1, true)), beaconMat);
  beacon.scale.y = 0.001;
  scene.add(beacon);

  // Breadcrumbs: the trail the guardians follow, one dot per few steps.
  const CRUMBS = 21;
  const crumbPos = new Float32Array(CRUMBS * 3);
  for (let i = 0; i < CRUMBS; i++) crumbPos.set([0, 0.07, -i * (WALK_DISTANCE / (CRUMBS - 1))], i * 3);
  const crumbs = makePoints(crumbPos, 70, new THREE.Color(), 0);

  // Guardians: floating pins around her, joined to her by arcs once she is live.
  const GUARDIANS: [number, number, number][] = [
    [-5, 7, -7],
    [5.5, 9.5, -19],
    [-6.2, 11, -29],
    [4.6, 6, -3],
    [0.5, 13.5, -26],
  ];
  const ARC_POINTS = 49;
  const start = new THREE.Vector3(0, 1.6, -WALK_DISTANCE);
  const guardianPinGeo = own(new THREE.SphereGeometry(0.24, 16, 12));
  const arcs = GUARDIANS.map((g) => {
    const end = new THREE.Vector3(...g);
    const mid = start.clone().add(end).multiplyScalar(0.5);
    mid.y += 5;
    const curve = new THREE.QuadraticBezierCurve3(start, mid, end);
    const geo = own(new THREE.BufferGeometry().setFromPoints(curve.getPoints(ARC_POINTS - 1)));
    geo.setDrawRange(0, 0);
    const mat = own(new THREE.LineBasicMaterial({ color: 0xa5b4fc, transparent: true, opacity: 0 }));
    const line = new THREE.Line(geo, mat);
    scene.add(line);
    const pinMat = own(new THREE.MeshBasicMaterial({ color: 0xa5b4fc, transparent: true, opacity: 0.12 }));
    const pin = new THREE.Mesh(guardianPinGeo, pinMat);
    pin.position.copy(end);
    scene.add(pin);
    return { geo, mat, pin, pinMat };
  });

  // Frame --------------------------------------------------------------------------------
  const camPos = new THREE.Vector3();
  const camLook = new THREE.Vector3();
  const wantPos = new THREE.Vector3();
  const wantLook = new THREE.Vector3();
  const ptr = { x: 0, y: 0, sx: 0, sy: 0 };
  let snap = true;

  const frame = (p: number, t: number, dt: number) => {
    const s = stageAt(p);
    uniforms.uTime.value = t;
    uniforms.uSafe.value = s.safe;

    const wz = -s.walk * WALK_DISTANCE;
    walker.position.set(0, 0, wz);
    const moving = s.walk > 0.001 && s.walk < 0.999 ? 1 : 0;
    figure.position.y = Math.sin(t * 7) * 0.025 * moving;

    accent.copy(IDLE).lerp(AMBER, s.countdown).lerp(ROSE, s.sos).lerp(INDIGO, s.live).lerp(EMERALD, s.safe);
    phoneMat.color.copy(accent);
    aura.mat.uniforms.uColor.value.copy(accent);
    aura.pts.position.z = wz;

    lamps.mat.uniforms.uColor.value.lerpColors(WARM, SAFE_LAMP, s.safe * 0.7);

    discMat.uniforms.uArc.value = s.countdown;
    discMat.uniforms.uAlpha.value = s.countdown > 0 ? 1 - s.sos : 0;
    discMat.uniforms.uColor.value.copy(AMBER);
    disc.position.z = wz;

    for (const r of rings) {
      const k = (t * 0.45 + r.phase) % 1;
      const sc = 1 + k * 7;
      r.mesh.scale.set(sc, sc, 1);
      r.mesh.position.z = wz;
      r.mat.opacity = (1 - k) * 0.75 * s.sos * (1 - 0.6 * s.safe);
      r.mat.color.copy(ROSE).lerp(EMERALD, s.safe);
    }
    const bs = Math.max(0.001, s.sos);
    beacon.scale.y = bs;
    beacon.position.set(0, 15 * bs, wz);
    beaconMat.opacity = 0.2 * s.sos * (1 - s.safe);
    beaconMat.color.copy(ROSE);

    crumbs.mat.uniforms.uColor.value.copy(accent);
    crumbs.mat.uniforms.uAlpha.value = 0.9 * s.sos;
    crumbs.geo.setDrawRange(0, Math.max(0, Math.floor(s.walk * CRUMBS)));

    arcs.forEach((a, i) => {
      const reach = Math.min(1, Math.max(0, s.live * 1.4 - i * 0.07));
      a.geo.setDrawRange(0, Math.floor(reach * ARC_POINTS));
      a.mat.opacity = 0.7 * reach * (1 - 0.25 * s.safe);
      a.mat.color.copy(INDIGO).lerp(EMERALD, s.safe);
      a.pinMat.opacity = 0.12 + 0.88 * reach;
      a.pinMat.color.copy(INDIGO).lerp(EMERALD, s.safe);
      a.pin.scale.setScalar(0.7 + 0.3 * reach + 0.08 * Math.sin(t * 2.2 + i) * reach);
    });

    const c = cameraAt(p);
    ptr.sx += (ptr.x - ptr.sx) * Math.min(1, dt * 4);
    ptr.sy += (ptr.y - ptr.sy) * Math.min(1, dt * 4);
    wantPos.set(c.offset[0] + ptr.sx * 0.35, c.offset[1] + ptr.sy * 0.15, wz + c.offset[2]);
    wantLook.set(c.look[0], c.look[1], wz + c.look[2]);
    const k = snap ? 1 : 1 - Math.exp(-dt * 6);
    snap = false;
    camPos.lerp(wantPos, k);
    camLook.lerp(wantLook, k);
    camera.position.copy(camPos);
    camera.lookAt(camLook);
    uniforms.uCam.value.copy(camPos);

    renderer.render(scene, camera);
  };

  const resize = () => {
    const w = holder.clientWidth || 1;
    const h = holder.clientHeight || 1;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    // Park the street in the part of the screen the copy is not using:
    // right of centre on wide screens, above the copy on narrow ones.
    const wide = w >= 1024;
    camera.setViewOffset(w, h, wide ? -w * 0.17 : 0, wide ? 0 : h * 0.14, w, h);
    camera.updateProjectionMatrix();
    if (staticAt !== undefined) {
      snap = true;
      frame(staticAt, 1.2, 1);
    }
  };
  const ro = new ResizeObserver(resize);
  ro.observe(holder);
  resize();

  const onPointer = (e: PointerEvent) => {
    ptr.x = (e.clientX / window.innerWidth) * 2 - 1;
    ptr.y = -((e.clientY / window.innerHeight) * 2 - 1);
  };

  if (staticAt !== undefined) {
    return () => {
      ro.disconnect();
      disposables.forEach((d) => d.dispose());
      renderer.dispose();
    };
  }

  window.addEventListener('pointermove', onPointer, { passive: true });
  let raf = 0;
  let last = performance.now();
  let inView = true;
  let visible = !document.hidden;
  const io = new IntersectionObserver((es) => {
    inView = es.some((e) => e.isIntersecting);
  });
  io.observe(holder);
  const onVisibility = () => {
    visible = !document.hidden;
  };
  document.addEventListener('visibilitychange', onVisibility);

  const loop = (now: number) => {
    raf = requestAnimationFrame(loop);
    if (!inView || !visible) {
      last = now;
      return;
    }
    const dt = Math.min((now - last) / 1000, 0.05);
    last = now;
    frame(progress.current, now / 1000, dt);
  };
  raf = requestAnimationFrame(loop);

  return () => {
    cancelAnimationFrame(raf);
    ro.disconnect();
    io.disconnect();
    document.removeEventListener('visibilitychange', onVisibility);
    window.removeEventListener('pointermove', onPointer);
    disposables.forEach((d) => d.dispose());
    renderer.dispose();
  };
}
