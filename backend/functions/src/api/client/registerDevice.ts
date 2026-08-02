import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { REGION } from "../../config/env";
import { UserRepository } from "../../repositories/UserRepository";

const userRepository = new UserRepository();

const registerDeviceSchema = z.object({
  deviceId: z.string().min(1),
  platform: z.enum(["ios", "android", "wearos", "watchos", "garmin"]),
  watchModel: z.string().max(120).optional(),
  phoneModel: z.string().max(120).optional(),
  bluetoothSpeakerBrand: z.string().max(120).optional(),
  playbackStrategy: z.enum(["DIRECT", "RELAY", "PHONE_ONLY"]),
  fcmToken: z.string().optional(),
  appVersion: z.string().min(1),
  osVersion: z.string().min(1),
});

/**
 * Writes the caller's `DeviceCapabilityProfile`. A callable rather than a
 * direct client write (Firestore rules deny direct writes to
 * `users/{uid}/devices/**`) so device/analytics-segmentation fields — watch
 * model, bluetooth speaker brand, playback strategy — are always populated
 * through one validated, schema-checked path instead of trusting arbitrary
 * client-shaped documents.
 */
export const registerDevice = onCall({ region: REGION }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign-in required (anonymous auth is fine).");
  }

  const parsed = registerDeviceSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const device = await userRepository.upsertDevice(uid, parsed.data);
  return device;
});
