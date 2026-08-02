// Shared domain types mirrored from the backend's Firestore schema /
// Cloud Functions contract (see docs/ARCHITECTURE.md §6, §10). These are
// hand-typed against the *plausible* contract described for the backend
// agent's work-in-progress — reconcile against DATABASE_SCHEMA.md /
// API_DESIGN.md once those land, and adjust field names if they drift.

export type StaffRole = "admin" | "content_manager" | "viewer";

export interface StaffClaims {
  role: StaffRole;
}

/** Product spec categories — "Personalizados" covers user-recorded audios. */
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
  icon: string; // icon name/emoji reference rendered by clients
  color: string; // hex, used for chips/badges across clients
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
  /** Storage path of the already-uploaded file, e.g. `audios/raw/<uuid>.m4a`. */
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
