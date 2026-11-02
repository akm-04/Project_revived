-- +goose Up
-- owner: Arena
CREATE TABLE arena_friend_invitations (
 invitation_id uuid PRIMARY KEY,
 inviter_player bigint NOT NULL REFERENCES players(player_id),
 recipient_player bigint NOT NULL REFERENCES players(player_id),
 status text NOT NULL CHECK(status IN ('PENDING','ACCEPTED','REJECTED','EXPIRED')),
 room_id uuid REFERENCES arena_tournament_rooms(room_id),
 created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL CHECK(expires_at=created_at+interval '60 seconds'),
 sequence bigint NOT NULL UNIQUE CHECK(sequence>0),
 state_version bigint NOT NULL CHECK(state_version>0),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 CHECK(inviter_player<>recipient_player),
 CHECK((status='ACCEPTED')=(room_id IS NOT NULL)),
 CHECK((payload->>'identifier')::uuid=invitation_id),
 CHECK((payload->'inviter'->>'PlayerID')::bigint=inviter_player),
 CHECK((payload->>'recipient')::bigint=recipient_player),
 CHECK((payload->>'sequence')::bigint=sequence),
 CHECK((payload->>'state_version')::bigint=state_version),
 CHECK(payload->>'status'=status)
);
CREATE UNIQUE INDEX arena_friend_pending_pair ON arena_friend_invitations(LEAST(inviter_player,recipient_player),GREATEST(inviter_player,recipient_player)) WHERE status='PENDING';
CREATE INDEX arena_friend_pending_due ON arena_friend_invitations(expires_at,invitation_id) WHERE status='PENDING';
CREATE INDEX arena_friend_inviter_latest ON arena_friend_invitations(inviter_player,sequence DESC);
ALTER TABLE arena_tournament_rooms ADD COLUMN friend_invitation_id uuid REFERENCES arena_friend_invitations(invitation_id);
ALTER TABLE arena_tournament_rooms DROP CONSTRAINT arena_tournament_rooms_check1;
ALTER TABLE arena_tournament_rooms ADD CONSTRAINT arena_room_exact_origin CHECK(num_nonnulls(season,casual_week_day,friend_invitation_id)=1);
ALTER TABLE arena_tournament_rooms ADD CONSTRAINT arena_room_friend_identity CHECK(friend_invitation_id IS NULL OR (payload->>'friend_invitation')::uuid=friend_invitation_id);
