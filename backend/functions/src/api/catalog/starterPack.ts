import { onCall } from "firebase-functions/v2/https";
import { REGION, config } from "../../config/env";
import { AudioRepository } from "../../repositories/AudioRepository";
import { CategoryRepository } from "../../repositories/CategoryRepository";

const audioRepository = new AudioRepository();
const categoryRepository = new CategoryRepository();

/**
 * Retorna o "starter pack" mínimo (todas as categorias ativas + áudios em
 * destaque) para uso 100% offline no primeiro uso, conforme ARCHITECTURE.md §7.
 * Público — não exige autenticação, já que uma instalação recém-feita pode
 * ainda estar em auth anônima ou sem nenhuma durante o onboarding.
 *
 * Esta é apenas uma agregação de conveniência: nada aqui é inacessível via
 * leituras diretas no Firestore (categories/audios têm leitura pública), isso
 * só evita que o cliente precise disparar várias queries no cold start.
 */
export const getStarterPack = onCall({ region: REGION }, async () => {
  const [categories, featuredAudios] = await Promise.all([
    categoryRepository.listActive(),
    audioRepository.listFeatured(config.limits.maxStarterPackAudios),
  ]);

  return { categories, audios: featuredAudios };
});
