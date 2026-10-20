'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Pause, Play } from 'lucide-react';

/** Procedural WebGL: no remote textures, user data, location access, or live alerts. */
export function GuardianSculpture() {
  const rootRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRender = useRef<(() => void) | null>(null);
  const controls = useRef({ paused: false, angle: 0, pointerX: 0, pointerY: 0 });
  const [paused, setPaused] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    controls.current.paused = paused;
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
        const renderer = new THREE.WebGLRenderer({ canvas: canvas!, antialias: true, alpha: true, powerPreference: 'low-power' });
        renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 50);
        camera.position.set(0, 0.3, 7.4);
        const sculpture = new THREE.Group();
        sculpture.rotation.z = -0.12;
        scene.add(sculpture);
        scene.add(new THREE.AmbientLight(0xc4b5fd, 1.3));
        const key = new THREE.DirectionalLight(0xe5fff4, 3);
        key.position.set(3, 4, 5);
        scene.add(key);
        const rim = new THREE.PointLight(0x8b7bff, 35);
        rim.position.set(-3, -1, 2);
        scene.add(rim);

        const rounded = new THREE.Shape();
        const w = 0.83, h = 1.53, r = 0.2;
        rounded.moveTo(-w + r, -h);
        rounded.lineTo(w - r, -h);
        rounded.quadraticCurveTo(w, -h, w, -h + r);
        rounded.lineTo(w, h - r);
        rounded.quadraticCurveTo(w, h, w - r, h);
        rounded.lineTo(-w + r, h);
        rounded.quadraticCurveTo(-w, h, -w, h - r);
        rounded.lineTo(-w, -h + r);
        rounded.quadraticCurveTo(-w, -h, -w + r, -h);
        const body = new THREE.Mesh(new THREE.ExtrudeGeometry(rounded, { depth: 0.14, bevelEnabled: true, bevelSegments: 3, steps: 1, bevelSize: 0.07, bevelThickness: 0.07 }), new THREE.MeshStandardMaterial({ color: 0x191b30, metalness: 0.72, roughness: 0.28 }));
        body.rotation.y = -0.23;
        sculpture.add(body);
        const face = new THREE.Mesh(new THREE.PlaneGeometry(1.5, 2.82), new THREE.MeshStandardMaterial({ color: 0x21213c, metalness: 0.28, roughness: 0.55 }));
        face.position.z = 0.23;
        body.add(face);
        const island = new THREE.Mesh(new THREE.CapsuleGeometry(0.045, 0.28, 4, 12), new THREE.MeshBasicMaterial({ color: 0x080912 }));
        island.rotation.z = Math.PI / 2;
        island.position.set(0, 1.27, 0.25);
        body.add(island);
        const core = new THREE.Mesh(new THREE.IcosahedronGeometry(0.37, 1), new THREE.MeshStandardMaterial({ color: 0xb8e8d7, emissive: 0x378c79, emissiveIntensity: 0.5, metalness: 0.25, roughness: 0.2 }));
        core.position.set(0, 0.2, 0.38);
        body.add(core);
        [0.59, 0.78].forEach((radius) => {
          const ring = new THREE.Mesh(new THREE.TorusGeometry(radius, 0.009, 8, 90), new THREE.MeshBasicMaterial({ color: 0xb0a1ff, transparent: true, opacity: 0.7 }));
          ring.position.set(0, 0.2, 0.3);
          body.add(ring);
        });

        const orbit = new THREE.Group();
        sculpture.add(orbit);
        [1.95, 2.3].forEach((radius, index) => {
          const ring = new THREE.Mesh(new THREE.TorusGeometry(radius, 0.012, 8, 128), new THREE.MeshBasicMaterial({ color: index ? 0xb0a1ff : 0xb8e8d7, transparent: true, opacity: 0.4 }));
          ring.rotation.set(1.05 + index * 0.35, index * 0.6, index * 0.7);
          orbit.add(ring);
        });

        const points = [
          new THREE.Vector3(-2.05, 0.78, 0.45),
          new THREE.Vector3(1.95, 0.9, 0.05),
          new THREE.Vector3(1.55, -1.2, 0.5),
        ];
        const packets: { mesh: import('three').Mesh; curve: import('three').QuadraticBezierCurve3 }[] = [];
        points.forEach((point, index) => {
          const material = new THREE.MeshStandardMaterial({ color: index === 1 ? 0xc7baff : 0xb8e8d7, emissive: 0x204c45, metalness: 0.6, roughness: 0.25 });
          const node = new THREE.Mesh(new THREE.OctahedronGeometry(0.2, 0), material);
          node.position.copy(point);
          sculpture.add(node);
          const curve = new THREE.QuadraticBezierCurve3(new THREE.Vector3(0, 0.2, 0.45), point.clone().multiplyScalar(0.5).add(new THREE.Vector3(0, 0.6, 0.5)), point);
          sculpture.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(curve.getPoints(48)), new THREE.LineBasicMaterial({ color: index === 1 ? 0xc7baff : 0xb8e8d7, transparent: true, opacity: 0.48 })));
          const packet = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 8), new THREE.MeshBasicMaterial({ color: 0xecfff7 }));
          sculpture.add(packet);
          packets.push({ mesh: packet, curve });
        });

        let raf = 0;
        let inView = true;
        let reduced = media.matches;
        let visible = !document.hidden;
        let globalPaused = document.querySelector<HTMLElement>('.shakti-site')?.dataset.motion === 'paused';
        let contextLost = false;
        let last = 0;
        let time = 0;
        function schedule() {
          if (!disposed && !contextLost && !raf && visible && inView) raf = requestAnimationFrame(draw);
        }
        function draw(now: number) {
          raf = 0;
          if (disposed || !visible || !inView) return;
          const animate = !reduced && !globalPaused && !controls.current.paused;
          if (animate && now - last < 32) { schedule(); return; }
          if (animate) time += Math.min((now - (last || now)) / 1000, 0.08);
          last = now;
          const pointer = controls.current;
          sculpture.rotation.y = pointer.angle + (reduced ? 0 : pointer.pointerX * 0.16);
          sculpture.rotation.x = reduced ? 0 : pointer.pointerY * -0.08;
          sculpture.position.y = animate ? Math.sin(time * 0.8) * 0.07 : 0;
          core.rotation.y = time * 0.4;
          core.rotation.z = time * 0.2;
          orbit.rotation.y = time * 0.07;
          packets.forEach(({ mesh, curve }, index) => mesh.position.copy(curve.getPoint((time * 0.18 + index / 3) % 1)));
          renderer.render(scene, camera);
          if (animate) schedule();
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
        function onPointer(event: PointerEvent) {
          if (reduced || event.pointerType === 'touch') return;
          const bounds = root!.getBoundingClientRect();
          controls.current.pointerX = (event.clientX - bounds.left) / bounds.width - 0.5;
          controls.current.pointerY = (event.clientY - bounds.top) / bounds.height - 0.5;
          schedule();
        }
        function resetPointer() { controls.current.pointerX = 0; controls.current.pointerY = 0; schedule(); }
        function onVisibility() { visible = !document.hidden; last = 0; if (visible) schedule(); else { cancelAnimationFrame(raf); raf = 0; } }
        function onMotion() { reduced = media.matches; schedule(); }
        function onGlobalMotion(event: Event) { globalPaused = Boolean((event as CustomEvent<{ paused: boolean }>).detail.paused); schedule(); }
        function onContextLost(event: Event) { event.preventDefault(); contextLost = true; cancelAnimationFrame(raf); raf = 0; if (!disposed) setReady(false); }
        const observer = new IntersectionObserver(([entry]) => { inView = entry.isIntersecting; last = 0; if (inView) schedule(); else { cancelAnimationFrame(raf); raf = 0; } });
        observer.observe(root!);
        const sizing = new ResizeObserver(resize);
        sizing.observe(root!);
        root!.addEventListener('pointermove', onPointer, { passive: true });
        root!.addEventListener('pointerleave', resetPointer);
        document.addEventListener('visibilitychange', onVisibility);
        media.addEventListener('change', onMotion);
        document.addEventListener('shakti:motion', onGlobalMotion);
        canvas!.addEventListener('webglcontextlost', onContextLost);
        cleanup = () => {
          cancelAnimationFrame(raf);
          observer.disconnect();
          sizing.disconnect();
          root!.removeEventListener('pointermove', onPointer);
          root!.removeEventListener('pointerleave', resetPointer);
          document.removeEventListener('visibilitychange', onVisibility);
          media.removeEventListener('change', onMotion);
          document.removeEventListener('shakti:motion', onGlobalMotion);
          canvas!.removeEventListener('webglcontextlost', onContextLost);
          requestRender.current = null;
          const geometries = new Set<import('three').BufferGeometry>();
          const materials = new Set<import('three').Material>();
          scene.traverse((object) => {
            const drawable = object as import('three').Mesh;
            if (drawable.geometry) geometries.add(drawable.geometry);
            if (drawable.material) (Array.isArray(drawable.material) ? drawable.material : [drawable.material]).forEach((material) => materials.add(material));
          });
          geometries.forEach((geometry) => geometry.dispose());
          materials.forEach((material) => material.dispose());
          renderer.dispose();
        };
        resize();
        setReady(true);
      } catch {
        if (!disposed) setReady(false);
        cleanup?.();
      }
    }
    const lazy = new IntersectionObserver(([entry]) => { if (entry.isIntersecting) { void start(); lazy.disconnect(); } }, { rootMargin: '120px' });
    lazy.observe(root);
    return () => { disposed = true; lazy.disconnect(); cleanup?.(); };
  }, []);

  function rotate(direction: number) {
    controls.current.angle += direction * 0.25;
    requestRender.current?.();
  }

  return (
    <div className="s-sculpture" ref={rootRef}>
      <div className="s-sculpture-grid" aria-hidden="true" />
      <div className="s-sculpture-orbit" aria-hidden="true" />
      <div className="s-sculpture-top"><span>YOUR TRUSTED CIRCLE</span><span>3D / INTERACTIVE</span></div>
      <div className="s-sculpture-fallback" hidden={ready} aria-hidden="true"><div><span>SHAKTI</span><strong>One signal.<br />Your people.</strong><i /><i /><i /></div></div>
      <canvas ref={canvasRef} aria-hidden="true" />
      <span className="s-node-label s-node-left">01 / trusted contact</span>
      <span className="s-node-label s-node-right">02 / guardian browser</span>
      <span className="s-node-label s-node-bottom">03 / your community</span>
      <div className="s-sculpture-bottom">
        <p>Illustrated network. No live location data.</p>
        <div role="group" aria-label="Control the 3D illustration">
          <button type="button" aria-label="Rotate illustration left" onClick={() => rotate(-1)}><ArrowLeft size={15} /></button>
          <button type="button" aria-label={paused ? 'Play illustration' : 'Pause illustration'} onClick={() => setPaused((value) => !value)}>{paused ? <Play size={14} /> : <Pause size={14} />}</button>
          <button type="button" aria-label="Rotate illustration right" onClick={() => rotate(1)}><ArrowRight size={15} /></button>
        </div>
      </div>
    </div>
  );
}
