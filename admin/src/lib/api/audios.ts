import {
  collection,
  getDocs,
  limit as fsLimit,
  orderBy,
  query,
  Timestamp,
  where,
  type QueryConstraint,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { ref, uploadBytesResumable, type UploadTask } from "firebase/storage";
import { db, functions, storage } from "@/lib/firebase";
import type {
  Audio,
  AudioListFilters,
  CreateAudioInput,
  UpdateAudioInput,
} from "./types";

const COLLECTION = "audios";

interface AudioDoc {
  title: string;
  phraseText: string;
  categoryId: string;
  audioUrl: string;
  durationMs: number | null;
  active: boolean;
  playCount: number;
  createdAt: Timestamp | null;
  updatedAt: Timestamp | null;
  createdBy: string | null;
}

function fromDoc(id: string, data: AudioDoc): Audio {
  return {
    id,
    title: data.title,
    phraseText: data.phraseText,
    categoryId: data.categoryId,
    audioUrl: data.audioUrl,
    durationMs: data.durationMs,
    active: data.active,
    playCount: data.playCount ?? 0,
    createdAt: data.createdAt?.toDate().toISOString() ?? "",
    updatedAt: data.updatedAt?.toDate().toISOString() ?? "",
    createdBy: data.createdBy,
  };
}

export async function listAudios(
  filters: AudioListFilters = {},
): Promise<Audio[]> {
  const constraints: QueryConstraint[] = [orderBy("createdAt", "desc")];
  if (filters.categoryId) {
    constraints.push(where("categoryId", "==", filters.categoryId));
  }
  if (filters.active !== undefined) {
    constraints.push(where("active", "==", filters.active));
  }
  constraints.push(fsLimit(500));

  const snap = await getDocs(query(collection(db, COLLECTION), ...constraints));
  let items = snap.docs.map((d) => fromDoc(d.id, d.data() as AudioDoc));

  // Client-side text filter — Firestore has no native full-text search and
  // this list is expected to stay in the low thousands, not millions.
  if (filters.search?.trim()) {
    const needle = filters.search.trim().toLowerCase();
    items = items.filter(
      (a) =>
        a.title.toLowerCase().includes(needle) ||
        a.phraseText.toLowerCase().includes(needle),
    );
  }

  return items;
}

/**
 * Uploads the raw audio file to Cloud Storage under `audios/uploads/` and
 * returns the storage path Cloud Functions will use to validate/transcode
 * and register the Firestore doc (see createAudio callable below).
 */
export function uploadAudioFile(
  file: File,
  onProgress?: (pct: number) => void,
): { task: UploadTask; storagePath: string } {
  const ext = file.name.split(".").pop() ?? "m4a";
  const storagePath = `audios/uploads/${crypto.randomUUID()}.${ext}`;
  const task = uploadBytesResumable(ref(storage, storagePath), file, {
    contentType: file.type || "audio/mp4",
  });
  if (onProgress) {
    task.on("state_changed", (snapshot) => {
      onProgress(
        Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100),
      );
    });
  }
  return { task, storagePath };
}

export async function createAudio(
  input: CreateAudioInput,
): Promise<{ id: string }> {
  const call = httpsCallable<CreateAudioInput, { id: string }>(
    functions,
    "createAudio",
  );
  const result = await call(input);
  return result.data;
}

export async function updateAudio(input: UpdateAudioInput): Promise<void> {
  const call = httpsCallable<UpdateAudioInput, void>(functions, "updateAudio");
  await call(input);
}

export async function deleteAudio(id: string): Promise<void> {
  const call = httpsCallable<{ id: string }, void>(functions, "deleteAudio");
  await call({ id });
}

export async function setAudioActive(
  id: string,
  active: boolean,
): Promise<void> {
  await updateAudio({ id, active });
}
