"""Stable private I3 identity/auth failure classes."""

from __future__ import annotations


class IdentityError(RuntimeError):
    error_kind = "IDENTITY_ERROR"
    status_code = 409


class AccountConflict(IdentityError):
    error_kind = "ACCOUNT_CONFLICT"
    status_code = 409


class CredentialInvalid(IdentityError):
    error_kind = "CREDENTIAL_INVALID"
    status_code = 401


class CredentialMismatch(CredentialInvalid):
    error_kind = "CREDENTIAL_MISMATCH"


class SessionExpired(CredentialInvalid):
    error_kind = "SESSION_EXPIRED"


class SessionRevoked(CredentialInvalid):
    error_kind = "SESSION_REVOKED"


class ContextStale(CredentialInvalid):
    error_kind = "CONTEXT_STALE"
    status_code = 409


class RegionUnavailable(IdentityError):
    error_kind = "REGION_UNAVAILABLE"
    status_code = 409


class RegionFull(RegionUnavailable):
    error_kind = "REGION_FULL"
