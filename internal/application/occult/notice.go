package occult

import (
	"context"
	"strconv"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	domainroom "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"

	"gxb.local/backend/v2/internal/application/i5"
)

// PlayerBody is one player's share of a room push.
type PlayerBody struct {
	Player identity.PlayerID
	Body   map[string]any
}

// RoomNotice is the canonical room a wakeup projects: each seated member's
// ROOM_CHANGE, the departures and invites that are delivered once, the run's
// applied events and the members' map positions.
type RoomNotice struct {
	RoomID    int64
	Seated    []PlayerBody
	Removed   []PlayerBody
	Invites   []PlayerBody
	Events    []d.EventRecord
	Pushes    []RoomPush
	Positions map[identity.PlayerID]int64
}

// RoomPush is one co-op or fight-status push with the body each addressee gets.
type RoomPush struct {
	Sequence int64
	Function int64
	Bodies   []PlayerBody
}

// NoticeReader reads a room for the realtime push; it never writes.
type NoticeReader struct {
	Rooms     sharedroom.Store
	Content   Content
	Directory Directory
	Presence  Presence
	Scores    interface {
		ReadScoresTx(context.Context, tx.Queryer, identity.PlayerID) (d.Scores, error)
	}
	Tickets i5.OccultTicketPort
	Queryer tx.Queryer
}

func (r NoticeReader) ReadRoomNotice(c context.Context, reference string) (RoomNotice, bool, error) {
	roomID, err := strconv.ParseInt(reference, 10, 64)
	if err != nil || roomID <= 0 {
		return RoomNotice{}, false, d.ErrInvalid
	}
	room, found, err := r.Rooms.ReadRoomTx(c, r.Queryer, roomID)
	if err != nil || !found || room.Family != RoomFamily || room.Slot != RoomSlot {
		return RoomNotice{}, false, err
	}
	state, err := d.LoadRunState(room.Payload)
	if err != nil {
		return RoomNotice{}, false, d.ErrInvalid
	}
	revision, err := r.Content.ActiveRevision(c, r.Queryer)
	if err != nil {
		return RoomNotice{}, false, err
	}
	catalog, err := r.Content.OccultCatalogTx(c, r.Queryer, revision)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out := RoomNotice{RoomID: room.ID, Events: state.Events, Positions: map[identity.PlayerID]int64{}}
	view := &roomView{room: room, state: state, catalog: catalog, at: room.UpdatedAt}
	if room.Status == domainroom.StatusOpen {
		out.Seated, err = r.seatedBodies(c, view)
		if err != nil {
			return RoomNotice{}, false, err
		}
	}
	for _, member := range room.Members() {
		out.Positions[member] = state.StayPosition(int64(member))
	}
	out.Pushes, err = r.pushes(c, view, out.Seated)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out.Removed, err = r.removedBodies(c, view)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out.Invites, err = r.inviteBodies(c, view)
	if err != nil {
		return RoomNotice{}, false, err
	}
	return out, true, nil
}

func (r NoticeReader) seatedBodies(c context.Context, view *roomView) ([]PlayerBody, error) {
	var bodies []PlayerBody
	for _, member := range view.room.Members() {
		body, err := r.roomChange(c, member, view.catalog, view)
		if err != nil {
			return nil, err
		}
		bodies = append(bodies, PlayerBody{Player: member, Body: body})
	}
	return bodies, nil
}

// removedBodies are the room_id 0 changes of seats that are no longer seated. A
// player who now holds another Occult room is skipped: a stale removal must not
// close the room they sit in.
func (r NoticeReader) removedBodies(c context.Context, view *roomView) ([]PlayerBody, error) {
	var bodies []PlayerBody
	for _, seat := range view.room.Seats {
		if seat.Stage == domainroom.SeatSeated && view.room.Status == domainroom.StatusOpen {
			continue
		}
		current, held, err := r.Rooms.ReadPlayerRoomTx(c, r.Queryer, seat.Player, RoomFamily, RoomSlot)
		if err != nil {
			return nil, err
		}
		if held && current.ID != view.room.ID {
			continue
		}
		body, err := r.roomChange(c, seat.Player, view.catalog, nil)
		if err != nil {
			return nil, err
		}
		bodies = append(bodies, PlayerBody{Player: seat.Player, Body: body})
	}
	return bodies, nil
}

func (r NoticeReader) inviteBodies(c context.Context, view *roomView) ([]PlayerBody, error) {
	if view.room.Status != domainroom.StatusOpen || len(view.state.Invites) == 0 {
		return nil, nil
	}
	owner, found, err := r.Directory.ProfileTx(c, r.Queryer, view.room.Owner)
	if err != nil || !found {
		return nil, err
	}
	var bodies []PlayerBody
	for _, invitee := range view.state.Invites {
		bodies = append(bodies, PlayerBody{Player: identity.PlayerID(invitee), Body: inviteParams(view, owner)})
	}
	return bodies, nil
}

// inviteParams is the friend notice type 7 payload; room_id is added because the
// join request needs it.
// shortcut: force is 0 because the player directory carries no battle power.
func inviteParams(view *roomView, owner playerdirectory.Profile) map[string]any {
	return map[string]any{"room_id": view.room.ID, "chapter_id": view.state.ChapterID, "force": int64(0), "player_info": playerInfo(owner, false)}
}

func (r NoticeReader) roomChange(c context.Context, player identity.PlayerID, catalog d.Catalog, view *roomView) (map[string]any, error) {
	scores, err := r.Scores.ReadScoresTx(c, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	tickets, err := r.Tickets.OccultTicketsTx(c, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	body, err := Mode{Directory: r.Directory, Presence: r.Presence}.stateBody(c, r.Queryer, identity.ActorContext{PlayerID: player}, catalog, scores, tickets, view)
	if err != nil {
		return nil, err
	}
	body["function_type"] = int64(roomChangeFunction)
	return body, nil
}

// pushes turn the room's recorded team notices into per-member bodies read from
// the current room state. The seated members are the only addressees, so a
// player who left never receives a stale one.
func (r NoticeReader) pushes(c context.Context, view *roomView, seated []PlayerBody) ([]RoomPush, error) {
	if len(seated) == 0 {
		return nil, nil
	}
	reader := Mode{Directory: r.Directory}
	var pushes []RoomPush
	for _, record := range view.state.Notices {
		params, everyone, err := reader.pushParams(c, r.Queryer, view.state, record, seated[0].Body["hero_stat"])
		if err != nil {
			return nil, err
		}
		push := RoomPush{Sequence: record.Sequence, Function: record.Function}
		for _, member := range seated {
			if everyone || int64(member.Player) != record.Actor {
				push.Bodies = append(push.Bodies, PlayerBody{Player: member.Player, Body: params})
			}
		}
		pushes = append(pushes, push)
	}
	return pushes, nil
}

// pushParams is the params of one push and whether the acting member gets it too.
func (s Mode) pushParams(c context.Context, q tx.Queryer, state d.RunState, record d.NoticeRecord, heroStat any) (map[string]any, bool, error) {
	name, err := s.playerName(c, q, record.Actor)
	if err != nil {
		return nil, false, err
	}
	info, err := s.subCampaignInfo(c, q, state)
	if err != nil {
		return nil, false, err
	}
	switch record.Function {
	case d.NoticeTeamInvite:
		return map[string]any{"campaign_id": record.CampaignID, "sub_id": record.SubID, "start_player": record.Actor, "start_player_name": name}, false, nil
	case d.NoticeTeamAccept:
		return map[string]any{"sub_campaign_info": info, "player_name": name}, true, nil
	case d.NoticeTeamQuit:
		return map[string]any{"player_name": name}, true, nil
	case d.NoticeTeamSelect, d.NoticeTeamPrepare:
		formation := map[string]any{}
		if state.Team != nil {
			formation = teamFightInfo(*state.Team, record.Actor)
		}
		return map[string]any{"player_id": record.Actor, "team_fight_info": formation}, true, nil
	case d.NoticeTeamFight:
		return map[string]any{"report_key": record.ReportKey, "hero_stat": heroStat}, false, nil
	case d.NoticeSingleFight:
		return map[string]any{"hero_stat": heroStat}, false, nil
	}
	return map[string]any{}, false, nil
}
