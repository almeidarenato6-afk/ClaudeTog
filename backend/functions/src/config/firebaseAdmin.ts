import { initializeApp, getApps, App } from "firebase-admin/app";
import { getFirestore, Firestore } from "firebase-admin/firestore";
import { getAuth, Auth } from "firebase-admin/auth";
import { getStorage, Storage } from "firebase-admin/storage";
import { getMessaging, Messaging } from "firebase-admin/messaging";

// Instância única do app Admin SDK compartilhada por todas as functions deste codebase.
// Cloud Functions pode fazer cold-start de múltiplas instâncias do módulo, então
// protegemos contra reinicialização quando `getApps()` já retorna uma (comum em
// execuções de emulador + testes).
export const app: App = getApps().length > 0 ? getApps()[0] : initializeApp();

export const db: Firestore = getFirestore(app);
export const auth: Auth = getAuth(app);
export const storage: Storage = getStorage(app);
export const messaging: Messaging = getMessaging(app);

// O Firestore ignora campos `undefined` por padrão no Admin SDK, mas definimos
// isso explicitamente para que os helpers de atualização parcial (ex.: `{...patch}`)
// nunca quebrem quando um campo opcional for omitido.
db.settings({ ignoreUndefinedProperties: true });
