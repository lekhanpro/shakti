// Telegram Bot API helpers.
// MarkdownV2 reference: https://core.telegram.org/bots/api#markdownv2-style

const MDV2_SPECIAL = /[_*\[\]()~`>#+\-=|{}.!\\]/g;

/** Escapes every MarkdownV2 special character (and backslash) in plain text. */
export function escapeMarkdownV2(text: string): string {
  return text.replace(MDV2_SPECIAL, (c) => `\\${c}`);
}

/** Escapes the URL part of an inline link `[text](url)`: only `)` and `\` need it. */
export function escapeMarkdownV2Url(url: string): string {
  return url.replace(/[)\\]/g, (c) => `\\${c}`);
}

/** Builds a MarkdownV2 inline link from plain label text and an http(s) URL. */
export function mdLink(label: string, url: string): string {
  return `[${escapeMarkdownV2(label)}](${escapeMarkdownV2Url(url)})`;
}

export const TELEGRAM_TIMEOUT_MS = 5_000;

/**
 * Sends one MarkdownV2 message. Resolves true on `ok: true`, false on any
 * failure (timeout, HTTP error, Telegram error). Never throws and never logs
 * the bot token.
 */
export async function sendTelegram(
  token: string,
  chatId: string,
  text: string,
  fetchImpl: typeof fetch = fetch,
  timeoutMs = TELEGRAM_TIMEOUT_MS,
): Promise<boolean> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetchImpl(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: chatId,
        text,
        parse_mode: "MarkdownV2",
        disable_web_page_preview: true,
      }),
      signal: ctrl.signal,
    });
    if (!res.ok) {
      await res.body?.cancel();
      console.warn(`[telegram] send failed: HTTP ${res.status}`);
      return false;
    }
    const body = await res.json().catch(() => null) as { ok?: boolean } | null;
    return body?.ok === true;
  } catch (e) {
    console.warn(`[telegram] send failed: ${e instanceof Error ? e.name : "error"}`);
    return false;
  } finally {
    clearTimeout(timer);
  }
}
