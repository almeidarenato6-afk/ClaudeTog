import { Timestamp } from "firebase-admin/firestore";

export type ClientPlatform = "ios" | "android" | "wearos" | "watchos" | "garmin";

/** Mirrors the on-device `PlaybackStrategy` from docs/DEVICE_DETECTION.md. */
export type PlaybackStrategy = "DIRECT" | "RELAY" | "PHONE_ONLY";

/**
 * Firestore: `users/{uid}/devices/{deviceId}`
 * Owner-only read; write only via the `registerDevice` callable (Admin SDK),
 * never directly from the client — keeps capability-probe data trustworthy
 * for analytics segmentation (watch model, bluetooth speaker brand, etc.).
 */
export interface DeviceCapabilityProfile {
  deviceId: string; // client-generated stable installation/device id
  platform: ClientPlatform;
  watchModel?: string; // e.g. "Galaxy Watch6", "Apple Watch Series 9"
  phoneModel?: string; // e.g. "Pixel 8", "iPhone 15"
  bluetoothSpeakerBrand?: string; // best-effort, only known when a speaker is paired
  playbackStrategy: PlaybackStrategy;
  fcmToken?: string; // push token for this installation
  appVersion: string;
  osVersion: string;
  createdAt: Timestamp;
  lastSeenAt: Timestamp;
}

export type DeviceRegisterInput = Omit<
  DeviceCapabilityProfile,
  "createdAt" | "lastSeenAt"
>;
