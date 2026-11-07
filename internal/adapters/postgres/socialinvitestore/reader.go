package socialinvitestore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	application "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Reader is the durable socialinvite projection used by MID 384. It reads only
// committed binding/claim rows plus canonical owner observations in one caller
// snapshot; it never writes or advances state.
type Reader struct {
	Owner application.Owner
	Facts application.FactsReader
}

var _ application.InviteReader = Reader{}

func (reader Reader) ReadInviteTx(ctx context.Context, scope tx.Scope, actor identity.ActorContext, revision string, at time.Time) (application.Snapshot, error) {
	out := application.Snapshot{Invitees: []application.InviteeFacts{}, Claimed: []int64{}}
	if reader.Owner == nil || reader.Facts == nil || scope.Tx == nil || (scope.Options.Isolation != tx.RepeatableRead && scope.Options.Isolation != tx.Serializable) || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || at.IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return out, application.ErrFacts
	}
	if err := validPins(scope, revision); err != nil {
		return out, err
	}
	code, err := domain.EncodeCode(actor.PlayerID)
	if err != nil {
		return out, application.ErrFacts
	}
	out.InviteCode = code

	binding, found, err := reader.Owner.ReadBindingTx(ctx, scope.Tx, actor.PlayerID)
	if err != nil {
		return out, err
	}
	if found {
		profile, err := reader.Facts.ReadPlayerProfileTx(ctx, scope.Tx, binding.Inviter)
		if err != nil {
			return out, err
		}
		if profile.Validate(binding.Inviter) != nil {
			return out, application.ErrFacts
		}
		out.InvitorID = binding.Inviter
		out.InvitorName = profile.Name
	}

	invitees, err := reader.Owner.InviteesForInviterTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID, application.InviteeLimit)
	if err != nil {
		return out, err
	}
	previous := identity.PlayerID(0)
	for _, invitee := range invitees {
		if !invitee.Valid() || invitee <= previous || logicalserver.PlayerRegion(invitee) != actor.LogicalServerID {
			return out, application.ErrFacts
		}
		previous = invitee
		facts, err := reader.Facts.ReadInviteeFactsTx(ctx, scope, invitee, revision, at)
		if err != nil {
			return out, err
		}
		if facts.Validate() != nil || facts.Player != invitee {
			return out, application.ErrFacts
		}
		out.Invitees = append(out.Invitees, facts)
	}

	claimed, err := reader.Owner.ClaimsTx(ctx, scope.Tx, actor.PlayerID, actor.LogicalServerID)
	if err != nil {
		return out, err
	}
	out.Claimed = claimed
	if err := out.Validate(actor.LogicalServerID); err != nil {
		return out, err
	}
	return out, nil
}

func validPins(scope tx.Scope, revision string) error {
	content, bound := scope.Operation.Policies.Get("content")
	if !bound || content != revision {
		return application.ErrFacts
	}
	invite, bound := scope.Operation.Policies.Get("socialinvite")
	if !bound || invite != application.PolicyVersion {
		return application.ErrFacts
	}
	return nil
}
