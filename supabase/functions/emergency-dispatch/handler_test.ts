import { assert, assertEquals, assertFalse, assertStringIncludes } from "@std/assert";
import { escapeMarkdownV2 } from "../_shared/telegram.ts";
import { fakeAuth, fakeEnv, fakeFetch, fakeRateLimit, jsonResponse, post, USER_A, USER_B } from "../_shared/testing.ts";
import {
  chatTargets,
  type DispatchDb,
  type DispatchDeps,
  handle,
  type IncidentRow,
  trackerUrl,
  type UpsertResult,
} from "./handler.ts";

const URL_ = "http://localhost/functions/v1/emergency-dispatch";
const NOW = new Date("2026-09-29T10:00:00Z");
const INCIDENT_ID = "9b2f7c1e-3a4d-4e5f-8a6b-7c8d9e0f1a2b";
const TOKEN = "AbCdEfGhJkMnPqRsTuVwXyZ2";

function fakeDb(opts: { ownerOf?: Record<string, string>; tokens?: string[]; conflict?: boolean } = {}) {
  const rows = new Map<string, IncidentRow & { user_id: string; telegram_broadcast_sent: boolean }>();
  for (const [id, owner] of Object.entries(opts.ownerOf ?? {})) {
    rows.set(id, {
      id,
      user_id: owner,
      share_token: "StoredTokenOfOtherUser_1",
      trigger_source: "HUD_TAP",
      status: "ACTIVE",
      latitude: null,
      longitude: null,
      street_address: null,
      battery_level: null,
      carrier_sms_dispatched: false,
      covert: false,
      resolved_at: null,
      created_at: NOW.toISOString(),
      telegram_broadcast_sent: false,
    });
  }
  const guardianCalls: string[] = [];
  const db: DispatchDb = {
    upsertOwnedIncident(userId, row): Promise<UpsertResult> {
      if (opts.conflict) return Promise.resolve({ kind: "conflict" });
      const existing = rows.get(row.id);
      if (existing && existing.user_id !== userId) return Promise.resolve({ kind: "forbidden" });
      if (!existing) {
        rows.set(row.id, { ...row, user_id: userId, telegram_broadcast_sent: false });
      } else {
        Object.assign(existing, { status: row.status, latitude: row.latitude, longitude: row.longitude });
      }
      return Promise.resolve({ kind: "ok", share_token: rows.get(row.id)!.share_token });
    },
    guardianPushTokens(ownerId) {
      guardianCalls.push(ownerId);
      return Promise.resolve(opts.tokens ?? []);
    },
    markTelegramSent(id) {
      const r = rows.get(id);
      if (r) r.telegram_broadcast_sent = true;
      return Promise.resolve();
    },
  };
  return { db, rows, guardianCalls };
}

function setup(opts: {
  env?: Record<string, string>;
  db?: ReturnType<typeof fakeDb>;
  telegram?: (url: string, init: RequestInit) => Response | Promise<Response>;
} = {}) {
  const http = fakeFetch(opts.telegram ?? (() => jsonResponse({ ok: true, result: {} })));
  const rl = fakeRateLimit();
  const store = opts.db ?? fakeDb();
  const deps: DispatchDeps = {
    env: fakeEnv({
      TELEGRAM_BOT_TOKEN: "123456:SECRET_BOT",
      TELEGRAM_DEFAULT_CHAT_ID: "-100200300",
      PUBLIC_TRACK_BASE_URL: "https://shakti.example/",
      ...opts.env,
    }),
    fetch: http.fn,
    auth: fakeAuth(),
    rateLimit: rl.fn,
    db: store.db,
    now: () => NOW,
  };
  return { deps, http, rl, store };
}

function body(over: Record<string, unknown> = {}, incidentOver: Record<string, unknown> = {}) {
  return {
    action: "sos",
    userName: "Priya Sharma",
    incident: {
      id: INCIDENT_ID,
      share_token: TOKEN,
      trigger_source: "TRIPLE_POWER",
      status: "ACTIVE",
      latitude: 28.613939,
      longitude: 77.209023,
      street_address: "Connaught Place, New Delhi",
      battery_level: 41,
      carrier_sms_dispatched: true,
      covert: false,
      resolved_at: null,
      created_at: "2026-09-29T09:58:00.000Z",
      ...incidentOver,
    },
    ...over,
  };
}

function telegramTexts(http: ReturnType<typeof fakeFetch>): string[] {
  return http.requests
    .filter((r) => r.url.startsWith("https://api.telegram.org/"))
    .map((r) => (r.body as { text: string }).text);
}

Deno.test("dispatch: 401 without a user", async () => {
  const { deps, http } = setup();
  const res = await handle(post(URL_, body(), { auth: null }), deps);
  assertEquals(res.status, 401);
  assertEquals(http.requests.length, 0);
});

Deno.test("dispatch: 400 on malformed JSON", async () => {
  const { deps } = setup();
  const res = await handle(post(URL_, "{\"action\":", { raw: true }), deps);
  assertEquals(res.status, 400);
});

Deno.test("dispatch: 400 on a bad incident UUID", async () => {
  const { deps, http } = setup();
  const res = await handle(post(URL_, body({}, { id: "1; drop table incident_reports" })), deps);
  assertEquals(res.status, 400);
  const text = await res.text();
  assertFalse(text.includes("drop table"));
  assertEquals(http.requests.length, 0);
});

Deno.test("dispatch: 400 on a short share_token", async () => {
  const { deps } = setup();
  const res = await handle(post(URL_, body({}, { share_token: "short" })), deps);
  assertEquals(res.status, 400);
});

Deno.test("dispatch: 400 on unknown trigger_source and action", async () => {
  const { deps } = setup();
  assertEquals((await handle(post(URL_, body({}, { trigger_source: "PANIC" })), deps)).status, 400);
  assertEquals((await handle(post(URL_, body({ action: "nuke" })), deps)).status, 400);
});

Deno.test("dispatch: 400 on an invalid telegramChatId", async () => {
  const { deps } = setup();
  const res = await handle(post(URL_, body({ telegramChatId: "123; rm -rf" })), deps);
  assertEquals(res.status, 400);
});

Deno.test("dispatch: location may be missing", async () => {
  const { deps, http } = setup();
  const res = await handle(post(URL_, body({}, { latitude: null, longitude: null, street_address: null })), deps);
  assertEquals(res.status, 200);
  const [text] = telegramTexts(http);
  assertStringIncludes(text, "not available yet");
  assertFalse(text.includes("google.com/maps"));
});

Deno.test("dispatch: 403 when the incident belongs to another user", async () => {
  const store = fakeDb({ ownerOf: { [INCIDENT_ID]: USER_B.id } });
  const { deps, http } = setup({ db: store });
  const res = await handle(post(URL_, body()), deps);
  assertEquals(res.status, 403);
  assertEquals(telegramTexts(http).length, 0);
  assertEquals(store.rows.get(INCIDENT_ID)!.user_id, USER_B.id);
  assertEquals(store.rows.get(INCIDENT_ID)!.status, "ACTIVE");
});

Deno.test("dispatch: 409 when share_token collides", async () => {
  const { deps } = setup({ db: fakeDb({ conflict: true }) });
  const res = await handle(post(URL_, body()), deps);
  assertEquals(res.status, 409);
});

Deno.test("dispatch: SOS creates the row, sends Telegram to default + body chat, sets the flag", async () => {
  const { deps, http, store, rl } = setup();
  const res = await handle(post(URL_, body({ telegramChatId: "@shakti_family" })), deps);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { telegram: 2, push: 0 });

  const row = store.rows.get(INCIDENT_ID)!;
  assertEquals(row.user_id, USER_A.id);
  assertEquals(row.telegram_broadcast_sent, true);

  const tg = http.requests.filter((r) => r.url.startsWith("https://api.telegram.org/"));
  assertEquals(tg.map((r) => (r.body as { chat_id: string }).chat_id), ["-100200300", "@shakti_family"]);
  for (const r of tg) {
    assertEquals((r.body as { parse_mode: string }).parse_mode, "MarkdownV2");
    assert(r.init.signal instanceof AbortSignal);
  }

  const text = (tg[0].body as { text: string }).text;
  assertStringIncludes(text, "🚨 *SHAKTI SOS: Priya Sharma needs help*");
  assertStringIncludes(text, "Power button x3");
  assertStringIncludes(text, "IST");
  assertStringIncludes(text, "Connaught Place, New Delhi");
  assertStringIncludes(text, "https://www.google.com/maps/search/?api=1&query=28.613939,77.209023");
  assertStringIncludes(text, `https://shakti.example/track/${TOKEN}`);
  assertStringIncludes(text, "41%");

  assertEquals(rl.calls[0], { userId: USER_A.id, bucket: "emergency-dispatch", limit: 30, windowSec: 600 });
});

Deno.test("dispatch: hostile name is MarkdownV2-escaped", async () => {
  const { deps, http } = setup();
  const res = await handle(post(URL_, body({ userName: "*_[evil](http://x)" })), deps);
  assertEquals(res.status, 200);
  const [text] = telegramTexts(http);
  assertStringIncludes(text, "\\*\\_\\[evil\\]\\(http://x\\)");
  assertFalse(text.includes("[evil](http://x)"));
});

Deno.test("dispatch: hostile address is escaped too", async () => {
  const { deps, http } = setup();
  await handle(post(URL_, body({}, { street_address: "[click](https://phish.example) `x` > #1!" })), deps);
  const [text] = telegramTexts(http);
  assertStringIncludes(text, "\\[click\\]\\(https://phish\\.example\\) \\`x\\` \\> \\#1\\!");
});

Deno.test("dispatch: resolved sends the safe message and marks the incident resolved", async () => {
  const { deps, http, store } = setup();
  await handle(post(URL_, body()), deps);
  const res = await handle(
    post(URL_, body({ action: "resolved" }, { status: "RESOLVED", resolved_at: "2026-09-29T09:59:30Z" })),
    deps,
  );
  assertEquals(res.status, 200);
  const texts = telegramTexts(http);
  assertStringIncludes(texts.at(-1)!, "✅ *Priya Sharma marked themselves safe*");
  assertEquals(store.rows.get(INCIDENT_ID)!.status, "RESOLVED");
});

Deno.test("dispatch: 'resolved' with an ACTIVE status still closes the incident", async () => {
  const { deps, store } = setup();
  await handle(post(URL_, body({ action: "resolved" }, { status: "ACTIVE" })), deps);
  assertEquals(store.rows.get(INCIDENT_ID)!.status, "RESOLVED");
});

Deno.test("dispatch: 429 after 30 dispatches in the window", async () => {
  const { deps } = setup();
  for (let i = 0; i < 30; i++) assertEquals((await handle(post(URL_, body()), deps)).status, 200);
  const res = await handle(post(URL_, body()), deps);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("Retry-After"), "600");
});

Deno.test("dispatch: Telegram failure never fails the request and leaves the flag false", async () => {
  const { deps, store } = setup({ telegram: () => jsonResponse({ ok: false, description: "chat not found" }, 400) });
  const res = await handle(post(URL_, body()), deps);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { telegram: 0, push: 0 });
  assertEquals(store.rows.get(INCIDENT_ID)!.telegram_broadcast_sent, false);
});

Deno.test("dispatch: no bot token means no Telegram calls", async () => {
  const { deps, http } = setup({ env: { TELEGRAM_BOT_TOKEN: "" } });
  const res = await handle(post(URL_, body({ telegramChatId: "12345" })), deps);
  assertEquals(await res.json(), { telegram: 0, push: 0 });
  assertEquals(http.requests.length, 0);
});

Deno.test("dispatch: push is skipped silently when FCM is not configured", async () => {
  const store = fakeDb({ tokens: ["device-token-aaaaaaaaaaaa"] });
  const { deps } = setup({ db: store });
  const res = await handle(post(URL_, body()), deps);
  assertEquals((await res.json()).push, 0);
  assertEquals(store.guardianCalls.length, 0);
});

Deno.test("dispatch: bad FCM_SERVICE_ACCOUNT json is a no-op", async () => {
  const store = fakeDb({ tokens: ["device-token-aaaaaaaaaaaa"] });
  const { deps, http } = setup({ db: store, env: { FCM_SERVICE_ACCOUNT: "{not json" } });
  const res = await handle(post(URL_, body()), deps);
  assertEquals((await res.json()).push, 0);
  assertFalse(http.requests.some((r) => r.url.includes("googleapis")));
});

Deno.test("dispatch: errors never leak the bot token", async () => {
  const { deps } = setup({ telegram: () => Promise.reject(new Error("connect to api.telegram.org/bot123456:SECRET_BOT failed")) });
  const res = await handle(post(URL_, body()), deps);
  assertEquals(res.status, 200);
  assertFalse((await res.text()).includes("SECRET_BOT"));
});

Deno.test("chatTargets de-duplicates and drops invalid env entries", () => {
  assertEquals(chatTargets(" -100200300, @family_group ,bad id,-100200300", "-100200300"), [
    "-100200300",
    "@family_group",
  ]);
  assertEquals(chatTargets(undefined, undefined), []);
});

Deno.test("trackerUrl rejects non-http bases and trims slashes", () => {
  assertEquals(trackerUrl("https://x.example//", TOKEN), `https://x.example/track/${TOKEN}`);
  assertEquals(trackerUrl("javascript:alert(1)", TOKEN), null);
  assertEquals(trackerUrl(undefined, TOKEN), null);
});

Deno.test("escapeMarkdownV2 escapes every special character and backslash", () => {
  const specials = "_*[]()~`>#+-=|{}.!\\";
  const escaped = escapeMarkdownV2(specials);
  assertEquals(escaped, [...specials].map((c) => `\\${c}`).join(""));
  assertEquals(escapeMarkdownV2("plain text 123"), "plain text 123");
});
