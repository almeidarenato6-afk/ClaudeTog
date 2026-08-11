// Vai Márcia (TogPlay) — ponto de entrada das Cloud Functions.
// Toda função implantável precisa ser reexportada aqui (o Firebase descobre
// as funções implantáveis pelos exports de nível superior deste arquivo).
import "./config/firebaseAdmin"; // garante que o Admin SDK seja inicializado exatamente uma vez, antes de tudo

// API do painel admin
export { setUserRole } from "./api/admin/auth";
export { createAudio, updateAudio, deleteAudio } from "./api/admin/audios";
export { createCategory, updateCategory } from "./api/admin/categories";
export { listAnalyticsSummary } from "./api/admin/analytics";
export { sendNotification } from "./api/admin/notifications";
export { createPromotion, updatePromotion } from "./api/admin/promotions";

// API pública de catálogo
export { getStarterPack } from "./api/catalog/starterPack";

// API do cliente mobile/watch
export { registerDevice } from "./api/client/registerDevice";
export { recordAnalyticsEvent } from "./api/client/analyticsEvents";
// Nota: toggleFavorite está propositalmente ausente daqui — veja api/client/favorites.ts.

// Triggers
export { onAudioCreate } from "./triggers/onAudioCreate";
export { onUserCreate } from "./triggers/onUserCreate";
export { onFavoriteWrite } from "./triggers/onFavoriteWrite";
export { aggregateDailyAnalytics } from "./triggers/aggregateDailyAnalytics";
