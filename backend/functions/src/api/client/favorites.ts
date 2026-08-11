/**
 * Nota de design: favoritos NÃO são uma callable function.
 *
 * `toggleFavorite` é implementado como uma escrita direta do cliente em
 * `users/{uid}/favorites/{audioId}` (criar para favoritar, apagar para
 * desfavoritar), aplicado pelo firestore.rules como restrito ao dono. Este é
 * o design correto mais simples porque:
 *
 *   1. Não há validação do lado do servidor a fazer além de "esta é a minha
 *      própria subcoleção" — as regras do Firestore já expressam isso com
 *      precisão.
 *   2. Evita uma ida e volta de rede via Cloud Functions para uma ação de UI
 *      muito sensível a latência e tocada com frequência (veja o orçamento
 *      de <150ms do ARCHITECTURE.md §4 — favoritar está no mesmo caminho de
 *      interação da reprodução).
 *   3. A persistência offline do Firestore dá ao cliente, de graça, um
 *      toggle de favorito otimista e offline-first; uma callable exigiria
 *      reimplementar essa fila do lado do cliente de qualquer forma.
 *
 * A única coisa que REALMENTE precisa de consistência do lado do servidor —
 * o `AudioClip.favoriteCount` desnormalizado — é mantida em sincronia pelo
 * trigger `onFavoriteWrite` do Firestore (veja triggers/onFavoriteWrite.ts),
 * que roda com privilégios do Admin SDK independentemente de como o
 * documento de favorito foi escrito.
 *
 * Os eventos de analytics `favorite_add` / `favorite_remove` ainda são
 * enviados via `recordAnalyticsEvent` (veja analyticsEvents.ts), já que
 * escritas de analytics são sempre exclusivas de Cloud Function.
 */
export {};
