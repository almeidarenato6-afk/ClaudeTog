import { onSchedule } from "firebase-functions/v2/scheduler";
import { Timestamp } from "firebase-admin/firestore";
import { REGION } from "../config/env";
import { AnalyticsRepository } from "../repositories/AnalyticsRepository";
import { AudioRepository } from "../repositories/AudioRepository";
import { AnalyticsDailyRollup, PlaybackStrategy } from "../domain";

const analyticsRepository = new AnalyticsRepository();
const audioRepository = new AudioRepository();

function yesterdayUtcRange(): { date: string; start: Timestamp; end: Timestamp } {
  const now = new Date();
  const startOfToday = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const startOfYesterday = startOfToday - 24 * 60 * 60 * 1000;
  const date = new Date(startOfYesterday).toISOString().slice(0, 10); // YYYY-MM-DD
  return {
    date,
    start: Timestamp.fromMillis(startOfYesterday),
    end: Timestamp.fromMillis(startOfToday),
  };
}

/**
 * Executa uma vez por dia e consolida os `analytics_events` do dia UTC
 * anterior em um único doc `analytics_daily/{date}` para leituras baratas no
 * painel admin. Na escala atual, um scan simples do Firestore é suficiente;
 * veja ARCHITECTURE.md §11 para o caminho planejado Pub/Sub → BigQuery quando
 * o volume de eventos ultrapassar isso.
 */
export const aggregateDailyAnalytics = onSchedule(
  { region: REGION, schedule: "every day 03:00", timeZone: "America/Sao_Paulo" },
  async () => {
    const { date, start, end } = yesterdayUtcRange();
    const events = await analyticsRepository.listEventsInRange(start, end);

    const playsByAudio: Record<string, number> = {};
    const playsByCategory: Record<string, number> = {};
    const playsByStrategy: Record<PlaybackStrategy, number> = {
      DIRECT: 0,
      RELAY: 0,
      PHONE_ONLY: 0,
    };

    let totalPlays = 0;
    let totalSessions = 0;
    let totalFavoritesAdded = 0;
    let totalFavoritesRemoved = 0;
    let sessionDurationSum = 0;
    let sessionDurationCount = 0;
    const activeUids = new Set<string>();

    for (const event of events) {
      if (event.uid) activeUids.add(event.uid);

      switch (event.type) {
        case "audio_play":
          totalPlays += 1;
          if (event.audioId) {
            playsByAudio[event.audioId] = (playsByAudio[event.audioId] ?? 0) + 1;
          }
          if (event.categoryId) {
            playsByCategory[event.categoryId] = (playsByCategory[event.categoryId] ?? 0) + 1;
          }
          if (event.playbackStrategy) {
            playsByStrategy[event.playbackStrategy] += 1;
          }
          break;
        case "session_start":
          totalSessions += 1;
          break;
        case "session_end":
          if (typeof event.sessionDurationMs === "number") {
            sessionDurationSum += event.sessionDurationMs;
            sessionDurationCount += 1;
          }
          break;
        case "favorite_add":
          totalFavoritesAdded += 1;
          break;
        case "favorite_remove":
          totalFavoritesRemoved += 1;
          break;
        default:
          break;
      }
    }

    const rollup: AnalyticsDailyRollup = {
      date,
      totalPlays,
      totalSessions,
      totalFavoritesAdded,
      totalFavoritesRemoved,
      activeUsers: activeUids.size,
      avgSessionDurationMs:
        sessionDurationCount > 0 ? Math.round(sessionDurationSum / sessionDurationCount) : 0,
      playsByAudio,
      playsByCategory,
      playsByStrategy,
      generatedAt: Timestamp.now(),
    };

    await analyticsRepository.saveDailyRollup(rollup);

    // Sincroniza o AudioClip.playCount desnormalizado para que leituras do
    // catálogo (ex.: "mais tocados") não precisem de um join com analytics_daily.
    await Promise.all(
      Object.entries(playsByAudio).map(([audioId, count]) =>
        audioRepository.incrementPlayCount(audioId, count)
      )
    );
  }
);
