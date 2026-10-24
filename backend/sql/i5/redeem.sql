-- owner: redeem
-- source: Pass422 Wave-E redeem control

-- name: LockRedeemCodeByDigest :one
SELECT code_id,campaign_id,lookup_digest,code_kind,global_use_limit,use_count,status,issued_batch_id,created_at,state_version
FROM redeem_codes WHERE lookup_digest=$1 FOR UPDATE;

-- name: GetRedeemCampaign :one
SELECT campaign_id,name,status,redemption_subject,starts_at,ends_at,audience_policy,reward_bundle_revision_id,total_cap,per_subject_cap,policy_version,created_by,created_at,activated_at,disabled_at
FROM redeem_campaigns WHERE campaign_id=$1;

-- name: GetRedeemRewardBundleRevision :one
SELECT reward_bundle_revision_id,grant_plan,content_hash,created_by,created_at,immutable_after_issue
FROM redeem_reward_bundle_revisions WHERE reward_bundle_revision_id=$1;

-- name: FindRedeemRedemption :one
SELECT redemption_id,code_id,subject_type,subject_id,redemption_slot,player_id,account_id,logical_server_id,reward_bundle_revision_id,grant_receipt_id,redeemed_at,request_platform_hint,policy_version
FROM redeem_redemptions WHERE code_id=$1 AND subject_type=$2 AND subject_id=$3 AND redemption_slot=$4;

-- name: InsertRedeemRedemption :exec
INSERT INTO redeem_redemptions(redemption_id,code_id,subject_type,subject_id,redemption_slot,player_id,account_id,logical_server_id,reward_bundle_revision_id,grant_receipt_id,redeemed_at,request_platform_hint,policy_version)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13);

-- name: AdvanceRedeemCodeUse :execrows
UPDATE redeem_codes SET use_count=use_count+1,state_version=state_version+1,
 status=CASE WHEN global_use_limit IS NOT NULL AND use_count+1>=global_use_limit THEN 'EXHAUSTED' ELSE status END
WHERE code_id=$1 AND state_version=$2 AND status='ACTIVE'
  AND (global_use_limit IS NULL OR use_count<global_use_limit);
