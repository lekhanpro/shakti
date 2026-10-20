import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
const { chromium, expect } = await import(process.env.PLAYWRIGHT_MODULE || '@playwright/test');

const origin = 'http://127.0.0.1:3100';
const server = spawn(process.execPath, ['node_modules/next/dist/bin/next', 'start', '--hostname', '127.0.0.1', '--port', '3100'], {
  stdio: 'inherit',
});
let browser;
try {
  let started = false;
  for (let attempt = 0; attempt < 60; attempt++) {
    if (server.exitCode !== null) throw new Error('Next.js exited before readiness');
    try {
      const response = await fetch(origin);
      if (response.ok) { started = true; break; }
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  if (!started) throw new Error('Next.js did not become ready');
  await mkdir('test-results', { recursive: true });
  browser = await chromium.launch();
  for (const [name, viewport, reducedMotion] of [
    ['desktop', { width: 1440, height: 1000 }, 'no-preference'],
    ['mobile-reduced-motion', { width: 390, height: 844 }, 'reduce'],
  ]) {
    const context = await browser.newContext({ viewport, reducedMotion });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', (error) => errors.push(error.message));
    await page.goto(origin, { waitUntil: 'domcontentloaded' });
    await expect(page.getByRole('heading', { level: 1 })).toContainText('Your people.');
    // Original product chapters remain reachable after the redesign.
    for (const id of ['story', 'trigger', 'network', 'features', 'map', 'ai', 'faq', 'download']) {
      await expect(page.locator('#' + id)).toHaveCount(1);
    }
    await page.getByRole('button', { name: /Alert/ }).click();
    await page.getByRole('button', { name: 'Internet connected', exact: true }).click();
    await expect(page.getByText('Queued', { exact: true })).toBeVisible();
    await expect(page.getByText('Android handoff · simulated, delivery unconfirmed')).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1);
    expect(overflow, name + ' must fit its viewport').toBe(false);
    await page.screenshot({ path: 'test-results/' + name + '.png', fullPage: true });
    await page.goto(origin + '/track/demo', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('body')).toContainText(/demo|simulat/i);
    expect(errors, name + ' must not throw browser errors').toEqual([]);
    await context.close();
  }
  const fallback = await browser.newContext({ reducedMotion: 'reduce' });
  await fallback.addInitScript(() => {
    const original = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type, ...args) {
      if (String(type).includes('webgl')) return null;
      return original.call(this, type, ...args);
    };
  });
  const page = await fallback.newPage();
  await page.goto(origin, { waitUntil: 'domcontentloaded' });
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Your people.');
  await expect(page.getByRole('link', { name: /Try the guardian demo/ }).first()).toBeVisible();
  await page.screenshot({ path: 'test-results/no-webgl.png', fullPage: true });
  await fallback.close();
} finally {
  await browser?.close();
  server.kill('SIGTERM');
}
