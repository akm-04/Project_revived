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
type AdmissionBinding struct {
	Store  Store
	Family string
	Slot   int64
}

var _ cb.Rooms = AdmissionBinding{}

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
	if !found || !admissible(room, admission.Members, scope.ObservedAt.UTC()) {
		return cd.ErrRoomRefused
	}
	return nil
}

func admissible(room d.Room, roster []identity.PlayerID, at time.Time) bool {
	if room.Status != d.StatusOpen || !at.Before(room.ExpiresAt) {
		return false
	}
	if !slices.Equal(room.Members(), roster) {
		return false
	}
	for _, seat := range room.Seats {
		if seat.Stage == d.SeatSeated && !seat.Ready {
			return false
		}
	}
	return true
}
