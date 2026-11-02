package objective

import (
	"encoding/json"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/domain/grant"
)

func TestActivityRewardSelectionAndVIPBoundary(t *testing.T) {
	raw, err := os.ReadFile("../../content/builtin/generated/objective_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog struct {
		Activity ActivityCatalog `json:"activity_chests"`
	}
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	sum := func(plan grant.Plan, kind grant.LineKind, key string) int64 {
		var n int64
		for _, l := range plan.Lines {
			if l.Kind == kind && l.ResourceKey == key {
				n += l.Amount
			}
		}
		return n
	}
	for _, tc := range []struct {
		level, vip int64
		exp        bool
		coin       int64
	}{{10, 5, true, 240}, {10, 6, true, 360}, {100, 6, false, 360}} {
		plan, medal, err := catalog.Activity.Reward("DAY", 3, tc.level, 100, tc.vip)
		if err != nil {
			t.Fatal(err)
		}
		if medal != 90 || (sum(plan, grant.PlayerExp, "") > 0) != tc.exp || sum(plan, grant.ScalarCurrency, "guild_coin") != tc.coin {
			t.Fatalf("case %#v: medal=%d plan=%#v", tc, medal, plan)
		}
		if !tc.exp && sum(plan, grant.ScalarCurrency, "march_coin") == 0 {
			t.Fatal("max level must receive March Coin")
		}
	}
	before, _ := json.Marshal(catalog.Activity)
	plan, _, _ := catalog.Activity.Reward("DAY", 3, 10, 100, 6)
	plan.Lines[0].Amount = 999
	after, _ := json.Marshal(catalog.Activity)
	if string(before) != string(after) {
		t.Fatal("reward selection mutated immutable content")
	}
	if _, _, err = catalog.Activity.Reward("WEEK", 3, 10, 100, 0); err == nil {
		t.Fatal("invalid index accepted")
	}
	catalog.Activity.Rules[0].GiftEXP = 123
	if err = catalog.Activity.Validate(); err == nil {
		t.Fatal("dangling gift accepted")
	}
}
