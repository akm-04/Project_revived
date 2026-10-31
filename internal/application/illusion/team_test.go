package illusion

import (
	"context"
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type teamDirectory struct{}

func (teamDirectory) ProfileTx(_ context.Context, _ tx.Queryer, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: player, Name: fmt.Sprint("p", player), Level: 70, AvatarID: 1}, true, nil
}

type teamRoster struct{}

func (teamRoster) OverlayMID1(_ context.Context, _ tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	heroes := map[string]any{}
	for _, id := range []int64{101, 201, 202} {
		heroes[strconv.FormatInt(id, 10)] = map[string]any{"partner_id": id, "table_id": id, "lev": int64(70)}
	}
	detail["49"] = map[string]any{"heros": heroes}
	detail["780"] = map[string]any{"pets": []any{map[string]any{"pet_id": int64(55), "table_id": int64(55)}}}
	return nil
}

func TestTeamInfoCarriesSeatsStatusPartnersAndPet(t *testing.T) {
	at := time.Unix(1_800_000_000, 0)
	room, err := sharedroom.NewRoom(7, RoomFamily, RoomSlot, d.TeamSeats, identity.PlayerID(1), at.Add(time.Hour), []byte(`{"paradise_id":100001}`), at)
	if err != nil {
		t.Fatal(err)
	}
	room.ID = 9
	if err = room.Join(identity.PlayerID(2), at); err != nil {
		t.Fatal(err)
	}
	if err = room.Join(identity.PlayerID(3), at); err != nil {
		t.Fatal(err)
	}
	if err = room.SetReady(identity.PlayerID(1), true, at); err != nil {
		t.Fatal(err)
	}
	state := d.RoomState{ParadiseID: 100001, MasterLevel: 70}
	state.SetPick(1, d.TeamPick{Heroes: []int64{101}, PetID: 55, Force: 100})
	state.SetPick(2, d.TeamPick{Heroes: []int64{201, 202}, Force: 80})
	state.SetPick(3, d.TeamPick{})
	info, err := Mode{Directory: teamDirectory{}, Heroes: teamRoster{}, Pets: teamRoster{}}.teamInfo(context.Background(), nil, room, state, at)
	if err != nil {
		t.Fatal(err)
	}
	if info["room_id"] != int64(9) || info["status"] != int64(1) || info["master_id"] != int64(1) || info["mate_1"] != int64(2) || info["mate_2"] != int64(3) {
		t.Fatalf("seats %#v", info)
	}
	if info["master_partner"] != "101" || info["mate_1_partner"] != "201|202" || info["mate_2_partner"] != "" {
		t.Fatalf("partners %#v", info)
	}
	if info["master_status"] != int64(1) || info["mate_1_status"] != int64(0) {
		t.Fatalf("status %#v", info)
	}
	if pet := info["master_pet_detail"].(map[string]any); pet["table_id"] != int64(55) {
		t.Fatalf("pet %#v", pet)
	}
}

func TestReportDamageSumsOnlyAAndCaps(t *testing.T) {
	total, err := reportDamage([]byte(`{"fighter":{"A|1":{"harms":5},"B|1":{"harms":99},"A|2":{"harms":7.5}},"star":1}`))
	if err != nil || total != 12 {
		t.Fatalf("damage %d %v", total, err)
	}
	total, err = reportDamage([]byte(`{"fighter":{"A|1":{"harms":20000000}}}`))
	if err != nil || total != d.DamageCap {
		t.Fatalf("cap %d %v", total, err)
	}
	if _, err = reportDamage([]byte(`{"fighter":{"A|1":{"harms":-1}}}`)); err == nil {
		t.Fatal("negative harms accepted")
	}
}
