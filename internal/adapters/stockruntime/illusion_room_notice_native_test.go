//go:build postgres

package stockruntime

import (
	"encoding/json"
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// TestIllusionNoticeLateSeatReadsWithoutReport pins DL-2ffb0688 against a
// migrated database: the room holds a report for its original members, and a
// member seated after it has no damage_result, so the 518 frame that member
// receives carries is_report 0 and no report_id (Illusion.lua:412).
func TestIllusionNoticeLateSeatReadsWithoutReport(t *testing.T) {
	p := broadcastPool(t)
	const server = identity.LogicalServerID(3)
	master, _ := broadcastPlayerRoot(t, p, server)
	mate, _ := broadcastPlayerRoot(t, p, server)
	late, _ := broadcastPlayerRoot(t, p, server)
	reportID := "00000000-0000-4000-8000-00000000d518"
	payload, err := (di.RoomState{ParadiseID: 100001, MasterLevel: 66, Stage: di.StageSelectHero, ReportID: reportID,
		DamageResults: map[string]json.RawMessage{
			strconv.FormatInt(int64(master.PlayerID), 10): json.RawMessage(`{"rank":1,"now_hurt":900}`),
			strconv.FormatInt(int64(mate.PlayerID), 10):   json.RawMessage(`{"rank":2,"now_hurt":800}`),
		}}).Encode()
	if err != nil {
		t.Fatal(err)
	}
	var roomID int64
	if err = p.QueryRow(broadcastContext, `INSERT INTO shared_rooms(logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload,created_at,updated_at)
VALUES($1,'illusion',1,$2,'OPEN',3,clock_timestamp()+interval '1 hour',1,1,$3::jsonb,clock_timestamp(),clock_timestamp()) RETURNING room_id`,
		int64(server), int64(master.PlayerID), string(payload)).Scan(&roomID); err != nil {
		t.Fatal(err)
	}
	for index, player := range []identity.PlayerID{master.PlayerID, mate.PlayerID, late.PlayerID} {
		broadcastExec(t, p, `INSERT INTO shared_room_seats(room_id,seat_index,player_id,family,slot,stage,ready,joined_at,updated_at)
VALUES($1,$2,$3,'illusion',1,'SEATED',false,clock_timestamp(),clock_timestamp())`, roomID, index, int64(player))
	}

	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	pipes := map[identity.PlayerID]*noticePipe{}
	for index, player := range []identity.PlayerID{master.PlayerID, late.PlayerID} {
		writer, _, client := newRegistryPipeWriter(t)
		defer client.Close()
		admission := registryAdmission(t, fmt.Sprintf("44444444-4444-4444-8444-%012d", index+1), player, domainrt.World, 1)
		if _, err = registry.Replace(admission, writer); err != nil {
			t.Fatal(err)
		}
		pipes[player] = startNoticePipe(client)
	}
	events, err := NewIllusionRoomNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := IllusionRoomNoticeHandler{Service: IllusionRoomNoticeReader{Store: sharedroomstore.Store{},
		Directory: i4store.PlayerDirectoryReader{}, Queryer: p}, Registry: registry,
		Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{},
		Time: deliveryClock{}, MaxHandles: 10, Delivered: NewRoomNoticeLedger()}
	if err = handler.ReloadAndDeliver(broadcastContext, strconv.FormatInt(roomID, 10)); err != nil {
		t.Fatal(err)
	}

	report := illusionNoticeMessage(t, pipes[master.PlayerID])
	if report["is_report"] != float64(1) || report["report_id"] != reportID {
		t.Fatalf("report seat %#v", report)
	}
	if _, ok := report["damage_result"]; !ok {
		t.Fatalf("report seat lost damage_result %#v", report)
	}
	lateSeat := illusionNoticeMessage(t, pipes[late.PlayerID])
	if lateSeat["room_id"] != float64(roomID) || lateSeat["status"] != float64(1) {
		t.Fatalf("late seat cannot read the notice %#v", lateSeat)
	}
	if lateSeat["is_report"] != float64(0) {
		t.Fatalf("late seat was told is_report %#v", lateSeat["is_report"])
	}
	if _, ok := lateSeat["report_id"]; ok {
		t.Fatalf("late seat got report_id %#v", lateSeat["report_id"])
	}
	if _, ok := lateSeat["damage_result"]; ok {
		t.Fatalf("late seat got damage_result %#v", lateSeat["damage_result"])
	}
}

func illusionNoticeMessage(t *testing.T, pipe *noticePipe) map[string]any {
	t.Helper()
	select {
	case frame := <-pipe.frames:
		if frame.MID != mids.MIDIllusionNotice {
			t.Fatalf("notice MID %d", frame.MID)
		}
		fields, err := frame.Params.(*amf3.Object).StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		message, ok := fields["message"].(*amf3.Object)
		if !ok {
			t.Fatalf("notice body %#v", fields["message"])
		}
		body, err := message.StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		return body
	case err := <-pipe.errors:
		t.Fatal(err)
	case <-time.After(3 * time.Second):
		t.Fatal("no illusion notice delivered")
	}
	return nil
}
