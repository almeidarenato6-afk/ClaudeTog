import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import type { AnalyticsQuery, AnalyticsSummary } from "./types";

export async function listAnalyticsSummary(
  input: AnalyticsQuery,
): Promise<AnalyticsSummary> {
  const call = httpsCallable<AnalyticsQuery, AnalyticsSummary>(
    functions,
    "listAnalyticsSummary",
  );
  const result = await call(input);
  return result.data;
}
