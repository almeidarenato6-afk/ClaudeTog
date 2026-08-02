import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `categories/{categoryId}`
 * Public-read, admin/content_manager-write (see firestore.rules).
 */
export interface Category {
  id: string;
  name: string; // display name, e.g. "Motivação"
  slug: string; // stable machine-readable key, e.g. "motivacao"
  order: number; // ascending display order in category rail
  icon: string; // icon asset key resolved client-side (not a URL)
  color: string; // hex color, e.g. "#FF6B00", used for category chip/theme
  isActive: boolean; // soft delete — inactive categories hidden from clients
  audioCount: number; // denormalized count of active audios, kept in sync by triggers
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export type CategoryCreateInput = Pick<
  Category,
  "name" | "slug" | "order" | "icon" | "color"
>;

export type CategoryUpdateInput = Partial<
  Pick<Category, "name" | "slug" | "order" | "icon" | "color" | "isActive">
>;
