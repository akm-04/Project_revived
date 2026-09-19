-- owner: mail
-- source: Pass415 Wave-E durable Mail

-- name: LockMailNamespaceCounter :one
SELECT recipient_player_id,namespace,next_wire_id,state_version
FROM mail_namespace_counters WHERE recipient_player_id=$1 AND namespace=$2 FOR UPDATE;

-- name: InsertMailNamespaceCounter :exec
INSERT INTO mail_namespace_counters(recipient_player_id,namespace,next_wire_id,state_version)
VALUES($1,$2,$3,1);

-- name: AdvanceMailNamespaceCounter :execrows
UPDATE mail_namespace_counters SET next_wire_id=$3,state_version=state_version+1
WHERE recipient_player_id=$1 AND namespace=$2 AND state_version=$4;

-- name: InsertMailRecord :exec
INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,category,title,sender,body,created_at,expires_at,platform_eligibility,compatibility_policy_version)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14);

-- name: InsertMailAttachment :exec
INSERT INTO mail_attachments(mail_uuid,ordinal,grant_line_kind,resource_key,item_id,amount,metadata)
VALUES($1,$2,$3,$4,$5,$6,$7);

-- name: LockMailByWireAddress :one
SELECT mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,category,title,sender,body,created_at,expires_at,read_at,shown,claimed_at,platform_eligibility,compatibility_policy_version,state_version
FROM mail_records WHERE recipient_player_id=$1 AND namespace=$2 AND wire_id=$3 FOR UPDATE;

-- name: ListMailAttachments :many
SELECT mail_uuid,ordinal,grant_line_kind,resource_key,item_id,amount,metadata
FROM mail_attachments WHERE mail_uuid=$1 ORDER BY ordinal;

-- name: MarkMailRead :execrows
UPDATE mail_records SET read_at=COALESCE(read_at,$2),state_version=state_version+1
WHERE mail_uuid=$1 AND read_at IS NULL;

-- name: MarkMailClaimed :execrows
UPDATE mail_records SET read_at=COALESCE(read_at,$2),claimed_at=$2,state_version=state_version+1
WHERE mail_uuid=$1 AND claimed_at IS NULL;

-- name: ListPlayerMail :many
SELECT mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,category,title,sender,body,created_at,expires_at,read_at,shown,claimed_at,platform_eligibility,compatibility_policy_version,state_version
FROM mail_records WHERE recipient_player_id=$1 AND (expires_at IS NULL OR expires_at>$2)
ORDER BY created_at DESC,namespace,wire_id DESC LIMIT $3;
