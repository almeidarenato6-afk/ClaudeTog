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
 * Sends a push through FCM to a topic, a resolved segment (only "favorites_users"
 * today — expand as new segments are needed), or a single user's registered devices.
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
 * Segment resolution is intentionally minimal today — only "favorites_users"
 * (anyone with >= 1 favorite). Extend here as the admin panel grows more
 * targeting options; keep the resolution logic out of the callable handlers.
 */
async function resolveSegmentTokens(segment: string): Promise<string[]> {
  if (segment !== "favorites_users") {
    throw new Error(`Unknown notification segment: ${segment}`);
  }
  // NOTE: naive collection-group scan; fine at current scale, revisit with a
  // denormalized `hasFavorites` flag on the user doc if this gets expensive.
  const favSnap = await db.collectionGroup("favorites").select().get();
  const uids = new Set(favSnap.docs.map((d) => d.ref.parent.parent!.id));

  const tokenLists = await Promise.all(
    [...uids].map((uid) => userRepository.fcmTokensForUser(uid))
  );
  return tokenLists.flat();
}
