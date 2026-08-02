import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { Timestamp } from "firebase-admin/firestore";
import { REGION } from "../../config/env";
import { requireAdmin } from "./middleware";
import { PromotionRepository } from "../../repositories/PromotionRepository";

const promotionRepository = new PromotionRepository();

const isoDate = z.string().datetime();

const createPromotionSchema = z.object({
  title: z.string().min(1).max(80),
  description: z.string().min(1).max(400),
  imageUrl: z.string().url().optional(),
  linkUrl: z.string().url(),
  startAt: isoDate,
  endAt: isoDate,
  audience: z.enum(["all", "favorites_users"]).default("all"),
});

/**
 * Promotions today only drive the "Loja TogPlay" banner (external link) —
 * see domain/Promotion.ts for the deliberately-unimplemented e-commerce
 * extension fields (coupon/cashback/loyalty).
 */
export const createPromotion = onCall({ region: REGION }, async (request) => {
  const uid = requireAdmin(request);

  const parsed = createPromotionSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { startAt, endAt, ...rest } = parsed.data;

  if (new Date(endAt) <= new Date(startAt)) {
    throw new HttpsError("invalid-argument", "endAt must be after startAt.");
  }

  return promotionRepository.create(
    {
      ...rest,
      startAt: Timestamp.fromDate(new Date(startAt)),
      endAt: Timestamp.fromDate(new Date(endAt)),
    },
    uid
  );
});

const updatePromotionSchema = z.object({
  promotionId: z.string().min(1),
  patch: z.object({
    title: z.string().min(1).max(80).optional(),
    description: z.string().min(1).max(400).optional(),
    imageUrl: z.string().url().optional(),
    linkUrl: z.string().url().optional(),
    startAt: isoDate.optional(),
    endAt: isoDate.optional(),
    isActive: z.boolean().optional(),
    audience: z.enum(["all", "favorites_users"]).optional(),
  }),
});

export const updatePromotion = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);

  const parsed = updatePromotionSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { promotionId, patch } = parsed.data;

  const existing = await promotionRepository.getById(promotionId);
  if (!existing) {
    throw new HttpsError("not-found", `Promotion ${promotionId} does not exist.`);
  }

  const { startAt, endAt, ...rest } = patch;
  const nextStart = startAt ? new Date(startAt) : existing.startAt.toDate();
  const nextEnd = endAt ? new Date(endAt) : existing.endAt.toDate();
  if (nextEnd <= nextStart) {
    throw new HttpsError("invalid-argument", "endAt must be after startAt.");
  }

  await promotionRepository.update(promotionId, {
    ...rest,
    ...(startAt ? { startAt: Timestamp.fromDate(nextStart) } : {}),
    ...(endAt ? { endAt: Timestamp.fromDate(nextEnd) } : {}),
  });
  return { promotionId };
});
