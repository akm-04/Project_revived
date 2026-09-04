from __future__ import annotations

import hashlib
import json

import pytest

from gxb_backend.identity.credentials import (
    ARGON2_MEMORY_KIB,
    ARGON2_PARALLELISM,
    ARGON2_TIME_COST,
    BearerIssuer,
    PasswordCredentialService,
    credential_digest,
    normalize_login,
)
from gxb_backend.identity.models import CredentialKind


def test_login_normalization_matches_current_backend_semantics() -> None:
    assert normalize_login("  TeSt@Example.COM \n") == "test@example.com"


def test_credential_digest_is_domain_separated_and_sha256() -> None:
    raw = "same-secret"
    sid = credential_digest(CredentialKind.SDK_SID_COMPAT, raw)
    login = credential_digest(CredentialKind.LOGIN_TOKEN, raw)
    gameplay = credential_digest(CredentialKind.GAMEPLAY_TOKEN, raw)
    assert len(sid) == len(login) == len(gameplay) == 32
    assert len({sid, login, gameplay}) == 3
    assert sid == hashlib.sha256(b"SDK_SID_COMPAT\0same-secret").digest()


def test_bearer_issuer_preserves_sid_shape_and_uses_256_bit_other_bearers() -> None:
    def deterministic(count: int) -> bytes:
        return bytes(range(count))

    issuer = BearerIssuer(deterministic)
    sid = issuer.sid()
    login = issuer.login_token()
    game = issuer.gameplay_token()
    assert len(sid.raw) == 32
    assert len(login.raw) == 64
    assert len(game.raw) == 64
    assert sid.digest == credential_digest(CredentialKind.SDK_SID_COMPAT, sid.raw)
    assert login.digest == credential_digest(CredentialKind.LOGIN_TOKEN, login.raw)
    assert game.digest == credential_digest(CredentialKind.GAMEPLAY_TOKEN, game.raw)


def test_argon2id_profile_is_at_least_frozen_pass342_owasp_minimum() -> None:
    assert ARGON2_MEMORY_KIB >= 19_456
    assert ARGON2_TIME_COST >= 2
    assert ARGON2_PARALLELISM >= 1
    service = PasswordCredentialService()
    encoded = service.hash_new("correct horse battery staple")
    assert encoded.startswith("$argon2id$")
    assert service.verify(
        algorithm=service.ARGON2_ALGORITHM,
        encoded_hash=encoded,
        password="correct horse battery staple",
    ).valid
    assert not service.verify(
        algorithm=service.ARGON2_ALGORITHM,
        encoded_hash=encoded,
        password="wrong",
    ).valid


def test_pass299_pbkdf2_json_record_verifies_and_upgrades_to_argon2id() -> None:
    password = "legacy-password"
    salt = bytes.fromhex("00112233445566778899aabbccddeeff")
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 200_000)
    record = json.dumps(
        {
            "algorithm": "pbkdf2-sha256",
            "iterations": 200_000,
            "salt": salt.hex(),
            "hash": digest.hex(),
        }
    )
    service = PasswordCredentialService()
    result = service.verify(
        algorithm=service.LEGACY_ALGORITHM,
        encoded_hash=record,
        password=password,
    )
    assert result.valid
    assert result.upgraded_algorithm == service.ARGON2_ALGORITHM
    assert result.upgraded_hash and result.upgraded_hash.startswith("$argon2id$")
    assert not service.verify(
        algorithm=service.LEGACY_ALGORITHM,
        encoded_hash=record,
        password="bad",
    ).valid


def test_unknown_credential_kind_and_empty_raw_are_rejected() -> None:
    with pytest.raises(ValueError):
        credential_digest("NOT_A_KIND", "x")
    with pytest.raises(ValueError):
        credential_digest(CredentialKind.LOGIN_TOKEN, "")


def test_gameplay_token_for_context_is_stable_per_account_bearer_and_rotates_by_context() -> None:
    from uuid import UUID
    from gxb_backend.identity.credentials import BearerIssuer

    issuer = BearerIssuer(token_bytes=lambda n: b"x" * n)
    c1 = UUID("11111111-1111-1111-1111-111111111111")
    c2 = UUID("22222222-2222-2222-2222-222222222222")
    a = issuer.gameplay_token_for_context(context_id=c1, login_token="L" * 64, sid="S" * 32)
    b = issuer.gameplay_token_for_context(context_id=c1, login_token="L" * 64, sid="S" * 32)
    c = issuer.gameplay_token_for_context(context_id=c2, login_token="L" * 64, sid="S" * 32)
    assert a == b
    assert a.raw != c.raw
    assert len(a.raw) == 64
    assert len(a.digest) == 32
