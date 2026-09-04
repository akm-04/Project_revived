"""Reusable optimistic state_version backstop for mutable aggregate rows."""

from __future__ import annotations

from typing import Any, Mapping

from sqlalchemy import Table, and_, update
from sqlalchemy.engine import Connection

from .errors import StateVersionConflict


def validate_state_version(value: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError("state_version must be a non-negative integer")
    return value


def execute_versioned_update(
    connection: Connection,
    table: Table,
    *,
    identity: Mapping[str, Any],
    expected_state_version: int,
    values: Mapping[str, Any],
    resource_label: str,
) -> int:
    """Update exactly one row and increment state_version with an expected-version predicate."""

    expected = validate_state_version(expected_state_version)
    if "state_version" not in table.c:
        raise ValueError(f"table {table.name} has no state_version column")
    if not identity:
        raise ValueError("identity predicate must not be empty")
    unknown = [name for name in identity if name not in table.c]
    if unknown:
        raise ValueError(f"unknown identity column(s): {', '.join(sorted(unknown))}")
    if "state_version" in values:
        raise ValueError("state_version is managed by execute_versioned_update")

    predicates = [table.c[name] == value for name, value in identity.items()]
    predicates.append(table.c.state_version == expected)
    statement = (
        update(table)
        .where(and_(*predicates))
        .values(**dict(values), state_version=expected + 1)
        .returning(table.c.state_version)
    )
    result = connection.execute(statement)
    row = result.first()
    if row is None:
        raise StateVersionConflict(resource=resource_label, expected=expected)
    return int(row[0])
