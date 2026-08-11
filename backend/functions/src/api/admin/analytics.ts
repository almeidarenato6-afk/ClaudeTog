import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { REGION } from "../../config/env";
import { requireRole } from "./middleware";
import { AnalyticsRepository } from "../../repositories/AnalyticsRepository";

const analyticsRepository = new AnalyticsRepository();

const listAnalyticsSummarySchema = z.object({
  days: z.number().int().min(1).max(90).default(7),
});

/** Também somente leitura para `viewer` — dashboards não deveriam exigir acesso de escrita. */
export const listAnalyticsSummary = onCall({ region: REGION }, async (request) => {
  requireRole(request, ["admin", "content_manager", "viewer"]);

  const parsed = listAnalyticsSummarySchema.safeParse(request.data ?? {});
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const rollups = await analyticsRepository.listRecentRollups(parsed.data.days);
  return { rollups };
});
