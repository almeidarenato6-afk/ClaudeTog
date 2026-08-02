import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `promotions/{promotionId}`
 * Public-read (drives the in-app "Loja TogPlay" banner), admin-only write.
 *
 * Today this is purely a marketing banner pointing at the external store
 * (https://www.lojatogplay.com.br) — see ARCHITECTURE.md §9. The commented
 * fields below are the deliberate extension point for a future in-app
 * e-commerce flow (catalog/cart/checkout/coupons/cashback/loyalty); do not
 * implement them now, just keep the shape ready so a future
 * `EcommerceApiStoreRepository` on the client has somewhere to read from.
 */
export interface Promotion {
  id: string;
  title: string;
  description: string;
  imageUrl?: string;
  linkUrl: string; // deep link — today always an external lojatogplay.com.br URL
  startAt: Timestamp;
  endAt: Timestamp;
  isActive: boolean;
  audience: "all" | "favorites_users"; // simple segmentation for targeted banners
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;

  // --- Future e-commerce extension point (NOT implemented) ---
  // couponCode?: string;
  // discountPercent?: number;
  // cashbackPercent?: number;
  // minPurchaseValue?: number;
  // loyaltyPointsMultiplier?: number;
}

export type PromotionCreateInput = Pick<
  Promotion,
  "title" | "description" | "linkUrl" | "startAt" | "endAt" | "audience"
> &
  Partial<Pick<Promotion, "imageUrl">>;

export type PromotionUpdateInput = Partial<
  Pick<
    Promotion,
    | "title"
    | "description"
    | "imageUrl"
    | "linkUrl"
    | "startAt"
    | "endAt"
    | "isActive"
    | "audience"
  >
>;
