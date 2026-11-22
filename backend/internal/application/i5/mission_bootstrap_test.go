package i5

import (
	"context"
	"reflect"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type missionActivityMemory struct{ catalog *objective.ActivityCatalog }

func (m missionActivityMemory) MissionActivityCatalogTx(context.Context, tx.Queryer, string) (*objective.ActivityCatalog, error) {
	return m.catalog, nil
}

func TestMissionBootstrapClaimsTheMID2560Detail(t *testing.T) {
	if !slices.Contains((MissionBootstrap{}).Claims(), "2560") {
		t.Fatalf("MissionBootstrap claims %v, want 2560", (MissionBootstrap{}).Claims())
	}
}

func TestMissionBootstrapPublishesMissionRedmarksAsMID2560(t *testing.T) {
	at := time.Unix(100000, 0).UTC()
	activity := missionActivityMemory{catalog: &objective.ActivityCatalog{Rules: []objective.ActivityRule{{Period: "DAY", Index: 1, Medal: 30}}}}
	for _, testCase := range []struct {
		name      string
		dayHuoyue int64
		want      []int64
	}{
		{name: "claimable activity medal", dayHuoyue: 30, want: []int64{2701}},
		{name: "no claimable medal", dayHuoyue: 29, want: []int64{}},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			root, err := objective.NewMissionRoot(100001, at)
			if err != nil {
				t.Fatal(err)
			}
			root.DayHuoyue = testCase.dayHuoyue
			memory := &missionMemory{root: root, rows: map[string]objective.Instance{}}
			service := Service{
				Missions: &MissionMaterializer{Store: memory, Catalog: memory, Activity: activity},
				Content:  &testContent{},
			}
			// The lobby bootstrap writes the inactive zero shape first; the mission overlay must replace it.
			detail := map[string]any{"160": map[string]any{}, "2560": map[string]any{}}
			if err := (MissionBootstrap{Owner: service}).OverlayMID1(context.Background(), nil, identity.ActorContext{PlayerID: 100001}, false, at, detail); err != nil {
				t.Fatal(err)
			}
			want := map[string]any{"27": map[string]any{"function_id": int64(27), "redmark_list": testCase.want}}
			if !reflect.DeepEqual(detail["2560"], want) {
				t.Fatalf("MID1 2560 = %#v, want %#v", detail["2560"], want)
			}
			mission, ok := detail["160"].(map[string]any)
			if !ok || !reflect.DeepEqual(mission["redmarks_"], detail["2560"]) {
				t.Fatalf("MID1 160 redmarks_ = %#v, 2560 = %#v", mission["redmarks_"], detail["2560"])
			}
			if _, present := detail["2560"].(map[string]any)["97"]; present {
				t.Fatal("BattlePass function 97 must stay absent")
			}
		})
	}
}
