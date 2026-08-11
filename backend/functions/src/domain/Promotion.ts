import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `promotions/{promotionId}`
 * Leitura pública (alimenta o banner "Loja TogPlay" dentro do app), escrita
 * restrita a admin.
 *
 * Hoje isso é puramente um banner de marketing apontando para a loja externa
 * (https://www.lojatogplay.com.br) — veja ARCHITECTURE.md §9. Os campos
 * comentados abaixo são o ponto de extensão deliberado para um futuro fluxo
 * de e-commerce dentro do app (catálogo/carrinho/checkout/cupons/cashback/
 * fidelidade); não os implemente agora, apenas mantenha o formato pronto para
 * que um futuro `EcommerceApiStoreRepository` no cliente tenha de onde ler.
 */
export interface Promotion {
  id: string;
  title: string;
  description: string;
  imageUrl?: string;
  linkUrl: string; // deep link — hoje sempre uma URL externa lojatogplay.com.br
  startAt: Timestamp;
  endAt: Timestamp;
  isActive: boolean;
  audience: "all" | "favorites_users"; // segmentação simples para banners direcionados
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;

  // --- Futuro ponto de extensão de e-commerce (NÃO implementado) ---
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
