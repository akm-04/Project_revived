package builtin_test

import (
	"encoding/json"
	"errors"
	"os"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
)

func TestDecodeSocialInputCatalogRejectsMalformedPayload(t *testing.T) {
	for _, raw := range []string{
		`{}`,
		`{"schema_version":1} trailing`,
		`{"schema_version":1,"exchange_limit":10,"unknown":true}`,
	} {
		if _, err := builtin.DecodeSocialInputCatalog([]byte(raw)); !errors.Is(err, builtin.ErrSocialUnqualified) {
			t.Fatalf("malformed payload accepted: %s -> %v", raw, err)
		}
	}
}

func TestSocialInputCatalogValidationRefusesDrift(t *testing.T) {
	cases := map[string]func(*builtin.SocialInputCatalog){
		"gift dropbox":         func(c *builtin.SocialInputCatalog) { c.Gifts[0].Drops = []int64{999999} },
		"unreferenced dropbox": func(c *builtin.SocialInputCatalog) { c.Gifts[1].Drops = append([]int64(nil), c.Gifts[0].Drops...) },
		"schema version":       func(c *builtin.SocialInputCatalog) { c.SchemaVersion = 3 },
		"exchange limit":       func(c *builtin.SocialInputCatalog) { c.ExchangeLimit = 11 },
		"product count":        func(c *builtin.SocialInputCatalog) { c.ExchangeProducts = c.ExchangeProducts[:2] },
		"product gift":         func(c *builtin.SocialInputCatalog) { c.ExchangeProducts[0].GiftID = 99999999 },
		"dropbox weight":       func(c *builtin.SocialInputCatalog) { c.Dropboxes[0].Rolls[0].DropRate++ },
		"dropbox roll id":      func(c *builtin.SocialInputCatalog) { c.Dropboxes[0].Rolls[1].ID = c.Dropboxes[0].Rolls[0].ID },
		"recall gift dropbox":  func(c *builtin.SocialInputCatalog) { c.RecallMilestones[0].GiftID = 90032001 },
		"mission threshold":    func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].Threshold = 1 },
		"mission reference":    func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].NextTaskIDs = []int64{999999} },
		"mission self cycle":   func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].NextTaskIDs = []int64{100001} },
		"mission type count":   func(c *builtin.SocialInputCatalog) { c.InvitationMissions[len(c.InvitationMissions)-1].Type = 3 },
		"reward gift collision": func(c *builtin.SocialInputCatalog) {
			for index := range c.Gifts {
				if len(c.Gifts[index].Items) != 0 {
					c.Gifts[index].Items[0].ItemID = 90070002
					return
				}
			}
		},
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			catalog := decodeSourceCatalog(t)
			mutate(&catalog)
			if err := catalog.Validate(); !errors.Is(err, builtin.ErrSocialUnqualified) {
				t.Fatalf("drifted catalog accepted: %v", err)
			}
		})
	}
}

func TestSourceSocialCatalogPlansRecallThroughDomain(t *testing.T) {
	catalog := decodeSourceCatalog(t)
	summary := sourceCompletionSummary(t)
	if summary != (socialrecall.CompletionSummary{CompletedTargets: 3, AcademyLevel: 95, OwnedHeroCount: 20, ChargeTotal: 250}) {
		t.Fatalf("source completion summary wrong: %+v", summary)
	}
	groups := sourceMilestoneCategories(catalog)
	claimable, err := socialrecall.ClaimableByCategory(groups, nil, summary)
	if err != nil {
		t.Fatal(err)
	}
	expected := []int64{100001, 100002, 100005, 100007, 100008, 100009, 100011}
	if !slices.Equal(claimable, expected) {
		t.Fatalf("source category claim planning wrong: %v", claimable)
	}
}

func sourceMilestoneCategories(catalog builtin.SocialInputCatalog) []socialrecall.MilestoneCategory {
	categories := []socialrecall.Category{
		socialrecall.CategoryCompletedTargets,
		socialrecall.CategoryAcademyLevel,
		socialrecall.CategoryOwnedHeroCount,
		socialrecall.CategoryCharge,
	}
	groups := make([]socialrecall.MilestoneCategory, 0, len(categories))
	for _, category := range categories {
		group := socialrecall.MilestoneCategory{Category: category}
		for _, milestone := range catalog.RecallMilestones {
			if milestone.Type == int64(category) {
				group.Milestones = append(group.Milestones, socialrecall.Milestone{ID: milestone.ID, Threshold: milestone.Condition})
			}
		}
		groups = append(groups, group)
	}
	return groups
}

func sourceCompletionSummary(t *testing.T) socialrecall.CompletionSummary {
	t.Helper()
	baselines := []socialrecall.Baseline{
		{AcademyLevel: 90, OwnedHeroCount: 0, ChargeTotal: 0},
		{AcademyLevel: 50, OwnedHeroCount: 0, ChargeTotal: 0},
		{AcademyLevel: 91, OwnedHeroCount: 0, ChargeTotal: 0},
	}
	currents := []socialrecall.Baseline{
		{AcademyLevel: 95, OwnedHeroCount: 20, ChargeTotal: 250},
		{AcademyLevel: 0, OwnedHeroCount: 0, ChargeTotal: 0},
		{AcademyLevel: 0, OwnedHeroCount: 0, ChargeTotal: 0},
	}
	completed := make([]socialrecall.CompletedTarget, 0, len(baselines))
	for index, baseline := range baselines {
		identifier, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		task, err := socialrecall.NewTask(100001, identity.PlayerID(100002+index), 1, identifier, time.Unix(1_700_000_000, 0).UTC(), 3*24*time.Hour, baseline)
		if err != nil {
			t.Fatal(err)
		}
		done, completedNow, err := task.Complete(time.Unix(1_700_000_100, 0).UTC())
		if err != nil || !completedNow {
			t.Fatalf("source task did not complete: %v %v", completedNow, err)
		}
		completed = append(completed, socialrecall.CompletedTarget{Task: done, Current: currents[index]})
	}
	summary, err := socialrecall.SummarizeCompleted(100001, 1, completed)
	if err != nil {
		t.Fatal(err)
	}
	return summary
}

func decodeSourceCatalog(t *testing.T) builtin.SocialInputCatalog {
	t.Helper()
	path := os.Getenv("GXB_SOCIAL_CATALOG_PATH")
	if path == "" {
		t.Skip("exact Social compiler catalog not supplied")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := builtin.DecodeSocialInputCatalog(raw)
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestSocialRecallRulesAndHistoricalSchema(t *testing.T) {
	catalog := decodeSourceCatalog(t)
	if catalog.SchemaVersion != 2 || catalog.RecallRules == nil || catalog.RecallRules.Validate() != nil {
		t.Fatal("missing qualified recall settings", catalog.RecallRules)
	}
	original := *catalog.RecallRules
	for _, invalid := range []builtin.SocialRecallRules{{OfflineDays: 0, TaskDays: 3, MaxActiveTasks: 3}, {OfflineDays: 7, TaskDays: 0, MaxActiveTasks: 3}, {OfflineDays: 7, TaskDays: 3, MaxActiveTasks: 4}} {
		catalog.RecallRules = &invalid
		if catalog.Validate() == nil {
			t.Fatal("invalid settings accepted", invalid)
		}
	}
	catalog.RecallRules = &original
	catalog.SchemaVersion = 1
	if catalog.Validate() == nil {
		t.Fatal("legacy schema accepted new settings")
	}
	catalog.RecallRules = nil
	if err := catalog.Validate(); err != nil {
		t.Fatal("historical schema rejected", err)
	}
	raw, err := json.Marshal(catalog)
	if err != nil {
		t.Fatal(err)
	}
	decoded, err := builtin.DecodeSocialInputCatalog(raw)
	if err != nil || decoded.SchemaVersion != 1 || decoded.RecallRules != nil {
		t.Fatal("historical decoding changed", decoded.SchemaVersion, err)
	}
}
