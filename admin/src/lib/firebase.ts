import { initializeApp } from "firebase/app";
import {
  connectAuthEmulator,
  getAuth,
  setPersistence,
  browserLocalPersistence,
} from "firebase/auth";
import { connectFirestoreEmulator, getFirestore } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions } from "firebase/functions";
import { connectStorageEmulator, getStorage } from "firebase/storage";

// Todos os valores vêm de env vars do Vite (ver .env.example). Até o time
// de backend disponibilizar a config real do projeto Firebase, esses
// valores resolvem para a string literal "TODO" e o app vai falhar nas
// chamadas de Firebase Auth/Firestore em runtime — a UI em si continua
// buildando e renderizando normalmente.
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const functionsRegion =
  import.meta.env.VITE_FIREBASE_FUNCTIONS_REGION || "us-central1";

export const firebaseApp = initializeApp(firebaseConfig);

export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
export const functions = getFunctions(firebaseApp, functionsRegion);
export const storage = getStorage(firebaseApp);

void setPersistence(auth, browserLocalPersistence);

const useEmulators = import.meta.env.VITE_USE_FIREBASE_EMULATORS === "true";

if (useEmulators) {
  connectAuthEmulator(auth, "http://localhost:9099", {
    disableWarnings: true,
  });
  connectFirestoreEmulator(db, "localhost", 8080);
  connectFunctionsEmulator(functions, "localhost", 5001);
  connectStorageEmulator(storage, "localhost", 9199);
}
