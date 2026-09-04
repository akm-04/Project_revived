# PostgreSQL foundation scaffold (Pass339 I0)

This directory defines only the role/configuration boundary. It does not switch
gameplay away from Pass299 JSON persistence.

- PostgreSQL is the sole planned production gameplay database.
- `gxb_owner` is the migration/DDL privilege role.
- `gxb_app`, `gxb_realtime`, and `gxb_scheduler` are separate NOLOGIN privilege
  roles. Operator-managed LOGIN identities inherit the appropriate role.
- Real DSNs/passwords stay in a host-side restricted file or credential store.
- `GXB_DATABASE_URL` selects synchronous `postgresql+psycopg` only.
- Every process owns its own bounded SQLAlchemy Engine/pool after fork.
- The initial Alembic revision creates only the `gxb` namespace. I2 adds the
  transactional kernel tables and exact grants.

For a disposable developer database, set `GXB_POSTGRES_ADMIN_DSN`, optionally
set `GXB_TEST_DATABASE`, then run:

```text
python tools/pass339_postgres_testdb.py ensure
GXB_TEST_DATABASE_URL=postgresql+psycopg://... alembic upgrade head
pytest -m postgresql
```

The helper refuses production-looking names and never deletes a database.
