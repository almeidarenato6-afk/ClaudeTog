import { db, messaging } from "../config/firebaseAdmin";
import { UserRepository } from "../repositories/UserRepository";
import { NotificationTarget } from "../domain/Notification";

const userRepository = new UserRepository();

export interface SendResult {
  successCount: number;
  failureCount: number;
}

interface PushPayload {
  title: string;
  body: string;
  imageUrl?: string;
  data?: Record<string, string>;
}

/**
 * Envia um push via FCM para um tópico, um segmento resolvido (apenas "favorites_users"
 * por enquanto — expanda conforme novos segmentos forem necessários), ou os dispositivos
 * registrados de um único usuário.
 */
export async function sendPush(
  target: NotificationTarget,
  payload: PushPayload
): Promise<SendResult> {
  const notification = {
    title: payload.title,
    body: payload.body,
    ...(payload.imageUrl ? { imageUrl: payload.imageUrl } : {}),
  };

  if (target.type === "topic") {
    await messaging.send({ topic: target.topic, notification, data: payload.data });
    return { successCount: 1, failureCount: 0 };
  }

  if (target.type === "uid") {
    const tokens = await userRepository.fcmTokensForUser(target.uid);
    return sendToTokens(tokens, notification, payload.data);
  }

  // target.type === "segment"
  const tokens = await resolveSegmentTokens(target.segment);
  return sendToTokens(tokens, notification, payload.data);
}

async function sendToTokens(
  tokens: string[],
  notification: { title: string; body: string; imageUrl?: string },
  data?: Record<string, string>
): Promise<SendResult> {
  if (tokens.length === 0) return { successCount: 0, failureCount: 0 };

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification,
    data,
  });
  return { successCount: response.successCount, failureCount: response.failureCount };
}

/**
 * A resolução de segmentos é intencionalmente mínima por enquanto — apenas
 * "favorites_users" (qualquer um com >= 1 favorito). Estenda aqui conforme o
 * painel admin ganhar mais opções de segmentação; mantenha a lógica de
 * resolução fora dos handlers callable.
 */
async function resolveSegmentTokens(segment: string): Promise<string[]> {
  if (segment !== "favorites_users") {
    throw new Error(`Unknown notification segment: ${segment}`);
  }
  // NOTA: scan ingênuo de collection-group; ok na escala atual, revisitar com uma
  // flag `hasFavorites` desnormalizada no doc do usuário se isso ficar caro.
  const favSnap = await db.collectionGroup("favorites").select().get();
  const uids = new Set(favSnap.docs.map((d) => d.ref.parent.parent!.id));

  const tokenLists = await Promise.all(
    [...uids].map((uid) => userRepository.fcmTokensForUser(uid))
  );
  return tokenLists.flat();
}
