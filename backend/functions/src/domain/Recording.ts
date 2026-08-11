import { Timestamp } from "firebase-admin/firestore";

/**
 * Espelha os estágios do `AudioProcessingPipeline` do lado do cliente descritos
 * em docs/ARCHITECTURE.md §8. Hoje só `uploaded`/`ready`/`failed` têm sentido
 * (um único `PassthroughStage`); `processing` fica reservado para quando um
 * futuro pipeline (redução de ruído, realce de voz, auto-categorização)
 * realmente rodar no servidor. Ainda não implementado — apenas um ponto de extensão.
 */
export type RecordingStatus = "uploaded" | "processing" | "ready" | "failed";

/**
 * Firestore: `users/{uid}/recordings/{recordingId}`
 * Privado por padrão — leitura/escrita restrita ao dono (veja firestore.rules).
 */
export interface Recording {
  id: string;
  storagePath: string; // users/{uid}/recordings/{fileName} no Cloud Storage
  durationMs: number;
  status: RecordingStatus;
  createdAt: Timestamp;
}
