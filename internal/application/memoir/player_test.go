package memoir

import (
	"context"
	"encoding/json"
	domain "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
)

func TestPlayerCarryRequiresActualServerEndState(t *testing.T) {
	fighter := func(identifier int64, health float64) map[string]any {
		return map[string]any{"summon_type": 0, "hero": map[string]any{"partner_id": identifier}, "memoir_final_status": map[string]any{"hp": health, "mp": 345, "is_reborn": 0}}
	}
	report := map[string]any{"fighter": map[string]any{"A|1": fighter(7, 4.5), "B|1": fighter(1, 0)}}
	raw, _ := json.Marshal(report)
	allies, enemies, err := playerStatuses(raw, []int64{7}, 100001)
	if err != nil || len(allies) != 1 || allies[0].HP != 4.5 || allies[0].Player != 100001 || enemies[1].HP != 0 {
		t.Fatal(allies, enemies, err)
	}
	for _, test := range []struct {
		name      string
		report    any
		formation []int64
	}{
		{"missing", map[string]any{"fighter": map[string]any{"A|1": map[string]any{"hero": map[string]any{"partner_id": 7}}}}, []int64{7}},
		{"unselected", report, []int64{8}},
		{"missing_ally", report, []int64{7, 8}},
		{"negative", map[string]any{"fighter": map[string]any{"A|1": fighter(7, -1), "B|1": fighter(1, 0)}}, []int64{7}},
		{"duplicate", map[string]any{"fighter": map[string]any{"A|1": fighter(7, 1), "A|2": fighter(7, 1), "B|1": fighter(1, 0)}}, []int64{7}},
	} {
		t.Run(test.name, func(t *testing.T) {
			raw, _ := json.Marshal(test.report)
			if _, _, err := playerStatuses(raw, test.formation, 100001); err == nil {
				t.Fatal("unqualified server carry accepted")
			}
		})
	}
}
func TestMemoirPlayerSelectionBoundary(t *testing.T) {
	for _, request := range []PlayerFight{{Grid: 0, Formation: []int64{1}}, {Grid: 1, Formation: []int64{1, 1}}, {Grid: 1, Formation: []int64{0}}, {Grid: 1, Formation: []int64{1}, Pet: -1}, {Grid: 1, Formation: []int64{1, 2, 3, 4, 5, 6}}} {
		if request.valid() {
			t.Fatal(request)
		}
	}
	if !(PlayerFight{Grid: 1, Formation: []int64{1, 2}, Pet: 3}).valid() {
		t.Fatal("valid selection refused")
	}
}
func TestMemoirProjectionKeepsEmptyStockCollections(t *testing.T) {
	state := domain.State{}
	state.Initialize()
	raw, err := json.Marshal(projection(state))
	if err != nil {
		t.Fatal(err)
	}
	var fields map[string]any
	if err = json.Unmarshal(raw, &fields); err != nil {
		t.Fatal(err)
	}
	if len(fields["drops_info"].([]any)) != 0 || len(fields["heroes_status"].(map[string]any)) != 0 {
		t.Fatal(fields)
	}
}

func TestMemoirInitialInfoPopulatesStockModel(t *testing.T) {
	state := domain.State{}
	state.Initialize()
	fields := projection(state)
	maze, present := fields["maze_info"].(map[string]any)
	if !present || maze["map_open"] == nil || maze["maze_map"] == nil || maze["enemy_grids_info"] == nil {
		t.Fatal("stock model initializes max-floor/status only inside maze_info", fields)
	}
}

type memoirRevisionContent struct{ catalog domain.Catalog }

func (content memoirRevisionContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "new", nil
}
func (content memoirRevisionContent) MemoirCatalogTx(context.Context, tx.Queryer, string) (domain.Catalog, error) {
	return content.catalog, nil
}
func TestMemoirNewStartsRefuseChangedRunCatalog(t *testing.T) {
	pinned := domain.Catalog{SourceArchive: "source", BigKey: 50001400}
	mode := Mode{Content: memoirRevisionContent{catalog: pinned}}
	revision, err := mode.startRevision(context.Background(), scope{revision: "old", catalog: pinned})
	if err != nil || revision != "new" {
		t.Fatal("compatible stat revision", revision, err)
	}
	changed := pinned
	changed.BigKey++
	mode.Content = memoirRevisionContent{catalog: changed}
	if _, err = mode.startRevision(context.Background(), scope{revision: "old", catalog: pinned}); err == nil {
		t.Fatal("same archive does not prove unchanged Memoir payload")
	}
}
