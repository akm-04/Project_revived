package campaign

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/i5"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type awakeCampaignProbe struct{ eligible bool }

func (p *awakeCampaignProbe) FreezeAwakeningCampaignTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, node, kind int64, formation []int64, pet int64, eligible bool) (objective.AwakeCampaignContext, error) {
	p.eligible = eligible
	return objective.AwakeCampaignContext{Player: int64(pid), Campaign: node, Type: kind, Formation: formation, Pet: pet}, nil
}
func (*awakeCampaignProbe) SettleAwakeningCampaignTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeCampaignContext, int64, int64, bool) ([]objective.AwakeFrozenDrop, map[string]any, error) {
	panic("freeze-only test")
}
func TestAwakeningFirstClearDayAndLegacyUnknown(t *testing.T) {
	probe := &awakeCampaignProbe{}
	s := Mode{Awakening: probe}
	day := int64(40000)
	node := d.Node{ID: 1200021, Type: d.Super}
	for _, c := range []struct {
		star     int64
		first    *int64
		now      int64
		eligible bool
	}{{0, nil, day, false}, {3, nil, day, true}, {3, &day, day, false}, {3, &day, day + 1, true}} {
		_, e := s.freezeAwakening(context.Background(), nil, 7, node, d.Progress{Nodes: map[int64]d.NodeState{node.ID: {CampaignID: node.ID, Star: c.star, FirstClearDay: c.first}}}, c.now, []int64{1}, 0)
		if e != nil || probe.eligible != c.eligible {
			t.Fatal(c, probe.eligible, e)
		}
	}
}
func TestAwakeningStartPackageLegacyAndExactContext(t *testing.T) {
	items, context, e := readAwakeningPackage([]byte(`[{"item_id":9,"item_num":2}]`))
	if e != nil || len(items) != 1 || context != nil {
		t.Fatal(items, context, e)
	}
	a := objective.AwakeInstance{Mission: 1001003, Type: 1, OwnerID: 7, Generation: 2, Revision: strings.Repeat("a", 64)}
	frozen := objective.AwakeCampaignContext{Player: 5, Campaign: 1200021, Type: 2, Formation: []int64{7}, Final: &a, Drops: []objective.AwakeFrozenDrop{}}
	raw, e := json.Marshal(awakeningStartPackage{Items: []d.Item{}, Awakening: &frozen})
	if e != nil {
		t.Fatal(e)
	}
	_, context, e = readAwakeningPackage(raw)
	if e != nil {
		t.Fatal(e)
	}
	got, e := readAwakeningPending(context)
	if e != nil || got.Final.Generation != 2 || got.Final.Revision != a.Revision {
		t.Fatal(got, e)
	}
	if _, _, e = readAwakeningPackage([]byte(`{"items":[]}`)); e == nil {
		t.Fatal("missing occurrence silently invented")
	}
}

func TestPetAwakeningPendingEnvelopeKeepsOrdinaryContextSeparate(t *testing.T) {
	occurrence := objective.AwakeInstance{Mission: 10001002, Type: 3, OwnerID: 7, Generation: 2, Revision: strings.Repeat("a", 64)}
	frozen := i5.AwakeningPetContext{Occurrence: occurrence, Campaign: 41002, Formation: []int64{7}}
	raw, e := json.Marshal(awakeningStartPackage{Items: []d.Item{}, PetAwakening: &frozen})
	if e != nil {
		t.Fatal(e)
	}
	_, pending, e := readAwakeningPackage(raw)
	if e != nil {
		t.Fatal(e)
	}
	generic, e := readAwakeningPending(pending)
	if e != nil || generic != nil {
		t.Fatal("pet context laundered through ordinary/Blood", generic, e)
	}
	pet, e := readPetAwakeningPending(pending)
	if e != nil || pet == nil || pet.Occurrence.Generation != 2 || pet.Campaign != 41002 {
		t.Fatal(pet, e)
	}
	frozen.Occurrence.Type = 2
	raw, _ = json.Marshal(awakeningStartPackage{Items: []d.Item{}, PetAwakening: &frozen})
	if _, _, e = readAwakeningPackage(raw); e == nil {
		t.Fatal("non-pet occurrence accepted")
	}
}
