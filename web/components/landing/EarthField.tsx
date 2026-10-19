'use client';

import { useEffect, useRef } from 'react';

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
  { label: 'guardian / London', point: { lat: 51.5, lon: -0.1 }, color: '#a49dff' },
  { label: 'guardian / Toronto', point: { lat: 43.65, lon: -79.38 }, color: '#a49dff' },
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

  useEffect(() => {
    const canvas = canvasRef.current;
    const root = rootRef.current;
    if (!canvas || !root) return;
    let disposed = false;
    let stop: (() => void) | undefined;
    import('three').then(async (THREE) => {
      if (disposed) return;
      const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, powerPreference: 'high-performance' });
      const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
      renderer.setPixelRatio(dpr);
      renderer.setClearColor(0x000000, 0);
      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(30, 1, 0.1, 100);
      camera.position.set(0, 0.1, 4.85);

      const globe = new THREE.Group();
      scene.add(globe);
      const textureLoader = new THREE.TextureLoader();
      textureLoader.setCrossOrigin('anonymous');
      const loadTexture = (url: string) => new Promise<import('three').Texture>((resolve, reject) => textureLoader.load(url, resolve, undefined, reject));
      const textureResults = await Promise.allSettled([
        loadTexture('https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg'),
        loadTexture('https://threejs.org/examples/textures/planets/earth_normal_2048.jpg'),
        loadTexture('https://threejs.org/examples/textures/planets/earth_specular_2048.jpg'),
        loadTexture('https://threejs.org/examples/textures/planets/earth_clouds_1024.png'),
        loadTexture('https://threejs.org/examples/textures/planets/earth_lights_2048.png'),
      ]);
      const fallbackMap = new THREE.CanvasTexture(createMapTexture(document));
      const fallbackClouds = new THREE.CanvasTexture(createCloudTexture(document));
      const getTexture = (index: number, fallback: import('three').Texture) => textureResults[index]?.status === 'fulfilled' ? textureResults[index].value : fallback;
      const map = getTexture(0, fallbackMap);
      map.colorSpace = THREE.SRGBColorSpace;
      const normal = getTexture(1, fallbackMap);
      const specular = getTexture(2, fallbackMap);
      const clouds = getTexture(3, fallbackClouds);
      const lights = textureResults[4]?.status === 'fulfilled' ? textureResults[4].value : null;
      clouds.colorSpace = THREE.SRGBColorSpace;
      const sphere = new THREE.Mesh(new THREE.SphereGeometry(1.12, 96, 96), new THREE.MeshPhongMaterial({ map, normalMap: normal, specularMap: specular, shininess: 22, specular: new THREE.Color('#a49dff'), emissive: new THREE.Color('#07122c'), emissiveIntensity: 0.42 }));
      globe.add(sphere);
      const cloudSphere = new THREE.Mesh(new THREE.SphereGeometry(1.135, 64, 64), new THREE.MeshLambertMaterial({ map: clouds, transparent: true, opacity: 0.72, depthWrite: false }));
      globe.add(cloudSphere);
      if (lights) {
        lights.colorSpace = THREE.SRGBColorSpace;
        const cityLights = new THREE.Mesh(new THREE.SphereGeometry(1.126, 64, 64), new THREE.MeshBasicMaterial({ map: lights, transparent: true, blending: THREE.AdditiveBlending, opacity: 0.72, depthWrite: false }));
        globe.add(cityLights);
      }

      const atmosphere = new THREE.Mesh(new THREE.SphereGeometry(1.23, 64, 64), new THREE.ShaderMaterial({ transparent: true, side: THREE.BackSide, blending: THREE.AdditiveBlending, uniforms: { glowColor: { value: new THREE.Color('#635bff') }, viewVector: { value: camera.position } }, vertexShader: `varying vec3 vNormal; varying vec3 vWorldPosition; void main(){ vNormal=normalize(normalMatrix*normal); vec4 worldPosition=modelMatrix*vec4(position,1.0); vWorldPosition=worldPosition.xyz; gl_Position=projectionMatrix*viewMatrix*worldPosition; }`, fragmentShader: `uniform vec3 glowColor; varying vec3 vNormal; varying vec3 vWorldPosition; void main(){ vec3 viewDirection=normalize(cameraPosition-vWorldPosition); float intensity=pow(0.72-dot(vNormal,viewDirection),2.2); gl_FragColor=vec4(glowColor,intensity*0.85); }` }));
      globe.add(atmosphere);
      const sun = new THREE.DirectionalLight('#d8ffb8', 2.4);
      sun.position.set(-3, 1.5, 4);
      scene.add(sun);
      scene.add(new THREE.AmbientLight('#2b2a6d', 0.8));

      const orbitGroup = new THREE.Group();
      globe.add(orbitGroup);
      const orbitMaterials = ['#a49dff', '#d8ff45', '#ffffff'];
      [1.34, 1.48, 1.62].forEach((radius, index) => {
        const ring = new THREE.Mesh(new THREE.TorusGeometry(radius, index === 1 ? 0.008 : 0.004, 8, 160), new THREE.MeshBasicMaterial({ color: orbitMaterials[index], transparent: true, opacity: index === 1 ? 0.62 : 0.26 }));
        ring.rotation.set(0.92 + index * 0.2, 0.2 + index * 0.35, 0.25);
        orbitGroup.add(ring);
      });

      const nodes = new THREE.Group();
      globe.add(nodes);
      const source = latLngToVector(LOCATIONS[0].point.lat, LOCATIONS[0].point.lon, 1.15, THREE);
      const nodeObjects = LOCATIONS.map((location) => {
        const point = latLngToVector(location.point.lat, location.point.lon, 1.15, THREE);
        const node = new THREE.Mesh(new THREE.SphereGeometry(location === LOCATIONS[0] ? 0.035 : 0.026, 16, 16), new THREE.MeshBasicMaterial({ color: location.color }));
        node.position.copy(point);
        nodes.add(node);
        const linePoints = new THREE.QuadraticBezierCurve3(source.clone(), source.clone().lerp(point, 0.5).normalize().multiplyScalar(1.5), point.clone()).getPoints(80);
        const lineGeometry = new THREE.BufferGeometry().setFromPoints(linePoints);
        lineGeometry.setDrawRange(0, reduced ? linePoints.length : 0);
        const line = new THREE.Line(lineGeometry, new THREE.LineBasicMaterial({ color: location.color, transparent: true, opacity: location === LOCATIONS[0] ? 0 : 0.8 }));
        nodes.add(line);
        return { lineGeometry, line, node };
      });

      const starsGeometry = new THREE.BufferGeometry();
      const starPositions = new Float32Array(250 * 3);
      for (let i = 0; i < 250; i += 1) { const radius = 2.8 + Math.random() * 2.4; const a = Math.random() * Math.PI * 2; const b = Math.acos(2 * Math.random() - 1); starPositions.set([radius * Math.sin(b) * Math.cos(a), radius * Math.sin(b) * Math.sin(a), radius * Math.cos(b)], i * 3); }
      starsGeometry.setAttribute('position', new THREE.BufferAttribute(starPositions, 3));
      scene.add(new THREE.Points(starsGeometry, new THREE.PointsMaterial({ color: '#d8ff45', size: 0.018, transparent: true, opacity: 0.7 }))); 

      const pointer = { x: 0, y: 0, tx: 0, ty: 0 };
      const onPointer = (event: PointerEvent) => { const bounds = root.getBoundingClientRect(); pointer.tx = (event.clientX - bounds.left) / bounds.width - 0.5; pointer.ty = (event.clientY - bounds.top) / bounds.height - 0.5; };
      root.addEventListener('pointermove', onPointer, { passive: true });
      let raf = 0;
      let inView = true;
      const observer = new IntersectionObserver(([entry]) => { inView = entry?.isIntersecting ?? true; });
      observer.observe(root);
      const resize = () => { const bounds = root.getBoundingClientRect(); renderer.setSize(bounds.width, bounds.height, false); camera.aspect = bounds.width / bounds.height; camera.updateProjectionMatrix(); };
      const resizeObserver = new ResizeObserver(resize);
      resizeObserver.observe(root);
      resize();
      const start = performance.now();
      const render = (now: number) => {
        if (!inView) { raf = requestAnimationFrame(render); return; }
        const elapsed = (now - start) / 1000;
        pointer.x += (pointer.tx - pointer.x) * 0.04;
        pointer.y += (pointer.ty - pointer.y) * 0.04;
        globe.rotation.y = (reduced ? -0.72 : -0.72 + elapsed * 0.08) + pointer.x * 0.2;
        globe.rotation.x = pointer.y * -0.08;
        cloudSphere.rotation.y = globe.rotation.y * 1.14 + 0.1;
        orbitGroup.rotation.z = Math.sin(elapsed * 0.16) * 0.08;
        if (!reduced) nodeObjects.forEach((item, index) => { const drawCount = Math.floor(((elapsed * 0.55 + index * 19) % 80)); item.lineGeometry.setDrawRange(0, Math.max(2, drawCount)); item.node.scale.setScalar(1 + Math.sin(elapsed * 3 + index) * 0.18); });
        renderer.render(scene, camera);
        if (!reduced) raf = requestAnimationFrame(render);
      };
      render(reduced ? 1000 : performance.now());
      stop = () => { cancelAnimationFrame(raf); observer.disconnect(); resizeObserver.disconnect(); root.removeEventListener('pointermove', onPointer); renderer.dispose(); map.dispose(); clouds.dispose(); }; 
    }).catch(() => {});
    return () => { disposed = true; stop?.(); };
  }, []);

  return <div ref={rootRef} className="earth-field" role="img" aria-label="Animated Earth with a glowing atmosphere and safety signals connecting Bengaluru to trusted guardians around the world."><canvas ref={canvasRef} /><div className="earth-field-grid" aria-hidden="true" /><div className="earth-field-tag earth-field-tag-one" aria-hidden="true"><span className="motion-live-dot" /> EARTH / RESPONSE NETWORK</div><div className="earth-field-tag earth-field-tag-two" aria-hidden="true">3 → 1 → MANY</div><div className="earth-field-center" aria-hidden="true"><strong>SHAKTI</strong><span>GLOBAL SIGNAL / 01</span></div><div className="earth-field-coordinates" aria-hidden="true"><span>12.9716° N</span><span>77.5946° E</span></div></div>;
}
