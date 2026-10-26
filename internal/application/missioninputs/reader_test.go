package missioninputs

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/application/i5"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type heroRows []character.Hero

func (h heroRows) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	return h, nil
}

type campaignRows struct{ campaign.Record }

func (c campaignRows) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (campaign.Record, error) {
	return c.Record, nil
}

func definitions(t *testing.T) map[int64]objective.MissionDefinition {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/objective_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var c struct {
		Definitions []objective.MissionDefinition `json:"definitions"`
	}
	if err = json.Unmarshal(raw, &c); err != nil {
		t.Fatal(err)
	}
	out := map[int64]objective.MissionDefinition{}
	for _, d := range c.Definitions {
		out[d.ObjectiveID] = d
	}
	return out
}

func TestReaderUsesCampaignClearsAndExplicitUnavailableSource(t *testing.T) {
	rows := definitions(t)
	r := Reader{Campaigns: campaignRows{campaign.Record{Progress: campaign.Progress{Nodes: map[int64]campaign.NodeState{100019: {CampaignID: 100019, Star: 3, ClearCountFloor: 2}}}}}}
	scope := i5.MissionScope{PlayerID: 100001, DecisionAt: time.Unix(1000, 0)}
	got, err := r.ObserveMissionTx(context.Background(), nil, scope, rows[30001], 0)
	if err != nil || !got.GatePassed || got.Value != 2 {
		t.Fatalf("story clear count: %+v %v", got, err)
	}
	got, err = Reader{}.ObserveMissionTx(context.Background(), nil, scope, rows[30014], 0)
	if err != nil || got.GatePassed {
		t.Fatalf("source-unavailable mission should stay closed: %+v %v", got, err)
	}
	if _, err = (Reader{}).ObserveMissionTx(context.Background(), nil, scope, rows[30001], 0); err == nil {
		t.Fatal("missing canonical reader treated as zero progress")
	}
}

func TestReaderCountsQualifyingHeroesAndBindsPartnerTemplate(t *testing.T) {
	rows := definitions(t)
	r := Reader{Heroes: heroRows{{OriginTableID: 10, Color: 5, Level: 20}, {OriginTableID: 11, Color: 8, Level: 30}, {OriginTableID: 12, Color: 2, Level: 50}}}
	scope := i5.MissionScope{PlayerID: 100001, DecisionAt: time.Unix(1000, 0)}
	var quality, partner objective.MissionDefinition
	for _, d := range rows {
		if d.Presentation.Condition == 5 {
			quality = d
		}
		if d.Family == objective.Partner && d.Presentation.Condition == 21 {
			partner = d
		}
	}
	quality.Prerequisite = objective.MissionPrerequisite{Gate: []int64{0}}
	got, err := r.ObserveMissionTx(context.Background(), nil, scope, quality, 0)
	if err != nil || got.Value != 2 {
		t.Fatalf("quality count is not maximum color: %+v %v", got, err)
	}
	partner.Prerequisite = objective.MissionPrerequisite{Gate: []int64{9}}
	got, err = r.ObserveMissionTx(context.Background(), nil, scope, partner, 11)
	if err != nil || !got.GatePassed || got.Value != 30 {
		t.Fatalf("partner template binding: %+v %v", got, err)
	}
	got, err = r.ObserveMissionTx(context.Background(), nil, scope, partner, 99)
	if err != nil || got.GatePassed {
		t.Fatalf("unowned partner admitted: %+v %v", got, err)
	}
}

type bookRows struct{ bookskill.Inputs }

func (b bookRows) BookInputsTx(context.Context, tx.Queryer, bookskill.InputScope) (bookskill.Inputs, error) {
	return b.Inputs, nil
}

func TestReaderCountsCompletedBooksRatherThanSummingSkillLevels(t *testing.T) {
	rows := definitions(t)
	var d objective.MissionDefinition
	for _, row := range rows {
		if row.Presentation.Condition == 20 {
			d = row
			break
		}
	}
	d.Prerequisite = objective.MissionPrerequisite{Gate: []int64{0}}
	r := Reader{Books: bookRows{bookskill.Inputs{Catalog: book.Catalog{Books: map[int64]book.BookRule{1: {Star: 2, Skills: []int64{10, 11}}, 2: {Star: 3, Skills: []int64{20, 21}}}}, Applied: book.State{Skills: map[int64]int64{10: 2, 11: 2, 20: 3, 21: 2}}}}}
	got, err := r.ObserveMissionTx(context.Background(), nil, i5.MissionScope{}, d, 0)
	if err != nil || got.Value != 1 {
		t.Fatalf("completed books: %+v %v", got, err)
	}
}
