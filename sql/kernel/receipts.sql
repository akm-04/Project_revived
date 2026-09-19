-- owner: kernel/idempotency
-- source: PASS409_WAVE_A_KERNEL_SCHEMA_CATALOG; R4B adds durable operation-policy evidence.

-- name: InsertOperationReceipt :one
WITH ins AS (
    INSERT INTO gxb_operation_receipts (
        receipt_id, owner_kind, owner_key, domain, operation, operation_class,
        semantic_key, request_fingerprint, result_schema, result_payload,
        operation_started_at, policy_version, operation_policy_refs,
        actor_account_uid, context_id, retain_until
    ) VALUES (
        $1::uuid, $2, $3, $4, $5, $6, $7, $8::bytea, $9, $10::jsonb,
        $11::timestamptz, NULLIF($12, ''), $13::jsonb, NULLIF($14, ''),
        NULLIF($15, '')::uuid, $16::timestamptz
    )
    ON CONFLICT (owner_kind, owner_key, domain, operation, semantic_key)
    DO NOTHING
    RETURNING 1
)
SELECT EXISTS(SELECT 1 FROM ins) AS inserted;

-- name: FindOperationReceipt :one
SELECT
    receipt_id::text,
    owner_kind,
    owner_key,
    domain,
    operation,
    semantic_key,
    operation_class,
    encode(request_fingerprint, 'hex') AS request_fingerprint_hex,
    result_schema,
    result_payload::text,
    operation_started_at,
    COALESCE(policy_version, '') AS policy_version,
    operation_policy_refs::text,
    COALESCE(actor_account_uid, '') AS actor_account_uid,
    COALESCE(context_id::text, '') AS context_id,
    recorded_at,
    retain_until IS NOT NULL AS has_retain_until,
    COALESCE(retain_until, 'epoch'::timestamptz) AS retain_until
FROM gxb_operation_receipts
WHERE owner_kind = $1
  AND owner_key = $2
  AND domain = $3
  AND operation = $4
  AND semantic_key = $5;
