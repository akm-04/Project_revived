package arenastore

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/arena"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadFriendInvitationTx(requestContext context.Context, query tx.Queryer, identifier ids.UUID, lock bool) (d.FriendInvitation, bool, error) {
	statement := `SELECT payload::text FROM arena_friend_invitations WHERE invitation_id=$1`
	if lock {
		statement += ` FOR UPDATE`
	}
	var invitation d.FriendInvitation
	found, err := readJSON(requestContext, query, statement, &invitation, identifier.String())
	if err != nil || !found {
		return invitation, found, err
	}
	return invitation, true, invitation.Validate()
}

func (Store) LatestFriendInvitationTx(requestContext context.Context, query tx.Queryer, inviter, recipient identity.PlayerID) (d.FriendInvitation, bool, error) {
	var invitation d.FriendInvitation
	found, err := readJSON(requestContext, query, `SELECT payload::text FROM arena_friend_invitations WHERE inviter_player=$1 AND ($2::bigint=0 OR recipient_player=$2) ORDER BY sequence DESC LIMIT 1`, &invitation, int64(inviter), int64(recipient))
	if err != nil || !found {
		return invitation, found, err
	}
	return invitation, true, invitation.Validate()
}

func (Store) PendingFriendInvitationsForPlayersTx(requestContext context.Context, query tx.Queryer, first, second identity.PlayerID) ([]d.FriendInvitation, error) {
	var invitations []d.FriendInvitation
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(payload ORDER BY sequence),'[]'::jsonb)::text FROM arena_friend_invitations WHERE status='PENDING' AND (inviter_player IN($1,$2) OR recipient_player IN($1,$2))`, &invitations, int64(first), int64(second))
	if err != nil {
		return nil, err
	}
	for _, invitation := range invitations {
		if err := invitation.Validate(); err != nil {
			return nil, err
		}
	}
	return invitations, nil
}

func (Store) FriendFightBusyTx(requestContext context.Context, query tx.Queryer, player identity.PlayerID, at time.Time, excluded ids.UUID) (bool, error) {
	var busy bool
	err := query.QueryRow(requestContext, `SELECT EXISTS(SELECT 1 FROM arena_friend_invitations WHERE status='PENDING' AND invitation_id<>$3 AND expires_at>$2 AND (inviter_player=$1 OR recipient_player=$1)) OR EXISTS(SELECT 1 FROM arena_tournament_rooms WHERE (first_player=$1 OR second_player=$1) AND (status IN('SELECTING','FIGHTING') OR(status='PREPARING' AND starts_at<=$2+interval '30 seconds'))) OR EXISTS(SELECT 1 FROM arena_casual_entries WHERE player_id=$1 AND status IN('WAITING','MATCHED') AND (status='MATCHED' OR expires_at>$2))`, int64(player), at, excluded.String()).Scan(&busy)
	return busy, err
}

func (Store) DueFriendInvitationsTx(requestContext context.Context, query tx.Queryer, at time.Time, limit int) ([]ids.UUID, error) {
	var identifiers []ids.UUID
	_, err := readJSON(requestContext, query, `SELECT COALESCE(jsonb_agg(invitation_id ORDER BY expires_at,invitation_id),'[]'::jsonb)::text FROM (SELECT invitation_id,expires_at FROM arena_friend_invitations WHERE status='PENDING' AND expires_at<=$1 ORDER BY expires_at,invitation_id LIMIT $2) due`, &identifiers, at, limit)
	return identifiers, err
}

func (Store) SaveFriendInvitationTx(requestContext context.Context, transaction tx.Tx, invitation d.FriendInvitation, previousVersion int64) error {
	if transaction == nil || invitation.Validate() != nil || invitation.StateVersion != previousVersion+1 {
		return d.ErrConflict
	}
	payload, err := encode(invitation)
	if err != nil {
		return err
	}
	var room any
	if !invitation.Room.IsZero() {
		room = invitation.Room.String()
	}
	if previousVersion == 0 {
		err = one(transaction.Exec(requestContext, `INSERT INTO arena_friend_invitations(invitation_id,inviter_player,recipient_player,status,room_id,created_at,expires_at,sequence,state_version,payload) VALUES($1,$2,$3,$4,$5,$6,$7,$8,1,$9::jsonb)`, invitation.Identifier.String(), int64(invitation.Inviter.PlayerID), int64(invitation.Recipient), invitation.Status, room, invitation.CreatedAt, invitation.ExpiresAt, invitation.Sequence, payload))
	} else {
		err = one(transaction.Exec(requestContext, `UPDATE arena_friend_invitations SET status=$3,room_id=$4,state_version=$5,payload=$6::jsonb WHERE invitation_id=$1 AND state_version=$2 AND inviter_player=$7 AND recipient_player=$8 AND sequence=$9`, invitation.Identifier.String(), previousVersion, invitation.Status, room, invitation.StateVersion, payload, int64(invitation.Inviter.PlayerID), int64(invitation.Recipient), invitation.Sequence))
	}
	if err != nil {
		return err
	}
	return postgres.EmitRealtimeWakeup(requestContext, transaction, wake.Envelope{Version: wake.EnvelopeVersion, Route: app.FriendFightNoticeRoute, Ref: invitation.Identifier.String()})
}
