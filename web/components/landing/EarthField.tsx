'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Pause, Play } from 'lucide-react';

type LatLng = { lat: number; lon: number };
type XY = [number, number];

const LAND = '#1e293b';
const LAND_LIGHT = '#334155';
const LAND_GLOW = '#38bdf8';

// Continent outlines for procedural hero fallback texture.
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

const LOCATIONS: { label: string; point: LatLng; color: string; isOrigin?: boolean }[] = [
  { label: 'you / Bengaluru', point: { lat: 12.97, lon: 77.59 }, color: '#d8ff45', isOrigin: true },
  { label: 'guardian / Mumbai', point: { lat: 19.08, lon: 72.88 }, color: '#a49dff' },
  { label: 'guardian / Delhi', point: { lat: 28.61, lon: 77.21 }, color: '#a49dff' },
  { label: 'guardian / Singapore', point: { lat: 1.35, lon: 103.82 }, color: '#38bdf8' },
];

function createMapTexture(documentRef: Document) {
  const map = documentRef.createElement('canvas');
  map.width = 2048;
  map.height = 1024;
  const ctx = map.getContext('2d');
  if (!ctx) return map;

  // Deep obsidian/sapphire oceanic gradient
  const ocean = ctx.createLinearGradient(0, 0, 0, map.height);
  ocean.addColorStop(0, '#040916');
  ocean.addColorStop(0.25, '#07162e');
  ocean.addColorStop(0.5, '#0a1d3d');
  ocean.addColorStop(0.75, '#07162e');
  ocean.addColorStop(1, '#030814');
  ctx.fillStyle = ocean;
  ctx.fillRect(0, 0, map.width, map.height);

  // Subtle longitude & latitude graticule lines
  ctx.strokeStyle = 'rgba(129, 140, 248, 0.08)';
  ctx.lineWidth = 1;
  for (let lat = -80; lat <= 80; lat += 20) {
    const y = ((90 - lat) / 180) * map.height;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(map.width, y);
    ctx.stroke();
  }
  for (let lon = -180; lon <= 180; lon += 30) {
    const x = ((lon + 180) / 360) * map.width;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, map.height);
    ctx.stroke();
  }

  // Draw continents with cyber-specular outlines and micro-stippling
  const project = ([lon, lat]: XY): [number, number] => [
    ((lon + 180) / 360) * map.width,
    ((90 - lat) / 180) * map.height,
  ];

  CONTINENTS.forEach((continent, index) => {
    ctx.beginPath();
    continent.forEach((point, pointIndex) => {
      const [x, y] = project(point);
      if (pointIndex === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.closePath();

    ctx.fillStyle = index % 2 === 0 ? LAND : LAND_LIGHT;
    ctx.globalAlpha = 0.95;
    ctx.fill();

    // Glowing boundary
    ctx.globalAlpha = 1;
    ctx.strokeStyle = LAND_GLOW;
    ctx.lineWidth = 2.5;
    ctx.shadowColor = LAND_GLOW;
    ctx.shadowBlur = 10;
    ctx.stroke();
    ctx.shadowBlur = 0;
  });

  // Soft latitude sheen
  const glow = ctx.createLinearGradient(0, 0, map.width, map.height);
  glow.addColorStop(0, 'rgba(164, 157, 255, 0.14)');
  glow.addColorStop(0.4, 'rgba(255, 255, 255, 0.02)');
  glow.addColorStop(0.85, 'rgba(216, 255, 69, 0.1)');
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

  for (let i = 0; i < 90; i += 1) {
    const x = Math.random() * cloud.width;
    const y = 60 + Math.random() * 380;
    const w = 30 + Math.random() * 140;
    const h = 4 + Math.random() * 14;
    const cloudGradient = ctx.createRadialGradient(x, y, 0, x, y, w);
    cloudGradient.addColorStop(0, 'rgba(240, 245, 255, 0.28)');
    cloudGradient.addColorStop(0.5, 'rgba(220, 235, 255, 0.12)');
    cloudGradient.addColorStop(1, 'rgba(240, 245, 255, 0)');
    ctx.fillStyle = cloudGradient;
    ctx.beginPath();
    ctx.ellipse(x, y, w, h, (Math.random() - 0.5) * 0.4, 0, Math.PI * 2);
    ctx.fill();
  }
  return cloud;
}

function latLngToVector(lat: number, lon: number, radius: number, THREE: typeof import('three')) {
  const phi = (90 - lat) * (Math.PI / 180);
  const theta = (lon + 180) * (Math.PI / 180);
  return new THREE.Vector3(
    -radius * Math.sin(phi) * Math.cos(theta),
    radius * Math.cos(phi),
    radius * Math.sin(phi) * Math.sin(theta)
  );
}

export function EarthField() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rootRef = useRef<HTMLDivElement>(null);
  const scheduleRef = useRef<(() => void) | null>(null);

  // Rotation and momentum physics state
  const physics = useRef({
    paused: false,
    angleY: -2.92,
    targetAngleY: -2.92,
    angleX: 0.08,
    targetAngleX: 0.08,
    isDragging: false,
    lastPointerX: 0,
    lastPointerY: 0,
    velocityX: 0,
    velocityY: 0,
    pointerHoverX: 0,
    pointerHoverY: 0,
  });

  const [paused, setPaused] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    physics.current.paused = paused;
    scheduleRef.current?.();
  }, [paused]);

  useEffect(() => {
    const canvas = canvasRef.current;
    const root = rootRef.current;
    if (!canvas || !root) return;

    let disposed = false;
    let cleanup: (() => void) | undefined;
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');

    void import('three').then((THREE) => {
      if (disposed) return;

      const renderer = new THREE.WebGLRenderer({
        canvas,
        antialias: true,
        alpha: true,
        powerPreference: 'high-performance',
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      renderer.setClearColor(0x000000, 0);

      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(36, 1, 0.1, 40);
      camera.position.set(0, 0.08, 5.5);

      const globe = new THREE.Group();
      scene.add(globe);

      const textures = new Set<import('three').Texture>();
      const fallback = new THREE.CanvasTexture(createMapTexture(document));
      fallback.colorSpace = THREE.SRGBColorSpace;
      textures.add(fallback);

      // 1. Earth Base Mesh with rich specular response
      const earthMaterial = new THREE.MeshPhongMaterial({
        map: fallback,
        shininess: 24,
        specular: new THREE.Color('#a5b4fc'),
        emissive: new THREE.Color('#030712'),
      });
      const earthGeometry = new THREE.SphereGeometry(1.15, 80, 64);
      const earth = new THREE.Mesh(earthGeometry, earthMaterial);
      globe.add(earth);

      // Dynamic studio lighting with directional sun and atmospheric ambient
      const sunDirection = new THREE.Vector3(-3.2, 2.0, 3.8).normalize();
      const sun = new THREE.DirectionalLight('#fff5ea', 2.8);
      sun.position.copy(sunDirection).multiplyScalar(6);
      const ambient = new THREE.AmbientLight('#2a3754', 0.85);
      const rimLight = new THREE.DirectionalLight('#38bdf8', 1.2);
      rimLight.position.set(4, -1, -3);
      scene.add(sun, ambient, rimLight);

      // 2. Cloud Layer with counter-rotation
      const cloudTexture = new THREE.CanvasTexture(createCloudTexture(document));
      textures.add(cloudTexture);
      const cloudMaterial = new THREE.MeshPhongMaterial({
        map: cloudTexture,
        transparent: true,
        opacity: 0.65,
        depthWrite: false,
        blending: THREE.NormalBlending,
      });
      const clouds = new THREE.Mesh(new THREE.SphereGeometry(1.166, 64, 48), cloudMaterial);
      globe.add(clouds);

      // 3. Night Side City Lights Shader with rhythmic twinkling
      const nightMaterial = new THREE.ShaderMaterial({
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        uniforms: {
          nightMap: { value: fallback },
          sunDirection: { value: sunDirection },
          uTime: { value: 0 },
          enabled: { value: 0 },
        },
        vertexShader: `
          varying vec2 vUv;
          varying vec3 vNormal;
          void main() {
            vUv = uv;
            vNormal = normalize(mat3(modelMatrix) * normal);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `
          uniform sampler2D nightMap;
          uniform vec3 sunDirection;
          uniform float uTime;
          uniform float enabled;
          varying vec2 vUv;
          varying vec3 vNormal;
          void main() {
            float dark = 1.0 - smoothstep(-0.2, 0.18, dot(normalize(vNormal), sunDirection));
            vec3 lights = texture2D(nightMap, vUv).rgb;
            float pulse = 0.88 + 0.12 * sin(uTime * 3.0 + vUv.x * 30.0);
            vec3 amberGlow = vec3(1.1, 0.95, 0.65);
            gl_FragColor = vec4(lights * amberGlow * dark * enabled * pulse, dark * enabled * 0.9);
          }
        `,
      });
      globe.add(new THREE.Mesh(new THREE.SphereGeometry(1.153, 64, 48), nightMaterial));

      // 4. Inner Atmospheric Fresnel Haze
      const innerAtmosphereMaterial = new THREE.ShaderMaterial({
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.FrontSide,
        vertexShader: `
          varying vec3 vNormal;
          varying vec3 vViewPosition;
          void main() {
            vNormal = normalize(normalMatrix * normal);
            vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
            vViewPosition = -mvPos.xyz;
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          varying vec3 vNormal;
          varying vec3 vViewPosition;
          void main() {
            vec3 normal = normalize(vNormal);
            vec3 view = normalize(vViewPosition);
            float fresnel = pow(1.0 - max(0.0, dot(normal, view)), 3.2);
            vec3 haze = mix(vec3(0.22, 0.55, 1.0), vec3(0.85, 1.0, 0.27), fresnel * 0.35);
            gl_FragColor = vec4(haze, fresnel * 0.65);
          }
        `,
      });
      globe.add(new THREE.Mesh(new THREE.SphereGeometry(1.157, 64, 48), innerAtmosphereMaterial));

      // 5. Outer Atmospheric Corona
      const atmosphereMaterial = new THREE.ShaderMaterial({
        transparent: true,
        side: THREE.BackSide,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        vertexShader: `
          varying vec3 vNormal;
          varying vec3 vWorld;
          void main() {
            vNormal = normalize(mat3(modelMatrix) * normal);
            vec4 world = modelMatrix * vec4(position, 1.0);
            vWorld = world.xyz;
            gl_Position = projectionMatrix * viewMatrix * world;
          }
        `,
        fragmentShader: `
          varying vec3 vNormal;
          varying vec3 vWorld;
          void main() {
            float rim = pow(max(0.0, 1.0 - abs(dot(normalize(vNormal), normalize(cameraPosition - vWorld)))), 2.5);
            vec3 glowColor = mix(vec3(0.24, 0.45, 0.98), vec3(0.65, 0.4, 1.0), rim * 0.7);
            gl_FragColor = vec4(glowColor, rim * 0.75);
          }
        `,
      });
      const atmosphere = new THREE.Mesh(new THREE.SphereGeometry(1.23, 64, 48), atmosphereMaterial);
      globe.add(atmosphere);

      // 6. Orbital Satellite Constellation (Particle Swarm)
      const PARTICLE_COUNT = 160;
      const particlePositions = new Float32Array(PARTICLE_COUNT * 3);
      const particlePhases = new Float32Array(PARTICLE_COUNT);
      for (let i = 0; i < PARTICLE_COUNT; i++) {
        const u = Math.random();
        const v = Math.random();
        const theta = u * 2.0 * Math.PI;
        const phi = Math.acos(2.0 * v - 1.0);
        const r = 1.35 + Math.random() * 0.35;
        particlePositions[i * 3] = r * Math.sin(phi) * Math.cos(theta);
        particlePositions[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
        particlePositions[i * 3 + 2] = r * Math.cos(phi);
        particlePhases[i] = Math.random() * Math.PI * 2;
      }
      const particleGeometry = new THREE.BufferGeometry();
      particleGeometry.setAttribute('position', new THREE.BufferAttribute(particlePositions, 3));
      const particleMaterial = new THREE.ShaderMaterial({
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        uniforms: {
          uTime: { value: 0 },
        },
        vertexShader: `
          uniform float uTime;
          void main() {
            vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
            float dist = length(position);
            float pulse = 0.8 + 0.3 * sin(uTime * 2.5 + dist * 10.0);
            gl_PointSize = clamp(3.0 * (150.0 / -mvPos.z) * pulse, 2.0, 14.0);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          void main() {
            float dist = length(gl_PointCoord - vec2(0.5));
            if (dist > 0.5) discard;
            float alpha = pow(max(0.0, 1.0 - dist * 2.0), 2.0);
            vec3 col = mix(vec3(0.55, 0.75, 1.0), vec3(0.85, 1.0, 0.27), alpha);
            gl_FragColor = vec4(col, alpha * 0.7);
          }
        `,
      });
      const orbitalParticles = new THREE.Points(particleGeometry, particleMaterial);
      scene.add(orbitalParticles);

      // 7. Active Cities, Guardian Radar Rings, Laser Beacons & Connecting Signal Arcs
      const source = latLngToVector(LOCATIONS[0].point.lat, LOCATIONS[0].point.lon, 1.155, THREE);
      const packets: { point: import('three').Mesh; curve: import('three').QuadraticBezierCurve3 }[] = [];
      const pulseRings: { mesh: import('three').Mesh; originPos: import('three').Vector3; phase: number }[] = [];

      LOCATIONS.forEach((location, index) => {
        const position = latLngToVector(location.point.lat, location.point.lon, 1.155, THREE);
        const normal = position.clone().normalize();

        // City Marker Pin
        const pointColor = location.isOrigin ? '#d8ff45' : '#a49dff';
        const pinMesh = new THREE.Mesh(
          new THREE.SphereGeometry(location.isOrigin ? 0.034 : 0.024, 16, 16),
          new THREE.MeshBasicMaterial({ color: pointColor })
        );
        pinMesh.position.copy(position);
        globe.add(pinMesh);

        // Vertical Laser Beacon Pillar
        const beaconLength = location.isOrigin ? 0.16 : 0.1;
        const beaconGeo = new THREE.CylinderGeometry(0.003, 0.008, beaconLength, 8);
        beaconGeo.translate(0, beaconLength / 2, 0);
        const beaconMat = new THREE.MeshBasicMaterial({
          color: pointColor,
          transparent: true,
          opacity: 0.85,
        });
        const beacon = new THREE.Mesh(beaconGeo, beaconMat);
        beacon.position.copy(position);
        beacon.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), normal);
        globe.add(beacon);

        // Surface Radar Ripple Ring
        const ringGeo = new THREE.RingGeometry(0.02, 0.028, 32);
        const ringMat = new THREE.MeshBasicMaterial({
          color: pointColor,
          transparent: true,
          opacity: 0.8,
          side: THREE.DoubleSide,
        });
        const ringMesh = new THREE.Mesh(ringGeo, ringMat);
        ringMesh.position.copy(position.clone().add(normal.clone().multiplyScalar(0.002)));
        ringMesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), normal);
        globe.add(ringMesh);
        pulseRings.push({ mesh: ringMesh, originPos: ringMesh.position.clone(), phase: index * 0.4 });

        if (!index) return; // Arcs originate from index 0 (Bengaluru)

        // Arched Great Circle Bezier Curve to Guardians
        const midPoint = source.clone().lerp(position, 0.5).normalize().multiplyScalar(1.36 + index * 0.045);
        const curve = new THREE.QuadraticBezierCurve3(source, midPoint, position);
        const curvePoints = curve.getPoints(72);
        const arcLine = new THREE.Line(
          new THREE.BufferGeometry().setFromPoints(curvePoints),
          new THREE.LineBasicMaterial({ color: '#7dd3fc', transparent: true, opacity: 0.75, linewidth: 2 })
        );
        globe.add(arcLine);

        // Luminous Data Photon Packet
        const packet = new THREE.Mesh(
          new THREE.SphereGeometry(0.018, 12, 12),
          new THREE.MeshBasicMaterial({ color: '#ffffff' })
        );
        globe.add(packet);
        packets.push({ point: packet, curve });
      });

      // Gyroscopic Orbital Torus Rings
      const orbit1 = new THREE.Mesh(
        new THREE.TorusGeometry(1.58, 0.005, 8, 144),
        new THREE.MeshBasicMaterial({ color: '#818cf8', transparent: true, opacity: 0.4 })
      );
      orbit1.rotation.set(1.15, 0.2, -0.25);
      scene.add(orbit1);

      const orbit2 = new THREE.Mesh(
        new THREE.TorusGeometry(1.72, 0.004, 8, 144),
        new THREE.MeshBasicMaterial({ color: '#38bdf8', transparent: true, opacity: 0.3 })
      );
      orbit2.rotation.set(-0.8, 0.45, 0.6);
      scene.add(orbit2);

      // Render Loop & Animation State
      let raf = 0;
      let last = 0;
      let time = 0;
      let inView = true;
      let visible = !document.hidden;
      let reduced = media.matches;
      let contextLost = false;
      let pagePaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';

      function schedule() {
        if (!disposed && !contextLost && !raf && inView && visible) {
          raf = requestAnimationFrame(draw);
        }
      }

      function draw(now: number) {
        raf = 0;
        if (disposed || contextLost || !inView || !visible) return;

        const animate = !reduced && !pagePaused && !physics.current.paused;
        const delta = Math.min((now - (last || now)) / 1000, 0.08);
        if (animate) time += delta;
        last = now;

        const p = physics.current;

        // Inertia & Damped Smooth Easing
        if (!p.isDragging) {
          p.targetAngleY += p.velocityX;
          p.targetAngleX += p.velocityY;
          p.velocityX *= 0.92;
          p.velocityY *= 0.92;

          // Continuous celestial drift when idle
          if (animate) {
            p.targetAngleY += delta * 0.07;
          }
        }

        // Clamp vertical tilt so poles don't invert
        p.targetAngleX = Math.max(-0.65, Math.min(0.65, p.targetAngleX));

        p.angleY += (p.targetAngleY - p.angleY) * 0.12;
        p.angleX += (p.targetAngleX - p.angleX) * 0.12;

        // Apply smooth orientation + hover parallax
        const hoverX = reduced ? 0 : p.pointerHoverX * 0.14;
        const hoverY = reduced ? 0 : p.pointerHoverY * -0.09;

        globe.rotation.set(
          reduced ? 0.08 : p.angleX + hoverY,
          reduced ? -2.92 : p.angleY + hoverX,
          0.05
        );

        clouds.rotation.y = time * 0.016;
        orbitalParticles.rotation.y = time * 0.02;
        orbitalParticles.rotation.x = Math.sin(time * 0.01) * 0.1;
        orbit1.rotation.z = time * 0.03;
        orbit2.rotation.y = -time * 0.025;

        // Update shader uniforms
        nightMaterial.uniforms.uTime.value = time;
        particleMaterial.uniforms.uTime.value = time;

        // Animate traveling signal packets
        packets.forEach(({ point, curve }, idx) => {
          const t = (time * 0.28 + idx / packets.length) % 1;
          point.position.copy(curve.getPoint(t));
          // Scale packet slightly near peak of flight
          const peakScale = 1.0 + 0.5 * Math.sin(t * Math.PI);
          point.scale.setScalar(peakScale);
        });

        // Animate radar ripple rings expanding outward
        pulseRings.forEach(({ mesh, phase }) => {
          const cycle = (time * 0.8 + phase) % 1;
          const scale = 1.0 + cycle * 4.2;
          mesh.scale.set(scale, scale, 1);
          const mat = mesh.material as import('three').MeshBasicMaterial;
          mat.opacity = Math.max(0, 0.85 * (1 - cycle));
        });

        renderer.render(scene, camera);
        if (animate || Math.abs(p.velocityX) > 0.0001 || Math.abs(p.targetAngleY - p.angleY) > 0.0005) {
          schedule();
        }
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

      // Pointer Orbit Controls (Mouse & Touch Drag with Velocity & Hover Parallax)
      function onPointerDown(event: PointerEvent) {
        if (reduced) return;
        const p = physics.current;
        p.isDragging = true;
        p.lastPointerX = event.clientX;
        p.lastPointerY = event.clientY;
        p.velocityX = 0;
        p.velocityY = 0;
        try {
          canvas!.setPointerCapture(event.pointerId);
        } catch {
          // pointer capture unsupported or detached
        }
      }

      function onPointerMove(event: PointerEvent) {
        const p = physics.current;
        const bounds = root!.getBoundingClientRect();
        p.pointerHoverX = (event.clientX - bounds.left) / bounds.width - 0.5;
        p.pointerHoverY = (event.clientY - bounds.top) / bounds.height - 0.5;

        if (p.isDragging) {
          const dx = event.clientX - p.lastPointerX;
          const dy = event.clientY - p.lastPointerY;
          p.lastPointerX = event.clientX;
          p.lastPointerY = event.clientY;

          const factor = 0.0055;
          p.velocityX = dx * factor;
          p.velocityY = dy * factor;
          p.targetAngleY += p.velocityX;
          p.targetAngleX += p.velocityY;
        }

        schedule();
      }

      function onPointerUp(event: PointerEvent) {
        const p = physics.current;
        p.isDragging = false;
        try {
          canvas!.releasePointerCapture(event.pointerId);
        } catch {
          // already released
        }
        schedule();
      }

      function onPointerLeave() {
        const p = physics.current;
        p.pointerHoverX = 0;
        p.pointerHoverY = 0;
        schedule();
      }

      function onVisible() {
        visible = !document.hidden;
        last = 0;
        if (visible) schedule();
        else {
          cancelAnimationFrame(raf);
          raf = 0;
        }
      }

      function onMotion() {
        reduced = media.matches;
        schedule();
      }

      function onPageMotion(event: Event) {
        pagePaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused);
        schedule();
      }

      function onLost(event: Event) {
        event.preventDefault();
        contextLost = true;
        cancelAnimationFrame(raf);
        raf = 0;
        setReady(false);
      }

      function onRestored() {
        contextLost = false;
        setReady(true);
        schedule();
      }

      const sizing = new ResizeObserver(resize);
      sizing.observe(root!);
      const observer = new IntersectionObserver(([entry]) => {
        inView = entry.isIntersecting;
        last = 0;
        if (inView) schedule();
        else {
          cancelAnimationFrame(raf);
          raf = 0;
        }
      });
      observer.observe(root!);

      canvas!.addEventListener('pointerdown', onPointerDown);
      canvas!.addEventListener('pointermove', onPointerMove, { passive: true });
      canvas!.addEventListener('pointerup', onPointerUp);
      canvas!.addEventListener('pointercancel', onPointerUp);
      root!.addEventListener('pointerleave', onPointerLeave);
      document.addEventListener('visibilitychange', onVisible);
      document.addEventListener('shakti:motion', onPageMotion);
      media.addEventListener('change', onMotion);
      canvas!.addEventListener('webglcontextlost', onLost);
      canvas!.addEventListener('webglcontextrestored', onRestored);

      cleanup = () => {
        cancelAnimationFrame(raf);
        scheduleRef.current = null;
        sizing.disconnect();
        observer.disconnect();

        canvas!.removeEventListener('pointerdown', onPointerDown);
        canvas!.removeEventListener('pointermove', onPointerMove);
        canvas!.removeEventListener('pointerup', onPointerUp);
        canvas!.removeEventListener('pointercancel', onPointerUp);
        root!.removeEventListener('pointerleave', onPointerLeave);
        document.removeEventListener('visibilitychange', onVisible);
        document.removeEventListener('shakti:motion', onPageMotion);
        media.removeEventListener('change', onMotion);
        canvas!.removeEventListener('webglcontextlost', onLost);
        canvas!.removeEventListener('webglcontextrestored', onRestored);

        const geometries = new Set<import('three').BufferGeometry>();
        const materials = new Set<import('three').Material>();
        scene.traverse((object) => {
          const mesh = object as import('three').Mesh;
          if (mesh.geometry) geometries.add(mesh.geometry);
          if (mesh.material) {
            (Array.isArray(mesh.material) ? mesh.material : [mesh.material]).forEach((mat) =>
              materials.add(mat)
            );
          }
        });
        geometries.forEach((g) => g.dispose());
        materials.forEach((m) => m.dispose());
        textures.forEach((t) => t.dispose());
        renderer.dispose();
      };

      resize();
      setReady(true);

      // Progressive Texture Loading for High-Fidelity Photorealism
      const loader = new THREE.TextureLoader();
      function load(name: string, apply: (texture: import('three').Texture) => void, color = false) {
        loader.load(
          '/textures/' + name,
          (texture) => {
            if (disposed) {
              texture.dispose();
              return;
            }
            textures.add(texture);
            if (color) texture.colorSpace = THREE.SRGBColorSpace;
            apply(texture);
            schedule();
          },
          undefined,
          () => {
            /* Retain procedural vector fallback on error */
          }
        );
      }

      load('earth-day.jpg', (texture) => {
        earthMaterial.map = texture;
        earthMaterial.needsUpdate = true;
      }, true);
      load('earth-normal.jpg', (texture) => {
        earthMaterial.normalMap = texture;
        earthMaterial.normalScale.set(0.65, 0.65);
        earthMaterial.needsUpdate = true;
      });
      load('earth-specular.jpg', (texture) => {
        earthMaterial.specularMap = texture;
        earthMaterial.needsUpdate = true;
      });
      load('earth-clouds.png', (texture) => {
        cloudMaterial.map = texture;
        cloudMaterial.needsUpdate = true;
      }, true);
      load('earth-night.png', (texture) => {
        nightMaterial.uniforms.nightMap.value = texture;
        nightMaterial.uniforms.enabled.value = 1;
      }, true);
    }).catch(() => {
      cleanup?.();
      if (!disposed) setReady(false);
    });

    return () => {
      disposed = true;
      cleanup?.();
    };
  }, []);

  function rotate(amount: number) {
    physics.current.targetAngleY += amount;
    scheduleRef.current?.();
  }

  return (
    <div
      ref={rootRef}
      className="s-earth"
      role="group"
      aria-label="Illustrated 3D globe showing a Shakti emergency signal from Bengaluru to trusted guardians"
    >
      <div className="s-sculpture-grid" aria-hidden="true" />
      <div className="s-earth-poster" hidden={ready} aria-hidden="true" />
      <canvas
        ref={canvasRef}
        aria-hidden="true"
        style={{ cursor: 'grab', touchAction: 'none' }}
      />
      <div className="s-sculpture-top">
        <span>BENGALURU / YOUR TRUSTED CIRCLE</span>
        <span>EARTH · 3D ORBIT</span>
      </div>
      <div className="s-earth-origin" aria-hidden="true">
        <span className="s-dot" /> One signal. Your people.
      </div>
      <div className="s-sculpture-bottom">
        <p>Drag to inspect orbit. Real-time guardian signal beacons.</p>
        <div role="group" aria-label="Control globe illustration">
          <button
            type="button"
            aria-label="Rotate globe left"
            onClick={() => rotate(-0.35)}
          >
            <ArrowLeft size={15} />
          </button>
          <button
            type="button"
            aria-label={paused ? 'Play globe' : 'Pause globe'}
            onClick={() => setPaused((value) => !value)}
          >
            {paused ? <Play size={14} /> : <Pause size={14} />}
          </button>
          <button
            type="button"
            aria-label="Rotate globe right"
            onClick={() => rotate(0.35)}
          >
            <ArrowRight size={15} />
          </button>
        </div>
      </div>
    </div>
  );
}
