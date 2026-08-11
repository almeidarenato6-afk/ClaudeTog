import { Timestamp } from "firebase-admin/firestore";

export type NotificationTarget =
  | { type: "topic"; topic: string }
  | { type: "segment"; segment: string } // resolvido no servidor para um conjunto de tokens
  | { type: "uid"; uid: string };

/**
 * Firestore: `notifications_log/{notificationId}`
 * Escrito apenas pelo callable admin `sendNotification` após o envio ao
 * FCM; legível pelos papéis admin/content_manager/viewer para o histórico de
 * envios do painel. Não é o payload da mensagem em si — o FCM não persiste isso.
 */
export interface NotificationRecord {
  id: string;
  title: string;
  body: string;
  imageUrl?: string;
  target: NotificationTarget;
  data?: Record<string, string>; // payload de deep-link arbitrário tratado pelo cliente
  sentBy: string; // uid do admin
  sentAt: Timestamp;
  successCount: number;
  failureCount: number;
}
