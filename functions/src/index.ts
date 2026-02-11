import { onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

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
