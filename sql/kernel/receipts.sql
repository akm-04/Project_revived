-- owner: kernel/idempotency
-- source: PASS409_WAVE_A_KERNEL_SCHEMA_CATALOG; R4B adds durable operation-policy evidence.

-- name: InsertOperationReceipt :one
WITH ins AS (
    INSERT INTO gxb_operation_receipts (
        receipt_id, operation_id, owner_kind, owner_key, domain, operation, operation_class,
        semantic_key, request_fingerprint, result_schema, result_payload,
        operation_started_at, policy_version, operation_policy_refs,
        actor_account_uid, context_id, retain_until, payload_version
    ) VALUES (
        $1::uuid, NULLIF($2, '')::uuid, $3, $4, $5, $6, $7, $8, $9::bytea, $10, $11::jsonb,
        $12::timestamptz, NULLIF($13, ''), $14::jsonb, NULLIF($15, ''),
        NULLIF($16, '')::uuid, $17::timestamptz, $18
    )
    ON CONFLICT (owner_kind, owner_key, domain, operation, semantic_key)
    DO NOTHING
    RETURNING 1
)
SELECT EXISTS(SELECT 1 FROM ins) AS inserted;

-- name: FindOperationReceipt :one
SELECT
    receipt_id::text,
    COALESCE(operation_id::text, '') AS operation_id,
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
    COALESCE(retain_until, 'epoch'::timestamptz) AS retain_until,
    payload_version
FROM gxb_operation_receipts
WHERE owner_kind = $1
  AND owner_key = $2
  AND domain = $3
  AND operation = $4
  AND semantic_key = $5;

-- name: ListOperationReceiptIdentities :one
SELECT COALESCE(jsonb_agg(jsonb_build_object('OwnerKind',owner_kind,'OwnerKey',owner_key,'Domain',domain,'Operation',operation,'SemanticKey',semantic_key) ORDER BY semantic_key,owner_key),'[]'::jsonb)::text
FROM (SELECT owner_kind,owner_key,domain,operation,semantic_key FROM gxb_operation_receipts
      WHERE domain=$1 AND operation=$2 AND semantic_key>$3
      ORDER BY semantic_key,owner_key LIMIT 256) r;
