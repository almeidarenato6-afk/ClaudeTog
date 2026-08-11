import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { REGION } from "../config/env";
import { AudioRepository } from "../repositories/AudioRepository";

const audioRepository = new AudioRepository();

/**
 * Mantém `AudioClip.favoriteCount` sincronizado com a subcoleção
 * `users/{uid}/favorites/{audioId}`, gravável diretamente pelo cliente (veja
 * api/client/favorites.ts para entender por que favoritar em si é uma
 * escrita direta do cliente em vez de um callable).
 */
export const onFavoriteWrite = onDocumentWritten(
  { region: REGION, document: "users/{uid}/favorites/{audioId}" },
  async (event) => {
    const { audioId } = event.params;
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;

    if (existedBefore === existsAfter) return; // escritas no-op não deveriam ocorrer, mas protegemos mesmo assim

    await audioRepository.incrementFavoriteCount(audioId, existsAfter ? 1 : -1);
  }
);
