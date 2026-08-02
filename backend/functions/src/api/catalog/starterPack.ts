import { onCall } from "firebase-functions/v2/https";
import { REGION, config } from "../../config/env";
import { AudioRepository } from "../../repositories/AudioRepository";
import { CategoryRepository } from "../../repositories/CategoryRepository";

const audioRepository = new AudioRepository();
const categoryRepository = new CategoryRepository();

/**
 * Returns the minimal "starter pack" (all active categories + featured audios)
 * for first-run 100% offline usage, per ARCHITECTURE.md §7. Public — no auth
 * required, since a brand-new install may still be on anonymous auth or none
 * at all during onboarding.
 *
 * This is a convenience aggregation only: nothing here is unreachable by
 * direct Firestore reads (categories/audios are public-read), it just saves
 * the client a fan-out of queries on cold start.
 */
export const getStarterPack = onCall({ region: REGION }, async () => {
  const [categories, featuredAudios] = await Promise.all([
    categoryRepository.listActive(),
    audioRepository.listFeatured(config.limits.maxStarterPackAudios),
  ]);

  return { categories, audios: featuredAudios };
});
