package occult

import (
	"context"
	"fmt"
	"slices"
	"strconv"

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
// ROOM_CHANGE, the departures that are delivered once, the run's applied events
// and the members' map positions.
type RoomNotice struct {
	RoomID int64
	// Signature changes only with the room's shape (members, start, type); a
	// fight-only wakeup keeps it, and the projection does not re-send ROOM_CHANGE.
	Signature string
	Seated    []PlayerBody
	// Members are the push addressees: the seated members while the room is
	// open, the last members once it closed, so the closing write's notices
	// still reach them. Seated stays empty for a closed room: its ROOM_CHANGE
	// is the removal.
	Members []PlayerBody
	// Closed marks a room whose run settled and ended; only the notices of the
	// closing write are projected.
	Closed    bool
	Removed   []PlayerBody
	Events    []d.EventRecord
	Pushes    []RoomPush
	Positions map[identity.PlayerID]int64
	Chats     []domainroom.ChatMessage
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
	out := RoomNotice{RoomID: room.ID, Signature: roomSignature(room, state), Events: state.Events, Positions: map[identity.PlayerID]int64{}, Chats: state.Chats}
	view := &roomView{room: room, state: state, catalog: catalog, at: room.UpdatedAt}
	if room.Status == domainroom.StatusOpen {
		out.Seated, err = r.seatedBodies(c, view)
		if err != nil {
			return RoomNotice{}, false, err
		}
		out.Members = out.Seated
	} else {
		out.Closed = true
		for _, seat := range room.Seats {
			if seat.Stage == domainroom.SeatClosed {
				out.Members = append(out.Members, PlayerBody{Player: seat.Player})
			}
		}
	}
	for _, member := range room.Members() {
		out.Positions[member] = state.StayPosition(int64(member))
	}
	// Only a clear-settled close has notices of its own; a room closed by a
	// departure or expiry must not replay its old notice tail.
	recipients := out.Members
	if out.Closed && state.ClosingNoticeSequence == 0 {
		recipients = nil
	}
	out.Pushes, err = r.pushes(c, view, recipients)
	if err != nil {
		return RoomNotice{}, false, err
	}
	out.Removed, err = r.removedBodies(c, view)
	if err != nil {
		return RoomNotice{}, false, err
	}
	return out, true, nil
}

// roomSignature is what a ROOM_CHANGE push may announce; stage HP, notices and
// hero status deliberately stay out of it.
func roomSignature(room domainroom.Room, state d.RunState) string {
	members := slices.Clone(room.Members())
	slices.Sort(members)
	return fmt.Sprintf("%v|%d|%d|%d|%d|%s", members, state.StartedAt, state.ChapterID, state.CampaignType, room.Capacity, room.Status)
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

// recipientBody is the 2362 projection one room addressee reads: base info,
// tickets, the room, the map and stage progress, and that player's dispatch.
func (r NoticeReader) recipientBody(c context.Context, view *roomView, player identity.PlayerID) (map[string]any, error) {
	scores, err := r.Scores.ReadScoresTx(c, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	tickets, err := r.Tickets.OccultTicketsTx(c, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	return Mode{Directory: r.Directory, Presence: r.Presence}.stateBody(c, r.Queryer, identity.ActorContext{PlayerID: player}, view.catalog, scores, tickets, view)
}

func (r NoticeReader) roomChange(c context.Context, player identity.PlayerID, catalog d.Catalog, view *roomView) (map[string]any, error) {
	var body map[string]any
	if view == nil {
		scores, err := r.Scores.ReadScoresTx(c, r.Queryer, player)
		if err != nil {
			return nil, err
		}
		tickets, err := r.Tickets.OccultTicketsTx(c, r.Queryer, player)
		if err != nil {
			return nil, err
		}
		var errState error
		body, errState = Mode{Directory: r.Directory, Presence: r.Presence}.stateBody(c, r.Queryer, identity.ActorContext{PlayerID: player}, catalog, scores, tickets, nil)
		if errState != nil {
			return nil, errState
		}
	} else {
		var errBody error
		body, errBody = r.recipientBody(c, view, player)
		if errBody != nil {
			return nil, errBody
		}
	}
	body["function_type"] = int64(roomChangeFunction)
	return body, nil
}

// pushes turn the room's recorded notices into per-member bodies. While the
// room is open the addressees are its seated members; once the clear-settling
// command closed it, they are its last members and only that write's notices
// are projected, so the final report still reaches every teammate.
func (r NoticeReader) pushes(c context.Context, view *roomView, recipients []PlayerBody) ([]RoomPush, error) {
	if len(recipients) == 0 {
		return nil, nil
	}
	closed := view.room.Status != domainroom.StatusOpen
	reader := Mode{Directory: r.Directory}
	var heroStat any
	if recipients[0].Body != nil {
		heroStat = recipients[0].Body["hero_stat"]
	}
	projections := map[identity.PlayerID]map[string]any{}
	projection := func(player identity.PlayerID) (map[string]any, error) {
		if body, known := projections[player]; known {
			return body, nil
		}
		body, err := r.recipientBody(c, view, player)
		if err != nil {
			return nil, err
		}
		projections[player] = body
		return body, nil
	}
	var pushes []RoomPush
	for _, record := range view.state.Notices {
		if closed && view.state.ClosingNoticeSequence > 0 && record.Sequence < view.state.ClosingNoticeSequence {
			continue
		}
		params, everyone, err := reader.pushParams(c, r.Queryer, view.state, record, heroStat)
		if err != nil {
			return nil, err
		}
		push := RoomPush{Sequence: record.Sequence, Function: record.Function}
		for _, member := range recipients {
			if !everyone && int64(member.Player) == record.Actor {
				continue
			}
			body := params
			switch {
			case record.Function == d.NoticeTeamFight:
				body = map[string]any{"report_key": record.ReportKey}
				if !closed {
					full, err := projection(member.Player)
					if err != nil {
						return nil, err
					}
					body["hero_stat"] = full["hero_stat"]
				}
			case record.Function == d.NoticeFightStatus && !closed:
				body, err = projection(member.Player)
				if err != nil {
					return nil, err
				}
			case record.Function == d.NoticeFightStatus:
				body = map[string]any{}
			}
			push.Bodies = append(push.Bodies, PlayerBody{Player: member.Player, Body: body})
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
		// The starter receives it too: the stock TEAM_INVITE handler stores
		// teamInviteInfos, which the team-selection window's ctor needs, while
		// its own-popup guard keeps the confirm dialog hidden.
		return map[string]any{"campaign_id": record.CampaignID, "sub_id": record.SubID, "start_player": record.Actor, "start_player_name": name}, true, nil
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
		params := map[string]any{"report_key": record.ReportKey}
		if heroStat != nil {
			params["hero_stat"] = heroStat
		}
		return params, false, nil
	case d.NoticeSingleFight:
		params := map[string]any{}
		if heroStat != nil {
			params["hero_stat"] = heroStat
		}
		return params, false, nil
	}
	return map[string]any{}, false, nil
}
