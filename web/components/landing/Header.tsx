'use client';

import { useEffect, useRef, useState } from 'react';
import { ArrowUpRight, Download, Menu, X } from 'lucide-react';

const NAV_LINKS = [
  { href: '#story', label: 'Story' },
  { href: '#trigger', label: 'Trigger' },
  { href: '#network', label: 'Network' },
  { href: '#ai', label: 'AI guardian' },
  { href: '#helplines', label: 'Helplines' },
] as const;

export function LogoMark({ className = 'size-8' }: { className?: string }) {
  return (
    <span className={`motion-logo-mark ${className}`} aria-hidden="true">
      <span className="motion-logo-core" />
    </span>
  );
}

export function Header({ downloadHref }: { downloadHref: string }) {
  const [open, setOpen] = useState(false);
  const toggleRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpen(false);
        toggleRef.current?.focus();
      }
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open]);

  return (
    <header className="motion-header">
      <nav className="motion-header-nav" aria-label="Primary">
        <a href="#main" className="motion-brand"><LogoMark /><span>Shakti</span><small>/ safety network</small></a>
        <div className="motion-header-center"><span className="motion-header-index">00 / 06</span><span className="motion-header-line" /><span>always within reach</span></div>
        <div className="motion-header-actions">
          <a href="#trigger" className="motion-header-demo">Try it <ArrowUpRight size={15} aria-hidden="true" /></a>
          <a href={downloadHref} className="motion-header-download"><Download size={15} aria-hidden="true" /><span>Get the app</span></a>
          <button ref={toggleRef} type="button" className="motion-menu-button" aria-expanded={open} aria-controls="mobile-nav" onClick={() => setOpen((value) => !value)}>
            <span className="sr-only">{open ? 'Close menu' : 'Open menu'}</span>
            {open ? <X size={17} aria-hidden="true" /> : <Menu size={17} aria-hidden="true" />}
          </button>
        </div>
      </nav>
      {open ? <nav id="mobile-nav" className="motion-mobile-nav" aria-label="Primary, mobile"><p>Navigate the response</p><ul>{NAV_LINKS.map((link) => <li key={link.href}><a href={link.href} onClick={() => setOpen(false)}><span>{link.label}</span><ArrowUpRight size={16} aria-hidden="true" /></a></li>)}</ul></nav> : null}
    </header>
  );
}
