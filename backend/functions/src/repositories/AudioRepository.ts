import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import { AudioClip, AudioClipCreateInput, AudioClipUpdateInput } from "../domain/AudioClip";

const COLLECTION = "audios";

export class AudioRepository {
  private col = db.collection(COLLECTION);

  async getById(id: string): Promise<AudioClip | null> {
    const snap = await this.col.doc(id).get();
    return snap.exists ? (snap.data() as AudioClip) : null;
  }

  async listByCategory(categoryId: string): Promise<AudioClip[]> {
    const snap = await this.col
      .where("categoryId", "==", categoryId)
      .where("isActive", "==", true)
      .orderBy("order", "asc")
      .get();
    return snap.docs.map((d) => d.data() as AudioClip);
  }

  async listFeatured(limit: number): Promise<AudioClip[]> {
    const snap = await this.col
      .where("isActive", "==", true)
      .where("isFeatured", "==", true)
      .orderBy("order", "asc")
      .limit(limit)
      .get();
    return snap.docs.map((d) => d.data() as AudioClip);
  }

  async create(input: AudioClipCreateInput, createdBy: string): Promise<AudioClip> {
    const ref = this.col.doc();
    const now = Timestamp.now();
    const audio: AudioClip = {
      id: ref.id,
      categoryId: input.categoryId,
      title: input.title,
      phrase: input.phrase,
      audioUrl: input.audioUrl,
      storagePath: input.storagePath,
      durationMs: input.durationMs,
      order: input.order,
      tags: input.tags,
      locale: input.locale,
      isActive: true,
      isFeatured: input.isFeatured ?? false,
      playCount: 0,
      favoriteCount: 0,
      createdAt: now,
      updatedAt: now,
      createdBy,
    };
    await ref.set(audio);
    return audio;
  }

  async update(id: string, patch: AudioClipUpdateInput): Promise<void> {
    await this.col.doc(id).update({ ...patch, updatedAt: Timestamp.now() });
  }

  /** Soft delete — catalog content is never hard-deleted, only hidden. */
  async deactivate(id: string): Promise<void> {
    await this.update(id, { isActive: false });
  }

  async incrementPlayCount(id: string, delta: number): Promise<void> {
    await this.col.doc(id).update({
      playCount: FieldValue.increment(delta),
      updatedAt: Timestamp.now(),
    });
  }

  async incrementFavoriteCount(id: string, delta: 1 | -1): Promise<void> {
    await this.col.doc(id).update({
      favoriteCount: FieldValue.increment(delta),
      updatedAt: Timestamp.now(),
    });
  }
}
