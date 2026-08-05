from racket_image_agent.name_normalizer import build_image_filename, build_official_name, normalize_brand


def test_normalize_brand_known_brand_uses_canonical_casing():
    assert normalize_brand("nox") == "NOX"
    assert normalize_brand("  drop shot ") == "Drop Shot"
    assert normalize_brand("heroe's") == "Heroe's"


def test_normalize_brand_unknown_brand_falls_back_to_title_case():
    assert normalize_brand("marca desconhecida") == "Marca Desconhecida"


def test_build_official_name_combines_fields_in_order():
    name = build_official_name("head", "Speed Pro", year="2024", color="Preto-Verde", version="X")
    assert name == "Head Speed Pro X Preto-Verde 2024"


def test_build_official_name_omits_missing_optional_fields():
    name = build_official_name("wilson", "  Team   2.0  ")
    assert name == "Wilson Team 2.0"


def test_build_official_name_strips_illegal_drive_characters():
    name = build_official_name("nox", 'Modelo "Pro"/2024')
    assert '"' not in name
    assert "/" not in name


def test_build_image_filename_uses_expected_pattern():
    filename = build_image_filename(1, "Head Speed Pro 2024", "jpeg")
    assert filename == "1 - Head Speed Pro 2024.jpg"


def test_build_image_filename_preserves_png():
    filename = build_image_filename(5, "Bullpadel Vertex 04", "png")
    assert filename == "5 - Bullpadel Vertex 04.png"


def test_build_image_filename_rejects_out_of_range_index():
    import pytest

    with pytest.raises(ValueError):
        build_image_filename(6, "Wilson Team", "jpg")
