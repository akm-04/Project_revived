package arena

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type FriendFightNotice struct {
	Recipient identity.PlayerID
	Type      int64
	Inviter   d.Face
	Mode      int
	GameType  int
}
type FriendFightNoticeReader struct {
	Store     Store
	Directory Directory
	Queryer   tx.Queryer
	Time      gen.TimeAuthority
}

func (reader FriendFightNoticeReader) ReadFriendNotice(requestContext context.Context, reference string) (FriendFightNotice, bool, error) {
	var result FriendFightNotice
	identifier, err := ids.ParseUUID(reference)
	if err != nil || identifier.IsZero() {
		return result, false, d.ErrInvalid
	}
	if reader.Store == nil || reader.Directory == nil || reader.Queryer == nil || reader.Time == nil {
		return result, false, d.ErrUnavailable
	}
	invitation, found, err := reader.Store.ReadFriendInvitationTx(requestContext, reader.Queryer, identifier, false)
	if err != nil || !found {
		return result, false, err
	}
	latest, found, err := reader.Store.LatestFriendInvitationTx(requestContext, reader.Queryer, invitation.Inviter.PlayerID, 0)
	if err != nil || !found || latest.Identifier != identifier {
		return result, false, err
	}
	// The stock refusal notice carries no generation; suppress one superseded by a reverse offer too.
	reverse, found, err := reader.Store.LatestFriendInvitationTx(requestContext, reader.Queryer, invitation.Recipient, 0)
	if err != nil {
		return result, false, err
	}
	if found && reverse.Sequence > invitation.Sequence {
		return result, false, nil
	}
	at, err := reader.Time.Now(requestContext)
	if err != nil {
		return result, false, err
	}
	switch invitation.Status {
	case d.FriendInvitationPending:
		if !at.Before(invitation.ExpiresAt) {
			return result, false, nil
		}
		profile, found, err := reader.Directory.ProfileTx(requestContext, reader.Queryer, invitation.Inviter.PlayerID)
		if err != nil || !found {
			return result, false, err
		}
		result = FriendFightNotice{Recipient: invitation.Recipient, Type: 14, Inviter: d.Face{Player: invitation.Inviter.PlayerID, Name: profile.Name}, Mode: invitation.Mode, GameType: invitation.GameType}
	case d.FriendInvitationRejected, d.FriendInvitationExpired:
		result = FriendFightNotice{Recipient: invitation.Inviter.PlayerID, Type: 15}
	default:
		return result, false, nil
	}
	return result, true, nil
}
func (service Service) ExpireFriendInvitations(requestContext context.Context, parent operation.Context, limit int) (int, error) {
	at, err := service.Timed.Binder.Time.Now(requestContext)
	if err != nil {
		return 0, err
	}
	identifiers, err := service.Store.DueFriendInvitationsTx(requestContext, service.Fresh, at, limit)
	if err != nil || len(identifiers) == 0 {
		return 0, err
	}
	operationContext, err := child(parent, "friend-invitation-expiry")
	if err != nil {
		return 0, err
	}
	expired := 0
	_, _, err = service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		expired = 0
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		for _, identifier := range identifiers {
			invitation, found, err := service.Store.ReadFriendInvitationTx(requestContext, scope.Tx, identifier, true)
			if err != nil {
				return err
			}
			if !found || invitation.Status != d.FriendInvitationPending || scope.Operation.DecisionAt().Before(invitation.ExpiresAt) {
				continue
			}
			previous := invitation.StateVersion
			invitation.StateVersion++
			invitation.Status = d.FriendInvitationExpired
			if err := service.Store.SaveFriendInvitationTx(requestContext, scope.Tx, invitation, previous); err != nil {
				return err
			}
			expired++
		}
		if expired == 0 {
			return nil
		}
		previous := root.StateVersion
		root.StateVersion++
		root.UpdatedAt = scope.Operation.DecisionAt()
		return service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, previous)
	})
	return expired, err
}
