//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/channelchatread"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	gen "gxb.local/backend/v2/internal/application/generation"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"net"
	"testing"
)

func cardOwners() cc.Owners {
	return cc.Owners{
		Illusion:          channelchatread.IllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
		Occult:            channelchatread.OccultRoomReader{Store: sharedroomstore.Store{}},
		AdventureIllusion: channelchatread.AdventureIllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
		Defense:           channelchatread.DefenseRoomReader{Store: sharedroomstore.Store{}},
	}
}

func openIllusionRoom(t *testing.T, f *fixture, owner identity.PlayerID) int64 {
	t.Helper()
	roomID := f.number(`INSERT INTO shared_rooms(logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload,created_at,updated_at)
VALUES($1,'illusion',1,$2,'OPEN',3,clock_timestamp()+interval '1 hour',1,1,$3::jsonb,clock_timestamp(),clock_timestamp()) RETURNING room_id`,
		int64(owner)/100000, int64(owner), `{"paradise_id":100001,"master_level":66}`)
	f.sql(`INSERT INTO shared_room_seats(room_id,seat_index,player_id,family,slot,stage,ready,joined_at,updated_at)
VALUES($1,0,$2,'illusion',1,'SEATED',false,clock_timestamp(),clock_timestamp())`, roomID, int64(owner))
	return roomID
}

func illusionCard(roomID int64) string {
	return fmt.Sprintf(`{"room_id":%d,"type":3,"boss_name":"forged","room_lev":1}`, roomID)
}

func readCard(t *testing.T, c net.Conn, kind float64) map[string]any {
	t.Helper()
	frame := frameRead(t, c, mids.MIDChatMessage)
	m, e := frame.Params.(*amf3.Object).StrictMap()
	if e != nil || m["type"] != kind {
		t.Fatal(m, e)
	}
	text, ok := m["message"].(string)
	if !ok {
		t.Fatal(m)
	}
	var body map[string]any
	if e = json.Unmarshal([]byte(text), &body); e != nil {
		t.Fatal(e)
	}
	return body
}

func joinCardRoom(t *testing.T, f *fixture, player identity.PlayerID, roomID int64, family appsharedroom.Family) {
	t.Helper()
	actor, _ := f.live(player)
	timed := gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: f.p}}, Runner: tx.Runner{DB: f.p}}
	rooms := appsharedroom.Service{Timed: timed, Fresh: f.p, Store: sharedroomstore.Store{}, Fence: i5store.Store{Queryer: f.p}, Players: i4store.PlayerRootLocker{}}
	p, e := policy.NewSet()
	if e != nil {
		t.Fatal(e)
	}
	op, e := (operation.Factory{Clock: clock.System{}}).New(p)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = rooms.Join(ctx, actor, appsharedroom.JoinRequest{Family: family, RoomID: roomID}, op); e != nil {
		t.Fatal(e)
	}
}

var illusionFamily = appsharedroom.Family{Name: "illusion", Slot: 1, Route: "illusion.room.notice.v1"}
var defenseFamily = appsharedroom.Family{Name: "adventure", Slot: 1, Route: "adventure.room.notice.v1"}

func TestChatH2IllusionCardGuild(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002, 100003)
	f.chatGuild(1000001, 100001, 100002)
	f.chatGuild(1000002, 100003)
	roomID := openIllusionRoom(t, f, 100001)
	h := chatHarness(t, f, channelHarnessOptions{owners: cardOwners()})
	a, _, _ := h.login(100001, dr.Guild, 1000001)
	b, _, _ := h.login(100002, dr.Guild, 1000001)
	c, _, _ := h.login(100003, dr.Guild, 1000002)
	sendChat(t, a, illusionCard(roomID), 2, amf3.Property{Name: "type", Value: 3.0})
	body := readCard(t, b, 3)
	if body["room_id"] != float64(roomID) || body["room_lev"] != float64(66) || body["boss_name"] == "" {
		t.Fatal(body)
	}
	noChat(t, c)
	joinCardRoom(t, f, 100002, roomID, illusionFamily)
	if seated := f.number(`SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=100002 AND stage='SEATED'`, roomID); seated != 1 {
		t.Fatal("guild card room reference did not join")
	}
	if h.report().Outcomes[stockruntime.ChatTransportWriteRecorded] != 2 {
		t.Fatal("guild card recipients")
	}
}

func TestChatH2IllusionCardService(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002, 100003)
	roomID := openIllusionRoom(t, f, 100001)
	h := chatHarness(t, f, channelHarnessOptions{owners: cardOwners()})
	a, _, _ := h.login(100001, dr.Service, 99999)
	b, _, _ := h.login(100002, dr.Service, 99999)
	c, _, _ := h.login(100003, dr.Service, 99999)
	sendChat(t, a, illusionCard(roomID), 4, amf3.Property{Name: "type", Value: 3.0})
	for _, recipient := range []net.Conn{b, c} {
		body := readCard(t, recipient, 3)
		if body["room_id"] != float64(roomID) || body["room_lev"] != float64(66) || body["boss_name"] == "" {
			t.Fatal(body)
		}
	}
	joinCardRoom(t, f, 100002, roomID, illusionFamily)
	if seated := f.number(`SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=100002 AND stage='SEATED'`, roomID); seated != 1 {
		t.Fatal("service card room reference did not join")
	}
	if h.report().Outcomes[stockruntime.ChatTransportWriteRecorded] != 3 {
		t.Fatal("service card recipients")
	}
}

func TestChatH2DefenseCardService(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	roomID := f.number(`INSERT INTO shared_rooms(logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload,created_at,updated_at)
VALUES(1,'adventure',1,100001,'OPEN',6,clock_timestamp()+interval '1 hour',1,1,'{"room_type":2,"master_level":77,"phase":"OPEN"}'::jsonb,clock_timestamp(),clock_timestamp()) RETURNING room_id`)
	f.sql(`INSERT INTO shared_room_seats(room_id,seat_index,player_id,family,slot,stage,ready,joined_at,updated_at)
VALUES($1,0,100001,'adventure',1,'SEATED',false,clock_timestamp(),clock_timestamp())`, roomID)
	h := chatHarness(t, f, channelHarnessOptions{owners: cardOwners()})
	a, _, _ := h.login(100001, dr.Service, 99999)
	b, _, _ := h.login(100002, dr.Service, 99999)
	sendChat(t, a, fmt.Sprintf(`{"room_id":%d,"type":6,"room_lev":1}`, roomID), 4, amf3.Property{Name: "type", Value: 6.0})
	body := readCard(t, b, 6)
	if body["room_id"] != float64(roomID) || body["room_lev"] != float64(77) {
		t.Fatal(body)
	}
	joinCardRoom(t, f, 100002, roomID, defenseFamily)
	if seated := f.number(`SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=100002 AND stage='SEATED'`, roomID); seated != 1 {
		t.Fatal("defense card room reference did not join")
	}
	if h.report().Outcomes[stockruntime.ChatTransportWriteRecorded] != 2 {
		t.Fatal("defense card recipients")
	}
}
