package illusion

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type teamDirectory struct{}

func (teamDirectory) ProfileTx(_ context.Context, _ tx.Queryer, player identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: player, Name: fmt.Sprint("p", player), Level: 70, AvatarID: 1}, true, nil
}

type teamRoster struct{}

func (teamRoster) OverlayMID1(_ context.Context, _ tx.Queryer, actor identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	heroes := map[string]any{}
	for _, id := range []int64{101, 201, 202, 301, 302} {
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
	state := d.RoomState{ParadiseID: 100001, MasterLevel: 70, Stage: d.StageSelectHero}
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

func TestTeamInfoKeepsEmptySeatsPositional(t *testing.T) {
	at := time.Unix(1_800_000_000, 0)
	room, err := sharedroom.NewRoom(7, RoomFamily, RoomSlot, d.TeamSeats, identity.PlayerID(1), at.Add(time.Hour), []byte(`{"paradise_id":100001}`), at)
	if err != nil {
		t.Fatal(err)
	}
	if err = room.Join(identity.PlayerID(2), at); err != nil {
		t.Fatal(err)
	}
	state := d.RoomState{ParadiseID: 100001, MasterLevel: 70}
	state.SetPick(2, d.TeamPick{Heroes: []int64{0, 202}, Force: 80})
	info, err := Mode{Directory: teamDirectory{}, Heroes: teamRoster{}, Pets: teamRoster{}}.teamInfo(context.Background(), nil, room, state, at)
	if err != nil {
		t.Fatal(err)
	}
	if info["mate_1_partner"] != "0|202" {
		t.Fatalf("partners %#v", info["mate_1_partner"])
	}
	details := info["mate_1_partner_detail"].([]map[string]any)
	if len(details) != 2 || len(details[0]) != 0 || details[1]["table_id"] == nil {
		t.Fatalf("details %#v", details)
	}
	if info["master_pet"] != int64(0) {
		t.Fatalf("pet %#v", info["master_pet"])
	}
}

func TestRoomStageAndPickTurn(t *testing.T) {
	seats := []identity.PlayerID{1, 2, 3}
	state := d.RoomState{}
	if state.Status(len(seats)) != d.StagePrepare {
		t.Fatal("selection opened before the master pressed 1351")
	}
	state.Stage = d.StageSelectHero
	if state.Status(2) != d.StagePrepare {
		t.Fatal("selection opened with two seats")
	}
	if state.Status(3) != d.StageSelectHero {
		t.Fatal("selection did not open with three seats")
	}
	state.SetPick(1, d.TeamPick{Heroes: []int64{101}})
	if err := turnReady(state, seats, 1); err == nil {
		t.Fatal("mate one picked before the master's pet")
	}
	state.SetPick(1, d.TeamPick{Heroes: []int64{101}, PetID: 55})
	if err := turnReady(state, seats, 1); err != nil {
		t.Fatal(err)
	}
	if err := turnReady(state, seats, 2); err == nil {
		t.Fatal("mate two picked before mate one")
	}
	state.SetPick(2, d.TeamPick{Heroes: []int64{201, 0}})
	if err := turnReady(state, seats, 2); err == nil {
		t.Fatal("mate two picked before mate one filled both slots")
	}
	state.SetPick(2, d.TeamPick{Heroes: []int64{201, 202}})
	if err := turnReady(state, seats, 2); err != nil {
		t.Fatal(err)
	}
}

func TestTeamFromRoomKeepsHeroOwnForceAndMemberBestFifteen(t *testing.T) {
	at := time.Unix(1_800_000_000, 0).UTC()
	room, err := sharedroom.NewRoom(7, RoomFamily, RoomSlot, d.TeamSeats, identity.PlayerID(1), at.Add(time.Hour), []byte(`{"paradise_id":100001}`), at)
	if err != nil {
		t.Fatal(err)
	}
	if err = room.Join(identity.PlayerID(2), at); err != nil {
		t.Fatal(err)
	}
	if err = room.Join(identity.PlayerID(3), at); err != nil {
		t.Fatal(err)
	}
	state := d.RoomState{ParadiseID: 100001, MasterLevel: 70, Stage: d.StageSelectHero}
	state.SetPick(1, d.TeamPick{Heroes: []int64{101}, PetID: 55, Force: 3000, Powers: []int64{30000}})
	state.SetPick(2, d.TeamPick{Heroes: []int64{201, 202}, Force: 3000, Powers: []int64{30000, 30000}})
	state.SetPick(3, d.TeamPick{Heroes: []int64{301, 302}, Force: 3000, Powers: []int64{30000, 30000}})
	team, err := Mode{Directory: teamDirectory{}, Heroes: teamRoster{}}.teamFromRoom(context.Background(), nil, room, state, at)
	if err != nil {
		t.Fatal(err)
	}
	if team.Members[0].Force != 3000 || team.Members[0].Heroes[0].Power != 30000 {
		t.Fatalf("member %+v", team.Members[0])
	}
}

type powerTx struct{}

func (powerTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (powerTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (powerTx) Commit(context.Context) error                                { return nil }
func (powerTx) Rollback(context.Context) error                              { return nil }

type powerStats map[int64]float64

func (s powerStats) HeroTx(_ context.Context, _ ca.CoherentReadScope, ref character.HeroRef, _ publicstats.View) (publicstats.Result, error) {
	return publicstats.Result{Stats: statrules.Result{Force: s[ref.PartnerID]}}, nil
}

// powerRoster owns one strong hero (30000) and three weak ones (100 each).
type powerRoster struct{}

func (powerRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	heroes := map[string]any{}
	for table, partner := range map[int64]int64{210: 1210, 220: 1220, 230: 1230, 240: 1240} {
		heroes[strconv.FormatInt(partner, 10)] = map[string]any{"partner_id": partner, "table_id": table, "lev": int64(70)}
	}
	detail["49"] = map[string]any{"heros": heroes}
	return nil
}

type powerContent struct{}

func (powerContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return strings.Repeat("a", 64), nil
}

func (powerContent) IllusionCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{}, nil
}

func TestValidatePickUsesPlayerBestFifteenPowerFloor(t *testing.T) {
	at := time.Unix(1_800_000_000, 0).UTC()
	timed, err := gen.NewTimedOperation(operation.Context{ID: ids.UUID{1}, StartedAt: at}, at)
	if err != nil {
		t.Fatal(err)
	}
	sc := gen.TimedScope{Tx: powerTx{}, Operation: timed, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}
	mode := Mode{Heroes: powerRoster{}, Content: powerContent{},
		Stats: powerStats{1210: 30000, 1220: 100, 1230: 100, 1240: 100}}
	seats := []identity.PlayerID{1, 2, 3}
	_, err = mode.validatePick(context.Background(), sc, d.RoomState{}, seats, 1, PartnerRequest{Heroes: []int64{220, 230}}, at)
	if !errors.Is(err, d.ErrRefused) {
		t.Fatalf("two 100-force heroes against a 30300 best-15 were accepted: %v", err)
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

func TestTeamFingerprintHoldsOnlyTheStage(t *testing.T) {
	room := sharedroom.Room{ID: 12}
	occurrence := d.Occurrence{CampaignID: d.FirstCampaignID, OpenDay: 3}
	picked := d.Team{Members: []d.TeamMember{{PlayerID: 1, Heroes: []d.Hero{{TableID: 101, PartnerID: 101}}, PetID: 55}}}
	other := d.Team{Members: []d.TeamMember{{PlayerID: 1, Heroes: []d.Hero{{TableID: 201, PartnerID: 201}}, PetID: 56}}}
	if teamFingerprint(room, picked, occurrence) != teamFingerprint(room, other, occurrence) {
		t.Fatal("a changed pick is the same stage: START_REPLAY_IDENTITY_V1 ruling 1")
	}
	for name, mutate := range map[string]func(*sharedroom.Room, *d.Occurrence){
		"room":     func(r *sharedroom.Room, _ *d.Occurrence) { r.ID = 13 },
		"open day": func(_ *sharedroom.Room, o *d.Occurrence) { o.OpenDay = 4 },
		"campaign": func(_ *sharedroom.Room, o *d.Occurrence) { o.CampaignID = d.LastCampaignID },
	} {
		changedRoom, changed := room, occurrence
		mutate(&changedRoom, &changed)
		if teamFingerprint(room, picked, occurrence) == teamFingerprint(changedRoom, picked, changed) {
			t.Fatalf("%s change must be a different stage", name)
		}
	}
}
