import { assertEquals } from "@std/assert";
import { fakeEnv } from "../_shared/testing.ts";
import { handle, type TrackDeps } from "./handler.ts";

const TOKEN = "AbCdEfGhJkMnPqRsTuVwXyZ2";

function deps(known: Record<string, unknown> = { [TOKEN]: { status: "ACTIVE", first_name: "Asha" } }) {
  const calls: string[] = [];
  const d: TrackDeps = {
    env: fakeEnv(),
    track: (t) => {
      calls.push(t);
      return Promise.resolve(known[t] ?? null);
    },
  };
  return { d, calls };
}

Deno.test("track: GET with a valid token returns the RPC payload", async () => {
  const { d } = deps();
  const res = await handle(new Request(`http://x/track?token=${TOKEN}`), d);
  assertEquals(res.status, 200);
  assertEquals((await res.json()).first_name, "Asha");
  assertEquals(res.headers.get("Cache-Control"), "no-store");
});

Deno.test("track: POST {token} works", async () => {
  const { d } = deps();
  const res = await handle(
    new Request("http://x/track", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token: TOKEN }),
    }),
    d,
  );
  assertEquals(res.status, 200);
});

Deno.test("track: unknown and malformed tokens give the same 404; malformed never hits the DB", async () => {
  const { d, calls } = deps();
  const unknown = await handle(new Request("http://x/track?token=ZZZZZZZZZZZZZZZZZZZZZZZZ"), d);
  const malformed = await handle(new Request("http://x/track?token=%25"), d);
  const missing = await handle(new Request("http://x/track"), d);
  assertEquals([unknown.status, malformed.status, missing.status], [404, 404, 404]);
  assertEquals(await unknown.json(), await malformed.json());
  assertEquals(calls, ["ZZZZZZZZZZZZZZZZZZZZZZZZ"]);
});

Deno.test("track: DB error is a generic 500", async () => {
  const d: TrackDeps = { env: fakeEnv(), track: () => Promise.reject(new Error("relation secret_x")) };
  const res = await handle(new Request(`http://x/track?token=${TOKEN}`), d);
  assertEquals(res.status, 500);
  assertEquals((await res.json()).error, "Internal error");
});

Deno.test("track: DELETE is 405", async () => {
  const { d } = deps();
  assertEquals((await handle(new Request("http://x/track", { method: "DELETE" }), d)).status, 405);
});
