import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `users/{uid}/favorites/{audioId}`
 * Leitura/escrita restrita ao dono, escrito diretamente pelo cliente (veja
 * api/client/favorites.ts para entender por que isso não é um callable).
 */
export interface Favorite {
  audioId: string;
  createdAt: Timestamp;
}
