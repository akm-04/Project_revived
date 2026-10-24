package campaign

import (
	"bytes"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"testing"
)

func loadCatalog(t *testing.T) Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/campaign_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var c Catalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&c); err != nil {
		t.Fatal(err)
	}
	if err = c.Validate(); err != nil {
		t.Fatal(err)
	}
	return c
}

type fixedDraw uint64

func (f fixedDraw) Uniform(uint64) uint64 { return uint64(f) }

func TestOpeningAdmissionAndSettlement(t *testing.T) {
	c := loadCatalog(t)
	const day = 100
	p := Progress{}
	if got := c.Opened(p, Normal, false); !reflect.DeepEqual(got, []int64{100001}) {
		t.Fatalf("initial normal %v", got)
	}
	if got := c.Opened(p, Super, false); got != nil {
		t.Fatalf("closed super %v", got)
	}
	if _, err := c.Admit(p, Super, 100019, 30, day, true); !errors.Is(err, ErrRefused) {
		t.Fatalf("super before related clear: %v", err)
	}
	if _, err := c.Admit(p, Super, 100001, 30, day, true); !errors.Is(err, ErrInvalid) {
		t.Fatalf("wrong wire type: %v", err)
	}
	if _, err := c.Admit(p, Normal, 100002, 30, day, false); !errors.Is(err, ErrRefused) {
		t.Fatalf("unopened node: %v", err)
	}
	n, err := c.Admit(p, Normal, 100001, 1, day, false)
	if err != nil {
		t.Fatal(err)
	}
	lost, _ := c.Settle(p, n, 0, day, false)
	if lost.Win || lost.Energy != n.DefeatCost || lost.Mana != 0 || len(lost.Progress.Nodes) != 0 {
		t.Fatalf("loss %+v", lost)
	}
	won, err := c.Settle(p, n, 3, day, false)
	if err != nil {
		t.Fatal(err)
	}
	if !won.FirstClear || won.Energy != 6 || won.PlayerExp != 18 || won.Mana != 495 || won.PartnerExp != 75 || won.Crystal != 30 || !reflect.DeepEqual(won.Touched, []int64{100001, 100002}) {
		t.Fatalf("win %+v", won)
	}
	again, _ := c.Settle(won.Progress, n, 3, day, false)
	if again.FirstClear || again.Crystal != 0 || !reflect.DeepEqual(again.Touched, []int64{100001}) || n.BattleBox(won.Progress) != n.RepeatBox {
		t.Fatalf("repeat %+v", again)
	}
	p = won.Progress
	s, err := c.Admit(p, Super, 100019, 30, day, true)
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 3; i++ {
		out, err := c.Settle(p, s, 1, day, true)
		if err != nil {
			t.Fatal(err)
		}
		p = out.Progress
	}
	if c.Remaining(p, s, day) != 0 || c.Remaining(p, s, day+1) != 3 {
		t.Fatal("super daily limit")
	}
	if _, err := c.Admit(p, Super, 100019, 30, day, true); !errors.Is(err, ErrRefused) {
		t.Fatalf("exhausted super: %v", err)
	}
	if _, err := c.Settle(p, s, 1, day, true); !errors.Is(err, ErrRefused) {
		t.Fatalf("exhausted super settle: %v", err)
	}
	world := c.World(p, true, day)
	info := world["chapter_info"].(map[string]any)
	if world["normal_campaign_id"] != int64(100002) || info["super_campaign_id"] != int64(100020) || info["normal_stars"] != int64(3) || len(world["super"].([]any)) != 2 {
		t.Fatalf("world %v", world)
	}
	row := c.Row(p, 100019, day)
	if row["daily_limit"] != int64(0) || row["star"] != int64(1) || row["is_partner_drop"] != nil {
		t.Fatalf("super row %v", row)
	}
}

func TestDropLaw(t *testing.T) {
	c := Catalog{DropBoxes: []DropBox{{ID: 7, Rows: [][2]int64{{1, 25000}, {2, 4000}, {3, 10000}}}}}
	c.boxes = map[int64]int{7: 0}
	if got := c.Drop(7, fixedDraw(3999)); !reflect.DeepEqual(got, []Item{{1, 3}, {2, 1}, {3, 1}}) {
		t.Fatalf("low draw %v", got)
	}
	if got := c.Drop(7, fixedDraw(5000)); !reflect.DeepEqual(got, []Item{{1, 2}, {3, 1}}) {
		t.Fatalf("high draw %v", got)
	}
	if got := c.Drop(8, fixedDraw(0)); len(got) != 0 {
		t.Fatalf("missing box %v", got)
	}
}
