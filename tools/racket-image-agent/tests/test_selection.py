from racket_image_agent.imaging.selection import select_five_photos
from racket_image_agent.models import ImageCandidate


def _candidate(url, role_hint="other", angle=None, bag_confirmed=False, confidence=0.9):
    return ImageCandidate(
        url=url,
        page_url="https://example.com/produto",
        source_name="teste",
        role_hint=role_hint,
        angle=angle,
        bag_confirmed=bag_confirmed,
        confidence=confidence,
    )


def test_five_photos_selected_in_expected_order():
    candidates = [
        _candidate("capa.jpg", role_hint="capa", angle="inclinado"),
        _candidate("verso.jpg", role_hint="verso"),
        _candidate("detalhe.jpg", role_hint="detalhe"),
        _candidate("complementar.jpg", role_hint="complementar"),
        _candidate("bag.jpg", role_hint="bag", bag_confirmed=True),
    ]

    result = select_five_photos(candidates)

    assert [c.url for c in result.ordered_images] == [
        "capa.jpg",
        "verso.jpg",
        "detalhe.jpg",
        "complementar.jpg",
        "bag.jpg",
    ]
    assert result.pendencies == []


def test_cover_prefers_inclined_angle_over_plain_frontal():
    candidates = [
        _candidate("frontal.jpg", role_hint="capa", angle="frontal", confidence=0.99),
        _candidate("inclinado.jpg", role_hint="capa", angle="inclinado", confidence=0.5),
    ]
    result = select_five_photos(candidates)
    assert result.ordered_images[0].url == "inclinado.jpg"


def test_cover_falls_back_to_frontal_when_no_capa_role_present():
    candidates = [_candidate("frontal.jpg", role_hint="other", angle="frontal")]
    result = select_five_photos(candidates)
    assert result.ordered_images[0].url == "frontal.jpg"


def test_missing_bag_leaves_slot_five_empty_with_pendency_and_does_not_block_others():
    candidates = [
        _candidate("capa.jpg", role_hint="capa", angle="inclinado"),
        _candidate("verso.jpg", role_hint="verso"),
        _candidate("detalhe.jpg", role_hint="detalhe"),
        _candidate("complementar.jpg", role_hint="complementar"),
    ]
    result = select_five_photos(candidates)

    assert result.ordered_images[4] is None
    assert any("bag" in p.lower() for p in result.pendencies)
    assert result.ordered_images[0] is not None
    assert result.ordered_images[3] is not None


def test_unconfirmed_bag_image_is_never_used_for_slot_five():
    candidates = [
        _candidate("capa.jpg", role_hint="capa", angle="inclinado"),
        _candidate("bag-sem-confirmacao.jpg", role_hint="bag", bag_confirmed=False),
    ]
    result = select_five_photos(candidates)

    assert result.ordered_images[4] is None
    assert any("sem confirmacao" in p.lower() or "confirmacao" in p.lower() for p in result.pendencies)


def test_missing_slots_are_reported_as_pendencies():
    result = select_five_photos([])
    assert result.ordered_images == [None, None, None, None, None]
    assert len(result.pendencies) >= 4
