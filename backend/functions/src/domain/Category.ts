import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `categories/{categoryId}`
 * Leitura pública, escrita restrita a admin/content_manager (veja firestore.rules).
 */
export interface Category {
  id: string;
  name: string; // nome de exibição, ex.: "Motivação"
  slug: string; // chave estável legível por máquina, ex.: "motivacao"
  order: number; // ordem de exibição ascendente na trilha de categorias
  icon: string; // chave do asset de ícone resolvida no cliente (não é uma URL)
  color: string; // cor em hex, ex.: "#FF6B00", usada no chip/tema da categoria
  isActive: boolean; // soft delete — categorias inativas ficam ocultas dos clientes
  audioCount: number; // contagem desnormalizada de áudios ativos, mantida em sincronia pelos triggers
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
