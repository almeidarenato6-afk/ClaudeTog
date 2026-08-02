// Vai Márcia (TogPlay) — Cloud Functions entry point.
// Every deployable function must be re-exported from here (Firebase discovers
// deployable functions by the top-level exports of this file).
import "./config/firebaseAdmin"; // ensure Admin SDK is initialized exactly once, first

// Admin panel API
export { setUserRole } from "./api/admin/auth";
export { createAudio, updateAudio, deleteAudio } from "./api/admin/audios";
export { createCategory, updateCategory } from "./api/admin/categories";
export { listAnalyticsSummary } from "./api/admin/analytics";
export { sendNotification } from "./api/admin/notifications";
export { createPromotion, updatePromotion } from "./api/admin/promotions";

// Public catalog API
export { getStarterPack } from "./api/catalog/starterPack";

// Mobile/watch client API
export { registerDevice } from "./api/client/registerDevice";
export { recordAnalyticsEvent } from "./api/client/analyticsEvents";
// Note: toggleFavorite is intentionally NOT here — see api/client/favorites.ts.

// Triggers
export { onAudioCreate } from "./triggers/onAudioCreate";
export { onUserCreate } from "./triggers/onUserCreate";
export { onFavoriteWrite } from "./triggers/onFavoriteWrite";
export { aggregateDailyAnalytics } from "./triggers/aggregateDailyAnalytics";
