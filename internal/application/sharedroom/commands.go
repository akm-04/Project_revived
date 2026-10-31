package sharedroom

import (
	"context"
	"encoding/json"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OpenRequest creates a room. Capacity and Lease are family policy, and Payload
// is the family's opaque room state.
type OpenRequest struct {
	Family   Family
	Capacity int64
	Lease    time.Duration
	Payload  json.RawMessage
}

// LeaveResult reports the room after the leave; Closed says whether that leave
// (or an earlier one) closed it.
type LeaveResult struct {
	Room   d.Room
	Closed bool
}

func (s Service) Open(c context.Context, actor identity.ActorContext, request OpenRequest, op operation.Context) (d.Room, error) {
	if err := request.Family.validate(); err != nil {
		return d.Room{}, err
	}
	if request.Capacity < 1 || request.Capacity > d.MaxSeats || request.Lease <= 0 {
		return d.Room{}, d.ErrInvalid
	}
	var room d.Room
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		_, found, err := s.Store.ReadPlayerRoomTx(c, sc.Tx, actor.PlayerID, request.Family.Name, request.Family.Slot)
		if err != nil {
			return err
		}
		if found {
			return ErrAlreadyInRoom
		}
		if err := s.lockRoots(c, sc.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		built, err := d.NewRoom(actor.LogicalServerID, request.Family.Name, request.Family.Slot, request.Capacity, actor.PlayerID, at.Add(request.Lease), request.Payload, at)
		if err != nil {
			return err
		}
		stored, err := s.Store.OpenRoomTx(c, sc.Tx, built)
		if err != nil {
			return err
		}
		if err := s.Store.WakeRoomTx(c, sc.Tx, stored.ID, request.Family.Route); err != nil {
			return err
		}
		room = stored
		return nil
	})
	return room, err
}

// Join admits the actor by room id. Membership is idempotent; a kicked player
// is refused for the lifetime of that room.
func (s Service) Join(c context.Context, actor identity.ActorContext, family Family, roomID int64, op operation.Context) (d.Room, error) {
	if err := family.validate(); err != nil {
		return d.Room{}, err
	}
	if roomID <= 0 {
		return d.Room{}, d.ErrInvalid
	}
	var room d.Room
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		existing, found, err := s.Store.ReadPlayerRoomTx(c, sc.Tx, actor.PlayerID, family.Name, family.Slot)
		if err != nil {
			return err
		}
		if found && existing.ID != roomID {
			return ErrAlreadyInRoom
		}
		observed, found, err := s.Store.ReadRoomTx(c, sc.Tx, roomID)
		if err != nil {
			return err
		}
		if !found || observed.Family != family.Name || observed.Slot != family.Slot {
			return ErrNotFound
		}
		if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, append(observed.Members(), actor.PlayerID)); err != nil {
			return err
		}
		locked, err := s.lockObserved(c, sc.Tx, observed)
		if err != nil {
			return err
		}
		before := locked.StateVersion
		if err := locked.Join(actor.PlayerID, at); err != nil {
			return err
		}
		if err := s.saveAndWake(c, sc.Tx, locked, before, family.Route); err != nil {
			return err
		}
		room = locked
		return nil
	})
	return room, err
}

// Update applies a family payload change to the actor's active room under the
// same fence, root and room locks as the membership commands. Before runs after
// the roots and before the room lock, so a family can lock its own 605/606 rows
// in clause C2 order.
type UpdateRequest struct {
	Family Family
	Before func(context.Context, tx.Tx, d.Room, time.Time) error
	Apply  func(context.Context, gen.TimedScope, *d.Room) error
}

func (s Service) Update(c context.Context, actor identity.ActorContext, request UpdateRequest, op operation.Context) (d.Room, error) {
	if err := request.Family.validate(); err != nil {
		return d.Room{}, err
	}
	if request.Apply == nil {
		return d.Room{}, d.ErrInvalid
	}
	var room d.Room
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		observed, err := s.activeRoom(c, sc.Tx, actor, request.Family)
		if err != nil {
			return err
		}
		if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, append(observed.Members(), actor.PlayerID)); err != nil {
			return err
		}
		if request.Before != nil {
			if err := request.Before(c, sc.Tx, observed, at); err != nil {
				return err
			}
		}
		locked, err := s.lockObserved(c, sc.Tx, observed)
		if err != nil {
			return err
		}
		before := locked.StateVersion
		if err := request.Apply(c, sc, &locked); err != nil {
			return err
		}
		if err := s.saveAndWake(c, sc.Tx, locked, before, request.Family.Route); err != nil {
			return err
		}
		room = locked
		return nil
	})
	return room, err
}

// Leave removes the actor from their active room; owner or last leave closes it.
func (s Service) Leave(c context.Context, actor identity.ActorContext, family Family, op operation.Context) (LeaveResult, error) {
	if err := family.validate(); err != nil {
		return LeaveResult{}, err
	}
	var out LeaveResult
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		observed, found, err := s.Store.ReadPlayerRoomTx(c, sc.Tx, actor.PlayerID, family.Name, family.Slot)
		if err != nil {
			return err
		}
		if !found {
			return nil
		}
		if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, append(observed.Members(), actor.PlayerID)); err != nil {
			return err
		}
		locked, err := s.lockObserved(c, sc.Tx, observed)
		if err != nil {
			return err
		}
		before := locked.StateVersion
		if err := locked.Leave(actor.PlayerID, at); err != nil {
			return err
		}
		if err := s.saveAndWake(c, sc.Tx, locked, before, family.Route); err != nil {
			return err
		}
		out = LeaveResult{Room: locked, Closed: locked.Status == d.StatusClosed}
		return nil
	})
	return out, err
}

// Kick removes a seated player on the owner's order.
func (s Service) Kick(c context.Context, actor identity.ActorContext, family Family, target identity.PlayerID, op operation.Context) (d.Room, error) {
	if err := family.validate(); err != nil {
		return d.Room{}, err
	}
	if !target.Valid() {
		return d.Room{}, d.ErrInvalid
	}
	var room d.Room
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		observed, err := s.activeRoom(c, sc.Tx, actor, family)
		if err != nil {
			return err
		}
		if observed.Owner != actor.PlayerID {
			return d.ErrNotOwner
		}
		if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, append(observed.Members(), actor.PlayerID, target)); err != nil {
			return err
		}
		locked, err := s.lockObserved(c, sc.Tx, observed)
		if err != nil {
			return err
		}
		before := locked.StateVersion
		if err := locked.Kick(actor.PlayerID, target, at); err != nil {
			return err
		}
		if err := s.saveAndWake(c, sc.Tx, locked, before, family.Route); err != nil {
			return err
		}
		room = locked
		return nil
	})
	return room, err
}

func (s Service) SetReady(c context.Context, actor identity.ActorContext, family Family, ready bool, op operation.Context) (d.Room, error) {
	if err := family.validate(); err != nil {
		return d.Room{}, err
	}
	var room d.Room
	err := s.run(c, op, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(c, sc.Tx, actor, at); err != nil {
			return err
		}
		observed, err := s.activeRoom(c, sc.Tx, actor, family)
		if err != nil {
			return err
		}
		if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, append(observed.Members(), actor.PlayerID)); err != nil {
			return err
		}
		locked, err := s.lockObserved(c, sc.Tx, observed)
		if err != nil {
			return err
		}
		before := locked.StateVersion
		if err := locked.SetReady(actor.PlayerID, ready, at); err != nil {
			return err
		}
		if err := s.saveAndWake(c, sc.Tx, locked, before, family.Route); err != nil {
			return err
		}
		room = locked
		return nil
	})
	return room, err
}

func (s Service) activeRoom(c context.Context, t tx.Tx, actor identity.ActorContext, family Family) (d.Room, error) {
	room, found, err := s.Store.ReadPlayerRoomTx(c, t, actor.PlayerID, family.Name, family.Slot)
	if err != nil {
		return d.Room{}, err
	}
	if !found {
		return d.Room{}, ErrNotInRoom
	}
	return room, nil
}

// lockObserved locks the room after the unlocked read and retries through the
// abort budget when another command changed it first.
func (s Service) lockObserved(c context.Context, t tx.Tx, observed d.Room) (d.Room, error) {
	locked, found, err := s.Store.LockRoomTx(c, t, observed.ID)
	if err != nil {
		return d.Room{}, err
	}
	if !found {
		return d.Room{}, ErrNotFound
	}
	if roomDiffers(observed, locked) {
		return d.Room{}, tx.MarkDefiniteAbort(ErrConflict)
	}
	return locked, nil
}

func (s Service) saveAndWake(c context.Context, t tx.Tx, room d.Room, before int64, route string) error {
	if room.StateVersion == before {
		return nil
	}
	if err := s.Store.SaveRoomTx(c, t, room); err != nil {
		return err
	}
	return s.Store.WakeRoomTx(c, t, room.ID, route)
}
