/**
 * Populates Firestore with starter categories and audio clips.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
 *   STORAGE_BUCKET=<your-project-id>.appspot.com \
 *   npx ts-node seed.ts
 *
 * Safe to re-run: categories/audios use deterministic doc IDs (their slug /
 * file basename), so subsequent runs update rather than duplicate.
 *
 * NOTE: this only writes Firestore documents. It does NOT upload actual
 * audio files to Cloud Storage — `audioUrl`/`storagePath` below point at
 * where each file should live (`catalog/audios/{audioId}/master.m4a`).
 * Upload the real .m4a masters via the admin panel or `gsutil cp` before
 * shipping; until then `audioUrl` will 404.
 */
import * as admin from "firebase-admin";
import categoriesSeed from "./categories.json";
import audiosSeed from "./audios.json";

admin.initializeApp();
const db = admin.firestore();
const bucketName = process.env.STORAGE_BUCKET ?? "REPLACE_WITH_YOUR_BUCKET.appspot.com";

interface CategorySeed {
  slug: string;
  name: string;
  order: number;
  icon: string;
  color: string;
}

interface AudioSeed {
  categorySlug: string;
  title: string;
  phrase: string;
  fileName: string;
  durationMs: number;
  order: number;
  tags: string[];
  isFeatured: boolean;
}

async function seedCategories(): Promise<Record<string, string>> {
  const slugToId: Record<string, string> = {};
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();

  for (const category of categoriesSeed as CategorySeed[]) {
    const ref = db.collection("categories").doc(category.slug);
    slugToId[category.slug] = ref.id;
    batch.set(
      ref,
      {
        id: ref.id,
        name: category.name,
        slug: category.slug,
        order: category.order,
        icon: category.icon,
        color: category.color,
        isActive: true,
        audioCount: 0, // corrected below once audios are written
        createdAt: now,
        updatedAt: now,
      },
      { merge: true }
    );
  }

  await batch.commit();
  console.log(`Seeded ${categoriesSeed.length} categories.`);
  return slugToId;
}

async function seedAudios(slugToId: Record<string, string>): Promise<void> {
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  const audioCountByCategory: Record<string, number> = {};

  for (const audio of audiosSeed as AudioSeed[]) {
    const categoryId = slugToId[audio.categorySlug];
    if (!categoryId) {
      throw new Error(`Unknown categorySlug "${audio.categorySlug}" in audios.json`);
    }

    const docId = audio.fileName.replace(/\.[^.]+$/, "");
    const storagePath = `catalog/audios/${docId}/master.m4a`;
    const ref = db.collection("audios").doc(docId);

    batch.set(
      ref,
      {
        id: ref.id,
        categoryId,
        title: audio.title,
        phrase: audio.phrase,
        audioUrl: `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(
          storagePath
        )}?alt=media`,
        storagePath,
        durationMs: audio.durationMs,
        order: audio.order,
        isActive: true,
        isFeatured: audio.isFeatured,
        tags: audio.tags,
        locale: "pt-BR",
        playCount: 0,
        favoriteCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: "seed-script",
      },
      { merge: true }
    );

    audioCountByCategory[categoryId] = (audioCountByCategory[categoryId] ?? 0) + 1;
  }

  await batch.commit();
  console.log(`Seeded ${audiosSeed.length} audios.`);

  const countBatch = db.batch();
  for (const [categoryId, count] of Object.entries(audioCountByCategory)) {
    countBatch.update(db.collection("categories").doc(categoryId), { audioCount: count });
  }
  await countBatch.commit();
}

async function main() {
  const slugToId = await seedCategories();
  await seedAudios(slugToId);
  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
