// @ts-nocheck
// deno-lint-ignore-file no-explicit-any
// Edge Function: vision-analyze
// Validates input, attempts to generate signed URLs, performs optional provider analysis with timeout,
// and returns sanitized observations. Falls back to placeholder if provider credentials are missing.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface AnalyzeRequest {
  paths: string[];
  context?: Record<string, any>;
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const BUCKET = 'user-photos';

// Optional Gemini API key; if not present, we skip provider calls.
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-1.5-flash';
const DEFAULT_TIMEOUT_MS = Number(Deno.env.get('VISION_TIMEOUT_MS') ?? '15000');
const GOOGLE_VISION_API_KEY = Deno.env.get('GOOGLE_VISION_API_KEY') ?? '';

// Create Supabase client only if we have service role (for storage access regardless of RLS)
const supabase = SUPABASE_URL && SERVICE_ROLE ? createClient(SUPABASE_URL, SERVICE_ROLE) : null;

export async function handleRequest(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: jsonHeaders() });
    }

    const body = (await req.json().catch(() => ({}))) as Partial<AnalyzeRequest> | undefined;
    const paths = Array.isArray(body?.paths) ? body!.paths : [];
    if (!paths.length) {
      return json({ error: 'paths is required and must be a non-empty array of storage paths' }, 400);
    }

    // Basic input limits
    if (paths.length > 5) {
      return json({ error: 'Too many photos: max 5 per request' }, 400);
    }

    // Generate signed URLs if possible (best-effort)
    const signedUrlMap = await signUrls(paths).catch(() => ({} as Record<string, string | null>));

    const analyses: any[] = [];
    for (const p of paths) {
      // Moderation: optional Google Vision SafeSearch
      let moderation: any = { allowed: true, reason: 'not_configured' };
      try {
        const url = signedUrlMap[p] ?? null;
        if (GOOGLE_VISION_API_KEY && url) {
          const inline = await withTimeout(DEFAULT_TIMEOUT_MS, () => fetchAsInlineData(url));
          moderation = await withTimeout(DEFAULT_TIMEOUT_MS, () => moderateWithSafeSearch(inline.data));
        }
      } catch (_) {
        // Ignore moderation errors and proceed as allowed
      }

      let observations: any[] = [];
      let providerUsed = 'none';
      try {
        const url = signedUrlMap[p] ?? null;
        if (moderation.allowed && GEMINI_API_KEY && url) {
          providerUsed = 'gemini';
          const obs = await withTimeout(DEFAULT_TIMEOUT_MS, () => analyzeWithGemini(url));
          observations = sanitizeObservations(obs);
        }
      } catch (_e) {
        // Swallow provider errors; we'll fall back below
      }

      if (!observations.length) {
        if (!moderation.allowed) {
          const cats = Array.isArray(moderation.categories) ? moderation.categories.join(', ') : 'sensitive';
          observations = [
            {
              label: 'moderation_block',
              summary: `This image appears to contain ${cats}. For your safety, analysis was not performed.`,
              confidence: 0.0,
            },
          ];
          providerUsed = providerUsed === 'none' ? 'moderation' : providerUsed;
        } else {
          observations = [
            {
              label: 'skin_observation',
              summary: 'Placeholder analysis. Vision provider not configured.',
              confidence: 0.0,
            },
          ];
        }
      }

      analyses.push({ path: p, moderation, observations, provider: providerUsed });
    }

    return json({ analyses });
  } catch (e) {
    return json({ error: 'Unexpected error', details: String(e) }, 500);
  }
}

Deno.serve(handleRequest);

async function signUrls(paths: string[]): Promise<Record<string, string | null>> {
  const map: Record<string, string | null> = {};
  if (!supabase) return map; // cannot sign without service role
  for (const p of paths) {
    try {
      const { data, error } = await supabase.storage.from(BUCKET).createSignedUrl(p, 60 * 15); // 15 min
      if (!error && data?.signedUrl) {
        map[p] = data.signedUrl;
      } else {
        map[p] = null;
      }
    } catch (_) {
      map[p] = null;
    }
  }
  return map;
}

async function analyzeWithGemini(imageUrl: string): Promise<any[]> {
  // Minimal prompt and image URL; Gemini may not fetch all URLs, so network failures are possible.
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${encodeURIComponent(
    GEMINI_API_KEY,
  )}`;
  const payload = {
    contents: [
      {
        role: 'user',
        parts: [
          { text: 'Analyze the skin condition in this photo. Return 1-3 concise observations.' },
          { inline_data: await fetchAsInlineData(imageUrl) },
        ],
      },
    ],
  };
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`Gemini error ${res.status}`);
  const json = await res.json();
  const text = extractText(json) || '';
  if (!text) return [];
  // Split into up to 3 bullet-like observations
  const lines = text
    .split(/\r?\n|\u2022|-/)
    .map((s: string) => s.trim())
    .filter(Boolean)
    .slice(0, 3);
  return lines.map((summary: string) => ({ label: 'skin_observation', summary, confidence: 0.5 }));
}

async function fetchAsInlineData(url: string): Promise<{ mime_type: string; data: string }> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`image fetch failed ${res.status}`);
  const buf = new Uint8Array(await res.arrayBuffer());
  // Best-effort MIME sniff
  const mime = url.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  const b64 = btoa(String.fromCharCode(...buf));
  return { mime_type: mime, data: b64 };
}

async function moderateWithSafeSearch(base64Content: string): Promise<{ allowed: boolean; reason: string; categories: string[] }>{
  const endpoint = `https://vision.googleapis.com/v1/images:annotate?key=${encodeURIComponent(GOOGLE_VISION_API_KEY)}`;
  const payload = {
    requests: [
      {
        image: { content: base64Content },
        features: [{ type: 'SAFE_SEARCH_DETECTION' }],
      },
    ],
  };
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`SafeSearch error ${res.status}`);
  const json = await res.json();
  const ann = json?.responses?.[0]?.safeSearchAnnotation;
  if (!ann) return { allowed: true, reason: 'no_annotation', categories: [] };
  const levels = ['VERY_UNLIKELY', 'UNLIKELY', 'POSSIBLE', 'LIKELY', 'VERY_LIKELY'];
  const flags: string[] = [];
  const risky = (name: string) => {
    const v = String(ann[name] ?? '').toUpperCase();
    const idx = levels.indexOf(v);
    return idx >= levels.indexOf('LIKELY');
  };
  if (risky('adult')) flags.push('adult');
  if (risky('racy')) flags.push('racy');
  if (risky('violence')) flags.push('violence');
  const allowed = flags.length === 0;
  return { allowed, reason: 'safe_search', categories: flags };
}

function extractText(resp: any): string | null {
  try {
    // Gemini v1beta shape: candidates[0].content.parts[].text
    const c = resp?.candidates?.[0];
    const parts = c?.content?.parts ?? [];
    const texts = parts.map((p: any) => p?.text).filter((t: any) => typeof t === 'string');
    return texts.join('\n').trim() || null;
  } catch (_) {
    return null;
  }
}

function sanitizeObservations(obs: any[]): any[] {
  return (obs || []).map((o) => ({
    label: String(o.label || 'observation').slice(0, 64),
    summary: String(o.summary || '').replace(/[\u0000-\u001F]/g, '').slice(0, 512),
    confidence: Number.isFinite(o.confidence) ? Number(o.confidence) : 0.0,
  }));
}

async function withTimeout<T>(ms: number, fn: () => Promise<T>): Promise<T> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort('timeout'), ms);
  try {
    // Note: fn might not support AbortController; we enforce time via race
    return await Promise.race([
      fn(),
      new Promise<T>((_, reject) => setTimeout(() => reject(new Error('timeout')), ms + 50)),
    ]);
  } finally {
    clearTimeout(id);
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: jsonHeaders() });
}

function jsonHeaders(): HeadersInit {
  return {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
  };
}
