import { Timestamp } from "firebase-admin/firestore";

/**
 * Mirrors the client-side `AudioProcessingPipeline` stages described in
 * docs/ARCHITECTURE.md §8. Only `uploaded`/`ready`/`failed` are meaningful
 * today (a single `PassthroughStage`); `processing` is reserved for when a
 * future pipeline (noise reduction, voice enhancement, auto-categorization)
 * actually runs server-side. Not implemented yet — extension point only.
 */
export type RecordingStatus = "uploaded" | "processing" | "ready" | "failed";

/**
 * Firestore: `users/{uid}/recordings/{recordingId}`
 * Private by default — owner-only read/write (see firestore.rules).
 */
export interface Recording {
  id: string;
  storagePath: string; // users/{uid}/recordings/{fileName} in Cloud Storage
  durationMs: number;
  status: RecordingStatus;
  createdAt: Timestamp;
}
