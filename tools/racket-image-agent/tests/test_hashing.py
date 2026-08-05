from racket_image_agent.imaging.hashing import (
    Deduplicator,
    average_hash,
    hamming_distance,
    is_perceptual_duplicate,
    sha256_bytes,
)

from .helpers import make_jpeg


def test_sha256_exact_duplicate_detected():
    data_a = make_jpeg(1200, 1200, color=(100, 100, 100))
    data_b = make_jpeg(1200, 1200, color=(100, 100, 100))
    assert sha256_bytes(data_a) == sha256_bytes(data_b)


def test_sha256_different_images_differ():
    data_a = make_jpeg(1200, 1200, color=(100, 100, 100))
    data_b = make_jpeg(1200, 1200, color=(50, 200, 30))
    assert sha256_bytes(data_a) != sha256_bytes(data_b)


def test_perceptual_hash_flags_visually_similar_but_resized_image():
    original = make_jpeg(1600, 1600, color=(120, 60, 200))
    resized = make_jpeg(900, 900, color=(120, 60, 200))
    hash_a = average_hash(original)
    hash_b = average_hash(resized)
    assert hamming_distance(hash_a, hash_b) <= 6
    assert is_perceptual_duplicate(hash_a, hash_b, threshold=6)


def test_perceptual_hash_does_not_flag_very_different_images():
    img_a = average_hash(make_jpeg(1200, 1200, color=(10, 10, 10)))
    img_b = average_hash(make_jpeg(1200, 1200, color=(240, 240, 240)))
    assert not is_perceptual_duplicate(img_a, img_b, threshold=6)


def test_deduplicator_rejects_exact_and_perceptual_duplicates():
    dedup = Deduplicator(phash_threshold=6)

    original = make_jpeg(1600, 1600, color=(80, 160, 40))
    sha_a, phash_a = sha256_bytes(original), average_hash(original)
    is_dup, kind = dedup.is_duplicate(sha_a, phash_a)
    assert not is_dup
    dedup.register(sha_a, phash_a)

    # duplicata exata (mesmos bytes)
    is_dup, kind = dedup.is_duplicate(sha_a, phash_a)
    assert is_dup and kind == "sha256"

    # duplicata visual (mesma imagem, tamanho diferente -> bytes diferentes)
    resized = make_jpeg(950, 950, color=(80, 160, 40))
    sha_b, phash_b = sha256_bytes(resized), average_hash(resized)
    assert sha_b != sha_a
    is_dup, kind = dedup.is_duplicate(sha_b, phash_b)
    assert is_dup and kind == "phash"

    # imagem genuinamente diferente nao e marcada como duplicata
    different = make_jpeg(1600, 1600, color=(5, 5, 240))
    sha_c, phash_c = sha256_bytes(different), average_hash(different)
    is_dup, _ = dedup.is_duplicate(sha_c, phash_c)
    assert not is_dup
