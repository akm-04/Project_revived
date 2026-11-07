-- +goose Up
-- owner: socialinvite
CREATE TABLE social_invite_bindings (
 invitee_player_id bigint PRIMARY KEY,
 inviter_player_id bigint NOT NULL,
 logical_server_id integer NOT NULL,
 operation_id uuid NOT NULL UNIQUE,
 policy_version text NOT NULL CHECK(length(policy_version) > 0),
 bound_at timestamptz NOT NULL,
 CHECK(invitee_player_id > 0 AND inviter_player_id > 0 AND inviter_player_id <> invitee_player_id),
 CHECK(invitee_player_id / 100000 = logical_server_id AND inviter_player_id / 100000 = logical_server_id)
);
CREATE INDEX social_invite_bindings_inviter_idx ON social_invite_bindings(inviter_player_id,invitee_player_id);

CREATE TABLE social_invite_mission_claims (
 player_id bigint NOT NULL,
 mission_id bigint NOT NULL,
 logical_server_id integer NOT NULL,
 operation_id uuid NOT NULL UNIQUE,
 content_revision text NOT NULL CHECK(content_revision ~ '^[0-9a-f]{64}$'),
 policy_version text NOT NULL CHECK(length(policy_version) > 0),
 grant_key text NOT NULL UNIQUE CHECK(grant_key ~ '^[0-9a-f]{64}$'),
 claimed_at timestamptz NOT NULL,
 PRIMARY KEY(player_id, mission_id),
 CHECK(player_id > 0 AND mission_id > 0 AND player_id / 100000 = logical_server_id)
);

-- D476 validated operator override/off hook. No operator endpoint exists before I11.
CREATE TABLE social_invite_tuning (
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 updated_at timestamptz NOT NULL
);

