"""Pass344 I5 outbox wakeup trigger; durable rows remain the event truth."""
from __future__ import annotations

from typing import Sequence
from alembic import op

revision: str = "0005_pass344_i5"
down_revision: str | Sequence[str] | None = "0004_pass343_i4"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.execute(
        f'''CREATE OR REPLACE FUNCTION "{schema}".notify_outbox_insert()\nRETURNS trigger\nLANGUAGE plpgsql\nAS $$\nBEGIN\n  PERFORM pg_notify('gxb_outbox', 'wake');\n  RETURN NULL;\nEND;\n$$'''
    )
    op.execute(
        f'''CREATE TRIGGER trg_outbox_notify\nAFTER INSERT ON "{schema}".outbox_events\nFOR EACH STATEMENT\nEXECUTE FUNCTION "{schema}".notify_outbox_insert()'''
    )


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.execute(f'DROP TRIGGER IF EXISTS trg_outbox_notify ON "{schema}".outbox_events')
    op.execute(f'DROP FUNCTION IF EXISTS "{schema}".notify_outbox_insert()')
