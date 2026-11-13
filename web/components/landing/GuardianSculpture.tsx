'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Pause, Play } from 'lucide-react';

/** Creates a high-resolution, procedural OLED display texture for the Shakti Guardian phone. */
function createScreenTexture(documentRef: Document): HTMLCanvasElement {
  const canvas = documentRef.createElement('canvas');
  canvas.width = 768;
  canvas.height = 1536;
  const ctx = canvas.getContext('2d');
  if (!ctx) return canvas;

  // Deep obsidian dark glass background with cyan-to-violet radial gradient
  const bgGrad = ctx.createRadialGradient(
    canvas.width / 2,
    canvas.height * 0.42,
    50,
    canvas.width / 2,
    canvas.height / 2,
    canvas.height * 0.65
  );
  bgGrad.addColorStop(0, '#0a1628');
  bgGrad.addColorStop(0.5, '#050c18');
  bgGrad.addColorStop(1, '#02050c');
  ctx.fillStyle = bgGrad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // Subtle cyber telemetry grid
  ctx.strokeStyle = 'rgba(56, 189, 248, 0.05)';
  ctx.lineWidth = 1;
  for (let x = 40; x < canvas.width; x += 48) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
  }
  for (let y = 60; y < canvas.height; y += 48) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
  }

  // Dynamic Island Notch area
  const islandW = 180;
  const islandH = 46;
  const islandX = (canvas.width - islandW) / 2;
  const islandY = 32;
  ctx.fillStyle = '#010204';
  ctx.beginPath();
  ctx.roundRect(islandX, islandY, islandW, islandH, 23);
  ctx.fill();
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
  ctx.lineWidth = 1.5;
  ctx.stroke();

  // Status Bar: Time, 5G signal, WiFi, Battery
  ctx.fillStyle = '#f1f5f9';
  ctx.font = '600 24px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText('21:42', 54, 64);

  // Battery Pill & Icons on right
  const bx = canvas.width - 120;
  const by = 48;
  ctx.strokeStyle = '#94a3b8';
  ctx.lineWidth = 2;
  ctx.strokeRect(bx, by, 42, 20);
  ctx.fillStyle = '#34d399';
  ctx.fillRect(bx + 3, by + 3, 28, 14);
  ctx.fillStyle = '#94a3b8';
  ctx.fillRect(bx + 42, by + 6, 3, 8);

  // Central Radar Circle & Concentric Sentinel Rings
  const cx = canvas.width / 2;
  const cy = canvas.height * 0.44;

  [120, 200, 280].forEach((radius, i) => {
    ctx.strokeStyle = i === 1 ? 'rgba(52, 211, 153, 0.35)' : 'rgba(129, 140, 248, 0.2)';
    ctx.lineWidth = 1.5;
    ctx.setLineDash(i === 0 ? [6, 8] : []);
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();
  });
  ctx.setLineDash([]);

  // Radar Degree Hash Marks
  ctx.strokeStyle = 'rgba(56, 189, 248, 0.3)';
  ctx.lineWidth = 2;
  for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 4) {
    const x1 = cx + Math.cos(angle) * 190;
    const y1 = cy + Math.sin(angle) * 190;
    const x2 = cx + Math.cos(angle) * 210;
    const y2 = cy + Math.sin(angle) * 210;
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
  }

  // Central Glowing Shakti Shield Icon
  ctx.shadowColor = '#34d399';
  ctx.shadowBlur = 30;
  ctx.strokeStyle = '#34d399';
  ctx.lineWidth = 5;
  ctx.beginPath();
  const sw = 64;
  const sh = 80;
  ctx.moveTo(cx, cy - sh / 2);
  ctx.lineTo(cx + sw / 2, cy - sh / 4);
  ctx.lineTo(cx + sw / 2, cy + sh / 4);
  ctx.quadraticCurveTo(cx, cy + sh / 2 + 10, cx, cy + sh / 2 + 25);
  ctx.quadraticCurveTo(cx, cy + sh / 2 + 10, cx - sw / 2, cy + sh / 4);
  ctx.lineTo(cx - sw / 2, cy - sh / 4);
  ctx.closePath();
  ctx.stroke();
  ctx.fillStyle = 'rgba(52, 211, 153, 0.15)';
  ctx.fill();
  ctx.shadowBlur = 0;

  // Pulse Core Indicator
  ctx.fillStyle = '#d8ff45';
  ctx.beginPath();
  ctx.arc(cx, cy + 2, 8, 0, Math.PI * 2);
  ctx.fill();

  // Status Badge / Sentinel Header
  ctx.textAlign = 'center';
  ctx.fillStyle = '#e2e8f0';
  ctx.font = '700 32px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText('SHAKTI SENTINEL', cx, cy + 140);

  ctx.fillStyle = '#34d399';
  ctx.font = '600 20px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText('● 3 CHANNELS ARMED & READY', cx, cy + 175);

  ctx.fillStyle = '#94a3b8';
  ctx.font = '400 18px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText('POWER BUTTON TRIPLE-PRESS ARMED', cx, cy + 208);

  // Bottom Interactive Pipeline Pill & Channel Badges
  const cardY = canvas.height * 0.72;
  const cardW = canvas.width - 120;
  const cardH = 180;
  const cardX = 60;

  ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
  ctx.beginPath();
  ctx.roundRect(cardX, cardY, cardW, cardH, 24);
  ctx.fill();
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.14)';
  ctx.lineWidth = 2;
  ctx.stroke();

  // Channel Pills inside Card
  const channels = [
    { label: '01 LOCAL', state: 'SAVED', color: '#34d399' },
    { label: '02 CARRIER SMS', state: 'ONLINE', color: '#38bdf8' },
    { label: '03 WEB TRACK', state: '7-DAY LINK', color: '#a49dff' },
  ];

  channels.forEach((ch, idx) => {
    const py = cardY + 32 + idx * 46;
    ctx.textAlign = 'left';
    ctx.fillStyle = '#cbd5e1';
    ctx.font = '600 18px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    ctx.fillText(ch.label, cardX + 28, py);

    ctx.textAlign = 'right';
    ctx.fillStyle = ch.color;
    ctx.font = '700 16px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    ctx.fillText(ch.state, cardX + cardW - 28, py);
  });

  // Emergency Swipe Bar at Bottom
  const barY = canvas.height - 110;
  ctx.fillStyle = 'rgba(216, 255, 69, 0.12)';
  ctx.beginPath();
  ctx.roundRect(60, barY, canvas.width - 120, 60, 30);
  ctx.fill();
  ctx.strokeStyle = 'rgba(216, 255, 69, 0.35)';
  ctx.lineWidth = 1.5;
  ctx.stroke();

  ctx.textAlign = 'center';
  ctx.fillStyle = '#d8ff45';
  ctx.font = '700 18px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
  ctx.fillText('SWIPE TO TEST EMERGENCY SIGNAL', canvas.width / 2, barY + 36);

  return canvas;
}

export function GuardianSculpture() {
  const rootRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRender = useRef<(() => void) | null>(null);

  // Responsive physics & pointer controls
  const physics = useRef({
    paused: false,
    angleY: -0.22,
    targetAngleY: -0.22,
    angleX: 0.05,
    targetAngleX: 0.05,
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
    requestRender.current?.();
  }, [paused]);

  useEffect(() => {
    const root = rootRef.current;
    const canvas = canvasRef.current;
    if (!root || !canvas) return;

    let disposed = false;
    let cleanup: (() => void) | undefined;
    let started = false;
    const media = window.matchMedia('(prefers-reduced-motion: reduce)');

    async function start() {
      if (started || disposed) return;
      started = true;

      try {
        const THREE = await import('three');
        if (disposed) return;

        const renderer = new THREE.WebGLRenderer({
          canvas: canvas!,
          antialias: true,
          alpha: true,
          powerPreference: 'high-performance',
        });
        renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
        renderer.setClearColor(0x000000, 0);

        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 50);
        camera.position.set(0, 0.25, 7.2);

        const sculpture = new THREE.Group();
        sculpture.rotation.z = -0.1;
        scene.add(sculpture);

        // Three-Point Studio Lighting with Dynamic Orbiting Specular Key
        scene.add(new THREE.AmbientLight(0x334155, 1.2));

        const keyLight = new THREE.DirectionalLight(0xffffff, 3.2);
        keyLight.position.set(3.5, 4.5, 5);
        scene.add(keyLight);

        const rimLight = new THREE.PointLight(0x818cf8, 45, 15);
        rimLight.position.set(-3.5, -1.2, 2.8);
        scene.add(rimLight);

        const tealFill = new THREE.DirectionalLight(0x38bdf8, 1.4);
        tealFill.position.set(0, -3.5, 2.5);
        scene.add(tealFill);

        // Orbiting specular accent light
        const glintLight = new THREE.PointLight(0xd8ff45, 25, 10);
        scene.add(glintLight);

        // 1. Titanium Phone Chassis with Precision Chamfered Bevel
        const rounded = new THREE.Shape();
        const w = 0.85, h = 1.56, r = 0.22;
        rounded.moveTo(-w + r, -h);
        rounded.lineTo(w - r, -h);
        rounded.quadraticCurveTo(w, -h, w, -h + r);
        rounded.lineTo(w, h - r);
        rounded.quadraticCurveTo(w, h, w - r, h);
        rounded.lineTo(-w + r, h);
        rounded.quadraticCurveTo(-w, h, -w, h - r);
        rounded.lineTo(-w, -h + r);
        rounded.quadraticCurveTo(-w, -h, -w + r, -h);

        const bodyGeo = new THREE.ExtrudeGeometry(rounded, {
          depth: 0.13,
          bevelEnabled: true,
          bevelSegments: 4,
          steps: 1,
          bevelSize: 0.065,
          bevelThickness: 0.065,
        });

        const bodyMat = new THREE.MeshStandardMaterial({
          color: 0x0f172a,
          metalness: 0.86,
          roughness: 0.22,
        });
        const body = new THREE.Mesh(bodyGeo, bodyMat);
        body.rotation.y = -0.22;
        sculpture.add(body);

        // 2. High-Resolution OLED Screen Face
        const screenTexture = new THREE.CanvasTexture(createScreenTexture(document));
        screenTexture.colorSpace = THREE.SRGBColorSpace;
        const faceMat = new THREE.MeshStandardMaterial({
          map: screenTexture,
          metalness: 0.35,
          roughness: 0.18,
          emissive: 0x091424,
          emissiveIntensity: 0.45,
        });
        const face = new THREE.Mesh(new THREE.PlaneGeometry(1.56, 2.92), faceMat);
        face.position.z = 0.235;
        body.add(face);

        // Glass Surface Sheen Overlay (Specular Reflection)
        const glassSheenMat = new THREE.MeshPhysicalMaterial({
          color: 0xffffff,
          transparent: true,
          opacity: 0.18,
          metalness: 0.1,
          roughness: 0.05,
          clearcoat: 1.0,
          clearcoatRoughness: 0.1,
          depthWrite: false,
          blending: THREE.AdditiveBlending,
        });
        const glassSheen = new THREE.Mesh(new THREE.PlaneGeometry(1.56, 2.92), glassSheenMat);
        glassSheen.position.z = 0.238;
        body.add(glassSheen);

        // Hardware details: Side Power Button
        const powerBtn = new THREE.Mesh(
          new THREE.BoxGeometry(0.04, 0.34, 0.06),
          new THREE.MeshStandardMaterial({ color: 0x38bdf8, metalness: 0.9, roughness: 0.2 })
        );
        powerBtn.position.set(w + 0.06, 0.35, 0.06);
        body.add(powerBtn);

        // Side Volume Rocker
        const volBtn = new THREE.Mesh(
          new THREE.BoxGeometry(0.04, 0.52, 0.06),
          new THREE.MeshStandardMaterial({ color: 0x64748b, metalness: 0.9, roughness: 0.2 })
        );
        volBtn.position.set(-w - 0.06, 0.35, 0.06);
        body.add(volBtn);

        // Central Transmitter Core (Luminous Crystal)
        const core = new THREE.Mesh(
          new THREE.IcosahedronGeometry(0.38, 1),
          new THREE.MeshStandardMaterial({
            color: 0xd8ff45,
            emissive: 0x22c55e,
            emissiveIntensity: 0.75,
            metalness: 0.3,
            roughness: 0.15,
          })
        );
        core.position.set(0, 0.2, 0.42);
        body.add(core);

        // Core Halo Rings
        const coreRings: import('three').Mesh[] = [];
        [0.62, 0.84].forEach((radius) => {
          const ring = new THREE.Mesh(
            new THREE.TorusGeometry(radius, 0.01, 8, 96),
            new THREE.MeshBasicMaterial({ color: 0x818cf8, transparent: true, opacity: 0.75 })
          );
          ring.position.set(0, 0.2, 0.32);
          body.add(ring);
          coreRings.push(ring);
        });

        // 3. Gyroscopic Orbital Concentric Rings
        const orbitGroup = new THREE.Group();
        sculpture.add(orbitGroup);

        const orbitRings = [2.05, 2.42].map((radius, index) => {
          const ring = new THREE.Mesh(
            new THREE.TorusGeometry(radius, 0.012, 8, 144),
            new THREE.MeshBasicMaterial({
              color: index ? 0x818cf8 : 0x34d399,
              transparent: true,
              opacity: index ? 0.45 : 0.6,
            })
          );
          ring.rotation.set(1.1 + index * 0.4, index * 0.65, index * 0.75);
          orbitGroup.add(ring);
          return ring;
        });

        // 4. Three Sculpted Orbital Sentinel Nodes & Luminous Signal Streams
        const nodeDefinitions = [
          {
            pos: new THREE.Vector3(-2.15, 0.85, 0.45),
            color: 0x34d399,
            emissive: 0x059669,
            label: '01 / trusted contact',
          },
          {
            pos: new THREE.Vector3(2.1, 0.95, 0.1),
            color: 0x818cf8,
            emissive: 0x4f46e5,
            label: '02 / guardian browser',
          },
          {
            pos: new THREE.Vector3(1.7, -1.25, 0.5),
            color: 0x38bdf8,
            emissive: 0x0284c7,
            label: '03 / your community',
          },
        ];

        const nodes: {
          nodeMesh: import('three').Mesh;
          subRing: import('three').Mesh;
          packet: import('three').Mesh;
          curve: import('three').QuadraticBezierCurve3;
        }[] = [];

        nodeDefinitions.forEach((def, index) => {
          // Faceted crystalline node
          const nodeGeo = index === 1 ? new THREE.IcosahedronGeometry(0.24, 0) : new THREE.OctahedronGeometry(0.22, 0);
          const nodeMat = new THREE.MeshStandardMaterial({
            color: def.color,
            emissive: def.emissive,
            emissiveIntensity: 0.7,
            metalness: 0.65,
            roughness: 0.2,
          });
          const nodeMesh = new THREE.Mesh(nodeGeo, nodeMat);
          nodeMesh.position.copy(def.pos);
          sculpture.add(nodeMesh);

          // Node Mini Orbit Ring
          const subRing = new THREE.Mesh(
            new THREE.TorusGeometry(0.38, 0.008, 6, 48),
            new THREE.MeshBasicMaterial({ color: def.color, transparent: true, opacity: 0.65 })
          );
          subRing.position.copy(def.pos);
          subRing.rotation.set(0.8 + index * 0.5, index * 0.4, 0);
          sculpture.add(subRing);

          // Glowing Bezier Energy Stream from Phone Core to Node
          const originPos = new THREE.Vector3(0, 0.2, 0.45);
          const midControl = originPos.clone().lerp(def.pos, 0.5).add(new THREE.Vector3(0, 0.6, 0.4));
          const curve = new THREE.QuadraticBezierCurve3(originPos, midControl, def.pos);

          const streamLine = new THREE.Line(
            new THREE.BufferGeometry().setFromPoints(curve.getPoints(54)),
            new THREE.LineBasicMaterial({
              color: def.color,
              transparent: true,
              opacity: 0.55,
              linewidth: 2,
            })
          );
          sculpture.add(streamLine);

          // Traveling Luminous Signal Packet
          const packet = new THREE.Mesh(
            new THREE.SphereGeometry(0.045, 12, 12),
            new THREE.MeshBasicMaterial({ color: 0xffffff })
          );
          sculpture.add(packet);

          nodes.push({ nodeMesh, subRing, packet, curve });
        });

        // Animation Loop & Physics
        let raf = 0;
        let inView = true;
        let reduced = media.matches;
        let visible = !document.hidden;
        let globalPaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';
        let contextLost = false;
        let last = 0;
        let time = 0;

        function schedule() {
          if (!disposed && !contextLost && !raf && visible && inView) {
            raf = requestAnimationFrame(draw);
          }
        }

        function draw(now: number) {
          raf = 0;
          if (disposed || !visible || !inView || contextLost) return;

          const animate = !reduced && !globalPaused && !physics.current.paused;
          const delta = Math.min((now - (last || now)) / 1000, 0.08);
          if (animate) time += delta;
          last = now;

          const p = physics.current;

          // Drag Inertia & Smooth Momentum Easing
          if (!p.isDragging) {
            p.targetAngleY += p.velocityX;
            p.targetAngleX += p.velocityY;
            p.velocityX *= 0.92;
            p.velocityY *= 0.92;

            if (animate) {
              p.targetAngleY += delta * 0.05;
            }
          }

          p.targetAngleX = Math.max(-0.45, Math.min(0.45, p.targetAngleX));

          p.angleY += (p.targetAngleY - p.angleY) * 0.12;
          p.angleX += (p.targetAngleX - p.angleX) * 0.12;

          const hoverX = reduced ? 0 : p.pointerHoverX * 0.18;
          const hoverY = reduced ? 0 : p.pointerHoverY * -0.1;

          sculpture.rotation.y = reduced ? -0.22 : p.angleY + hoverX;
          sculpture.rotation.x = reduced ? 0 : p.angleX + hoverY;

          // Gentle floating levitation bob
          sculpture.position.y = animate ? Math.sin(time * 0.8) * 0.08 : 0;

          // Central core rotation
          core.rotation.y = time * 0.5;
          core.rotation.z = time * 0.25;

          coreRings.forEach((ring, idx) => {
            ring.rotation.z = time * (idx ? -0.4 : 0.6);
          });

          orbitGroup.rotation.y = time * 0.08;
          orbitRings[0].rotation.z = time * 0.04;
          orbitRings[1].rotation.x = -time * 0.03;

          // Orbiting specular accent light
          glintLight.position.set(
            Math.cos(time * 0.9) * 4.5,
            Math.sin(time * 0.7) * 2.5 + 1.0,
            Math.sin(time * 0.9) * 4.5 + 3.0
          );

          // Animate orbital nodes and traveling packets
          nodes.forEach(({ nodeMesh, subRing, packet, curve }, idx) => {
            nodeMesh.rotation.y = time * (0.8 + idx * 0.3);
            nodeMesh.rotation.x = time * 0.4;
            subRing.rotation.z = time * (idx % 2 === 0 ? 0.6 : -0.6);

            const t = (time * 0.24 + idx / nodes.length) % 1;
            packet.position.copy(curve.getPoint(t));
            packet.scale.setScalar(1.0 + 0.4 * Math.sin(t * Math.PI));
          });

          renderer.render(scene, camera);

          if (animate || Math.abs(p.velocityX) > 0.0001 || Math.abs(p.targetAngleY - p.angleY) > 0.0005) {
            schedule();
          }
        }

        requestRender.current = schedule;

        function resize() {
          const bounds = root!.getBoundingClientRect();
          if (bounds.width <= 0 || bounds.height <= 0) return;
          renderer.setSize(bounds.width, bounds.height, false);
          camera.aspect = bounds.width / bounds.height;
          camera.updateProjectionMatrix();
          schedule();
        }

        // Pointer Drag Controls (Mouse & Touch with Damping)
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
            // pointer capture detached
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
            // released
          }
          schedule();
        }

        function onPointerLeave() {
          const p = physics.current;
          p.pointerHoverX = 0;
          p.pointerHoverY = 0;
          schedule();
        }

        function onVisibility() {
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

        function onGlobalMotion(event: Event) {
          globalPaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused);
          schedule();
        }

        function onContextLost(event: Event) {
          event.preventDefault();
          contextLost = true;
          cancelAnimationFrame(raf);
          raf = 0;
          if (!disposed) setReady(false);
        }

        function onContextRestored() {
          contextLost = false;
          setReady(true);
          schedule();
        }

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

        const sizing = new ResizeObserver(resize);
        sizing.observe(root!);

        canvas!.addEventListener('pointerdown', onPointerDown);
        canvas!.addEventListener('pointermove', onPointerMove, { passive: true });
        canvas!.addEventListener('pointerup', onPointerUp);
        canvas!.addEventListener('pointercancel', onPointerUp);
        root!.addEventListener('pointerleave', onPointerLeave);
        document.addEventListener('visibilitychange', onVisibility);
        media.addEventListener('change', onMotion);
        document.addEventListener('shakti:motion', onGlobalMotion);
        canvas!.addEventListener('webglcontextlost', onContextLost);
        canvas!.addEventListener('webglcontextrestored', onContextRestored);

        cleanup = () => {
          cancelAnimationFrame(raf);
          observer.disconnect();
          sizing.disconnect();
          canvas!.removeEventListener('pointerdown', onPointerDown);
          canvas!.removeEventListener('pointermove', onPointerMove);
          canvas!.removeEventListener('pointerup', onPointerUp);
          canvas!.removeEventListener('pointercancel', onPointerUp);
          root!.removeEventListener('pointerleave', onPointerLeave);
          document.removeEventListener('visibilitychange', onVisibility);
          media.removeEventListener('change', onMotion);
          document.removeEventListener('shakti:motion', onGlobalMotion);
          canvas!.removeEventListener('webglcontextlost', onContextLost);
          canvas!.removeEventListener('webglcontextrestored', onContextRestored);
          requestRender.current = null;

          const geometries = new Set<import('three').BufferGeometry>();
          const materials = new Set<import('three').Material>();
          scene.traverse((object) => {
            const drawable = object as import('three').Mesh;
            if (drawable.geometry) geometries.add(drawable.geometry);
            if (drawable.material) {
              (Array.isArray(drawable.material) ? drawable.material : [drawable.material]).forEach((m) =>
                materials.add(m)
              );
            }
          });
          geometries.forEach((g) => g.dispose());
          materials.forEach((m) => m.dispose());
          screenTexture.dispose();
          renderer.dispose();
        };

        resize();
        setReady(true);
      } catch {
        if (!disposed) setReady(false);
        cleanup?.();
      }
    }

    const lazy = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          void start();
          lazy.disconnect();
        }
      },
      { rootMargin: '120px' }
    );
    lazy.observe(root);

    return () => {
      disposed = true;
      lazy.disconnect();
      cleanup?.();
    };
  }, []);

  function rotate(direction: number) {
    physics.current.targetAngleY += direction * 0.35;
    requestRender.current?.();
  }

  return (
    <div className="s-sculpture" ref={rootRef}>
      <div className="s-sculpture-grid" aria-hidden="true" />
      <div className="s-sculpture-orbit" aria-hidden="true" />
      <div className="s-sculpture-top">
        <span>YOUR TRUSTED CIRCLE</span>
        <span>3D / INTERACTIVE NETWORK</span>
      </div>
      <div className="s-sculpture-fallback" hidden={ready} aria-hidden="true">
        <div>
          <span>SHAKTI</span>
          <strong>One signal.<br />Your people.</strong>
          <i />
          <i />
          <i />
        </div>
      </div>
      <canvas
        ref={canvasRef}
        aria-hidden="true"
        style={{ cursor: 'grab', touchAction: 'none' }}
      />
      <span className="s-node-label s-node-left">01 / trusted contact</span>
      <span className="s-node-label s-node-right">02 / guardian browser</span>
      <span className="s-node-label s-node-bottom">03 / your community</span>
      <div className="s-sculpture-bottom">
        <p>Interactive 3D network model. Drag to inspect nodes.</p>
        <div role="group" aria-label="Control the 3D illustration">
          <button
            type="button"
            aria-label="Rotate illustration left"
            onClick={() => rotate(-1)}
          >
            <ArrowLeft size={15} />
          </button>
          <button
            type="button"
            aria-label={paused ? 'Play illustration' : 'Pause illustration'}
            onClick={() => setPaused((value) => !value)}
          >
            {paused ? <Play size={14} /> : <Pause size={14} />}
          </button>
          <button
            type="button"
            aria-label="Rotate illustration right"
            onClick={() => rotate(1)}
          >
            <ArrowRight size={15} />
          </button>
        </div>
      </div>
    </div>
  );
}
