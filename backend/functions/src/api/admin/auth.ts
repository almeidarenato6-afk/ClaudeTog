import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { auth } from "../../config/firebaseAdmin";
import { REGION } from "../../config/env";
import { requireAdmin } from "./middleware";
import { ROLES } from "../../domain/UserProfile";

const setUserRoleSchema = z.object({
  uid: z.string().min(1),
  role: z.enum(ROLES as [string, ...string[]]),
});

/**
 * Concede um papel de painel admin via custom claim. Somente um `admin` já
 * existente pode chamar isso — o bootstrap do primeiríssimo admin precisa ser
 * feito fora desse fluxo (console do Firebase ou script `firebase auth:import`/
 * Admin SDK), veja o README.
 */
export const setUserRole = onCall({ region: REGION }, async (request) => {
  requireAdmin(request);

  const parsed = setUserRoleSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }
  const { uid, role } = parsed.data;

  const user = await auth.getUser(uid).catch(() => null);
  if (!user) {
    throw new HttpsError("not-found", `No user with uid ${uid}.`);
  }

  const existingClaims = user.customClaims ?? {};
  await auth.setCustomUserClaims(uid, { ...existingClaims, role });

  return { uid, role };
});
