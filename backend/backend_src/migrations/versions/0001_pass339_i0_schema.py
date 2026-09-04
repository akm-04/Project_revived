"""Pass339 I0 PostgreSQL namespace scaffold; no gameplay tables."""

from __future__ import annotations

from typing import Sequence

from alembic import op
from sqlalchemy.schema import CreateSchema, DropSchema


revision: str = "0001_pass339_i0"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.execute(CreateSchema(schema, if_not_exists=True))


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.execute(DropSchema(schema, if_exists=True))
