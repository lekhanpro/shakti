// Client configuration contains public Supabase values only. Provider secrets
// stay in Edge Function secrets and are never accepted by this script.
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

export function validateClientConfig(config) {
  if (!config || typeof config !== 'object' || Array.isArray(config)) {
    throw new Error('Build configuration must be a JSON object');
  }
  if (Object.keys(config).some((key) => /GROQ|GEMINI|OPENAI|SERVICE_ROLE|SECRET|TOKEN|PASSWORD/i.test(key))) {
    throw new Error('Remove private credentials from the app build configuration');
  }
  let base;
  try {
    base = new URL(config.SUPABASE_URL);
  } catch {
    throw new Error('Set SUPABASE_URL to your Supabase project URL');
  }
  const local = ['localhost', '127.0.0.1', '[::1]'].includes(base.hostname);
  if ((base.protocol !== 'https:' && !(local && base.protocol === 'http:')) ||
      base.username || base.password || base.search || base.hash || base.pathname !== '/') {
    throw new Error('SUPABASE_URL must be an HTTPS origin (HTTP is allowed only for localhost)');
  }
  if (/YOUR_PROJECT|example\./i.test(base.hostname)) {
    throw new Error('Replace the example SUPABASE_URL with your project URL');
  }
  const key = config.SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_ANON_KEY;
  if (typeof key !== 'string' || !key.trim()) {
    throw new Error('Set SUPABASE_PUBLISHABLE_KEY or the legacy SUPABASE_ANON_KEY');
  }
  let publicKey = /^sb_publishable_[A-Za-z0-9_-]+$/.test(key);
  if (!publicKey) {
    try {
      const claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString());
      publicKey = key.split('.').length === 3 && claims.role === 'anon';
    } catch { /* Invalid keys are rejected below without printing the value. */ }
  }
  if (!publicKey) throw new Error('Use a public publishable/anon key; never a service-role or provider key');
  return { url: base.origin, key };
}

export async function checkOnline(config, { accessToken, fetchImpl = fetch } = {}) {
  if (!accessToken) {
    throw new Error('Set SHAKTI_AI_TEST_ACCESS_TOKEN for an existing Supabase test user before --live');
  }
  let response;
  try {
    response = await fetchImpl(`${config.url}/functions/v1/ai-guard`, {
      method: 'POST',
      headers: { apikey: config.key, Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ mode: 'chat', messages: [{ role: 'user',
        content: 'Reply with a short greeting. This is a synthetic setup check, not an emergency.' }] }),
      signal: AbortSignal.timeout(35_000),
    });
  } catch {
    throw new Error('AI endpoint could not be reached within 35 seconds');
  }
  if (!response.ok) {
    const hints = {
      401: 'Test user session is missing/expired or belongs to another Supabase project',
      404: 'Deploy the ai-guard function to the configured Supabase project',
      429: 'Rate limit reached; wait before retrying',
      502: 'AI provider failed; check the server-side key, model and provider availability',
      503: 'AI provider is not configured on the server',
    };
    throw new Error(`AI check failed (${response.status}): ${hints[response.status] || 'Check Edge Function logs'}`);
  }
  let body;
  try { body = await response.json(); } catch { throw new Error('AI endpoint returned invalid JSON'); }
  if (typeof body?.content !== 'string' || !body.content.trim()) {
    throw new Error('AI endpoint returned no assistant response');
  }
  return true;
}

async function main() {
  const args = process.argv.slice(2);
  const configIndex = args.indexOf('--config');
  const file = configIndex === -1 ? 'app/.env.build.json' : args[configIndex + 1];
  if (!file) throw new Error('Pass a path after --config');
  let raw;
  try { raw = JSON.parse(await readFile(file, 'utf8')); } catch {
    throw new Error('Create a valid local build JSON from app/.env.build.json.example');
  }
  const config = validateClientConfig(raw);
  console.log('Public client configuration is valid. This alone does not verify hosted AI.');
  if (args.includes('--live')) {
    await checkOnline(config, { accessToken: process.env.SHAKTI_AI_TEST_ACCESS_TOKEN });
    console.log('Live AI replied successfully through the authenticated Edge Function. No SOS alert was sent.');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
