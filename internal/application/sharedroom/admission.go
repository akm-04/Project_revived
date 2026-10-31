package sharedroom

import (
	"context"
	"slices"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AdmissionBinding is the production combat.Rooms capability for one family
// slot. It runs inside START after the caller took the actor fence and the I4
// roots in clause C2 order, and it locks the room row at rank 607 before
// comparing the roster.
//
// SeatOrder is the default: the roster is the seats in seat order, so only the
// owner can convene. ConvenerFirst accepts any seated member as convener with
// the others after it in any order.
type AdmissionBinding struct {
	Store         Store
	Family        string
	Slot          int64
	ConvenerFirst bool
}

var _ cb.Rooms = AdmissionBinding{}

// AdmissionRouter is the production combat.Rooms of a backend with several room
// families: each START is admitted by the binding of its locator's domain kind.
type AdmissionRouter map[string]AdmissionBinding

var _ cb.Rooms = AdmissionRouter{}

func (r AdmissionRouter) AdmitTx(ctx context.Context, t tx.Tx, scope ca.CoherentReadScope, admission cb.Admission) error {
	binding, found := r[admission.Locator.DomainKind]
	if !found {
		return cd.ErrRoomRefused
	}
	return binding.AdmitTx(ctx, t, scope, admission)
}

// AdmitTx confirms that the roster is exactly the seated members of the
// convener's open room, in seat order, with every seat ready.
func (b AdmissionBinding) AdmitTx(ctx context.Context, t tx.Tx, scope ca.CoherentReadScope, admission cb.Admission) error {
	if b.Store == nil || t == nil || !admission.Convener.Valid() {
		return cd.ErrRoomRefused
	}
	if len(admission.Members) == 0 || admission.Members[0] != admission.Convener {
		return cd.ErrRoomRefused
	}
	active, found, err := b.Store.ReadPlayerRoomTx(ctx, t, admission.Convener, b.Family, b.Slot)
	if err != nil {
		return err
	}
	if !found {
		return cd.ErrRoomRefused
	}
	room, found, err := b.Store.LockRoomTx(ctx, t, active.ID)
	if err != nil {
		return err
	}
	if !found || !admissible(room, admission.Members, scope.ObservedAt.UTC(), b.ConvenerFirst) {
		return cd.ErrRoomRefused
	}
	return nil
}

func admissible(room d.Room, roster []identity.PlayerID, at time.Time, convenerFirst bool) bool {
	if room.Status != d.StatusOpen || !at.Before(room.ExpiresAt) {
		return false
	}
	if !sameRoster(room.Members(), roster, convenerFirst) {
		return false
	}
	for _, seat := range room.Seats {
		if seat.Stage == d.SeatSeated && !seat.Ready {
			return false
		}
	}
	return true
}

func sameRoster(seated, roster []identity.PlayerID, convenerFirst bool) bool {
	if !convenerFirst {
		return slices.Equal(seated, roster)
	}
	ordered := slices.Clone(roster)
	slices.Sort(ordered)
	sortedSeats := slices.Clone(seated)
	slices.Sort(sortedSeats)
	return slices.Equal(sortedSeats, ordered)
}
