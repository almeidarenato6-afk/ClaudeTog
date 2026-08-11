import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { REGION } from "../../config/env";
import { requireContentManager } from "./middleware";
import { AudioRepository } from "../../repositories/AudioRepository";
import { CategoryRepository } from "../../repositories/CategoryRepository";

const audioRepository = new AudioRepository();
const categoryRepository = new CategoryRepository();

const createAudioSchema = z.object({
  categoryId: z.string().min(1),
  title: z.string().min(1).max(80),
  phrase: z.string().min(1).max(280),
  audioUrl: z.string().url(),
  storagePath: z.string().min(1),
  durationMs: z.number().int().positive(),
  order: z.number().int().nonnegative().default(0),
  tags: z.array(z.string()).default([]),
  locale: z.string().default("pt-BR"),
  isFeatured: z.boolean().optional(),
});

export const createAudio = onCall({ region: REGION }, async (request) => {
  const uid = requireContentManager(request);

  const parsed = createAudioSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const category = await categoryRepository.getById(parsed.data.categoryId);
  if (!category) {
    throw new HttpsError("not-found", `Category ${parsed.data.categoryId} does not exist.`);
  }

  const audio = await audioRepository.create(parsed.data, uid);
  await categoryRepository.incrementAudioCount(category.id, 1);
  return audio;
});

const updateAudioSchema = z.object({
  audioId: z.string().min(1),
  patch: z.object({
    categoryId: z.string().min(1).optional(),
    title: z.string().min(1).max(80).optional(),
    phrase: z.string().min(1).max(280).optional(),
    audioUrl: z.string().url().optional(),
    storagePath: z.string().min(1).optional(),
    durationMs: z.number().int().positive().optional(),
    order: z.number().int().nonnegative().optional(),
    tags: z.array(z.string()).optional(),
    isActive: z.boolean().optional(),
    isFeatured: z.boolean().optional(),
  }),
});

export const updateAudio = onCall({ region: REGION }, async (request) => {
  requireContentManager(request);

  const parsed = updateAudioSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { audioId, patch } = parsed.data;

  const existing = await audioRepository.getById(audioId);
  if (!existing) {
    throw new HttpsError("not-found", `Audio ${audioId} does not exist.`);
  }

  await audioRepository.update(audioId, patch);

  // Mantém as contagens desnormalizadas de categoria corretas quando um áudio muda de categoria.
  if (patch.categoryId && patch.categoryId !== existing.categoryId) {
    await categoryRepository.incrementAudioCount(existing.categoryId, -1);
    await categoryRepository.incrementAudioCount(patch.categoryId, 1);
  }

  return { audioId };
});

const deleteAudioSchema = z.object({ audioId: z.string().min(1) });

/** Apenas soft-delete — áudio do catálogo nunca é excluído de forma definitiva (veja AudioClip.isActive). */
export const deleteAudio = onCall({ region: REGION }, async (request) => {
  requireContentManager(request);

  const parsed = deleteAudioSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const existing = await audioRepository.getById(parsed.data.audioId);
  if (!existing) {
    throw new HttpsError("not-found", `Audio ${parsed.data.audioId} does not exist.`);
  }

  await audioRepository.deactivate(parsed.data.audioId);
  if (existing.isActive) {
    await categoryRepository.incrementAudioCount(existing.categoryId, -1);
  }
  return { audioId: parsed.data.audioId };
});
