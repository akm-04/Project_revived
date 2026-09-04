"""PostgreSQL schema namespace scaffolding; gameplay tables arrive in I2."""

from __future__ import annotations

import re

from sqlalchemy import MetaData


DEFAULT_SCHEMA = "gxb"
ALEMBIC_VERSION_TABLE = "gxb_alembic_version"
_IDENTIFIER = re.compile(r"^[a-z_][a-z0-9_]{0,62}$")


def validate_schema_name(value: str) -> str:
    schema = str(value).strip()
    if not _IDENTIFIER.fullmatch(schema):
        raise ValueError("database schema must be a lowercase PostgreSQL identifier")
    return schema


metadata = MetaData(schema=DEFAULT_SCHEMA)


def load_i2_kernel_tables() -> None:
    """Import Pass341 tables into shared metadata without creating an Engine."""
    from gxb_backend.transactions import schema as _kernel_schema  # noqa: F401


def load_i3_identity_tables() -> None:
    """Import Pass342 identity/session/context tables without creating an Engine."""
    load_i2_kernel_tables()
    from gxb_backend.identity import schema as _identity_schema  # noqa: F401


def load_i4_persistence_tables() -> None:
    """Import Pass343 account-global/I4 persistence metadata without an Engine."""
    load_i3_identity_tables()
    from gxb_backend.persistence import schema as _persistence_schema  # noqa: F401

def load_i6_scheduler_mail_projection_tables() -> None:
    """Import Pass345 relational mail/projection metadata without creating an Engine."""
    load_i4_persistence_tables()
    from gxb_backend.mail import schema as _mail_schema  # noqa: F401
    from gxb_backend.projections import schema as _projection_schema  # noqa: F401

def load_i8_runtime_tables() -> None:
    """Import Pass347 cutover authority metadata."""
    load_i6_scheduler_mail_projection_tables()
    from gxb_backend.runtime import schema as _runtime_schema  # noqa: F401
