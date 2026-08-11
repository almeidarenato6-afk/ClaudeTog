import { Timestamp } from "firebase-admin/firestore";

export type ClientPlatform = "ios" | "android" | "wearos" | "watchos" | "garmin";

/** Espelha o `PlaybackStrategy` do dispositivo definido em docs/DEVICE_DETECTION.md. */
export type PlaybackStrategy = "DIRECT" | "RELAY" | "PHONE_ONLY";

/**
 * Firestore: `users/{uid}/devices/{deviceId}`
 * Leitura restrita ao dono; escrita apenas via o callable `registerDevice` (Admin SDK),
 * nunca diretamente do cliente — isso mantém os dados de probe de capacidade confiáveis
 * para a segmentação de analytics (modelo do watch, marca da caixa de som bluetooth, etc.).
 */
export interface DeviceCapabilityProfile {
  deviceId: string; // id de instalação/dispositivo estável gerado pelo cliente
  platform: ClientPlatform;
  watchModel?: string; // ex.: "Galaxy Watch6", "Apple Watch Series 9"
  phoneModel?: string; // ex.: "Pixel 8", "iPhone 15"
  bluetoothSpeakerBrand?: string; // melhor esforço, só conhecido quando uma caixa de som está pareada
  playbackStrategy: PlaybackStrategy;
  fcmToken?: string; // token de push desta instalação
  appVersion: string;
  osVersion: string;
  createdAt: Timestamp;
  lastSeenAt: Timestamp;
}

export type DeviceRegisterInput = Omit<
  DeviceCapabilityProfile,
  "createdAt" | "lastSeenAt"
>;
