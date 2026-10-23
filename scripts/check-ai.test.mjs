import assert from 'node:assert/strict';
import test from 'node:test';
import { checkOnline, validateClientConfig } from './check-ai.mjs';

const sample = { SUPABASE_URL: 'https://project.supabase.co', SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_example' };

test('accepts public project configuration and rejects private provider keys', () => {
  assert.equal(validateClientConfig(sample).url, sample.SUPABASE_URL);
  assert.throws(() => validateClientConfig({ ...sample, GEMINI_API_KEY: 'private' }), /private/);
  assert.throws(() => validateClientConfig({ ...sample, SUPABASE_PUBLISHABLE_KEY: 'sb_secret_example' }), /public/);
});

test('only accepts anon legacy JWTs and HTTPS origins', () => {
  const jwt = (role) => `header.${Buffer.from(JSON.stringify({ role })).toString('base64url')}.signature`;
  assert.equal(validateClientConfig({ SUPABASE_URL: sample.SUPABASE_URL, SUPABASE_ANON_KEY: jwt('anon') }).key, jwt('anon'));
  assert.throws(() => validateClientConfig({ ...sample, SUPABASE_PUBLISHABLE_KEY: jwt('service_role') }), /public/);
  assert.throws(() => validateClientConfig({ ...sample, SUPABASE_URL: 'http://public.example.com' }), /HTTPS/);
  assert.throws(() => validateClientConfig({ ...sample, SUPABASE_URL: 'https://user:pass@project.supabase.co' }), /HTTPS/);
});

test('live check requires an existing test session and does not create users', async () => {
  let called = false;
  await assert.rejects(checkOnline(validateClientConfig(sample), { fetchImpl: () => { called = true; } }), /TEST_ACCESS_TOKEN/);
  assert.equal(called, false);
});

test('live check sends synthetic text without location or an emergency dispatch', async () => {
  await checkOnline(validateClientConfig(sample), { accessToken: 'session', fetchImpl: async (url, options) => {
    assert.match(url, /\/functions\/v1\/ai-guard$/);
    assert.equal(options.headers.Authorization, 'Bearer session');
    const body = JSON.parse(options.body);
    assert.equal(body.mode, 'chat');
    assert.equal(body.location, undefined);
    return Response.json({ content: 'Hello' });
  } });
});

test('upstream failure details do not leak through setup errors', async () => {
  await assert.rejects(checkOnline(validateClientConfig(sample), {
    accessToken: 'session', fetchImpl: async () => new Response('private provider key', { status: 502 }),
  }), (error) => error.message.includes('(502)') && !error.message.includes('private provider key'));
});
