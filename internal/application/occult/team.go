package occult

import (
	"context"
	"fmt"
	"math"
	"slices"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/publicstats"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const inviteForceHeroes = 15

// CreateTeam answers 2366 with campaign_type 1: an unstarted three-seat room.
// No ticket is spent until the owner starts the challenge. A repeated create of
// the same chapter answers the room already held.
func (s Mode) CreateTeam(c context.Context, a identity.ActorContext, chapterID int64, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	if len(loaded.catalog.RoomCampaigns(chapterID, d.MultiCampaignType)) == 0 {
		return nil, d.ErrInvalid
	}
	if loaded.view != nil {
		return s.heldRoom(c, a, loaded, chapterID, d.MultiCampaignType)
	}
	op, err = s.pin(c, op)
	if err != nil {
		return nil, err
	}
	payload, err := d.NewRun(chapterID, d.MultiCampaignType).Encode()
	if err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Leave(c, a, RoomFamilyRef(), op); err != nil {
		return nil, err
	}
	// shortcut: the source gives no waiting window, so an unstarted room lives as
	// long as a started one; starting extends the lease to start_time + 3000 s.
	if _, err = s.Rooms.Open(c, a, sr.OpenRequest{Family: RoomFamilyRef(), Capacity: loaded.catalog.RoomCapacity, Lease: time.Duration(loaded.catalog.RoomSeconds) * time.Second, Payload: payload}, op); err != nil {
		return nil, err
	}
	return s.roomChange(c, a, op)
}

// JoinRoom answers 2367. Capacity, a kick and expiry are the room core's; the
// function gate, the level band against the owner and the re-entry wait are
// enforced here before the seat is taken.
func (s Mode) JoinRoom(c context.Context, a identity.ActorContext, roomID int64, op operation.Context) (map[string]any, error) {
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	if roomID <= 0 {
		return nil, d.ErrInvalid
	}
	room, found, err := s.RoomStore.ReadRoomTx(c, s.Fresh, roomID)
	if err != nil {
		return nil, err
	}
	if !found || room.Family != RoomFamily || room.Slot != RoomSlot || room.Status != sharedroom.StatusOpen {
		return nil, fmt.Errorf("%w: room unavailable", d.ErrRefused)
	}
	state, err := d.LoadRunState(room.Payload)
	if err != nil {
		return nil, err
	}
	at := loaded.at.Unix()
	if state.CampaignType != d.MultiCampaignType || state.RoomExpired(at) || !state.MayJoin(int64(a.PlayerID), at) {
		return nil, fmt.Errorf("%w: room cannot be joined", d.ErrRefused)
	}
	if err = s.requireBand(c, s.Fresh, loaded.catalog, room.Owner, a.PlayerID); err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Join(c, a, RoomFamilyRef(), roomID, op); err != nil {
		return nil, err
	}
	return s.roomChange(c, a, op)
}

// requireBand refuses a player outside the room's level band or below the gate.
func (s Mode) requireBand(c context.Context, q tx.Queryer, catalog d.Catalog, owner, candidate identity.PlayerID) error {
	ownerProfile, ownerFound, err := s.Directory.ProfileTx(c, q, owner)
	if err != nil {
		return err
	}
	candidateProfile, candidateFound, err := s.Directory.ProfileTx(c, q, candidate)
	if err != nil {
		return err
	}
	if !ownerFound || !candidateFound || candidateProfile.Level < catalog.OpenAcademyLevel || !d.WithinLevelBand(ownerProfile.Level, candidateProfile.Level, catalog.LevelBand) {
		return fmt.Errorf("%w: level band", d.ErrRefused)
	}
	return nil
}

// Invite answers 2369: the owner records an invitee of the room's band. The
// room wakeup delivers the one-shot invite notice.
func (s Mode) Invite(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !target.Valid() || target == a.PlayerID {
		return nil, d.ErrInvalid
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	inviteRoomID, chapterID, force := int64(0), int64(0), int64(0)
	_, err = s.updateRoom(c, a, op, false, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		if view.room.Owner != a.PlayerID || view.state.CampaignType != d.MultiCampaignType || view.state.Started() {
			return nil, fmt.Errorf("%w: only the owner invites to an unstarted team room", d.ErrRefused)
		}
		if err := s.requireBand(c, sc.Tx, view.catalog, a.PlayerID, target); err != nil {
			return nil, err
		}
		view.state.Invite(int64(target))
		inviteRoomID, chapterID = view.room.ID, view.state.ChapterID
		force, err = s.bestForce(c, sc, a.PlayerID, view.at)
		return nil, err
	})
	if err != nil {
		return nil, err
	}
	if s.Invites != nil {
		invite := socialinbox.RoomInvite{Recipient: target, NoticeType: socialinbox.RoomInviteOccultNoticeType, RoomID: inviteRoomID, ChapterID: chapterID, Force: force}
		if err := s.Invites.Materialize(c, a, invite, op); err != nil {
			return nil, err
		}
	}
	return map[string]any{}, nil
}

// bestForce is the inviter's "best 15 AP" the client shows on the invite row
// (CREATS_TIPS_13). A power change makes a new row, because force is part of the
// notice source; the old row ages out with the retention window.
func (s Mode) bestForce(c context.Context, sc gen.TimedScope, player identity.PlayerID, at time.Time) (int64, error) {
	roster, err := s.rosterRows(c, sc.Tx, s.Heroes, player, at, "49", "heros")
	if err != nil {
		return 0, err
	}
	revision, err := s.Content.ActiveRevision(c, sc.Tx)
	if err != nil {
		return 0, err
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return 0, err
	}
	forces := make([]int64, 0, len(roster))
	for key := range roster {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			return 0, err
		}
		result, err := s.Stats.HeroTx(c, scope, character.HeroRef{PlayerID: player, PartnerID: id}, publicstats.View{Kind: publicstats.Self, Viewer: player})
		if err != nil {
			return 0, err
		}
		forces = append(forces, int64(math.Round(result.Stats.Force)))
	}
	slices.Sort(forces)
	total := int64(0)
	for _, force := range forces[max(0, len(forces)-inviteForceHeroes):] {
		total += force
	}
	return total, nil
}

// Kick answers 2370: the owner removes a member for the life of the room and the
// removed member's held stage is freed.
func (s Mode) Kick(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Kick(c, a, RoomFamilyRef(), target, op); err != nil {
		return nil, err
	}
	_, err = s.updateRoom(c, a, op, true, func(_ context.Context, _ gen.TimedScope, view *roomView) (map[string]any, error) {
		view.state.Release(int64(target))
		return nil, nil
	})
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// StartChallenge answers 2363. The owner starts a full room: every member pays
// one ticket in one transaction, so one short member refuses the start for all.
// Lock order: fence 315, roots, player rows 605 ascending, room 607, then the
// I5 ticket rows ascending.
func (s Mode) StartChallenge(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var scores d.Scores
	var body map[string]any
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(),
		Before: func(c context.Context, t tx.Tx, room sharedroom.Room, at time.Time) error {
			catalog, err := s.readCatalog(c, t, op)
			if err != nil {
				return err
			}
			members, err := playerroot.CanonicalPlayerIDs(room.Members())
			if err != nil {
				return err
			}
			for _, member := range members {
				if err = s.admit(c, t, identity.ActorContext{PlayerID: member}, catalog, at); err != nil {
					return err
				}
				memberScores, err := s.Store.LockPlayerTx(c, t, int64(a.LogicalServerID), member, at)
				if err != nil {
					return err
				}
				if member == a.PlayerID {
					scores = memberScores
				}
			}
			return nil
		},
		Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
			var err error
			body, err = s.startTeam(c, sc, a, room, scores)
			return err
		}}, op)
	return body, err
}

func (s Mode) startTeam(c context.Context, sc gen.TimedScope, a identity.ActorContext, room *sharedroom.Room, scores d.Scores) (map[string]any, error) {
	catalog, err := s.readCatalog(c, sc.Tx, sc.Operation.Operation())
	if err != nil {
		return nil, err
	}
	state, err := d.LoadRunState(room.Payload)
	if err != nil {
		return nil, err
	}
	members := room.Members()
	full := int64(len(members)) == room.Capacity
	if room.Owner != a.PlayerID || state.CampaignType != d.MultiCampaignType || !full {
		return nil, fmt.Errorf("%w: only the owner starts a full team room", d.ErrRefused)
	}
	at := sc.Operation.DecisionAt()
	view := &roomView{room: *room, state: state, catalog: catalog, scores: scores, at: at}
	if err = view.state.Start(at.Unix()); err != nil {
		return nil, err
	}
	if err = view.state.BindRoom(catalog); err != nil {
		return nil, err
	}
	ordered, err := playerroot.CanonicalPlayerIDs(members)
	if err != nil {
		return nil, err
	}
	var ownerTickets i5.OccultTickets
	for _, member := range ordered {
		tickets, err := s.Tickets.DebitOccultTicketTx(c, sc.Tx, member, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		if member == a.PlayerID {
			ownerTickets = tickets
		}
		if err = view.state.Seat(catalog, int64(member)); err != nil {
			return nil, err
		}
		if err = s.freezeFragment(c, sc, identity.ActorContext{PlayerID: member}, view); err != nil {
			return nil, err
		}
	}
	if err = room.ExtendLease(at.Add(time.Duration(catalog.RoomSeconds)*time.Second), at); err != nil {
		return nil, err
	}
	if err = s.Store.InsertRunTx(c, sc.Tx, room.ID, int64(room.LogicalServerID), state.ChapterID, state.CampaignType, at); err != nil {
		return nil, err
	}
	encoded, err := view.state.Encode()
	if err != nil {
		return nil, err
	}
	if err = room.SetPayload(encoded, at); err != nil {
		return nil, err
	}
	reply, err := s.stateBody(c, sc.Tx, a, catalog, scores, ownerTickets, view)
	if err != nil {
		return nil, err
	}
	reply["function_type"] = int64(roomChangeFunction)
	piggyback(c, reply)
	return reply, nil
}
