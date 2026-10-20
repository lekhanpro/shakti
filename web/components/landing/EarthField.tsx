'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Pause, Play } from 'lucide-react';

type LatLng = { lat: number; lon: number };
type XY = [number, number];

const LAND = '#627a5b';
const LAND_LIGHT = '#8ea26d';

// Approximate silhouettes are deliberately authored for the hero texture, not
// presented as cartographic data. The globe stays recognizable at hero scale.
const CONTINENTS: XY[][] = [
  [
    [-168, 71], [-153, 70], [-139, 60], [-130, 56], [-125, 49], [-122, 42], [-114, 32], [-106, 30], [-98, 25], [-90, 24], [-83, 29], [-77, 39], [-67, 45], [-60, 53], [-66, 60], [-84, 61], [-98, 65], [-115, 70], [-135, 73],
  ],
  [[-82, 12], [-70, 7], [-63, -5], [-58, -18], [-63, -34], [-70, -54], [-78, -48], [-83, -30], [-78, -12], [-86, 2]],
  [[-56, 82], [-28, 82], [-20, 70], [-38, 60], [-52, 65]],
  [[-17, 36], [8, 37], [28, 31], [41, 12], [32, -4], [23, -30], [9, -35], [-4, -20], [-12, 2], [-25, 16]],
  [[-10, 36], [8, 43], [23, 48], [39, 54], [56, 56], [78, 69], [105, 73], [136, 57], [159, 63], [174, 51], [161, 35], [139, 29], [121, 14], [102, 7], [87, 21], [70, 18], [56, 27], [41, 23], [29, 35], [10, 34]],
  [[113, -12], [133, -10], [153, -21], [149, -37], [128, -39], [113, -27]],
  [[42, 30], [50, 28], [54, 18], [47, 11], [40, 17]],
  [[-180, -61], [-130, -65], [-80, -63], [-20, -66], [32, -64], [90, -67], [150, -64], [180, -61], [180, -90], [-180, -90]],
];

const LOCATIONS: { label: string; point: LatLng; color: string }[] = [
  { label: 'you / Bengaluru', point: { lat: 12.97, lon: 77.59 }, color: '#d8ff45' },
  { label: 'guardian / Mumbai', point: { lat: 19.08, lon: 72.88 }, color: '#a49dff' },
  { label: 'guardian / Delhi', point: { lat: 28.61, lon: 77.21 }, color: '#a49dff' },
  { label: 'guardian / Singapore', point: { lat: 1.35, lon: 103.82 }, color: '#a49dff' },
];

function createMapTexture(documentRef: Document) {
  const map = documentRef.createElement('canvas');
  map.width = 1536;
  map.height = 768;
  const ctx = map.getContext('2d');
  if (!ctx) return map;

  const ocean = ctx.createLinearGradient(0, 0, 0, map.height);
  ocean.addColorStop(0, '#07142f');
  ocean.addColorStop(0.48, '#0d2d54');
  ocean.addColorStop(1, '#06142e');
  ctx.fillStyle = ocean;
  ctx.fillRect(0, 0, map.width, map.height);

  const project = ([lon, lat]: XY): [number, number] => [((lon + 180) / 360) * map.width, ((90 - lat) / 180) * map.height];
  CONTINENTS.forEach((continent, index) => {
    ctx.beginPath();
    continent.forEach((point, pointIndex) => {
      const [x, y] = project(point);
      if (pointIndex === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.closePath();
    ctx.fillStyle = index % 3 === 0 ? LAND_LIGHT : LAND;
    ctx.globalAlpha = 0.88;
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.strokeStyle = 'rgba(216,255,69,0.18)';
    ctx.lineWidth = 2;
    ctx.stroke();
  });

  // Soft latitude lighting gives the texture a hand-finished atlas feel.
  const glow = ctx.createLinearGradient(0, 0, map.width, map.height);
  glow.addColorStop(0, 'rgba(164,157,255,0.1)');
  glow.addColorStop(0.45, 'rgba(255,255,255,0)');
  glow.addColorStop(1, 'rgba(216,255,69,0.08)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, map.width, map.height);
  return map;
}

function createCloudTexture(documentRef: Document) {
  const cloud = documentRef.createElement('canvas');
  cloud.width = 1024;
  cloud.height = 512;
  const ctx = cloud.getContext('2d');
  if (!ctx) return cloud;
  for (let i = 0; i < 70; i += 1) {
    const x = Math.random() * cloud.width;
    const y = 70 + Math.random() * 340;
    const w = 24 + Math.random() * 120;
    const h = 2 + Math.random() * 8;
    const cloudGradient = ctx.createRadialGradient(x, y, 0, x, y, w);
    cloudGradient.addColorStop(0, 'rgba(240,245,255,0.2)');
    cloudGradient.addColorStop(1, 'rgba(240,245,255,0)');
    ctx.fillStyle = cloudGradient;
    ctx.beginPath();
    ctx.ellipse(x, y, w, h, Math.random() * 0.35, 0, Math.PI * 2);
    ctx.fill();
  }
  return cloud;
}

function latLngToVector(lat: number, lon: number, radius: number, THREE: typeof import('three')) {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lon + 180) * (Math.PI / 180);
  return new THREE.Vector3(-radius * Math.sin(phi) * Math.cos(theta), radius * Math.cos(phi), radius * Math.sin(phi) * Math.sin(theta));
}

export function EarthField() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rootRef = useRef<HTMLDivElement>(null);
  const scheduleRef = useRef<(() => void) | null>(null);
  const settings = useRef({ paused: false, angle: 0 });
  const [paused, setPaused] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => { settings.current.paused = paused; scheduleRef.current?.(); }, [paused]);

  useEffect(() => {
    const canvas = canvasRef.current;
    const root = rootRef.current;
    if (!canvas || !root) return;
    let disposed = false;
    let cleanup: (() => void) | undefined;
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');

    void import('three').then((THREE) => {
      if (disposed) return;
      const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'low-power' });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
      renderer.setClearColor(0x000000, 0);
      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(36, 1, 0.1, 30);
      camera.position.set(0, 0.08, 5.5);
      const globe = new THREE.Group();
      scene.add(globe);
      const textures = new Set<import('three').Texture>();
      const fallback = new THREE.CanvasTexture(createMapTexture(document));
      fallback.colorSpace = THREE.SRGBColorSpace;
      textures.add(fallback);
      const earthMaterial = new THREE.MeshPhongMaterial({ map: fallback, shininess: 16, specular: new THREE.Color('#9ab1c4') });
      const earth = new THREE.Mesh(new THREE.SphereGeometry(1.15, 80, 64), earthMaterial);
      globe.add(earth);
      const sunDirection = new THREE.Vector3(-3, 1.8, 4).normalize();
      const sun = new THREE.DirectionalLight('#fff1dc', 2.2);
      sun.position.copy(sunDirection).multiplyScalar(5);
      scene.add(sun, new THREE.AmbientLight('#42547a', 0.5));

      const cloudTexture = new THREE.CanvasTexture(createCloudTexture(document));
      textures.add(cloudTexture);
      const cloudMaterial = new THREE.MeshPhongMaterial({ map: cloudTexture, transparent: true, opacity: 0.6, depthWrite: false });
      const clouds = new THREE.Mesh(new THREE.SphereGeometry(1.164, 64, 48), cloudMaterial);
      globe.add(clouds);

      const nightMaterial = new THREE.ShaderMaterial({
        transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
        uniforms: { nightMap: { value: fallback }, sunDirection: { value: sunDirection }, enabled: { value: 0 } },
        vertexShader: 'varying vec2 vUv; varying vec3 vNormal; void main(){vUv=uv;vNormal=normalize(mat3(modelMatrix)*normal);gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',
        fragmentShader: 'uniform sampler2D nightMap; uniform vec3 sunDirection; uniform float enabled; varying vec2 vUv; varying vec3 vNormal; void main(){float dark=1.0-smoothstep(-0.18,0.15,dot(normalize(vNormal),sunDirection));vec3 lights=texture2D(nightMap,vUv).rgb;gl_FragColor=vec4(lights*dark*enabled, dark*enabled*0.85);}',
      });
      globe.add(new THREE.Mesh(new THREE.SphereGeometry(1.153, 64, 48), nightMaterial));
      const atmosphere = new THREE.Mesh(new THREE.SphereGeometry(1.205, 64, 48), new THREE.ShaderMaterial({
        transparent: true, side: THREE.BackSide, depthWrite: false, blending: THREE.AdditiveBlending,
        vertexShader: 'varying vec3 vNormal; varying vec3 vWorld; void main(){vNormal=normalize(mat3(modelMatrix)*normal);vec4 world=modelMatrix*vec4(position,1.0);vWorld=world.xyz;gl_Position=projectionMatrix*viewMatrix*world;}',
        fragmentShader: 'varying vec3 vNormal; varying vec3 vWorld; void main(){float rim=pow(max(0.0,1.0-abs(dot(normalize(vNormal),normalize(cameraPosition-vWorld)))),2.8);gl_FragColor=vec4(vec3(0.28,0.48,0.95),rim*0.65);}',
      }));
      globe.add(atmosphere);

      const packets: { point: import('three').Mesh; curve: import('three').QuadraticBezierCurve3 }[] = [];
      const source = latLngToVector(LOCATIONS[0].point.lat, LOCATIONS[0].point.lon, 1.18, THREE);
      LOCATIONS.forEach((location, index) => {
        const position = latLngToVector(location.point.lat, location.point.lon, 1.18, THREE);
        const point = new THREE.Mesh(new THREE.SphereGeometry(index ? 0.018 : 0.029, 12, 12), new THREE.MeshBasicMaterial({ color: index ? '#b7a8ee' : '#c0ecdb' }));
        point.position.copy(position);
        globe.add(point);
        if (!index) return;
        const curve = new THREE.QuadraticBezierCurve3(source, source.clone().lerp(position, 0.5).normalize().multiplyScalar(1.38 + index * 0.04), position);
        globe.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(curve.getPoints(64)), new THREE.LineBasicMaterial({ color: '#c0ecdb', transparent: true, opacity: 0.8 })));
        const packet = new THREE.Mesh(new THREE.SphereGeometry(0.014, 8, 8), new THREE.MeshBasicMaterial({ color: '#f4fff8' }));
        globe.add(packet);
        packets.push({ point: packet, curve });
      });
      const orbit = new THREE.Mesh(new THREE.TorusGeometry(1.53, 0.004, 6, 128), new THREE.MeshBasicMaterial({ color: '#b7a8ee', transparent: true, opacity: 0.35 }));
      orbit.rotation.set(1.1, 0.1, -0.3);
      scene.add(orbit);

      let raf = 0, last = 0, time = 0;
      let inView = true, visible = !document.hidden, reduced = media.matches, contextLost = false;
      let pagePaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';
      const pointer = { x: 0, y: 0 };
      function schedule() { if (!disposed && !contextLost && !raf && inView && visible) raf = requestAnimationFrame(draw); }
      function draw(now: number) {
        raf = 0;
        if (disposed || contextLost || !inView || !visible) return;
        const animate = !reduced && !pagePaused && !settings.current.paused;
        if (animate && now - last < 32) { schedule(); return; }
        if (animate) time += Math.min((now - (last || now)) / 1000, 0.08);
        last = now;
        // Keep Bengaluru on the visible hemisphere; rotations are illustrative.
        globe.rotation.set(reduced ? 0 : pointer.y * -0.07, -2.92 + settings.current.angle + Math.sin(time * 0.08) * 0.2 + (reduced ? 0 : pointer.x * 0.18), 0.07);
        clouds.rotation.y = time * 0.012;
        packets.forEach(({ point, curve }, index) => point.position.copy(curve.getPoint((time * 0.2 + index / 3) % 1)));
        renderer.render(scene, camera);
        if (animate) schedule();
      }
      scheduleRef.current = schedule;

      function resize() {
        const bounds = root!.getBoundingClientRect();
        if (bounds.width <= 0 || bounds.height <= 0) return;
        renderer.setSize(bounds.width, bounds.height, false);
        camera.aspect = bounds.width / bounds.height;
        camera.updateProjectionMatrix();
        schedule();
      }
      function onPointer(event: PointerEvent) {
        if (reduced || event.pointerType === 'touch') return;
        const bounds = root!.getBoundingClientRect();
        pointer.x = (event.clientX - bounds.left) / bounds.width - 0.5;
        pointer.y = (event.clientY - bounds.top) / bounds.height - 0.5;
        schedule();
      }
      function onLeave() { pointer.x = 0; pointer.y = 0; schedule(); }
      function onVisible() { visible = !document.hidden; last = 0; if (visible) schedule(); else { cancelAnimationFrame(raf); raf = 0; } }
      function onMotion() { reduced = media.matches; schedule(); }
      function onPageMotion(event: Event) { pagePaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused); schedule(); }
      function onLost(event: Event) { event.preventDefault(); contextLost = true; cancelAnimationFrame(raf); raf = 0; setReady(false); }
      const sizing = new ResizeObserver(resize);
      sizing.observe(root!);
      const observer = new IntersectionObserver(([entry]) => { inView = entry.isIntersecting; last = 0; if (inView) schedule(); else { cancelAnimationFrame(raf); raf = 0; } });
      observer.observe(root!);
      root!.addEventListener('pointermove', onPointer, { passive: true });
      root!.addEventListener('pointerleave', onLeave);
      document.addEventListener('visibilitychange', onVisible);
      document.addEventListener('shakti:motion', onPageMotion);
      media.addEventListener('change', onMotion);
      canvas!.addEventListener('webglcontextlost', onLost);

      cleanup = () => {
        cancelAnimationFrame(raf);
        scheduleRef.current = null;
        sizing.disconnect(); observer.disconnect();
        root!.removeEventListener('pointermove', onPointer);
        root!.removeEventListener('pointerleave', onLeave);
        document.removeEventListener('visibilitychange', onVisible);
        document.removeEventListener('shakti:motion', onPageMotion);
        media.removeEventListener('change', onMotion);
        canvas!.removeEventListener('webglcontextlost', onLost);
        const geometries = new Set<import('three').BufferGeometry>();
        const materials = new Set<import('three').Material>();
        scene.traverse((object) => {
          const mesh = object as import('three').Mesh;
          if (mesh.geometry) geometries.add(mesh.geometry);
          if (mesh.material) (Array.isArray(mesh.material) ? mesh.material : [mesh.material]).forEach((material) => materials.add(material));
        });
        geometries.forEach((geometry) => geometry.dispose());
        materials.forEach((material) => material.dispose());
        textures.forEach((texture) => texture.dispose());
        renderer.dispose();
      };
      resize();
      setReady(true);
      const loader = new THREE.TextureLoader();
      function load(name: string, apply: (texture: import('three').Texture) => void, color = false) {
        loader.load('/textures/' + name, (texture) => {
          if (disposed) { texture.dispose(); return; }
          textures.add(texture);
          if (color) texture.colorSpace = THREE.SRGBColorSpace;
          apply(texture);
          schedule();
        }, undefined, () => { /* Keep the rendered fallback and useful page content. */ });
      }
      // Render first, then progressively refine the locally served surface.
      load('earth-day.jpg', (texture) => { earthMaterial.map = texture; earthMaterial.needsUpdate = true; }, true);
      load('earth-normal.jpg', (texture) => { earthMaterial.normalMap = texture; earthMaterial.normalScale.set(0.45, 0.45); earthMaterial.needsUpdate = true; });
      load('earth-specular.jpg', (texture) => { earthMaterial.specularMap = texture; earthMaterial.needsUpdate = true; });
      load('earth-clouds.png', (texture) => { cloudMaterial.map = texture; cloudMaterial.needsUpdate = true; }, true);
      load('earth-night.png', (texture) => { nightMaterial.uniforms.nightMap.value = texture; nightMaterial.uniforms.enabled.value = 1; }, true);
    }).catch(() => { cleanup?.(); if (!disposed) setReady(false); });
    return () => { disposed = true; cleanup?.(); };
  }, []);

  function rotate(amount: number) { settings.current.angle += amount; scheduleRef.current?.(); }
  return <div ref={rootRef} className="s-earth" role="group" aria-label="Illustrated globe showing a Shakti signal from Bengaluru to trusted guardians">
    <div className="s-sculpture-grid" aria-hidden="true" />
    <div className="s-earth-poster" hidden={ready} aria-hidden="true" />
    <canvas ref={canvasRef} aria-hidden="true" />
    <div className="s-sculpture-top"><span>BENGALURU / YOUR TRUSTED CIRCLE</span><span>EARTH · 3D</span></div>
    <div className="s-earth-origin" aria-hidden="true"><span className="s-dot" /> One signal. Your people.</div>
    <div className="s-sculpture-bottom"><p>Illustrative guardian connections. No live location.</p><div role="group" aria-label="Control globe illustration"><button type="button" aria-label="Rotate globe left" onClick={() => rotate(-0.25)}><ArrowLeft size={15} /></button><button type="button" aria-label={paused ? 'Play globe' : 'Pause globe'} onClick={() => setPaused((value) => !value)}>{paused ? <Play size={14} /> : <Pause size={14} />}</button><button type="button" aria-label="Rotate globe right" onClick={() => rotate(0.25)}><ArrowRight size={15} /></button></div></div>
  </div>;
}
