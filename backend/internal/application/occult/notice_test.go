package occult

import (
	"context"
	"reflect"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	domainroom "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type noticeRoomStore struct {
	room domainroom.Room
}

func (s noticeRoomStore) ReadRoomTx(context.Context, tx.Queryer, int64) (domainroom.Room, bool, error) {
	return s.room, true, nil
}

func (s noticeRoomStore) ReadPlayerRoomTx(context.Context, tx.Queryer, identity.PlayerID, string, int64) (domainroom.Room, bool, error) {
	return domainroom.Room{}, false, nil
}

func (s noticeRoomStore) LockRoomTx(context.Context, tx.Tx, int64) (domainroom.Room, bool, error) {
	return domainroom.Room{}, false, nil
}

func (s noticeRoomStore) OpenRoomTx(context.Context, tx.Tx, domainroom.Room) (domainroom.Room, error) {
	return domainroom.Room{}, nil
}

func (s noticeRoomStore) SaveRoomTx(context.Context, tx.Tx, domainroom.Room) error { return nil }

func (s noticeRoomStore) ExpiredRoomIDsTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time, int) ([]int64, error) {
	return nil, nil
}

func (s noticeRoomStore) WakeRoomTx(context.Context, tx.Tx, int64, string) error { return nil }

type noticeContent struct {
	catalog d.Catalog
}

func (c noticeContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "rev", nil
}

func (c noticeContent) OccultCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return c.catalog, nil
}

type noticePresence struct{}

func (noticePresence) OnlineAt(context.Context, []identity.PlayerID, time.Time) (map[identity.PlayerID]bool, error) {
	return map[identity.PlayerID]bool{}, nil
}

func (noticePresence) OnlineAtTx(context.Context, tx.Queryer, []identity.PlayerID, time.Time) (map[identity.PlayerID]bool, error) {
	return map[identity.PlayerID]bool{}, nil
}

type noticeScores struct{}

func (noticeScores) ReadScoresTx(context.Context, tx.Queryer, identity.PlayerID) (d.Scores, error) {
	return d.Scores{}, nil
}

type noticeTickets struct{}

func (noticeTickets) OccultTicketsTx(context.Context, tx.Queryer, identity.PlayerID) (i5.OccultTickets, error) {
	return i5.OccultTickets{}, nil
}

func (noticeTickets) DebitOccultTicketTx(context.Context, tx.Tx, identity.PlayerID, operation.Context) (i5.OccultTickets, error) {
	return i5.OccultTickets{}, nil
}

func noticeReaderFor(room domainroom.Room, catalog d.Catalog) NoticeReader {
	return NoticeReader{Rooms: noticeRoomStore{room: room}, Content: noticeContent{catalog: catalog},
		Directory: fakeDirectory{}, Presence: noticePresence{}, Scores: noticeScores{}, Tickets: noticeTickets{}}
}

func noticeRoom(t *testing.T, state *d.RunState, members ...identity.PlayerID) domainroom.Room {
	t.Helper()
	at := time.Unix(1700000000, 0).UTC()
	payload, err := state.Encode()
	if err != nil {
		t.Fatal(err)
	}
	room, err := domainroom.NewRoom(1, RoomFamily, RoomSlot, int64(len(members)), members[0], at.Add(time.Hour), payload, at)
	if err != nil {
		t.Fatal(err)
	}
	for _, member := range members[1:] {
		if err = room.Join(member, at); err != nil {
			t.Fatal(err)
		}
	}
	room.ID = 7
	return room
}

func noticePushes(view RoomNotice, function int64) []RoomPush {
	var out []RoomPush
	for _, push := range view.Pushes {
		if push.Function == function {
			out = append(out, push)
		}
	}
	return out
}

// TestTeamInviteReachesTheStarterToo is A-178: the stock model only stores
// teamInviteInfos in the TEAM_INVITE handler, so the starter's own invite is
// the initializer the team-selection window reads; its own-popup guard hides
// the confirm dialog.
func TestTeamInviteReachesTheStarterToo(t *testing.T) {
	catalog := loadCatalog(t)
	state := d.NewRun(1, d.MultiCampaignType)
	state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamInvite, Actor: 1, CampaignID: 10002, SubID: 1})
	room := noticeRoom(t, &state, 1, 2, 3)
	view, found, err := noticeReaderFor(room, catalog).ReadRoomNotice(context.Background(), strconv.FormatInt(room.ID, 10))
	if err != nil || !found {
		t.Fatalf("room notice %v %v", found, err)
	}
	pushes := noticePushes(view, d.NoticeTeamInvite)
	if len(pushes) != 1 || len(pushes[0].Bodies) != 3 {
		t.Fatalf("invite push %+v", pushes)
	}
	for index, member := range pushes[0].Bodies {
		if member.Player != identity.PlayerID(index+1) || member.Body["start_player"] != int64(1) {
			t.Fatalf("starter invite body %+v", pushes[0].Bodies)
		}
	}
}

// TestClosingWriteDeliversTheFinalReportToEveryTeammate is A-179: the clear
// closes the room in the same write that records TEAM_FIGHT, so the projection
// must read the last members and only the closing write's notices.
func TestClosingWriteDeliversTheFinalReportToEveryTeammate(t *testing.T) {
	catalog := loadCatalog(t)
	state := d.NewRun(1, d.MultiCampaignType)
	state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamInvite, Actor: 1, CampaignID: 10002, SubID: 1})
	state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: 1, CampaignID: 10002})
	state.ClosingNoticeSequence = 3
	state.ClearSettled = true
	state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamFight, Actor: 1, CampaignID: 10013, SubID: 1, ReportKey: "attempt-key"})
	state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: 1, CampaignID: 10013})
	room := noticeRoom(t, &state, 1, 2, 3)
	room.Close(room.UpdatedAt)
	view, found, err := noticeReaderFor(room, catalog).ReadRoomNotice(context.Background(), strconv.FormatInt(room.ID, 10))
	if err != nil || !found {
		t.Fatalf("room notice %v %v", found, err)
	}
	if !view.Closed || len(view.Seated) != 0 || len(view.Members) != 3 {
		t.Fatalf("closed projection %+v", view)
	}
	teamFight := noticePushes(view, d.NoticeTeamFight)
	if len(teamFight) != 1 || len(teamFight[0].Bodies) != 2 {
		t.Fatalf("team fight pushes %+v", teamFight)
	}
	for _, member := range teamFight[0].Bodies {
		if member.Player == 1 {
			t.Fatal("the settling member replays from its own 2377 reply")
		}
		if member.Body["report_key"] != "attempt-key" {
			t.Fatalf("teammate %d report %+v", member.Player, member.Body)
		}
	}
	if old := noticePushes(view, d.NoticeTeamInvite); len(old) != 0 {
		t.Fatalf("a pre-closing notice was replayed %+v", old)
	}
}

// TestFightStatusCarriesTheReadRoomProjection is A-180: the stock handler
// repaints from the cached map, which only the 2362 projection replaces.
func TestFightStatusCarriesTheReadRoomProjection(t *testing.T) {
	catalog := loadCatalog(t)
	at := time.Unix(1700000000, 0).UTC()
	state := d.NewRun(1, d.MultiCampaignType)
	if err := state.Start(at.Unix()); err != nil {
		t.Fatal(err)
	}
	if err := state.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: 1, CampaignID: 10002})
	room := noticeRoom(t, &state, 1, 2, 3)
	view, found, err := noticeReaderFor(room, catalog).ReadRoomNotice(context.Background(), strconv.FormatInt(room.ID, 10))
	if err != nil || !found {
		t.Fatalf("room notice %v %v", found, err)
	}
	status := noticePushes(view, d.NoticeFightStatus)
	if len(status) != 1 || len(status[0].Bodies) != 2 {
		t.Fatalf("status push %+v", status)
	}
	projection, err := Mode{Directory: fakeDirectory{}, Presence: noticePresence{}}.stateBody(context.Background(), nil,
		identity.ActorContext{PlayerID: 2}, catalog, d.Scores{}, i5.OccultTickets{},
		&roomView{room: room, state: state, catalog: catalog, at: room.UpdatedAt})
	if err != nil {
		t.Fatal(err)
	}
	for _, member := range status[0].Bodies {
		if !reflect.DeepEqual(member.Body["open_campaigns"], projection["open_campaigns"]) {
			t.Fatalf("member %d map %+v, 2362 %+v", member.Player, member.Body["open_campaigns"], projection["open_campaigns"])
		}
		if member.Body["progress"] != projection["progress"] || member.Body["base_info"] == nil {
			t.Fatalf("member %d projection %+v", member.Player, member.Body)
		}
	}
}
