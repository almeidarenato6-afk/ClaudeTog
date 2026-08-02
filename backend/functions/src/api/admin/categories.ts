import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { REGION } from "../../config/env";
import { requireContentManager } from "./middleware";
import { CategoryRepository } from "../../repositories/CategoryRepository";

const categoryRepository = new CategoryRepository();

const createCategorySchema = z.object({
  name: z.string().min(1).max(60),
  slug: z
    .string()
    .min(1)
    .max(60)
    .regex(/^[a-z0-9-]+$/, "slug must be lowercase kebab-case"),
  order: z.number().int().nonnegative().default(0),
  icon: z.string().min(1),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, "color must be a 6-digit hex code"),
});

export const createCategory = onCall({ region: REGION }, async (request) => {
  requireContentManager(request);

  const parsed = createCategorySchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  return categoryRepository.create(parsed.data);
});

const updateCategorySchema = z.object({
  categoryId: z.string().min(1),
  patch: z.object({
    name: z.string().min(1).max(60).optional(),
    slug: z
      .string()
      .min(1)
      .max(60)
      .regex(/^[a-z0-9-]+$/)
      .optional(),
    order: z.number().int().nonnegative().optional(),
    icon: z.string().min(1).optional(),
    color: z
      .string()
      .regex(/^#[0-9A-Fa-f]{6}$/)
      .optional(),
    isActive: z.boolean().optional(),
  }),
});

export const updateCategory = onCall({ region: REGION }, async (request) => {
  requireContentManager(request);

  const parsed = updateCategorySchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { categoryId, patch } = parsed.data;

  const existing = await categoryRepository.getById(categoryId);
  if (!existing) {
    throw new HttpsError("not-found", `Category ${categoryId} does not exist.`);
  }

  await categoryRepository.update(categoryId, patch);
  return { categoryId };
});
