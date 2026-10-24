package publicprofile

import (
	"context"
	"errors"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	dconquer "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeRoster struct{ detail map[string]any }

func (f fakeRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, out map[string]any) error {
	for k, v := range f.detail {
		out[k] = v
	}
	return nil
}

type fakeAwakening struct{ known bool }

func (f fakeAwakening) RawAwakeningTx(_ context.Context, _ ca.CoherentReadScope, ref character.HeroRef) (ca.HeroRawAwakeningObservation, error) {
	return ca.HeroRawAwakeningObservation{Ref: ref, Known: f.known, RawStage: 2}, nil
}

type fakeConquer struct{ progress *dconquer.Progress }

func (f fakeConquer) FactsTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (dconquer.Observation, error) {
	return dconquer.Observation{Facts: dconquer.Facts{Payload: dconquer.Payload{Kind: "OWNED", Progress: f.progress}}}, nil
}

type fakeMode struct{ history cd.History }

func (f fakeMode) PublicHistoryTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (cd.History, error) {
	return f.history, nil
}

func richRoster() fakeRoster {
	return fakeRoster{detail: map[string]any{
		"49":  map[string]any{"heros": map[string]any{"7": map[string]any{"partner_id": int64(7), "table_id": int64(1001), "color": int64(16)}}},
		"780": map[string]any{"pets": []any{map[string]any{"pet_id": int64(3), "lev": int64(10)}}},
	}}
}

func TestRosterRecordsComposeHeroPetAndPreserveUnknown(t *testing.T) {
	roster := richRoster()
	records := RosterRecords{Heroes: roster, Pets: roster, Awakening: fakeAwakening{known: true}, Conquer: fakeConquer{progress: &dconquer.Progress{Level: 4}}}
	hero, err := records.RecordTx(context.Background(), ca.CoherentReadScope{}, 9, 7)
	if err != nil || hero["twice_awake_stage"] != int64(2) || hero["conquer_lev"] != int64(4) || hero["color"] != int64(16) {
		t.Fatalf("hero=%v err=%v", hero, err)
	}
	if _, ok := hero["conquer_loop_id"]; ok {
		t.Fatal("zero conquer loop emitted")
	}
	if _, ok := roster.detail["49"].(map[string]any)["heros"].(map[string]any)["7"].(map[string]any)["twice_awake_stage"]; ok {
		t.Fatal("record mutated the roster row")
	}

	records.Awakening, records.Conquer = fakeAwakening{}, fakeConquer{}
	hero, err = records.RecordTx(context.Background(), ca.CoherentReadScope{}, 9, 7)
	_, hasStage := hero["twice_awake_stage"]
	_, hasConquer := hero["conquer_lev"]
	if err != nil || hasStage || hasConquer {
		t.Fatalf("unknown basis leaked: %v %v", hero, err)
	}

	pet, err := records.RecordTx(context.Background(), ca.CoherentReadScope{}, 9, -3)
	if err != nil || pet["lev"] != int64(10) {
		t.Fatalf("pet=%v err=%v", pet, err)
	}
	if _, err = records.RecordTx(context.Background(), ca.CoherentReadScope{}, 9, 8); !errors.Is(err, ErrShowcaseUnavailable) {
		t.Fatalf("missing hero err=%v", err)
	}
}

func TestModeHistoryShapesSubtypeTwoAndFailsClosedOnBattleRecords(t *testing.T) {
	at := time.Unix(1_800_000_000, 0)
	usage := []cd.PartnerTotals{{PartnerID: 7, TableID: 1001, Fights: 3, Wins: 2, Kills: 5, Harms: "1234.9"}, {PartnerID: 99, TableID: 2002, Fights: 1}}
	history := ModeHistory{
		TopFloor: fakeMode{cd.History{Rank: 12, Fights: 3, Wins: 2, Version: 4, Partners: usage}},
		OneOnOne: fakeMode{cd.History{Fights: 1, Version: 1}},
		Arena:    fakeMode{cd.History{Points: 1500, Fights: 6, Wins: 5, Version: 2, Partners: []cd.PartnerTotals{{TableID: 1001, Fights: 6, Wins: 5}}}},
		Heroes:   richRoster(),
	}
	out, err := history.ReadPublicHistoryTx(context.Background(), tx.Scope{}, 9, 2, "rev", at)
	if err != nil || out.SourceVersion != 8 || out.PlayerID != 9 || out.ContentRevision != "rev" || !out.ObservedAt.Equal(at) {
		t.Fatalf("out=%+v err=%v", out, err)
	}
	top := out.Fields["arena_performance"].(map[string]any)
	partners := top["partners_info"].([]any)
	row := partners[0].(map[string]any)
	if top["arena_info"].(map[string]any)["rank"] != int64(12) || len(partners) != 1 || row["color"] != int64(16) || row["total_damage"] != int64(1234) || row["win_fight"] != int64(2) {
		t.Fatalf("top floor=%v", top)
	}
	if _, ok := out.Fields["super_arena_performance"].(map[string]any)["arena_info"].(map[string]any)["rank"]; ok {
		t.Fatal("unranked 1 on 1 emitted rank")
	}
	region := out.Fields["region_arena_performance"].(map[string]any)
	if region["arena_info"].(map[string]any)["king_coin"] != int64(1500) || region["partner_info"].([]any)[0].(map[string]any)["table_id"] != int64(1001) {
		t.Fatalf("region=%v", region)
	}
	if _, err = history.ReadPublicHistoryTx(context.Background(), tx.Scope{}, 9, 3, "rev", at); !errors.Is(err, ErrProfileProvider) {
		t.Fatalf("battle records err=%v", err)
	}
}
