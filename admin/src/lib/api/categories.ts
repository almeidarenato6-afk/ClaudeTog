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
  Category,
  CreateCategoryInput,
  UpdateCategoryInput,
} from "./types";

const COLLECTION = "categories";

interface CategoryDoc {
  name: string;
  slug: string;
  icon: string;
  color: string;
  order: number;
  active: boolean;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
}

function fromDoc(id: string, data: CategoryDoc): Category {
  return {
    id,
    name: data.name,
    slug: data.slug,
    icon: data.icon,
    color: data.color,
    order: data.order,
    active: data.active,
    createdAt: data.createdAt?.toDate().toISOString() ?? "",
    updatedAt: data.updatedAt?.toDate().toISOString() ?? "",
  };
}

export async function listCategories(): Promise<Category[]> {
  const snap = await getDocs(
    query(collection(db, COLLECTION), orderBy("order", "asc")),
  );
  return snap.docs.map((d) => fromDoc(d.id, d.data() as CategoryDoc));
}

// Mutations go through Cloud Functions callables rather than direct
// Firestore writes so backend-side validation (RBAC, slug uniqueness,
// client cache invalidation) stays authoritative in one place.
export async function createCategory(
  input: CreateCategoryInput,
): Promise<{ id: string }> {
  const call = httpsCallable<CreateCategoryInput, { id: string }>(
    functions,
    "createCategory",
  );
  const result = await call(input);
  return result.data;
}

export async function updateCategory(
  input: UpdateCategoryInput,
): Promise<void> {
  const call = httpsCallable<UpdateCategoryInput, void>(
    functions,
    "updateCategory",
  );
  await call(input);
}

export async function setCategoryActive(
  id: string,
  active: boolean,
): Promise<void> {
  await updateCategory({ id, active });
}
