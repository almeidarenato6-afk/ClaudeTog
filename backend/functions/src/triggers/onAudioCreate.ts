import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { REGION } from "../config/env";
import { AudioClip } from "../domain/AudioClip";

/**
 * Rede de segurança para valores padrão em docs de áudio, caso um documento
 * seja criado por algo além do callable `createAudio` (ex.: um futuro script
 * de importação em massa, ou uma edição manual de um admin no console do
 * Firestore). O callable já define esses valores corretamente, então isso é
 * idempotente/defensivo.
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
