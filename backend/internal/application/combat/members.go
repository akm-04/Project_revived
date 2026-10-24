package combat

import (
	"context"
	"fmt"
	"slices"
	"time"

	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// roster returns the request's member roster as stored (seat order); an empty
// roster is a single-member attempt.
func (r StartRequest) roster() ([]int64, error) {
	if len(r.Members) == 0 {
		return nil, nil
	}
	members := make([]int64, len(r.Members))
	for i, member := range r.Members {
		members[i] = int64(member)
	}
	return members, d.ValidMembers(int64(r.Actor.PlayerID), members)
}

// admit asks the room capability before any member read, so a refused roster
// touches no owner state; every co-member must field an actor.
func (f *freezer) admit(ctx context.Context, locator d.Locator, members []int64, battle BattleRequest) error {
	f.members = map[identity.PlayerID]bool{}
	if len(members) == 0 {
		return nil
	}
	admission := Admission{Convener: f.starter, Locator: locator}
	for _, member := range members {
		admission.Members = append(admission.Members, identity.PlayerID(member))
	}
	for _, member := range admission.Members[1:] {
		if !battlePlayer(battle, member) {
			return d.ErrInvalid
		}
	}
	if f.service.Inputs.Rooms == nil {
		return fmt.Errorf("%w: no room capability", d.ErrProviderUnavailable)
	}
	if err := f.service.Inputs.Rooms.AdmitTx(ctx, f.t, f.scope, admission); err != nil {
		return err
	}
	for _, member := range admission.Members[1:] {
		f.members[member] = true
	}
	return nil
}

type MemberSettleRequest struct {
	Locator           d.Locator
	AttemptID         ids.UUID
	Member            identity.PlayerID
	SemanticReceiptID string
	At                time.Time
}

type MemberSettled struct {
	Settlement d.MemberSettlement
	Replayed   bool
}

// SettleMemberTx runs inside the mode's settlement transaction after the
// attempt's single terminal and records one member's settlement once; a
// repeat with the same receipt replays it (D24d).
func (s Service) SettleMemberTx(ctx context.Context, t tx.Tx, request MemberSettleRequest) (MemberSettled, error) {
	settlement := d.MemberSettlement{AttemptID: request.AttemptID, Member: int64(request.Member), SemanticReceiptID: request.SemanticReceiptID, SettledAt: request.At.UTC()}
	if t == nil || !request.Locator.Valid() || settlement.Validate() != nil {
		return MemberSettled{}, d.ErrInvalid
	}
	if err := s.Store.LockLocatorTx(ctx, t, request.Locator); err != nil {
		return MemberSettled{}, err
	}
	attempt, found, err := s.Store.ReadAttemptTx(ctx, t, request.AttemptID)
	if err != nil {
		return MemberSettled{}, err
	}
	if !found {
		return MemberSettled{}, ErrAttemptNotFound
	}
	if attempt.Locator != request.Locator {
		return MemberSettled{}, d.ErrInvalid
	}
	if !attempt.Settleable() {
		return MemberSettled{}, d.ErrNotReady
	}
	members, err := s.Store.ReadMembersTx(ctx, t, attempt.ID)
	if err != nil {
		return MemberSettled{}, err
	}
	if !slices.Contains(members, settlement.Member) {
		return MemberSettled{}, d.ErrInvalid
	}
	done, found, err := s.Store.FindMemberSettlementTx(ctx, t, attempt.ID, settlement.Member)
	if err != nil {
		return MemberSettled{}, err
	}
	if found && done.SemanticReceiptID != settlement.SemanticReceiptID {
		return MemberSettled{}, d.ErrMemberSettled
	}
	if found {
		return MemberSettled{Settlement: done, Replayed: true}, nil
	}
	return MemberSettled{Settlement: settlement}, s.Store.InsertMemberSettlementTx(ctx, t, settlement)
}
