import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { REGION } from "../config/env";
import { AudioClip } from "../domain/AudioClip";

/**
 * Safety net for defaults on audio docs, in case a document is ever created
 * by something other than the `createAudio` callable (e.g. a future bulk
 * import script, or a manual Firestore console edit by an admin). The
 * callable already sets these correctly, so this is idempotent/defensive.
 */
export const onAudioCreate = onDocumentCreated(
  { region: REGION, document: "audios/{audioId}" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const audio = snap.data() as Partial<AudioClip>;
    const patch: Partial<AudioClip> = {};

    if (typeof audio.isActive !== "boolean") patch.isActive = true;
    if (typeof audio.isFeatured !== "boolean") patch.isFeatured = false;
    if (typeof audio.playCount !== "number") patch.playCount = 0;
    if (typeof audio.favoriteCount !== "number") patch.favoriteCount = 0;
    if (!audio.locale) patch.locale = "pt-BR";
    if (!Array.isArray(audio.tags)) patch.tags = [];

    if (Object.keys(patch).length > 0) {
      await snap.ref.update(patch);
    }
  }
);
