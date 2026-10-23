import { HttpError } from "./http.ts";
import type { EnvGetter } from "./types.ts";
import { isPlainObject } from "./validate.ts";

// Stable model verified against Google's model catalogue on 23 October 2026.
export const GEMINI_MODEL = "gemini-3.8-flash";
export const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";
export const GROQ_MODEL = "llama-3.3-70b-versatile";
export const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

export interface AiMessage {
  role: string;
  content: string;
}

export interface AiProvider {
  name: "gemini" | "groq";
  apiKey: string;
  model: string;
}

export function resolveAiProvider(env: EnvGetter): AiProvider {
  const name = env("AI_PROVIDER")?.trim().toLowerCase() || "gemini";
  if (name !== "gemini" && name !== "groq") {
    throw new HttpError(503, "The assistant provider is not configured.");
  }
  const apiKey = env(name === "gemini" ? "GEMINI_API_KEY" : "GROQ_API_KEY")?.trim();
  if (!apiKey) throw new HttpError(503, "The assistant is not configured.");
  const model = env(name === "gemini" ? "GEMINI_MODEL" : "GROQ_MODEL")?.trim() ||
    (name === "gemini" ? GEMINI_MODEL : GROQ_MODEL);
  // Keep model overrides in a path segment on the fixed provider host.
  if (!/^[a-zA-Z0-9._-]{1,120}$/.test(model)) {
    throw new HttpError(503, "The assistant model is not configured.");
  }
  return { name, apiKey, model };
}

export function aiProviderRequest(provider: AiProvider, messages: AiMessage[], mode: "chat" | "fir"): {
  url: string;
  headers: Record<string, string>;
  body: Record<string, unknown>;
} {
  if (provider.name === "groq") {
    return {
      url: GROQ_URL,
      headers: { Authorization: `Bearer ${provider.apiKey}`, "Content-Type": "application/json" },
      body: {
        model: provider.model,
        temperature: 0.4,
        max_completion_tokens: mode === "fir" ? 1800 : 700,
        messages,
      },
    };
  }
  const contents: Array<{ role: "user" | "model"; parts: Array<{ text: string }> }> = [];
  for (const message of messages.filter((m) => m.role !== "system")) {
    const role = message.role === "assistant" ? "model" : "user";
    // A bounded history can start halfway through an exchange.
    if (role === "model" && contents.length === 0) continue;
    const last = contents.at(-1);
    if (last?.role === role) last.parts.push({ text: message.content });
    else contents.push({ role, parts: [{ text: message.content }] });
  }
  return {
    url: `${GEMINI_BASE_URL}/${provider.model}:generateContent`,
    headers: { "x-goog-api-key": provider.apiKey, "Content-Type": "application/json" },
    body: {
      systemInstruction: {
        parts: messages.filter((m) => m.role === "system").map((m) => ({ text: m.content })),
      },
      contents,
      generationConfig: {
        maxOutputTokens: mode === "fir" ? 4096 : 2048,
        thinkingConfig: { thinkingLevel: "LOW", includeThoughts: false },
      },
      store: false,
    },
  };
}

export function aiProviderContent(provider: AiProvider, body: unknown): string | null {
  if (!isPlainObject(body)) return null;
  if (provider.name === "groq") {
    const choices = body.choices;
    const first = Array.isArray(choices) ? choices[0] : undefined;
    if (!isPlainObject(first) || first.finish_reason === "length" || !isPlainObject(first.message)) {
      return null;
    }
    return typeof first.message.content === "string" ? first.message.content.trim() || null : null;
  }
  const candidates = body.candidates;
  const first = Array.isArray(candidates) ? candidates[0] : undefined;
  if (!isPlainObject(first) || first.finishReason !== "STOP" || !isPlainObject(first.content)) return null;
  const parts = first.content.parts;
  if (!Array.isArray(parts)) return null;
  // Never expose reasoning/thought parts as an assistant answer.
  const text = parts.filter((p) => isPlainObject(p) && p.thought !== true && typeof p.text === "string")
    .map((p) => p.text).join("\n").trim();
  return text || null;
}
