package events_test

import (
	"encoding/json"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/events"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
)

const validDefinition = `{
	"activity_id": 1071,
	"revision": 1,
	"archetype": "TIERED_CLAIM",
	"tiers": [
		{"id": 1, "requirement": {"kind": "player_level", "value": 10}, "choices": [{"gift_id": 90001428}]},
		{"id": 2, "requirement": {"kind": "player_level", "value": 20}, "choices": [{"lines": [{"kind": "item", "item_id": 50001003, "amount": 2}]}, {"gift_id": 90001430}]}
	],
	"client_requirements": {"client_paths": ["windows/activities/1071/main_grow_up.csb"], "min_code_version": "1.631.0"},
	"default_days": -1
}`

func TestParseDefinitionValid(t *testing.T) {
	definition, err := events.ParseDefinition([]byte(validDefinition))
	if err != nil {
		t.Fatal(err)
	}
	if definition.ActivityID != 1071 || definition.Revision != 1 || definition.Archetype != events.ArchetypeTieredClaim {
		t.Fatalf("unexpected definition: %+v", definition)
	}
	ids := definition.GiftIDs()
	if len(ids) != 2 || ids[0] != 90001428 || ids[1] != 90001430 {
		t.Fatalf("gift ids = %v", ids)
	}
}

func TestParseDefinitionUnknownFieldRefused(t *testing.T) {
	raw := strings.Replace(validDefinition, `"revision": 1,`, `"revision": 1, "drop_multiplier": 2,`, 1)
	if _, err := events.ParseDefinition([]byte(raw)); !errors.Is(err, events.ErrInvalidDefinition) {
		t.Fatalf("unknown field must be refused, got %v", err)
	}
}

func TestParseDefinitionRefusals(t *testing.T) {
	cases := map[string]string{
		"unknown archetype":        `{"activity_id":1,"revision":1,"archetype":"LOTTERY","client_requirements":{}}`,
		"no hooks":                 `{"activity_id":1,"revision":1,"archetype":"RULE_MODIFIER","client_requirements":{}}`,
		"no tiers":                 `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{}}`,
		"bad activity":             `{"activity_id":0,"revision":1,"archetype":"DISPLAY","client_requirements":{}}`,
		"zero revision":            `{"activity_id":1,"revision":0,"archetype":"DISPLAY","client_requirements":{}}`,
		"four choices":             `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"player_level","value":1},"choices":[{"gift_id":1},{"gift_id":2},{"gift_id":3},{"gift_id":4}]}]}`,
		"empty choice":             `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"player_level","value":1},"choices":[{}]}]}`,
		"both choice forms":        `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"player_level","value":1},"choices":[{"gift_id":1,"lines":[{"kind":"item","item_id":2,"amount":1}]}]}]}`,
		"bad reward kind":          `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"player_level","value":1},"choices":[{"lines":[{"kind":"crystal","amount":1}]}]}]}`,
		"bad lazy md5":             `{"activity_id":1,"revision":1,"archetype":"DISPLAY","client_requirements":{"lazy_assets":[{"path":"a.csb","md5":"zz"}]}}`,
		"unknown requirement kind": `{"activity_id":1,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"tiers":[{"id":1,"requirement":{"kind":"vip_level","value":5},"choices":[{"gift_id":1}]}]}`,
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := events.ParseDefinition([]byte(raw)); !errors.Is(err, events.ErrInvalidDefinition) {
				t.Fatalf("want ErrInvalidDefinition, got %v", err)
			}
		})
	}
}

func TestExpandGift(t *testing.T) {
	definition, err := events.ParseDefinition([]byte(validDefinition))
	if err != nil {
		t.Fatal(err)
	}
	definition.ExpandGift(90001428, []events.RewardLine{{Kind: "item", ItemID: 50001003, Amount: 2}})
	if got := definition.GiftIDs(); len(got) != 1 || got[0] != 90001430 {
		t.Fatalf("remaining gift ids = %v", got)
	}
	if choice := definition.Tiers[0].Choices[0]; choice.GiftID != 0 || len(choice.Lines) != 1 || choice.Lines[0].ItemID != 50001003 {
		t.Fatalf("expanded choice = %+v", choice)
	}
	if err := definition.Validate(); err != nil {
		t.Fatalf("expanded definition must validate: %v", err)
	}
}

func TestDefinitionBodyRoundTrip(t *testing.T) {
	definition, err := events.ParseDefinition([]byte(validDefinition))
	if err != nil {
		t.Fatal(err)
	}
	body, err := definition.Body()
	if err != nil {
		t.Fatal(err)
	}
	again, err := events.ParseDefinition(body)
	if err != nil {
		t.Fatal(err)
	}
	if again.ActivityID != definition.ActivityID || len(again.Tiers) != len(definition.Tiers) || again.Tiers[1].Choices[0].Lines[0].Amount != 2 {
		t.Fatalf("round trip lost data: %+v", again)
	}
	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		t.Fatal(err)
	}
}

func TestCampaignHookValidation(t *testing.T) {
	valid := events.Definition{ActivityID: 1008, Revision: 1, Archetype: events.ArchetypeRuleModifier, Hooks: []events.Hook{{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1, 5}, Multiplier: 2}}}
	if err := valid.Validate(); err != nil {
		t.Fatalf("valid hook: %v", err)
	}
	boundary := valid
	boundary.Hooks = []events.Hook{{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1}, Multiplier: 100}}
	if err := boundary.Validate(); err != nil {
		t.Fatalf("multiplier 100 must be accepted: %v", err)
	}
	invalid := []events.Hook{
		{Kind: events.HookCampaignDropMultiplier, Scope: "hard", ItemKinds: []int64{1}, Multiplier: 2},
		{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: nil, Multiplier: 2},
		{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1}, Multiplier: 0},
		{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1, 1}, Multiplier: 2},
		{Kind: events.HookCampaignDropMultiplier, Scope: "normal", ItemKinds: []int64{1}, Multiplier: 101},
	}
	for index, hook := range invalid {
		definition := valid
		definition.Hooks = []events.Hook{hook}
		if err := definition.Validate(); !errors.Is(err, events.ErrInvalidDefinition) {
			t.Fatalf("hook %d must be refused, got %v", index, err)
		}
	}
}

func TestShipped1008RequirementsCoverOnlyWithLazyAsset(t *testing.T) {
	raw, err := os.ReadFile("../../../content/events/definitions/1008.json")
	if err != nil {
		t.Fatal(err)
	}
	definition, err := events.ParseDefinition(raw)
	if err != nil {
		t.Fatal(err)
	}
	request := definition.ClientRequirements.CoversRequest()
	if len(request.ClientPaths) != 0 {
		t.Fatalf("1008 ships no client table of its own, got client paths %v", request.ClientPaths)
	}
	want := otadomain.LazyAsset{Path: "res/web/windows/activities/1008/1008.csb", MD5: "67433bf1269e1fb05b36471e3cc142fc"}
	if len(request.LazyAssets) != 1 || request.LazyAssets[0] != want {
		t.Fatalf("1008 lazy assets = %+v, want %+v", request.LazyAssets, want)
	}
	covered := otadomain.EvaluateCovers(request, nil, nil, func(asset otadomain.LazyAsset) bool { return asset == want })
	if covered.Status != otadomain.CoversCovered {
		t.Fatalf("a present lazy asset must cover: %+v", covered)
	}
	missing := otadomain.EvaluateCovers(request, nil, nil, func(otadomain.LazyAsset) bool { return false })
	if missing.Status != otadomain.CoversMissing || len(missing.MissingLazyAssets) != 1 || missing.MissingLazyAssets[0] != want {
		t.Fatalf("an absent lazy asset must be the exact missing asset: %+v", missing)
	}
}

func TestStateEdges(t *testing.T) {
	starts := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	ends := starts.Add(24 * time.Hour)
	claimUntil := ends.Add(24 * time.Hour)
	occurrence := events.Occurrence{StartsAt: starts, EndsAt: &ends, ClaimUntil: &claimUntil}
	cases := []struct {
		name string
		now  time.Time
		want events.Phase
	}{
		{"before start", starts.Add(-time.Nanosecond), events.PhaseScheduled},
		{"at start", starts, events.PhaseRunning},
		{"inside run", ends.Add(-time.Nanosecond), events.PhaseRunning},
		{"at end", ends, events.PhaseClaimWindow},
		{"inside claim window", claimUntil.Add(-time.Nanosecond), events.PhaseClaimWindow},
		{"at claim until", claimUntil, events.PhaseEnded},
		{"after claim until", claimUntil.Add(time.Hour), events.PhaseEnded},
	}
	for _, testCase := range cases {
		if got := occurrence.State(testCase.now); got != testCase.want {
			t.Fatalf("%s: got %s want %s", testCase.name, got, testCase.want)
		}
	}
}

func TestStatePermanentCancelledArchived(t *testing.T) {
	starts := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	permanent := events.Occurrence{StartsAt: starts}
	if permanent.State(starts.Add(-time.Hour)) != events.PhaseScheduled || permanent.State(starts) != events.PhaseRunning || permanent.State(starts.Add(1000*time.Hour)) != events.PhaseRunning {
		t.Fatal("permanent occurrence must run until ended")
	}
	cancelledAt := starts.Add(-time.Hour)
	cancelled := permanent
	cancelled.CancelledAt = &cancelledAt
	if cancelled.State(starts) != events.PhaseCancelled {
		t.Fatal("cancelled occurrence must stay cancelled")
	}
	settledAt := starts.Add(time.Hour)
	settled := permanent
	settled.SettledAt = &settledAt
	if settled.State(starts.Add(2*time.Hour)) != events.PhaseArchived {
		t.Fatal("settled occurrence must be archived")
	}
	if !permanent.Active(starts) || permanent.Active(starts.Add(-time.Hour)) {
		t.Fatal("Active must be RUNNING or CLAIM_WINDOW only")
	}
}
