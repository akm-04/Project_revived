-- +goose Up
-- Forward-only; nonempty SocialGift/content rollback prohibited.
-- Neutral owner/content schema: no reconstructed gifts, balances or route activation.
CREATE TABLE content_social_gift_catalogs(
 revision_id text PRIMARY KEY REFERENCES gxb_content_revisions(revision_id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object')
);
CREATE TABLE social_gift_epochs(
 player_id bigint NOT NULL CHECK(player_id>0),
 policy_id text NOT NULL CHECK(policy_id='SOCIAL_GIFT_DAY_V1'),
 day_token text NOT NULL CHECK(day_token ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'),
 generation_id uuid NOT NULL UNIQUE,
 state_version bigint NOT NULL CHECK(state_version>0),
 created_at timestamptz NOT NULL,updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 PRIMARY KEY(player_id,policy_id,day_token)
);
CREATE TABLE social_gift_claim_operations(
 operation_id uuid PRIMARY KEY,
 recipient_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT,
 request_fingerprint text NOT NULL CHECK(request_fingerprint ~ '^[0-9a-f]{64}$'),
 operation_started_at timestamptz NOT NULL,decision_at timestamptz NOT NULL,
 policy_version text NOT NULL DEFAULT 'SOCIAL_GIFT_CLAIM_BATCH_V1' CHECK(policy_version='SOCIAL_GIFT_CLAIM_BATCH_V1'),
 created_at timestamptz NOT NULL CHECK(created_at=decision_at),
 claim_day text NOT NULL,claim_generation_id uuid REFERENCES social_gift_epochs(generation_id),
 content_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 grant_receipt_id text,
 semantic_result jsonb NOT NULL CHECK(jsonb_typeof(semantic_result)='object'),
 UNIQUE(recipient_player_id,operation_id)
);
CREATE TABLE social_gift_transfers(
 transfer_id uuid PRIMARY KEY,
 sender_player_id bigint NOT NULL CHECK(sender_player_id>0),
 recipient_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE RESTRICT CHECK(recipient_player_id<>sender_player_id),
 policy_id text NOT NULL CHECK(policy_id='SOCIAL_GIFT_DAY_V1'),
 sender_day text NOT NULL,sender_generation_id uuid NOT NULL REFERENCES social_gift_epochs(generation_id),
 send_operation_id uuid NOT NULL UNIQUE,
 request_fingerprint text NOT NULL CHECK(request_fingerprint ~ '^[0-9a-f]{64}$'),
 send_started_at timestamptz NOT NULL,issued_at timestamptz NOT NULL,
 friendship_generation bigint NOT NULL CHECK(friendship_generation>0),
 recipient_block_version bigint NOT NULL CHECK(recipient_block_version>=0),
 reward_revision text NOT NULL REFERENCES gxb_content_revisions(revision_id),
 vector_fingerprint text NOT NULL CHECK(vector_fingerprint ~ '^[0-9a-f]{64}$'),
 resource_key text NOT NULL CHECK(resource_key='friendship_coin'),amount bigint NOT NULL CHECK(amount=5),
 notice_id bigint NOT NULL CHECK(notice_id>0 AND notice_id<=9007199254740991),
 state_version bigint NOT NULL CHECK(state_version>0),
 claim_operation_id uuid REFERENCES social_gift_claim_operations(operation_id) DEFERRABLE INITIALLY DEFERRED,
 claim_day text,claim_generation_id uuid REFERENCES social_gift_epochs(generation_id),
 claimed_at timestamptz,grant_receipt_id text,claim_content_revision text REFERENCES gxb_content_revisions(revision_id),
 UNIQUE(sender_player_id,recipient_player_id,policy_id,sender_day),
 UNIQUE(recipient_player_id,notice_id),
 FOREIGN KEY(recipient_player_id,notice_id) REFERENCES social_notices(recipient_player_id,notice_id) ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED,
 CHECK((claim_operation_id IS NULL AND claim_day IS NULL AND claim_generation_id IS NULL AND claimed_at IS NULL AND grant_receipt_id IS NULL AND claim_content_revision IS NULL)
 OR(claim_operation_id IS NOT NULL AND claim_day IS NOT NULL AND claim_generation_id IS NOT NULL AND claimed_at IS NOT NULL AND claimed_at>=issued_at AND grant_receipt_id IS NOT NULL AND claim_content_revision IS NOT NULL))
);
CREATE INDEX social_gift_send_quota ON social_gift_transfers(sender_player_id,policy_id,sender_day);
CREATE INDEX social_gift_claim_quota ON social_gift_transfers(recipient_player_id,claim_day) WHERE claim_operation_id IS NOT NULL;
CREATE INDEX social_gift_unclaimed_window ON social_gift_transfers(recipient_player_id,issued_at DESC,notice_id DESC) WHERE claim_operation_id IS NULL;
