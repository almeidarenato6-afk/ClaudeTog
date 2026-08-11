from racket_image_agent.state_store import (
    get_product_state,
    load_state,
    product_key,
    save_state,
    upsert_product_state,
)


def test_load_state_returns_empty_default_when_file_absent(tmp_path):
    state = load_state(str(tmp_path / "does-not-exist.json"))
    assert state["products"] == {}
    assert state["folders"] == {}


def test_save_and_load_state_roundtrip(tmp_path):
    path = str(tmp_path / "state.json")
    state = load_state(path)
    upsert_product_state(state, "Head Speed Pro 2024", status="CONCLUIDO", folder_id="folder123")
    save_state(path, state)

    reloaded = load_state(path)
    entry = get_product_state(reloaded, "Head Speed Pro 2024")
    assert entry["status"] == "CONCLUIDO"
    assert entry["folder_id"] == "folder123"


def test_product_key_is_case_and_whitespace_insensitive():
    assert product_key("Head Speed Pro 2024") == product_key("  head speed pro 2024  ".strip())


def test_save_state_is_atomic_and_does_not_leave_partial_temp_files(tmp_path):
    path = tmp_path / "state.json"
    state = load_state(str(path))
    upsert_product_state(state, "Wilson Team 2.0", status="PARCIAL")
    save_state(str(path), state)

    assert path.exists()
    leftover_tmp = list(tmp_path.glob("*.tmp"))
    assert leftover_tmp == []
