from racket_image_agent.imaging.validation import validate_image

from .helpers import make_flat_jpeg, make_not_an_image, make_watermarked_jpeg


def test_valid_image_above_preferred_resolution_is_accepted():
    data = make_flat_jpeg(1600, 1600)
    result = validate_image(data, min_side=1000, preferred_side=1500)
    assert result.ok is True
    assert result.pending_low_resolution is False
    assert result.width == 1600 and result.height == 1600


def test_image_between_min_and_preferred_is_accepted_but_flagged_pending():
    data = make_flat_jpeg(1200, 1200)
    result = validate_image(data, min_side=1000, preferred_side=1500)
    assert result.ok is True
    assert result.pending_low_resolution is True


def test_image_below_min_side_is_rejected_with_pending_flag():
    data = make_flat_jpeg(800, 800)
    result = validate_image(data, min_side=1000, preferred_side=1500)
    assert result.ok is False
    assert result.reason == "resolucao_baixa"
    assert result.pending_low_resolution is True


def test_non_image_file_is_rejected_by_real_type_sniffing():
    result = validate_image(make_not_an_image(), min_side=1000, preferred_side=1500)
    assert result.ok is False
    assert result.reason == "tipo_arquivo_invalido"


def test_image_with_watermark_like_corner_pattern_is_rejected():
    data = make_watermarked_jpeg(1600, 1600)
    result = validate_image(data, min_side=1000, preferred_side=1500, check_watermark=True)
    assert result.ok is False
    assert result.reason == "marca_dagua_suspeita"
    assert result.pending_watermark_suspect is True


def test_clean_image_is_not_flagged_as_watermarked():
    data = make_flat_jpeg(1600, 1600)
    result = validate_image(data, min_side=1000, preferred_side=1500, check_watermark=True)
    assert result.ok is True
    assert result.pending_watermark_suspect is False
