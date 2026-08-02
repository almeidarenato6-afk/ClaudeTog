import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { REGION, config } from "../../config/env";
import { requireAdmin } from "./middleware";
import { sendPush } from "../../notifications/fcm";
import { NotificationRepository } from "../../repositories/NotificationRepository";

const notificationRepository = new NotificationRepository();

const sendNotificationSchema = z.object({
  title: z.string().min(1).max(120),
  body: z.string().min(1).max(400),
  imageUrl: z.string().url().optional(),
  data: z.record(z.string()).optional(),
  target: z.union([
    z.object({ type: z.literal("topic"), topic: z.string().min(1) }),
    z.object({ type: z.literal("segment"), segment: z.string().min(1) }),
    z.object({ type: z.literal("uid"), uid: z.string().min(1) }),
  ]),
});

/**
 * Broadcasts a push notification (new audio, promotion, new category) via FCM.
 * Every device subscribes to `config.fcmDefaultTopic` on registration, so
 * `{type: "topic", topic: config.fcmDefaultTopic}` is the "everyone" case.
 */
export const sendNotification = onCall({ region: REGION }, async (request) => {
  const uid = requireAdmin(request);

  const parsed = sendNotificationSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { title, body, imageUrl, data, target } = parsed.data;

  const result = await sendPush(target, { title, body, imageUrl, data });

  const record = await notificationRepository.log({
    title,
    body,
    imageUrl,
    target,
    data,
    sentBy: uid,
    successCount: result.successCount,
    failureCount: result.failureCount,
  });

  return record;
});

// Re-exported so callers/tests can reference the default broadcast topic name
// without importing config directly.
export const DEFAULT_BROADCAST_TOPIC = config.fcmDefaultTopic;
