import { onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

export const recommend = onRequest(async (req, res) => {
  try {
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

    const body = req.body ?? {};

    // -------------------------
    // Helpers
    // -------------------------
    const norm = (x: any) => String(x ?? "").trim().toLowerCase();

    const normalizeList = (arr: any): string[] => {
      if (!Array.isArray(arr)) return [];
      return arr.map((x) => norm(x)).filter(Boolean);
    };

    // Deterministic tiny tie-breaker (stable per user+gift)
    const hashStr = (s: string): number => {
      let h = 0;
      for (let i = 0; i < s.length; i++) {
        h = (h * 31 + s.charCodeAt(i)) >>> 0;
      }
      return h;
    };

    const containsAny = (keywords: string[], text: string) => {
      if (!keywords.length) return false;
      for (const k of keywords) {
        if (k && text.includes(k)) return true;
      }
      return false;
    };

    // -------------------------
    // Request inputs
    // -------------------------
    const userId = norm(body.userId);

    const occasion = norm(body.occasion);
    const relationship = norm(body.relationship);
    const budgetNpr = Number(body.budgetNpr ?? 0);
    const giftStyle = norm(body.giftStyle);
    const limit = Math.min(Number(body.limit ?? 10), 20);

    const sessionInterests = normalizeList(body.interests);

    // Recipient profile (from PreferencesScreen)
    const recipientAgeGroup = norm(body.recipientAgeGroup); // teen/young adult/adult/senior
    const recipientPersonality = norm(body.recipientPersonality); // minimalist/trendy/sentimental
    const dislikedCategories = normalizeList(body.dislikedCategories);

    // -------------------------
    // Fetch gifter profile (optional, from ProfileSetup)
    // -------------------------
    let profileInterests: string[] = [];
    let stylePreference = "";
    let personalityTag = "";

    if (userId) {
      const userSnap = await db.collection("users").doc(userId).get();
      const u = userSnap.data() || {};
      const profile = (u as any).profile || {};

      profileInterests = normalizeList(profile.interests);
      stylePreference = norm(profile.stylePreference);
      personalityTag = norm(profile.personalityTag);
    }

    // -------------------------
    // Merge interests
    // -------------------------
    const interestSet = new Set<string>([...profileInterests, ...sessionInterests]);
    const mergedInterests = Array.from(interestSet);

    // -------------------------
    // Personality keyword mapping
    // -------------------------
    const personalityKeywords: Record<string, string[]> = {
      minimalist: ["minimal", "minimalist", "simple", "clean", "basic", "sleek"],
      trendy: ["trendy", "fashion", "stylish", "modern", "cool", "aesthetic", "viral"],
      sentimental: ["sentimental", "memory", "keepsake", "personal", "personalized", "romantic", "heart"],
    };

    const recipientPersonalityKeys = personalityKeywords[recipientPersonality] ?? [];
    const gifterPersonalityKeys = personalityKeywords[personalityTag] ?? [];

    // -------------------------
    // Load gifts from Firestore
    // -------------------------
    const giftsSnap = await db.collection("gifts").get();
    const gifts = giftsSnap.docs.map((d) => ({ id: d.id, ...(d.data() as any) }));

    // -------------------------
    // Score gifts
    // -------------------------
    const scored = gifts
      .map((g: any) => {
        const giftId = String(g.id ?? g._id ?? "").trim() || "unknown";
        const name = String(g.name ?? g.title ?? giftId);
        const desc = String(g.description ?? "");
        const category = norm(g.category ?? g.mainCategory ?? "");
        const gStyle = norm(g.style);

        const tags: string[] = normalizeList(g.tags);

        // Searchable text
        const textBlob = norm(`${name} ${desc} ${category} ${tags.join(" ")}`);

        // --- Light filters ---
        const withinBudget =
          typeof g.minBudget === "number" && typeof g.maxBudget === "number"
            ? budgetNpr >= g.minBudget && budgetNpr <= g.maxBudget
            : true;

        const occasionMatch =
          Array.isArray(g.occasions) && occasion
            ? normalizeList(g.occasions).includes(occasion)
            : true;

        const relationshipMatch =
          Array.isArray(g.relationships) && relationship
            ? normalizeList(g.relationships).includes(relationship)
            : true;

        // --- Interest overlap ---
        const interestHits = mergedInterests.filter((i) => tags.includes(i) || textBlob.includes(i)).length;
        const interestScore = mergedInterests.length === 0 ? 0 : interestHits / mergedInterests.length;

        // --- Style boosts ---
        const sessionStyleBoost = giftStyle && gStyle === giftStyle ? 0.15 : 0;
        const profileStyleBoost = stylePreference && gStyle === stylePreference ? 0.22 : 0;

        // --- Recipient personality boost (strong) ---
        const recipientPersonalityBoost =
          recipientPersonality &&
          (tags.includes(recipientPersonality) || containsAny(recipientPersonalityKeys, textBlob))
            ? 0.35
            : 0;

        // --- Gifter personality boost (smaller) ---
        const gifterPersonalityBoost =
          personalityTag &&
          (tags.includes(personalityTag) || containsAny(gifterPersonalityKeys, textBlob))
            ? 0.12
            : 0;

        // --- Disliked category penalty (strong) ---
        const dislikedPenalty =
          dislikedCategories.length > 0 &&
          (dislikedCategories.includes(category) || dislikedCategories.some((dc) => textBlob.includes(dc)))
            ? -0.50
            : 0;

        // --- Age group boost (optional) ---
        const ageGroupBoost =
          recipientAgeGroup && Array.isArray(g.ageGroups)
            ? (normalizeList(g.ageGroups).includes(recipientAgeGroup) ? 0.12 : 0)
            : 0;

        // --- Deterministic tiny noise for tie-breaking (stable per user+gift) ---
        const noiseKey = `${userId || "anon"}|${giftId}`;
        const deterministicNoise = ((hashStr(noiseKey) % 1000) / 1000) * 0.01;

        // --- Final Score ---
        const score =
          (withinBudget ? 0.22 : 0) +
          (occasionMatch ? 0.14 : 0) +
          (relationshipMatch ? 0.14 : 0) +
          (interestScore * 0.60) +
          sessionStyleBoost +
          profileStyleBoost +
          recipientPersonalityBoost +
          gifterPersonalityBoost +
          ageGroupBoost +
          dislikedPenalty +
          deterministicNoise;

        return { id: giftId, name, score };
      })
      .filter((x: any) => x.score > 0.10)
      .sort((a: any, b: any) => b.score - a.score)
      .slice(0, limit);

    res.json({
      model: "Hybrid Context + Content + Recipient + User Profile Personalization",
      userProfileUsed: Boolean(userId),
      recipientSignalsUsed: Boolean(recipientAgeGroup || recipientPersonality || dislikedCategories.length),
      mergedInterestsCount: mergedInterests.length,
      count: scored.length,
      results: scored,
    });
  } catch (e: any) {
    logger.error("recommend error", e);
    res.status(500).json({ error: String(e?.message ?? e) });
  }
});

const UNSPLASH_ACCESS_KEY = defineSecret("UNSPLASH_ACCESS_KEY");

export const getGiftImage = onRequest(
  { secrets: [UNSPLASH_ACCESS_KEY] },
  async (req, res) => {
    try {
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

      // 1) cache
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

      // 2) Unsplash
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

      // 3) save cache
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