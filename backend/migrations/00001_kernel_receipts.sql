-- +goose Up
-- Pass434/I1: Wave-A minimal GXB-owned kernel persistence.
-- Production migrations are forward-only; rollback is restore or forward repair.

CREATE TABLE gxb_operation_receipts (
    receipt_id UUID PRIMARY KEY,
    owner_kind TEXT NOT NULL CHECK (owner_kind <> ''),
    owner_key TEXT NOT NULL CHECK (owner_key <> ''),
    domain TEXT NOT NULL CHECK (domain <> ''),
    operation TEXT NOT NULL CHECK (operation <> ''),
    operation_class TEXT NOT NULL CHECK (operation_class <> ''),
    semantic_key TEXT NOT NULL CHECK (semantic_key <> ''),
    request_fingerprint BYTEA NOT NULL CHECK (octet_length(request_fingerprint) = 32),
    result_schema TEXT NOT NULL CHECK (result_schema <> ''),
    result_payload JSONB NOT NULL,
    operation_started_at TIMESTAMPTZ NOT NULL,
    policy_version TEXT NULL,
    actor_account_uid TEXT NULL,
    context_id UUID NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    retain_until TIMESTAMPTZ NULL,
    CONSTRAINT gxb_operation_receipts_semantic_uq
        UNIQUE (owner_kind, owner_key, domain, operation, semantic_key)
);

COMMENT ON TABLE gxb_operation_receipts IS
    'Terminal semantic replay evidence committed atomically with canonical business effects; never mutable gameplay authority.';

-- No DOWN section by design. Production rollback uses pre-traffic restore or a
-- separately reviewed forward repair, never destructive arbitrary DOWN SQL.
