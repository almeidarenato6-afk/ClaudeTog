import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { REGION } from "../config/env";
import { AudioRepository } from "../repositories/AudioRepository";

const audioRepository = new AudioRepository();

/**
 * Keeps `AudioClip.favoriteCount` in sync with the client-writable
 * `users/{uid}/favorites/{audioId}` subcollection (see api/client/favorites.ts
 * for why favoriting itself is a direct client write rather than a callable).
 */
export const onFavoriteWrite = onDocumentWritten(
  { region: REGION, document: "users/{uid}/favorites/{audioId}" },
  async (event) => {
    const { audioId } = event.params;
    const existedBefore = event.data?.before.exists ?? false;
    const existsAfter = event.data?.after.exists ?? false;

    if (existedBefore === existsAfter) return; // no-op writes shouldn't happen, but guard anyway

    await audioRepository.incrementFavoriteCount(audioId, existsAfter ? 1 : -1);
  }
);
