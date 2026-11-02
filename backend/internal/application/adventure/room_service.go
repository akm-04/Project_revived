package adventure

import (
	"context"
	"fmt"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	RoomFamily = "adventure"
	// RoomNoticeRoute wakes the realtime projection that pushes notice 32.
	RoomNoticeRoute = "adventure.room.notice.v1"
	// DefenseSlot and IllusionSlot are the two Adventure room slots (D368).
	DefenseSlot  int64 = 1
	IllusionSlot int64 = 2
)

func DefenseFamily() sr.Family {
	return sr.Family{Name: RoomFamily, Slot: DefenseSlot, Route: RoomNoticeRoute}
}

func IllusionFamily() sr.Family {
	return sr.Family{Name: RoomFamily, Slot: IllusionSlot, Route: RoomNoticeRoute}
}

func (s Mode) roomState(room sharedroom.Room) (d.RoomState, error) {
	return d.LoadRoomState(room.Payload)
}

func (s Mode) restoreRoom(sc gen.TimedScope, room *sharedroom.Room, state d.RoomState) error {
	payload, err := state.Encode()
	if err != nil {
		return err
	}
	return room.SetPayload(payload, sc.Operation.DecisionAt())
}

func (s Mode) mutateRoom(sc gen.TimedScope, room *sharedroom.Room, mutate func(*d.RoomState) error) error {
	state, err := s.roomState(*room)
	if err != nil {
		return err
	}
	if err = mutate(&state); err != nil {
		return err
	}
	return s.restoreRoom(sc, room, state)
}

// admissionBefore runs the function 68 gate inside a room transaction.
func (s Mode) admissionBefore(a identity.ActorContext, op operation.Context) func(context.Context, tx.Tx, sharedroom.Room, time.Time) error {
	return func(c context.Context, t tx.Tx, _ sharedroom.Room, at time.Time) error {
		catalog, err := s.adventureCatalog(c, t, op)
		if err != nil {
			return err
		}
		return s.admit(c, t, a, catalog, at)
	}
}

// requireAdmission gates commands whose shared-room helper offers no callback.
func (s Mode) requireAdmission(c context.Context, a identity.ActorContext, op operation.Context) error {
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return err
	}
	catalog, err := s.adventureCatalog(c, s.Fresh, op)
	if err != nil {
		return err
	}
	return s.admit(c, s.Fresh, a, catalog, at)
}

func (s Mode) activeRoom(c context.Context, q tx.Queryer, player identity.PlayerID, family sr.Family) (sharedroom.Room, bool, error) {
	return s.RoomStore.ReadPlayerRoomTx(c, q, player, family.Name, family.Slot)
}

// admitCoop enforces the Fantasy function 43 at level 65 for 10006 co-op.
func (s Mode) admitCoop(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time) error {
	gate, open, err := s.Functions.ReadFunctionEligibilityTx(c, q, a.PlayerID, d.FantasyFunctionID)
	if err != nil {
		return err
	}
	if !open || at.Before(gate.EligibleAt) {
		return fmt.Errorf("%w: function %d is not open", d.ErrRefused, d.FantasyFunctionID)
	}
	profile, found, err := s.Directory.ProfileTx(c, q, a.PlayerID)
	if err != nil {
		return err
	}
	if !found || profile.Level < d.FantasyOpenLevel {
		return fmt.Errorf("%w: fantasy opens at level %d", d.ErrRefused, d.FantasyOpenLevel)
	}
	return nil
}

func (s Mode) memberInfo(c context.Context, q tx.Queryer, player identity.PlayerID) (map[string]any, error) {
	profile, found, err := s.Directory.ProfileTx(c, q, player)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrRefused
	}
	return map[string]any{"player_id": int64(profile.PlayerID), "player_name": profile.Name, "avatar_id": profile.AvatarID,
		"avatar_frame_id": profile.AvatarFrameID, "lev": profile.Level}, nil
}

func (s Mode) roomMembers(c context.Context, q tx.Queryer, room sharedroom.Room) ([]int64, []any, error) {
	members := room.Members()
	ids := make([]int64, 0, len(members))
	infos := make([]any, 0, len(members))
	for _, member := range members {
		info, err := s.memberInfo(c, q, member)
		if err != nil {
			return nil, nil, err
		}
		ids = append(ids, int64(member))
		infos = append(infos, info)
	}
	return ids, infos, nil
}

func abs64(value int64) int64 {
	if value < 0 {
		return -value
	}
	return value
}
