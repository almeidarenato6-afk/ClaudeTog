/**
 * Local central para configuração derivada do ambiente. Cloud Functions v2 lê a
 * configuração de runtime a partir de variáveis de ambiente (definidas via
 * `firebase functions:secrets:set` para segredos, ou arquivos `.env.<projectId>` para
 * configuração simples) em vez da API depreciada `functions.config()`.
 */

export const REGION = process.env.FUNCTIONS_REGION ?? "southamerica-east1";

export const config = {
  region: REGION,
  // Tópico FCM padrão ao qual todo dispositivo se inscreve no registro; usado para
  // notificações admin do tipo "transmitir para todos".
  fcmDefaultTopic: "all_users",
  // Tetos flexíveis aplicados nos handlers dos callables (defesa em profundidade além
  // das Storage rules, já que as Storage rules sozinhas não conseguem limitar escritas
  // em lote no Firestore).
  limits: {
    maxAnalyticsEventsPerBatch: 50,
    maxStarterPackAudios: 20,
  },
} as const;
