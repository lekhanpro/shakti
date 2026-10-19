import { assert, assertEquals, assertMatch, assertNotEquals } from "@std/assert";
import { fakeAuth, fakeEnv, fakeFetch, fakeRateLimit, post, USER_A, USER_B } from "../_shared/testing.ts";
import type { AuthUser } from "../_shared/types.ts";
import {
  CODE_RE,
  generateCode,
  handle,
  type InviteDb,
  type InviteDeps,
  type InviteRow,
  MAX_PENDING,
  normalizeCode,
} from "./handler.ts";

const URL_ = "http://localhost/functions/v1/guardian-invite";
const NOW = new Date("2026-09-29T10:00:00Z");

function memoryDb() {
  const rows: InviteRow[] = [];
  let n = 0;
  const db: InviteDb = {
    countPending: (owner, now) =>
      Promise.resolve(
        rows.filter((r) => r.owner_id === owner && r.status === "PENDING" && Date.parse(r.expires_at) > now.getTime())
          .length,
      ),
    insert(row) {
      if (rows.some((r) => r.code === row.code)) return Promise.resolve(null);
      const r: InviteRow = {
        id: `00000000-0000-4000-8000-${String(++n).padStart(12, "0")}`,
        guardian_user_id: null,
        status: "PENDING",
        revoked_at: null,
        ...row,
      };
      rows.push(r);
      return Promise.resolve(r);
    },
    findByCode: (code) => Promise.resolve(rows.find((r) => r.code === code) ?? null),
    findById: (id) => Promise.resolve(rows.find((r) => r.id === id) ?? null),
    accept(id, g) {
      const r = rows.find((x) => x.id === id && x.status === "PENDING");
      if (!r) return Promise.resolve(false);
      r.status = "ACCEPTED";
      r.guardian_user_id = g;
      return Promise.resolve(true);
    },
    revoke(id, now) {
      const r = rows.find((x) => x.id === id)!;
      r.status = "REVOKED";
      r.revoked_at = now.toISOString();
      return Promise.resolve();
    },
    hasActiveLink: (o, g) =>
      Promise.resolve(rows.some((r) => r.owner_id === o && r.guardian_user_id === g && r.status === "ACCEPTED")),
    displayName: () => Promise.resolve("Priya Sharma"),
  };
  return { db, rows };
}

function deps(user: AuthUser, store = memoryDb(), now = NOW): InviteDeps & { store: ReturnType<typeof memoryDb> } {
  return {
    env: fakeEnv(),
    fetch: fakeFetch(() => new Response()).fn,
    auth: fakeAuth(user),
    rateLimit: fakeRateLimit().fn,
    db: store.db,
    now: () => now,
    store,
  };
}

async function create(d: InviteDeps) {
  const res = await handle(post(URL_, { action: "create" }), d);
  assertEquals(res.status, 200);
  return await res.json() as { id: string; code: string; expires_at: string };
}

Deno.test("invite: 401 without a user", async () => {
  const res = await handle(post(URL_, { action: "create" }, { auth: null }), deps(USER_A));
  assertEquals(res.status, 401);
});

Deno.test("invite: 400 on malformed JSON and unknown action", async () => {
  const d = deps(USER_A);
  assertEquals((await handle(post(URL_, "nope", { raw: true }), d)).status, 400);
  assertEquals((await handle(post(URL_, { action: "steal" }), d)).status, 400);
});

Deno.test("invite: create returns an 8-char Crockford code valid for 7 days", async () => {
  const inv = await create(deps(USER_A));
  assertMatch(inv.code, /^[0-9A-HJKMNP-TV-Z]{8}$/);
  assertEquals(Date.parse(inv.expires_at) - NOW.getTime(), 7 * 24 * 3600 * 1000);
});

Deno.test("invite: generateCode never emits ambiguous letters I, L, O, U", () => {
  for (let i = 0; i < 2000; i++) {
    const c = generateCode();
    assertMatch(c, CODE_RE);
    assert(!/[ILOU]/.test(c));
  }
  // All-ones and all-zeros bytes map to the ends of the alphabet.
  assertEquals(generateCode((n) => new Uint8Array(n).fill(255)), "ZZZZZZZZ");
  assertEquals(generateCode((n) => new Uint8Array(n)), "00000000");
});

Deno.test("invite: create retries on a code collision", async () => {
  const d = deps(USER_A);
  let call = 0;
  d.random = (n) => new Uint8Array(n).fill(call++ < 2 ? 7 : 9);
  const first = await create(d);
  const second = await create(d);
  assertNotEquals(first.code, second.code);
});

Deno.test("invite: open invites are capped", async () => {
  const d = deps(USER_A);
  for (let i = 0; i < MAX_PENDING; i++) await create(d);
  const res = await handle(post(URL_, { action: "create" }), d);
  assertEquals(res.status, 409);
});

Deno.test("invite: owner cannot accept their own invite", async () => {
  const d = deps(USER_A);
  const inv = await create(d);
  const res = await handle(post(URL_, { action: "accept", code: inv.code }), d);
  assertEquals(res.status, 400);
  assertEquals((await res.json()).code, "SELF_ACCEPT");
  assertEquals(d.store.rows[0].status, "PENDING");
});

Deno.test("invite: another user accepts, lowercase and hyphenated input is normalised", async () => {
  const store = memoryDb();
  const inv = await create(deps(USER_A, store));
  const typed = `${inv.code.slice(0, 4)}-${inv.code.slice(4)}`.toLowerCase();
  const res = await handle(post(URL_, { action: "accept", code: typed }), deps(USER_B, store));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { id: inv.id, owner_id: USER_A.id, owner_name: "Priya", status: "ACCEPTED" });
  assertEquals(store.rows[0].guardian_user_id, USER_B.id);
});

Deno.test("invite: a used code cannot be accepted twice", async () => {
  const store = memoryDb();
  const inv = await create(deps(USER_A, store));
  await handle(post(URL_, { action: "accept", code: inv.code }), deps(USER_B, store));
  const third: AuthUser = { id: "33333333-3333-4333-8333-333333333333" };
  const res = await handle(post(URL_, { action: "accept", code: inv.code }), deps(third, store));
  assertEquals(res.status, 404);
});

Deno.test("invite: expired codes return 410", async () => {
  const store = memoryDb();
  const inv = await create(deps(USER_A, store));
  const later = new Date(NOW.getTime() + 8 * 24 * 3600 * 1000);
  const res = await handle(post(URL_, { action: "accept", code: inv.code }), deps(USER_B, store, later));
  assertEquals(res.status, 410);
});

Deno.test("invite: unknown and malformed codes", async () => {
  const d = deps(USER_B);
  assertEquals((await handle(post(URL_, { action: "accept", code: "ZZZZZZZZ" }), d)).status, 404);
  assertEquals((await handle(post(URL_, { action: "accept", code: "short" }), d)).status, 400);
  assertEquals((await handle(post(URL_, { action: "accept", code: 12345678 }), d)).status, 400);
});

Deno.test("invite: revoke by owner; strangers get 404; bad id is 400", async () => {
  const store = memoryDb();
  const inv = await create(deps(USER_A, store));
  const stranger: AuthUser = { id: "44444444-4444-4444-8444-444444444444" };
  assertEquals((await handle(post(URL_, { action: "revoke", id: inv.id }), deps(stranger, store))).status, 404);
  assertEquals((await handle(post(URL_, { action: "revoke", id: "not-a-uuid" }), deps(USER_A, store))).status, 400);
  const res = await handle(post(URL_, { action: "revoke", id: inv.id }), deps(USER_A, store));
  assertEquals(res.status, 200);
  assertEquals(store.rows[0].status, "REVOKED");
  // Revoked codes can no longer be accepted.
  assertEquals((await handle(post(URL_, { action: "accept", code: inv.code }), deps(USER_B, store))).status, 404);
});

Deno.test("invite: guardian can step down (revoke) after accepting", async () => {
  const store = memoryDb();
  const inv = await create(deps(USER_A, store));
  await handle(post(URL_, { action: "accept", code: inv.code }), deps(USER_B, store));
  const res = await handle(post(URL_, { action: "revoke", id: inv.id }), deps(USER_B, store));
  assertEquals(res.status, 200);
});

Deno.test("invite: 429 when rate limited", async () => {
  const d = deps(USER_A);
  d.rateLimit = () => Promise.resolve({ allowed: false, count: 21, retryAfterSec: 3600 });
  const res = await handle(post(URL_, { action: "create" }), d);
  assertEquals(res.status, 429);
});

Deno.test("normalizeCode maps O->0 and I/L->1", () => {
  assertEquals(normalizeCode("abco-ilxy"), "ABC0-11XY".replace("-", ""));
  assertEquals(normalizeCode("abcu1234"), null); // U is not in the alphabet
  assertEquals(normalizeCode(null), null);
});
