import { onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

type RecommendRequest = {
  occasion: string;
  relationship: string;
  budgetNpr: number;
  interests?: string[];
  giftStyle?: string;
  limit?: number;
};

function normalizeList(x: any): string[] {
  if (!Array.isArray(x)) return [];
  return x.map(v => String(v).toLowerCase().trim()).filter(Boolean);
}

function jaccard(a: string[], b: string[]): number {
  const A = new Set(a);
  const B = new Set(b);
  if (A.size === 0 && B.size === 0) return 0;
  let inter = 0;
  for (const v of A) if (B.has(v)) inter++;
  const union = A.size + B.size - inter;
  return union === 0 ? 0 : inter / union;
}

export const recommend = onRequest(async (req, res) => {
  try {
    // Optional: basic CORS for local testing
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Use POST" });
      return;
    }

    const body: RecommendRequest = (req.body ?? {}) as RecommendRequest;

    const occasion = String(body.occasion ?? "").trim().toLowerCase();
    const relationship = String(body.relationship ?? "").trim().toLowerCase();
    const budgetNpr = Number(body.budgetNpr ?? 0);
    const interests = normalizeList(body.interests);
    const giftStyle = String(body.giftStyle ?? "").trim().toLowerCase();
    const limit = Math.min(Number(body.limit ?? 10), 30);

    if (!occasion || !relationship || !budgetNpr) {
      res.status(400).json({ error: "Missing occasion/relationship/budgetNpr" });
      return;
    }

    logger.info("Recommend request", { occasion, relationship, budgetNpr, interests, giftStyle, limit });

    // Fetch candidates (keep bounded)
    const snap = await db.collection("gifts").limit(500).get();
    const candidates: any[] = [];
    snap.forEach(doc => candidates.push({ id: doc.id, ...doc.data() }));

    const scored = candidates
      .filter(item => {
        const occ = normalizeList(item.occasions);
        const rel = normalizeList(item.relationships);
        const minB = Number(item.minBudget ?? 0);
        const maxB = Number(item.maxBudget ?? Number.MAX_SAFE_INTEGER);

        const occasionOk = occ.length === 0 || occ.includes(occasion);
        const relationshipOk = rel.length === 0 || rel.includes(relationship);
        const budgetOk = budgetNpr >= minB && budgetNpr <= maxB;

        return occasionOk && relationshipOk && budgetOk;
      })
      .map(item => {
        const tags = normalizeList(item.tags);
        const style = String(item.style ?? "").toLowerCase().trim();

        const tagScore = jaccard(tags, interests); // 0..1
        const styleScore = giftStyle && style ? (giftStyle === style ? 1 : 0) : 0;

        const minB = Number(item.minBudget ?? 0);
        const maxB = Number(item.maxBudget ?? Number.MAX_SAFE_INTEGER);
        const center = (minB + maxB) / 2;
        const budgetDiff = Math.abs(budgetNpr - center);
        const budgetScore = Math.max(0, 1 - budgetDiff / Math.max(1, center));

        const reviewsCount = Number(item.reviewsCount ?? 0);
        const popularity = Math.min(1, Math.log10(reviewsCount + 1) / 5);

        const score =
          0.45 * tagScore +
          0.20 * styleScore +
          0.25 * budgetScore +
          0.10 * popularity;

        return {
          id: String(item.id ?? item.id ?? ""),
          name: String(item.name ?? item.title ?? ""),
          score,
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    res.json({
      model: "Hybrid Context-Aware + Content-Based (server-side)",
      count: scored.length,
      results: scored,
    });
  } catch (e: any) {
    logger.error("Recommend error", e);
    res.status(500).json({ error: String(e?.message ?? e) });
  }
});

const UNSPLASH_ACCESS_KEY = defineSecret("UNSPLASH_ACCESS_KEY");

export const getGiftImage = onRequest(
  { secrets: [UNSPLASH_ACCESS_KEY] },
  async (req, res) => {
    try {
      // CORS for mobile/web testing
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({ error: "Use POST" });
        return;
      }

      const giftId = String(req.body?.giftId ?? "").trim();
      const query = String(req.body?.query ?? "").trim();

      if (!giftId || !query) {
        res.status(400).json({ error: "Missing giftId/query" });
        return;
      }

      // 1) Check cache in Firestore
      const ref = db.collection("gifts").doc(giftId);
      const snap = await ref.get();
      if (snap.exists) {
        const data = snap.data() || {};
        const cached = String((data as any).imageUrl ?? "").trim();
        if (cached) {
          res.json({ giftId, imageUrl: cached, cached: true });
          return;
        }
      }

      // 2) Call Unsplash Search API
      const key = UNSPLASH_ACCESS_KEY.value();
      if (!key) {
        res.status(500).json({ error: "Missing UNSPLASH_ACCESS_KEY secret" });
        return;
      }

      const apiUrl =
        "https://api.unsplash.com/search/photos" +
        `?query=${encodeURIComponent(query)}` +
        "&per_page=1&orientation=squarish";

      const uresp = await fetch(apiUrl, {
        headers: {
          Authorization: `Client-ID ${key}`,
          "Accept-Version": "v1",
        },
      });

      if (!uresp.ok) {
        const t = await uresp.text();
        logger.error("Unsplash error", { status: uresp.status, body: t });
        res.status(502).json({ error: "Unsplash fetch failed", status: uresp.status });
        return;
      }

      const json: any = await uresp.json();
      const first = json?.results?.[0];
      const imageUrl = String(first?.urls?.regular ?? "").trim();

      if (!imageUrl) {
        res.json({ giftId, imageUrl: "", cached: false, message: "No image found" });
        return;
      }

      // 3) Save imageUrl into Firestore (cache)
      await ref.set(
        {
          imageUrl,
          imageSource: "unsplash",
          imageQuery: query,
          imageUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      res.json({ giftId, imageUrl, cached: false });
    } catch (e: any) {
      logger.error("getGiftImage error", e);
      res.status(500).json({ error: String(e?.message ?? e) });
    }
  }
);
