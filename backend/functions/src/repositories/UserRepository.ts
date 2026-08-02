import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import { UserProfile, UserProfileUpdateInput } from "../domain/UserProfile";
import { DeviceCapabilityProfile, DeviceRegisterInput } from "../domain/Device";
import { Favorite } from "../domain/Favorite";

export class UserRepository {
  private col = db.collection("users");

  async getProfile(uid: string): Promise<UserProfile | null> {
    const snap = await this.col.doc(uid).get();
    return snap.exists ? (snap.data() as UserProfile) : null;
  }

  async createProfile(profile: UserProfile): Promise<void> {
    await this.col.doc(profile.uid).set(profile, { merge: true });
  }

  async updateProfile(uid: string, patch: UserProfileUpdateInput): Promise<void> {
    await this.col.doc(uid).update({ ...patch, updatedAt: Timestamp.now() });
  }

  async touchLastActive(uid: string): Promise<void> {
    await this.col.doc(uid).update({ lastActiveAt: Timestamp.now() });
  }

  async upsertDevice(uid: string, input: DeviceRegisterInput): Promise<DeviceCapabilityProfile> {
    const ref = this.col.doc(uid).collection("devices").doc(input.deviceId);
    const existing = await ref.get();
    const now = Timestamp.now();
    const device: DeviceCapabilityProfile = {
      ...input,
      createdAt: existing.exists ? (existing.data() as DeviceCapabilityProfile).createdAt : now,
      lastSeenAt: now,
    };
    await ref.set(device, { merge: true });
    return device;
  }

  async listFavorites(uid: string): Promise<Favorite[]> {
    const snap = await this.col.doc(uid).collection("favorites").get();
    return snap.docs.map((d) => d.data() as Favorite);
  }

  async fcmTokensForUser(uid: string): Promise<string[]> {
    const snap = await this.col.doc(uid).collection("devices").get();
    return snap.docs
      .map((d) => (d.data() as DeviceCapabilityProfile).fcmToken)
      .filter((t): t is string => Boolean(t));
  }
}
