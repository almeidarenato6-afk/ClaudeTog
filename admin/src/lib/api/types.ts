// Tipos de domínio compartilhados espelhando o schema do Firestore /
// contrato de Cloud Functions do backend (ver docs/ARCHITECTURE.md §6, §10).
// Foram tipados manualmente contra o contrato *plausível* descrito para o
// trabalho em andamento do time de backend — reconciliar com
// DATABASE_SCHEMA.md / API_DESIGN.md quando existirem, e ajustar os nomes
// dos campos se houver divergência.

export type StaffRole = "admin" | "content_manager" | "viewer";

export interface StaffClaims {
  role: StaffRole;
}

/** Categorias definidas na especificação do produto — "Personalizados" cobre áudios gravados pelo usuário. */
export type AudioCategoryId =
  | "motivacao"
  | "recuperacao"
  | "energia"
  | "comemoracao"
  | "concentracao"
  | "humor"
  | "incentivo"
  | "treinador"
  | "parceiro"
  | "personalizados";

export interface Category {
  id: string;
  name: string;
  slug: AudioCategoryId | string;
  icon: string; // nome do ícone/referência de emoji renderizado pelos clients
  color: string; // hex, usado para chips/badges em todos os clients
  order: number;
  active: boolean;
  createdAt: string; // ISO 8601
  updatedAt: string;
}

export type CreateCategoryInput = Omit<
  Category,
  "id" | "createdAt" | "updatedAt"
>;
export type UpdateCategoryInput = Partial<CreateCategoryInput> & {
  id: string;
};

export interface Audio {
  id: string;
  title: string;
  phraseText: string;
  categoryId: string;
  audioUrl: string;
  durationMs: number | null;
  active: boolean;
  playCount: number;
  createdAt: string;
  updatedAt: string;
  createdBy: string | null;
}

export interface CreateAudioInput {
  title: string;
  phraseText: string;
  categoryId: string;
  active: boolean;
  /** Storage path do arquivo já enviado, ex.: `audios/raw/<uuid>.m4a`. */
  storagePath: string;
}

export type UpdateAudioInput = Partial<
  Omit<CreateAudioInput, "storagePath">
> & {
  id: string;
};

export interface AudioListFilters {
  categoryId?: string;
  active?: boolean;
  search?: string;
}

export type PlaybackStrategy = "DIRECT" | "RELAY" | "PHONE_ONLY";

export interface AnalyticsSummary {
  rangeStart: string;
  rangeEnd: string;
  totalPlays: number;
  totalUsers: number;
  dau: number;
  avgSessionSeconds: number;
  topAudios: Array<{
    audioId: string;
    title: string;
    plays: number;
  }>;
  dailyTrend: Array<{
    date: string; // YYYY-MM-DD
    plays: number;
    dau: number;
    avgSessionSeconds: number;
  }>;
  byWatchModel: Array<{ model: string; count: number }>;
  byPhoneModel: Array<{ model: string; count: number }>;
  byPlaybackStrategy: Array<{ strategy: PlaybackStrategy; count: number }>;
}

export interface AnalyticsQuery {
  rangeStart: string; // YYYY-MM-DD
  rangeEnd: string; // YYYY-MM-DD
}

export type NotificationTarget =
  | { type: "all" }
  | { type: "segment"; segment: string };

export interface NotificationRecord {
  id: string;
  title: string;
  body: string;
  target: NotificationTarget;
  sentAt: string | null;
  status: "draft" | "sending" | "sent" | "failed";
  sentBy: string | null;
  recipientCount: number | null;
}

export interface SendNotificationInput {
  title: string;
  body: string;
  target: NotificationTarget;
}

export interface Promotion {
  id: string;
  title: string;
  description: string;
  linkUrl: string;
  startsAt: string;
  endsAt: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export type CreatePromotionInput = Omit<
  Promotion,
  "id" | "createdAt" | "updatedAt"
>;
export type UpdatePromotionInput = Partial<CreatePromotionInput> & {
  id: string;
};

export const DEFAULT_STORE_URL = "https://www.lojatogplay.com.br";
