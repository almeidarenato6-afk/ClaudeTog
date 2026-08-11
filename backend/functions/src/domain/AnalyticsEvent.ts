import { Timestamp } from "firebase-admin/firestore";
import { ClientPlatform, PlaybackStrategy } from "./Device";

export type AnalyticsEventType =
  | "app_open"
  | "session_start"
  | "session_end"
  | "audio_play"
  | "favorite_add"
  | "favorite_remove";

/**
 * Firestore: `analytics_events/{eventId}`
 * Somente escrita a partir de Cloud Functions — os clientes nunca podem ler ou
 * escrever nesta coleção diretamente (veja firestore.rules); a ingestão passa
 * pelo callable `recordAnalyticsEvent` em api/client/analyticsEvents.ts.
 *
 * Nota sobre volume: conforme o ARCHITECTURE.md §11, em escala isso deveria fluir
 * via Pub/Sub para o BigQuery em vez do Firestore. Ainda não implementado — o
 * rollup `analytics_daily` (veja AnalyticsDailyRollup abaixo) é o caminho de
 * agregação provisório para o painel admin.
 */
export interface AnalyticsEvent {
  id: string;
  uid: string | null; // null apenas se de alguma forma ingerido antes da autenticação; auth anônima ainda tem uid
  type: AnalyticsEventType;
  audioId?: string; // presente para audio_play, favorite_add, favorite_remove
  categoryId?: string;
  sessionId?: string;
  sessionDurationMs?: number; // presente para session_end
  playbackStrategy?: PlaybackStrategy; // presente para audio_play
  watchModel?: string;
  phoneModel?: string;
  bluetoothSpeakerBrand?: string;
  platform?: ClientPlatform;
  appVersion?: string;
  clientTimestamp: Timestamp; // quando o evento aconteceu no dispositivo
  receivedAt: Timestamp; // horário de ingestão no servidor (referência para desvio de relógio)
}

export type AnalyticsEventInput = Omit<AnalyticsEvent, "id" | "uid" | "receivedAt">;

/**
 * Firestore: `analytics_daily/{date}` onde date é `YYYY-MM-DD` (UTC).
 * Construído pela function agendada `aggregateDailyAnalytics` a partir dos
 * `analytics_events` do dia anterior. Leitura restrita ao painel admin (veja rules).
 */
export interface AnalyticsDailyRollup {
  date: string;
  totalPlays: number;
  totalSessions: number;
  totalFavoritesAdded: number;
  totalFavoritesRemoved: number;
  activeUsers: number; // uids distintos vistos em todos os tipos de evento
  avgSessionDurationMs: number;
  playsByAudio: Record<string, number>;
  playsByCategory: Record<string, number>;
  playsByStrategy: Record<PlaybackStrategy, number>;
  generatedAt: Timestamp;
}
