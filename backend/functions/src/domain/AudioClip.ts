import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `audios/{audioId}`
 * Leitura pública, escrita restrita a admin/content_manager (veja firestore.rules).
 *
 * Esta é a superfície real de conteúdo do produto — o app lê esta coleção
 * (filtrada por categoryId + isActive) diretamente/via listener, então mudanças
 * de formato aqui são efetivamente um contrato de API com todos os clientes
 * (apps mobile e watch).
 */
export interface AudioClip {
  id: string;
  categoryId: string;
  title: string; // rótulo curto mostrado no botão do soundboard, ex.: "Vai Márcia!"
  phrase: string; // frase falada completa / transcrição, ex.: "Vai, Márcia! Bora pra cima!"
  audioUrl: string; // URL de download do Cloud Storage, pública e de longa duração
  storagePath: string; // caminho canônico do objeto no Storage, ex.: catalog/audios/{id}/master.m4a
  durationMs: number;
  order: number; // ordem de exibição dentro da categoria
  isActive: boolean; // soft delete — nunca fazer hard delete de conteúdo do catálogo
  isFeatured: boolean; // exibido no "starter pack" / destaques da home
  tags: string[]; // tags de busca/filtro livres, ex.: ["treino", "virada"]
  locale: string; // BCP-47, ex.: "pt-BR" — todo o conteúdo de lançamento é pt-BR
  playCount: number; // desnormalizado, só é incrementado no servidor (rollup de analytics)
  favoriteCount: number; // desnormalizado, mantido em sincronia pelo trigger onFavoriteWrite
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string; // uid do admin/content_manager que o criou
}

export type AudioClipCreateInput = Pick<
  AudioClip,
  | "categoryId"
  | "title"
  | "phrase"
  | "audioUrl"
  | "storagePath"
  | "durationMs"
  | "order"
  | "tags"
  | "locale"
> &
  Partial<Pick<AudioClip, "isFeatured">>;

export type AudioClipUpdateInput = Partial<
  Pick<
    AudioClip,
    | "categoryId"
    | "title"
    | "phrase"
    | "audioUrl"
    | "storagePath"
    | "durationMs"
    | "order"
    | "tags"
    | "isActive"
    | "isFeatured"
  >
>;
