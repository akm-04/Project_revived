"""Pass342 secret generation, digest lookup and password verification."""

from __future__ import annotations

import hashlib
import hmac
import json
import secrets
from dataclasses import dataclass
from typing import Callable

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError, VerificationError
from argon2.low_level import Type

from .models import CredentialKind


# Current OWASP Argon2id minimum profile at Pass342 implementation time:
# 19 MiB, two iterations, one lane.  This is an implementation/security choice,
# not an original-server protocol fact and remains upgradeable.
ARGON2_MEMORY_KIB = 19_456
ARGON2_TIME_COST = 2
ARGON2_PARALLELISM = 1
ARGON2_HASH_LEN = 32
ARGON2_SALT_LEN = 16


def normalize_login(value: object) -> str:
    return str(value or "").strip().casefold()


def credential_digest(kind: CredentialKind | str, raw_value: str) -> bytes:
    try:
        normalized_kind = kind if isinstance(kind, CredentialKind) else CredentialKind(str(kind))
    except ValueError as exc:
        raise ValueError("unknown credential kind") from exc
    raw = str(raw_value)
    if not raw:
        raise ValueError("credential value must not be empty")
    return hashlib.sha256(normalized_kind.value.encode("ascii") + b"\0" + raw.encode("utf-8")).digest()


@dataclass(frozen=True, slots=True)
class BearerPair:
    raw: str
    digest: bytes


class BearerIssuer:
    """Opaque CSPRNG credentials; raw values never become durable rows/log fields."""

    def __init__(self, token_bytes: Callable[[int], bytes] = secrets.token_bytes) -> None:
        self._token_bytes = token_bytes

    def sid(self) -> BearerPair:
        # 128 random bits and the historical SDK-compatible 32-hex shape.
        raw = self._token_bytes(16).hex()
        return BearerPair(raw=raw, digest=credential_digest(CredentialKind.SDK_SID_COMPAT, raw))

    def login_token(self) -> BearerPair:
        raw = self._token_bytes(32).hex()
        return BearerPair(raw=raw, digest=credential_digest(CredentialKind.LOGIN_TOKEN, raw))

    def gameplay_token(self) -> BearerPair:
        raw = self._token_bytes(32).hex()
        return BearerPair(raw=raw, digest=credential_digest(CredentialKind.GAMEPLAY_TOKEN, raw))

    def gameplay_token_for_context(
        self,
        *,
        context_id,
        login_token: object = None,
        sid: object = None,
    ) -> BearerPair:
        """Derive a stable opaque gameplay bearer for one account-session context.

        Stock v1.631 can issue overlapping/re-entrant MID1 requests.  A random
        replacement bearer lets the later request revoke the earlier request
        before its bootstrap response finishes.  Derivation from the already
        random account bearer plus the opaque context UUID gives same-context
        retries the same gameplay token without persisting raw credential
        material.  A new context UUID still rotates the gameplay credential.
        """
        login_raw = str(login_token or "")
        sid_raw = str(sid or "")
        if login_raw:
            key = credential_digest(CredentialKind.LOGIN_TOKEN, login_raw)
        elif sid_raw:
            key = credential_digest(CredentialKind.SDK_SID_COMPAT, sid_raw)
        else:
            # AccountSessionAuthenticator normally makes this unreachable; keep
            # fail-safe compatibility for injected/test callers.
            return self.gameplay_token()
        message = b"gxb-gameplay-context-v1\0" + str(context_id).encode("ascii")
        raw = hmac.new(key, message, hashlib.sha256).hexdigest()
        return BearerPair(raw=raw, digest=credential_digest(CredentialKind.GAMEPLAY_TOKEN, raw))


@dataclass(frozen=True, slots=True)
class PasswordVerification:
    valid: bool
    upgraded_hash: str | None = None
    upgraded_algorithm: str | None = None


class PasswordCredentialService:
    """Argon2id for new credentials plus bounded Pass299 PBKDF2 compatibility."""

    ARGON2_ALGORITHM = "argon2id"
    LEGACY_ALGORITHM = "pbkdf2-sha256"

    def __init__(self, hasher: PasswordHasher | None = None) -> None:
        self.hasher = hasher or PasswordHasher(
            time_cost=ARGON2_TIME_COST,
            memory_cost=ARGON2_MEMORY_KIB,
            parallelism=ARGON2_PARALLELISM,
            hash_len=ARGON2_HASH_LEN,
            salt_len=ARGON2_SALT_LEN,
            type=Type.ID,
        )

    def hash_new(self, password: str) -> str:
        value = str(password)
        if not value:
            raise ValueError("password must not be empty")
        return self.hasher.hash(value)

    def verify(self, *, algorithm: str, encoded_hash: str, password: str) -> PasswordVerification:
        algorithm = str(algorithm or "")
        encoded_hash = str(encoded_hash or "")
        password = str(password)
        if algorithm == self.ARGON2_ALGORITHM:
            try:
                valid = bool(self.hasher.verify(encoded_hash, password))
            except (VerifyMismatchError, VerificationError, InvalidHashError, ValueError):
                return PasswordVerification(False)
            if not valid:
                return PasswordVerification(False)
            if self.hasher.check_needs_rehash(encoded_hash):
                return PasswordVerification(
                    True,
                    upgraded_hash=self.hash_new(password),
                    upgraded_algorithm=self.ARGON2_ALGORITHM,
                )
            return PasswordVerification(True)
        if algorithm == self.LEGACY_ALGORITHM:
            if not self._verify_legacy_pbkdf2(encoded_hash, password):
                return PasswordVerification(False)
            return PasswordVerification(
                True,
                upgraded_hash=self.hash_new(password),
                upgraded_algorithm=self.ARGON2_ALGORITHM,
            )
        return PasswordVerification(False)

    @staticmethod
    def encode_legacy_pbkdf2(*, iterations: int, salt_hex: str, hash_hex: str) -> str:
        return f"{int(iterations)}${str(salt_hex)}${str(hash_hex)}"

    @classmethod
    def _verify_legacy_pbkdf2(cls, encoded_hash: str, password: str) -> bool:
        try:
            if encoded_hash.lstrip().startswith("{"):
                record = json.loads(encoded_hash)
                iterations = int(record.get("iterations", 200_000))
                salt = bytes.fromhex(str(record["salt"]))
                expected = bytes.fromhex(str(record["hash"]))
            else:
                iterations_s, salt_s, expected_s = encoded_hash.split("$", 2)
                iterations = int(iterations_s)
                salt = bytes.fromhex(salt_s)
                expected = bytes.fromhex(expected_s)
            if iterations <= 0 or not salt or not expected:
                return False
        except Exception:
            return False
        actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations)
        return hmac.compare_digest(actual, expected)
