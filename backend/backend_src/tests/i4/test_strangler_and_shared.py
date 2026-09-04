from __future__ import annotations

from pathlib import Path

from gxb_backend.persistence.shared import (
    CompetitionAuthorityRepository,
    FiniteClaimResourceRepository,
    GuildAuthorityRepository,
    SharedEncounterRepository,
)
from gxb_backend.persistence.store import LegacyJsonPlayerStateStore
from gxb_backend.state.repository import StateRepository


def test_state_repository_default_remains_legacy_json_store(tmp_path: Path) -> None:
    repo = StateRepository(multiuser_root=tmp_path / "server")
    assert isinstance(repo._player_store, LegacyJsonPlayerStateStore)
    assert repo._player_store.db is repo.store
    assert repo._player_store.process_cache_safe is True


def test_state_repository_player_save_delegates_through_strangler_store(tmp_path: Path) -> None:
    class FakeStore:
        process_cache_safe = True
        def __init__(self): self.saved=[]
        def load(self, player_id): return None
        def save(self, player): self.saved.append(player)
        def fingerprint(self, player_id): return None

    fake = FakeStore()
    repo = StateRepository(multiuser_root=tmp_path / "server", player_state_store=fake)
    sandbox = repo.current_player_or_none()
    assert sandbox is not None
    repo._save_player_canonical(sandbox)
    assert fake.saved == [sandbox]


def test_i4_shared_interfaces_are_explicit_protocols_not_generic_eav_table() -> None:
    for protocol in (
        GuildAuthorityRepository,
        FiniteClaimResourceRepository,
        SharedEncounterRepository,
        CompetitionAuthorityRepository,
    ):
        assert getattr(protocol, "_is_protocol", False)
