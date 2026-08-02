import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `audios/{audioId}`
 * Public-read, admin/content_manager-write (see firestore.rules).
 *
 * This is the actual product content surface — the app reads this collection
 * (filtered by categoryId + isActive) directly/via listener, so shape changes
 * here are effectively an API contract with every client (mobile, watch apps).
 */
export interface AudioClip {
  id: string;
  categoryId: string;
  title: string; // short label shown on the soundboard button, e.g. "Vai Márcia!"
  phrase: string; // full spoken phrase / transcript, e.g. "Vai, Márcia! Bora pra cima!"
  audioUrl: string; // public, long-lived Cloud Storage download URL
  storagePath: string; // canonical Storage object path, e.g. catalog/audios/{id}/master.m4a
  durationMs: number;
  order: number; // display order within its category
  isActive: boolean; // soft delete — never hard-delete catalog content
  isFeatured: boolean; // surfaced in "starter pack" / home highlights
  tags: string[]; // free-form search/filter tags, e.g. ["treino", "virada"]
  locale: string; // BCP-47, e.g. "pt-BR" — all launch content is pt-BR
  playCount: number; // denormalized, only ever incremented server-side (analytics rollup)
  favoriteCount: number; // denormalized, kept in sync by onFavoriteWrite trigger
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string; // uid of the admin/content_manager who created it
}

export type AudioClipCreateInput = Pick<
  AudioClip,
  | "categoryId"
  | "title"
  | "phrase"
  | "audioUrl"
  | "storagePath"
  | "durationMs"
  | "order"
  | "tags"
  | "locale"
> &
  Partial<Pick<AudioClip, "isFeatured">>;

export type AudioClipUpdateInput = Partial<
  Pick<
    AudioClip,
    | "categoryId"
    | "title"
    | "phrase"
    | "audioUrl"
    | "storagePath"
    | "durationMs"
    | "order"
    | "tags"
    | "isActive"
    | "isFeatured"
  >
>;
