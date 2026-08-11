import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import { Promotion, PromotionCreateInput, PromotionUpdateInput } from "../domain/Promotion";

const COLLECTION = "promotions";

export class PromotionRepository {
  private col = db.collection(COLLECTION);

  async getById(id: string): Promise<Promotion | null> {
    const doc = await this.col.doc(id).get();
    return doc.exists ? (doc.data() as Promotion) : null;
  }

  async listActive(): Promise<Promotion[]> {
    const now = Timestamp.now();
    const snap = await this.col
      .where("isActive", "==", true)
      .where("startAt", "<=", now)
      .orderBy("startAt", "desc")
      .get();
    // endAt filtrado em memória para evitar um segundo campo de desigualdade
    // (o Firestore só permite filtros de intervalo em um campo por consulta).
    return snap.docs
      .map((d) => d.data() as Promotion)
      .filter((p) => p.endAt.toMillis() >= now.toMillis());
  }

  async create(input: PromotionCreateInput, createdBy: string): Promise<Promotion> {
    const ref = this.col.doc();
    const now = Timestamp.now();
    const promotion: Promotion = {
      id: ref.id,
      ...input,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      createdBy,
    };
    await ref.set(promotion);
    return promotion;
  }

  async update(id: string, patch: PromotionUpdateInput): Promise<void> {
    await this.col.doc(id).update({ ...patch, updatedAt: Timestamp.now() });
  }
}
