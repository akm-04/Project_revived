-- +goose Up
-- owner: mentor
CREATE TABLE mentor_relations (
 relation_id uuid PRIMARY KEY CHECK(relation_id <> '00000000-0000-0000-0000-000000000000'),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 mentor_id bigint NOT NULL REFERENCES players(player_id),
 student_id bigint NOT NULL REFERENCES players(player_id),
 content_revision text NOT NULL CHECK(content_revision ~ '^[0-9a-f]{64}$'),
 policy_version text NOT NULL CHECK(policy_version=btrim(policy_version) AND length(policy_version)>0),
 accepted_at timestamptz NOT NULL CHECK(isfinite(accepted_at)),
 ended_at timestamptz CHECK(isfinite(ended_at)),
 intimacy integer NOT NULL DEFAULT 0 CHECK(intimacy>=0 AND intimacy<=3000),
 last_intimacy_day date,
 background_baseline integer NOT NULL DEFAULT 0 CHECK(background_baseline>=0),
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK(mentor_id<>student_id),
 CHECK(mentor_id/100000=logical_server_id AND student_id/100000=logical_server_id),
 CHECK(ended_at IS NULL OR (ended_at>=accepted_at AND state_version>=2))
);
CREATE UNIQUE INDEX mentor_relations_active_mentor ON mentor_relations(mentor_id) WHERE ended_at IS NULL;
CREATE UNIQUE INDEX mentor_relations_active_student ON mentor_relations(student_id) WHERE ended_at IS NULL;
CREATE UNIQUE INDEX mentor_relations_active_pair ON mentor_relations(LEAST(mentor_id,student_id),GREATEST(mentor_id,student_id)) WHERE ended_at IS NULL;

CREATE TABLE mentor_states (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 apply_day date NOT NULL,
 apply_count_mentor integer NOT NULL CHECK(apply_count_mentor>=0),
 apply_count_student integer NOT NULL CHECK(apply_count_student>=0),
 broke_at timestamptz CHECK(isfinite(broke_at)),
 state_version bigint NOT NULL CHECK(state_version>0),
 CHECK(player_id/100000=logical_server_id)
);

CREATE TABLE mentor_applications (
 applicant_id bigint NOT NULL REFERENCES players(player_id),
 target_id bigint NOT NULL REFERENCES players(player_id),
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 recipient_relation_type smallint NOT NULL CHECK(recipient_relation_type IN (1,2)),
 msg text NOT NULL,
 created_at timestamptz NOT NULL CHECK(isfinite(created_at)),
 expires_at timestamptz NOT NULL CHECK(isfinite(expires_at) AND expires_at>created_at),
 status text NOT NULL CHECK(status IN ('PENDING','ACCEPTED','DENIED')),
 state_version bigint NOT NULL CHECK(state_version>0),
 PRIMARY KEY(applicant_id,target_id),
 CHECK(applicant_id<>target_id),
 CHECK(applicant_id/100000=logical_server_id AND target_id/100000=logical_server_id)
);

CREATE TABLE mentor_mission_progress (
 player_id bigint NOT NULL REFERENCES players(player_id),
 mission_id bigint NOT NULL CHECK(mission_id>0),
 progress bigint NOT NULL DEFAULT 0 CHECK(progress>=0),
 completed_at timestamptz CHECK(isfinite(completed_at)),
 awarded_at timestamptz CHECK(isfinite(awarded_at)),
 state_version bigint NOT NULL CHECK(state_version>0),
 PRIMARY KEY(player_id,mission_id),
 CHECK(awarded_at IS NULL OR completed_at IS NOT NULL)
);

CREATE TABLE mentor_exam_receipts (
 student_id bigint NOT NULL REFERENCES players(player_id),
 mission_id bigint NOT NULL CHECK(mission_id>0),
 relation_id uuid NOT NULL,
 won_at timestamptz NOT NULL CHECK(isfinite(won_at)),
 items jsonb NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 PRIMARY KEY(student_id,mission_id)
);
