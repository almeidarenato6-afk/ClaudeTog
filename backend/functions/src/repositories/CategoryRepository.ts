import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import { Category, CategoryCreateInput, CategoryUpdateInput } from "../domain/Category";

const COLLECTION = "categories";

export class CategoryRepository {
  private col = db.collection(COLLECTION);

  async getById(id: string): Promise<Category | null> {
    const snap = await this.col.doc(id).get();
    return snap.exists ? (snap.data() as Category) : null;
  }

  async listActive(): Promise<Category[]> {
    const snap = await this.col
      .where("isActive", "==", true)
      .orderBy("order", "asc")
      .get();
    return snap.docs.map((d) => d.data() as Category);
  }

  async create(input: CategoryCreateInput): Promise<Category> {
    const ref = this.col.doc();
    const now = Timestamp.now();
    const category: Category = {
      id: ref.id,
      ...input,
      isActive: true,
      audioCount: 0,
      createdAt: now,
      updatedAt: now,
    };
    await ref.set(category);
    return category;
  }

  async update(id: string, patch: CategoryUpdateInput): Promise<void> {
    await this.col.doc(id).update({ ...patch, updatedAt: Timestamp.now() });
  }

  /** Soft delete — catalog content is never hard-deleted. */
  async deactivate(id: string): Promise<void> {
    await this.update(id, { isActive: false });
  }

  async incrementAudioCount(id: string, delta: 1 | -1): Promise<void> {
    await this.col.doc(id).update({
      audioCount: FieldValue.increment(delta),
      updatedAt: Timestamp.now(),
    });
  }
}
