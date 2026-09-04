from __future__ import annotations

from pathlib import Path

from gxb_backend.state.maintenance_services import normalize_player_domain
from gxb_backend.state.profiles import make_fresh_player
from gxb_backend.state.skill_point_policy import SkillPointPolicy

ROOT = Path(__file__).resolve().parents[2]


def test_shared_fresh_normalization_seeds_aquaris_and_skill_pool() -> None:
    player = make_fresh_player(
        account_uid="29999999", player_id="19429999", region=194, region_name="Local-194"
    )
    assert player.heroes == {}
    SkillPointPolicy(player, ROOT / "data").initialize_fresh_full_pool()
    assert normalize_player_domain(player, ROOT / "data") is True
    assert player.skill_point == 10
    assert player.skill_time == 0
    assert player.heroes["1"]["partner_id"] == 1
    assert player.heroes["1"]["table_id"] == 10001001


def test_postgres_selection_materializes_and_repairs_through_shared_normalizer() -> None:
    text = (ROOT / "gxb_backend/runtime/state_repository.py").read_text()
    stub = text.index("except PlayerAggregateNotMaterialized:")
    skill = text.index("SkillPointPolicy(fresh, self._data_dir()).initialize_fresh_full_pool()", stub)
    normalize_fresh = text.index("normalize_player_domain(", skill)
    materialize = text.index("self._aggregates.materialize", normalize_fresh)
    normalize_loaded = text.index("if normalize_player_domain(", materialize)
    save = text.index("self._player_store.save(player)", normalize_loaded)
    assert stub < skill < normalize_fresh < materialize < normalize_loaded < save


def test_portable_static_asset_root_points_to_container_not_nested_res() -> None:
    text = (ROOT / "gxb-dev.sh").read_text()
    assert 'emit_export GXB_STATIC_ASSET_ROOT "$ROOT/local_assets"' in text
    assert 'emit_export GXB_STATIC_ASSET_ROOT "$ROOT/local_assets/res"' not in text
    config = (ROOT / "gxb_backend/config.py").read_text()
    assert 'roots.append(self.static_asset_root / "res")' in config


def test_sdk_login_revalidates_account_region_and_refuses_ambiguous_auto_entry() -> None:
    for arch in ("src_32", "src_64"):
        text = (ROOT / "local_assets" / arch / "app/windows/LoginWindow.lua").read_text(encoding="utf-8-sig")
        assert "xyd.db.meta.regionID > 0 and not arg_1_0.isSDKLogin" in text
        assert "local var_2_2 = arg_2_1.players or {}" in text
        assert "if #var_2_2 == 1 then" in text
        assert "arg_1_0.currentRegion = nil" in text
        assert 'translation("CLICKED_CHANGE_REGION")' in text
        assert "var_2_1 = var_2_0[7]" in text  # keep recovered EOL fresh-account default


def test_wrapper_clean_update_and_postgresql_backup_restore_are_explicit() -> None:
    text = (ROOT / "tools/workspace/gxb_backend_workspace.sh").read_text()
    assert 'WRAPPER_VERSION="7"' in text
    assert "clear_runtime_logs()" in text
    assert 'db-backup "pre-update-$stamp"' in text
    assert text.index("clear_runtime_logs", text.index("update_workspace()")) < text.index("setup_workspace", text.index("update_workspace()"))
    assert "workspace_backup()" in text
    assert "workspace_restore()" in text
    assert "GXB_WORKSPACE_POSTGRESQL_BACKUP_V1" in text
    assert "no legacy JSON remigration" in text
    dev = (ROOT / "gxb-dev.sh").read_text()
    assert "db_restore()" in dev
    assert 'db-restore) db_restore' in dev
