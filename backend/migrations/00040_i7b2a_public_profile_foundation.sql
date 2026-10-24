-- +goose Up
-- PublicProfile owns preferences only. Reads never materialize this root.
CREATE TABLE player_public_profile_roots (
 player_id bigint PRIMARY KEY REFERENCES players(player_id),
 intro text NOT NULL DEFAULT '' CHECK(char_length(intro)<=40),
 show_type_ids bigint[] NOT NULL DEFAULT '{}',
 hide_subtypes smallint[] NOT NULL DEFAULT '{}',
 share_switch smallint NOT NULL DEFAULT 0 CHECK(share_switch IN (0,1)),
 is_first_time smallint NOT NULL DEFAULT 0 CHECK(is_first_time IN (0,1)),
 state_version bigint NOT NULL CHECK(state_version>0),
 policy_version text NOT NULL CHECK(policy_version='I7B_PUBLIC_V1'),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL CHECK(updated_at>=created_at),
 CHECK(cardinality(show_type_ids)<=4 AND (cardinality(show_type_ids)=0 OR (array_ndims(show_type_ids)=1 AND array_lower(show_type_ids,1)=1))),
 CHECK(array_position(show_type_ids,NULL) IS NULL AND show_type_ids <@ ARRAY[1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011]::bigint[]),
 CHECK(COALESCE(show_type_ids[1]<>show_type_ids[2],true) AND COALESCE(show_type_ids[1]<>show_type_ids[3],true) AND COALESCE(show_type_ids[1]<>show_type_ids[4],true) AND COALESCE(show_type_ids[2]<>show_type_ids[3],true) AND COALESCE(show_type_ids[2]<>show_type_ids[4],true) AND COALESCE(show_type_ids[3]<>show_type_ids[4],true)),
 CHECK(cardinality(hide_subtypes)<=2 AND (cardinality(hide_subtypes)=0 OR (array_ndims(hide_subtypes)=1 AND array_lower(hide_subtypes,1)=1))),
 CHECK(array_position(hide_subtypes,NULL) IS NULL AND hide_subtypes <@ ARRAY[2,4]::smallint[]),
 CHECK(COALESCE(hide_subtypes[1]<hide_subtypes[2],true))
);
