import {
  collection,
  getDocs,
  orderBy,
  query,
  Timestamp,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import type {
  CreatePromotionInput,
  Promotion,
  UpdatePromotionInput,
} from "./types";

const COLLECTION = "promotions";

interface PromotionDoc {
  title: string;
  description: string;
  linkUrl: string;
  startsAt: Timestamp;
  endsAt: Timestamp | null;
  active: boolean;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
}

function fromDoc(id: string, data: PromotionDoc): Promotion {
  return {
    id,
    title: data.title,
    description: data.description,
    linkUrl: data.linkUrl,
    startsAt: data.startsAt.toDate().toISOString(),
    endsAt: data.endsAt?.toDate().toISOString() ?? null,
    active: data.active,
    createdAt: data.createdAt?.toDate().toISOString() ?? "",
    updatedAt: data.updatedAt?.toDate().toISOString() ?? "",
  };
}

export async function listPromotions(): Promise<Promotion[]> {
  const snap = await getDocs(
    query(collection(db, COLLECTION), orderBy("startsAt", "desc")),
  );
  return snap.docs.map((d) => fromDoc(d.id, d.data() as PromotionDoc));
}

export async function createPromotion(
  input: CreatePromotionInput,
): Promise<{ id: string }> {
  const call = httpsCallable<CreatePromotionInput, { id: string }>(
    functions,
    "createPromotion",
  );
  const result = await call(input);
  return result.data;
}

export async function updatePromotion(
  input: UpdatePromotionInput,
): Promise<void> {
  const call = httpsCallable<UpdatePromotionInput, void>(
    functions,
    "updatePromotion",
  );
  await call(input);
}

export async function setPromotionActive(
  id: string,
  active: boolean,
): Promise<void> {
  await updatePromotion({ id, active });
}
