-- +goose Up
-- owner: guildcampaign
-- I9_GUILD_CAMPAIGN_V1 C2. Member day 605, chapter 606, copy 607, server records 608.
-- No guild FK: it would take a key-share lock on guild 310 from a START or settle,
-- which never lock the guild. A live chapter row means the chapter is open.
CREATE TABLE guild_campaign_chapters (
 guild_id bigint NOT NULL CHECK(guild_id > 0),
 chapter_id bigint NOT NULL CHECK(chapter_id > 0),
 run bigint NOT NULL CHECK(run > 0),
 is_win boolean NOT NULL DEFAULT false,
 percent double precision NOT NULL DEFAULT 0 CHECK(percent >= 0 AND percent <= 1),
 start_time timestamptz NOT NULL,
 end_time timestamptz,
 PRIMARY KEY(guild_id, chapter_id)
);

-- C4: fixed at open or reset, under the chapter row's lock.
CREATE TABLE guild_campaign_registrations (
 guild_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 PRIMARY KEY(guild_id, chapter_id, player_id),
 FOREIGN KEY(guild_id, chapter_id) REFERENCES guild_campaign_chapters(guild_id, chapter_id) ON DELETE CASCADE
);
CREATE INDEX guild_campaign_registrations_by_player ON guild_campaign_registrations(guild_id, player_id);

-- C6, C7: enemy HP carries in waves; the holder columns are the one attacker's claim.
CREATE TABLE guild_campaign_copies (
 guild_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 copy_id bigint NOT NULL CHECK(copy_id > 0),
 run bigint NOT NULL CHECK(run > 0),
 waves jsonb NOT NULL,
 current_index bigint NOT NULL DEFAULT 1 CHECK(current_index >= 1),
 is_win boolean NOT NULL DEFAULT false,
 percent double precision NOT NULL DEFAULT 0 CHECK(percent >= 0 AND percent <= 1),
 holder_id bigint,
 holder_stage bigint NOT NULL DEFAULT 0 CHECK(holder_stage IN (0, 1, 2)),
 last_fight_time timestamptz,
 start_fight_time timestamptz,
 attempt_generation text,
 settled_by bigint,
 settled_index bigint NOT NULL DEFAULT 0,
 settled_body jsonb,
 PRIMARY KEY(guild_id, chapter_id, copy_id),
 FOREIGN KEY(guild_id, chapter_id) REFERENCES guild_campaign_chapters(guild_id, chapter_id) ON DELETE CASCADE
);

-- C9: older days are deleted on the member's next clear.
CREATE TABLE guild_campaign_member_days (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 chapter_id bigint NOT NULL,
 game_day bigint NOT NULL,
 clears bigint NOT NULL CHECK(clears >= 0),
 PRIMARY KEY(player_id, chapter_id, game_day)
);

-- C11: one row per member per run. These outlive a reset, for the award queue's seven days.
CREATE TABLE guild_campaign_damage (
 guild_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 run bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 best_damage bigint NOT NULL CHECK(best_damage >= 0),
 hit_at timestamptz NOT NULL,
 PRIMARY KEY(guild_id, chapter_id, run, player_id)
);
CREATE INDEX guild_campaign_damage_rank ON guild_campaign_damage(guild_id, chapter_id, run, best_damage DESC, hit_at);

-- C14: award queue, chapter_version 1 only. A member holds one application per run.
CREATE TABLE guild_campaign_awards (
 guild_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 run bigint NOT NULL,
 award_id bigint NOT NULL,
 remaining bigint NOT NULL CHECK(remaining >= 0),
 expires_at timestamptz NOT NULL,
 next_slot timestamptz NOT NULL,
 PRIMARY KEY(guild_id, chapter_id, run, award_id)
);
CREATE INDEX guild_campaign_awards_due ON guild_campaign_awards(next_slot) WHERE remaining > 0;

CREATE TABLE guild_campaign_applications (
 guild_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 run bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 award_id bigint NOT NULL,
 applied_at timestamptz NOT NULL,
 PRIMARY KEY(guild_id, chapter_id, run, player_id)
);
CREATE INDEX guild_campaign_applications_by_award ON guild_campaign_applications(guild_id, chapter_id, run, award_id);

CREATE TABLE guild_campaign_application_days (
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 game_day bigint NOT NULL,
 applications bigint NOT NULL CHECK(applications >= 0),
 PRIMARY KEY(player_id, game_day)
);

CREATE TABLE guild_campaign_distributions (
 distribution_id bigserial PRIMARY KEY,
 guild_id bigint NOT NULL,
 player_id bigint NOT NULL,
 item_id bigint NOT NULL,
 distributed_at timestamptz NOT NULL
);
CREATE INDEX guild_campaign_distributions_recent ON guild_campaign_distributions(guild_id, distributed_at DESC);

-- 609, bounded by guild_log_retention_days in I9_GUILD_POLICY_V1.
CREATE TABLE guild_campaign_log (
 log_id bigserial PRIMARY KEY,
 guild_id bigint NOT NULL,
 log_type bigint NOT NULL CHECK(log_type IN (7, 8, 9)),
 player_id bigint NOT NULL,
 chapter_id bigint NOT NULL,
 at timestamptz NOT NULL
);
CREATE INDEX guild_campaign_log_recent ON guild_campaign_log(guild_id, at DESC);

-- C15, rank 608: per logical server, one row per member per copy.
CREATE TABLE guild_campaign_server_records (
 logical_server_id bigint NOT NULL,
 copy_id bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 guild_id bigint NOT NULL,
 damage bigint NOT NULL CHECK(damage >= 0),
 partners jsonb NOT NULL,
 hit_at timestamptz NOT NULL,
 PRIMARY KEY(logical_server_id, copy_id, player_id)
);
CREATE INDEX guild_campaign_server_records_rank ON guild_campaign_server_records(logical_server_id, copy_id, damage DESC, hit_at);

CREATE TABLE guild_campaign_server_kills (
 logical_server_id bigint NOT NULL,
 copy_id bigint NOT NULL,
 first_player_id bigint NOT NULL,
 first_guild_id bigint NOT NULL,
 first_at timestamptz NOT NULL,
 fastest_guild_id bigint NOT NULL,
 fastest_seconds bigint NOT NULL CHECK(fastest_seconds >= 0),
 PRIMARY KEY(logical_server_id, copy_id)
);
