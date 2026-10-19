// emergency-dispatch: fan out an SOS (or "I'm safe") to Telegram and guardian push.
//
// Request  POST { action: 'sos'|'resolved',
//                 incident: { id, share_token, trigger_source, status?, latitude?, longitude?,
//                             street_address?, battery_level?, carrier_sms_dispatched?, covert?,
//                             resolved_at?, created_at },
//                 userName: string, telegramChatId?: string }
// Response 200 { telegram: number, push: number }
// Errors   { error, code } with 400/401/403/405/409/413/415/429

import { corsHeaders, preflight } from "../_shared/cors.ts";
import { sendPush } from "../_shared/fcm.ts";
import { HttpError, json, requireMethod, toErrorResponse } from "../_shared/http.ts";
import { escapeMarkdownV2, mdLink, sendTelegram } from "../_shared/telegram.ts";
import { formatIst } from "../_shared/time.ts";
import type { BaseDeps } from "../_shared/types.ts";
import {
  bad,
  clampString,
  isoTimestamp,
  isPlainObject,
  isShareToken,
  isTelegramChatId,
  isUuid,
  numberInRange,
  oneOf,
  optionalBoolean,
  readJsonObject,
} from "../_shared/validate.ts";

export const RATE_LIMIT = { bucket: "emergency-dispatch", limit: 30, windowSec: 600 } as const;

export const TRIGGER_SOURCES = [
  "HUD_TAP",
  "TRIPLE_POWER",
  "VOLUME_TRIPLE",
  "SHAKE",
  "VOICE_KEYWORD",
  "TIMER_EXPIRED",
  "DECOY_PIN",
] as const;
export type TriggerSource = typeof TRIGGER_SOURCES[number];

export const TRIGGER_LABELS: Record<TriggerSource, string> = {
  HUD_TAP: "SOS button",
  TRIPLE_POWER: "Power button x3",
  VOLUME_TRIPLE: "Volume key x3",
  SHAKE: "Shake or fall",
  VOICE_KEYWORD: "Voice keyword",
  TIMER_EXPIRED: "Escort timer expired",
  DECOY_PIN: "Duress PIN",
};

const STATUSES = ["COUNTDOWN", "ACTIVE", "RESOLVED", "FALSE_ALARM"] as const;
type Status = typeof STATUSES[number];

/** Columns of `incident_reports` this function writes (mirrors Incident.toRemoteJson()). */
export interface IncidentRow {
  id: string;
  share_token: string;
  trigger_source: TriggerSource;
  status: Status;
  latitude: number | null;
  longitude: number | null;
  street_address: string | null;
  battery_level: number | null;
  carrier_sms_dispatched: boolean;
  covert: boolean;
  resolved_at: string | null;
  created_at: string;
}

export type UpsertResult =
  /** Row now exists and belongs to the caller. `share_token` is the STORED token. */
  | { kind: "ok"; share_token: string }
  /** Row exists but belongs to someone else. */
  | { kind: "forbidden" }
  /** share_token collides with another incident. */
  | { kind: "conflict" };

export interface DispatchDb {
  /** Insert-if-absent, verify ownership, then apply mutable fields. Never changes owner or token. */
  upsertOwnedIncident(userId: string, row: IncidentRow): Promise<UpsertResult>;
  /** FCM tokens of accepted, non-revoked guardians of `ownerId`. */
  guardianPushTokens(ownerId: string): Promise<string[]>;
  markTelegramSent(incidentId: string): Promise<void>;
}

export interface DispatchDeps extends BaseDeps {
  db: DispatchDb;
}

export interface DispatchRequest {
  action: "sos" | "resolved";
  incident: IncidentRow;
  userName: string;
  telegramChatId?: string;
}

export function parseRequest(body: Record<string, unknown>, now: Date): DispatchRequest {
  const action = oneOf(body.action, "action", ["sos", "resolved"] as const);
  if (!isPlainObject(body.incident)) throw bad("incident must be an object");
  const i = body.incident;

  if (!isUuid(i.id)) throw bad("incident.id must be a UUID");
  if (!isShareToken(i.share_token)) throw bad("incident.share_token is invalid");

  const latitude = numberInRange(i.latitude, "incident.latitude", -90, 90, { optional: true }) ?? null;
  const longitude = numberInRange(i.longitude, "incident.longitude", -180, 180, { optional: true }) ?? null;
  if ((latitude === null) !== (longitude === null)) throw bad("incident.latitude and longitude go together");

  let status: Status;
  if (i.status === undefined || i.status === null) {
    status = action === "sos" ? "ACTIVE" : "RESOLVED";
  } else {
    status = oneOf(i.status, "incident.status", STATUSES);
  }
  // "resolved" must actually close the incident.
  if (action === "resolved" && (status === "ACTIVE" || status === "COUNTDOWN")) status = "RESOLVED";

  let telegramChatId: string | undefined;
  if (body.telegramChatId !== undefined && body.telegramChatId !== null && body.telegramChatId !== "") {
    if (!isTelegramChatId(body.telegramChatId)) throw bad("telegramChatId is invalid");
    telegramChatId = body.telegramChatId;
  }

  const incident: IncidentRow = {
    id: i.id.toLowerCase(),
    share_token: i.share_token,
    trigger_source: oneOf(i.trigger_source, "incident.trigger_source", TRIGGER_SOURCES),
    status,
    latitude,
    longitude,
    street_address: clampString(i.street_address, 300) || null,
    battery_level: numberInRange(i.battery_level, "incident.battery_level", 0, 100, {
      optional: true,
      integer: true,
    }) ?? null,
    carrier_sms_dispatched: optionalBoolean(i.carrier_sms_dispatched, "incident.carrier_sms_dispatched"),
    covert: optionalBoolean(i.covert, "incident.covert"),
    resolved_at: isoTimestamp(i.resolved_at, "incident.resolved_at", now, { optional: true }) ?? null,
    created_at: isoTimestamp(i.created_at, "incident.created_at", now)!,
  };

  return {
    action,
    incident,
    userName: clampString(body.userName, 60, "A Shakti user"),
    telegramChatId,
  };
}

/** Public tracker URL for a share token. Returns null if the base URL is unset or not http(s). */
export function trackerUrl(base: string | undefined, token: string): string | null {
  if (!base) return null;
  let u: URL;
  try {
    u = new URL(base);
  } catch {
    return null;
  }
  if (u.protocol !== "https:" && u.protocol !== "http:") return null;
  return `${base.replace(/\/+$/, "")}/track/${encodeURIComponent(token)}`;
}

export function mapsUrl(lat: number, lng: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${lat.toFixed(6)},${lng.toFixed(6)}`;
}

/** Builds the MarkdownV2 message. Every user-controlled value goes through escapeMarkdownV2. */
export function composeMessage(
  r: DispatchRequest,
  opts: { trackUrl: string | null; now: Date },
): string {
  const e = escapeMarkdownV2;
  const name = e(r.userName);
  const inc = r.incident;

  if (r.action === "resolved") {
    const lines = [
      `✅ *${name} marked themselves safe*`,
      `Time: ${e(formatIst(inc.resolved_at ?? opts.now.toISOString()))}`,
    ];
    if (inc.status === "FALSE_ALARM") lines.push(e("The alert was a false alarm."));
    return lines.join("\n");
  }

  const lines = [
    `🚨 *SHAKTI SOS: ${name} needs help*`,
    `Trigger: ${e(TRIGGER_LABELS[inc.trigger_source])}`,
    `Time: ${e(formatIst(inc.created_at))}`,
  ];
  if (inc.street_address) lines.push(`Address: ${e(inc.street_address)}`);
  if (inc.latitude !== null && inc.longitude !== null) {
    lines.push(
      `Location: ${e(`${inc.latitude.toFixed(5)}, ${inc.longitude.toFixed(5)}`)} ${
        mdLink("Open in Google Maps", mapsUrl(inc.latitude, inc.longitude))
      }`,
    );
  } else {
    lines.push(e("Location: not available yet"));
  }
  if (opts.trackUrl) lines.push(`Live tracker: ${mdLink(opts.trackUrl, opts.trackUrl)}`);
  if (inc.battery_level !== null) lines.push(`Battery: ${e(`${inc.battery_level}%`)}`);
  lines.push(e("If you cannot reach her, call 112."));
  return lines.join("\n");
}

/** Default chat ids (comma-separated in env) plus the validated body chat id, de-duplicated. */
export function chatTargets(envValue: string | undefined, fromBody: string | undefined): string[] {
  const set = new Set<string>();
  for (const raw of (envValue ?? "").split(",")) {
    const id = raw.trim();
    if (!id) continue;
    if (isTelegramChatId(id)) set.add(id);
    else console.warn("[emergency-dispatch] ignoring invalid TELEGRAM_DEFAULT_CHAT_ID entry");
  }
  if (fromBody) set.add(fromBody);
  return [...set];
}

export async function handle(req: Request, deps: DispatchDeps): Promise<Response> {
  const cors = corsHeaders(deps.env);
  const pre = preflight(req, deps.env);
  if (pre) return pre;

  try {
    requireMethod(req, "POST");
    const user = await deps.auth(req);
    const now = deps.now?.() ?? new Date();
    const parsed = parseRequest(await readJsonObject(req, 32 * 1024), now);

    const rl = await deps.rateLimit(user.id, RATE_LIMIT.bucket, RATE_LIMIT.limit, RATE_LIMIT.windowSec);
    if (!rl.allowed) {
      throw new HttpError(429, "Too many dispatches. SMS alerts are unaffected.", "RATE_LIMITED", {
        "Retry-After": String(rl.retryAfterSec),
      });
    }

    const up = await deps.db.upsertOwnedIncident(user.id, parsed.incident);
    if (up.kind === "forbidden") throw new HttpError(403, "This incident belongs to another user");
    if (up.kind === "conflict") throw new HttpError(409, "share_token already in use", "CONFLICT");

    const trackUrl = trackerUrl(deps.env("PUBLIC_TRACK_BASE_URL"), up.share_token);
    const text = composeMessage(parsed, { trackUrl, now });

    // Telegram and push run in parallel; neither can fail the request.
    const botToken = deps.env("TELEGRAM_BOT_TOKEN");
    const targets = botToken ? chatTargets(deps.env("TELEGRAM_DEFAULT_CHAT_ID"), parsed.telegramChatId) : [];

    const telegramP = Promise.all(targets.map((chat) => sendTelegram(botToken!, chat, text, deps.fetch)))
      .then((r) => r.filter(Boolean).length);

    const pushP = (async () => {
      if (!deps.env("FCM_SERVICE_ACCOUNT")) return 0;
      try {
        const tokens = await deps.db.guardianPushTokens(user.id);
        const sos = parsed.action === "sos";
        return await sendPush(deps.env, tokens, {
          title: sos ? `SHAKTI SOS: ${parsed.userName} needs help` : `${parsed.userName} is safe`,
          body: sos
            ? (parsed.incident.street_address ?? TRIGGER_LABELS[parsed.incident.trigger_source])
            : "They marked themselves safe.",
          data: {
            type: sos ? "sos" : "resolved",
            incident_id: parsed.incident.id,
            ...(trackUrl ? { track_url: trackUrl } : {}),
          },
        }, deps.fetch, deps.now);
      } catch (e) {
        console.warn(`[emergency-dispatch] push skipped: ${e instanceof Error ? e.name : "error"}`);
        return 0;
      }
    })();

    const [telegram, push] = await Promise.all([telegramP, pushP]);

    if (telegram > 0 && parsed.action === "sos") {
      await deps.db.markTelegramSent(parsed.incident.id).catch((e) =>
        console.warn(`[emergency-dispatch] could not set telegram_broadcast_sent: ${e instanceof Error ? e.name : "error"}`)
      );
    }

    return json({ telegram, push }, 200, cors);
  } catch (e) {
    return toErrorResponse(e, cors, "emergency-dispatch");
  }
}
