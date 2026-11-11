package arena

import (
	"encoding/json"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/arena"
)

func TestInfoKeepsTheDefenceFormationAnArray(t *testing.T) {
	body := Info(d.InfoView{Player: d.Player{Defense: d.Lineup{Heroes: nil}}})
	defence, ok := body["defence_formation"].([]int64)
	if !ok || defence == nil {
		t.Fatalf("defence_formation is not an array: %#v", body["defence_formation"])
	}
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"defence_formation":null`) {
		t.Fatal(string(raw))
	}
	kept := Info(d.InfoView{Player: d.Player{Defense: d.Lineup{Heroes: []int64{10001001}}}})
	if heroes := kept["defence_formation"].([]int64); len(heroes) != 1 || heroes[0] != 10001001 {
		t.Fatalf("defence_formation lost its heroes: %#v", heroes)
	}
}
