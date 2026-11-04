package builtin_test

import (
	"errors"
	"os"
	"reflect"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
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
		"schema version":      func(c *builtin.SocialInputCatalog) { c.SchemaVersion = 2 },
		"exchange limit":      func(c *builtin.SocialInputCatalog) { c.ExchangeLimit = 11 },
		"product count":       func(c *builtin.SocialInputCatalog) { c.ExchangeProducts = c.ExchangeProducts[:2] },
		"product gift":        func(c *builtin.SocialInputCatalog) { c.ExchangeProducts[0].GiftID = 99999999 },
		"dropbox weight":      func(c *builtin.SocialInputCatalog) { c.Dropboxes[0].Rolls[0].DropRate++ },
		"dropbox roll id":     func(c *builtin.SocialInputCatalog) { c.Dropboxes[0].Rolls[1].ID = c.Dropboxes[0].Rolls[0].ID },
		"recall gift dropbox": func(c *builtin.SocialInputCatalog) { c.RecallMilestones[0].GiftID = 90032001 },
		"mission threshold":   func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].Threshold = 1 },
		"mission reference":   func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].NextTaskIDs = []int64{999999} },
		"mission self cycle":  func(c *builtin.SocialInputCatalog) { c.InvitationMissions[0].NextTaskIDs = []int64{100001} },
		"mission type count":  func(c *builtin.SocialInputCatalog) { c.InvitationMissions[len(c.InvitationMissions)-1].Type = 3 },
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

func TestSourceSocialCatalogPlansThroughDomain(t *testing.T) {
	catalog := decodeSourceCatalog(t)
	exchangeCatalog := sourceExchangeCatalog(catalog)
	op := proofOperation(t)

	dropboxItems := make(map[int64]map[int64]struct{}, len(catalog.Dropboxes))
	for _, dropbox := range catalog.Dropboxes {
		items := make(map[int64]struct{}, len(dropbox.Rolls))
		for _, roll := range dropbox.Rolls {
			items[roll.ItemID] = struct{}{}
		}
		dropboxItems[dropbox.ID] = items
	}
	for _, product := range catalog.ExchangeProducts {
		plan, err := socialexchange.BuildPlan(exchangeCatalog, product.ID, 1, op)
		if err != nil {
			t.Fatalf("product %d plan: %v", product.ID, err)
		}
		if plan.UnitPrice != product.SellPrice || plan.TotalCost != product.SellPrice || plan.PriceCurrency != socialexchange.PriceCurrency {
			t.Fatalf("product %d cost wrong: %+v", product.ID, plan)
		}
		if len(plan.Items) == 0 {
			t.Fatalf("product %d planned no reward", product.ID)
		}
		items, found := dropboxItems[plan.DropboxID]
		if !found {
			t.Fatalf("product %d planned unknown dropbox %d", product.ID, plan.DropboxID)
		}
		for _, item := range plan.Items {
			if _, found := items[item.ItemID]; !found {
				t.Fatalf("product %d planned item %d outside its dropbox", product.ID, item.ItemID)
			}
			if item.ItemNum <= 0 {
				t.Fatalf("product %d planned non-positive quantity", product.ID)
			}
		}
	}

	second, err := socialexchange.BuildPlan(exchangeCatalog, 2, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(second.Items, []socialexchange.ItemQuantity{{ItemID: 50001046, ItemNum: 1}}) {
		t.Fatalf("source product 2 composite reward wrong: %+v", second.Items)
	}
	third, err := socialexchange.BuildPlan(exchangeCatalog, 3, 1, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(third.Items, []socialexchange.ItemQuantity{{ItemID: 50001024, ItemNum: 1}}) {
		t.Fatalf("source product 3 composite reward wrong: %+v", third.Items)
	}

	if _, err := socialexchange.BuildPlan(exchangeCatalog, 1, catalog.ExchangeLimit, op); err != nil {
		t.Fatalf("source exchange limit refused: %v", err)
	}
	if _, err := socialexchange.BuildPlan(exchangeCatalog, 1, catalog.ExchangeLimit+1, op); !errors.Is(err, socialexchange.ErrCount) {
		t.Fatalf("count above source limit accepted: %v", err)
	}
	if _, err := socialexchange.BuildPlan(exchangeCatalog, 999, 1, op); !errors.Is(err, socialexchange.ErrUnknownProduct) {
		t.Fatalf("unknown product accepted: %v", err)
	}
	retry, err := socialexchange.BuildPlan(exchangeCatalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	first, err := socialexchange.BuildPlan(exchangeCatalog, 1, 10, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, retry) {
		t.Fatalf("retry changed the source plan: %+v %+v", first, retry)
	}

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

func sourceExchangeCatalog(catalog builtin.SocialInputCatalog) socialexchange.Catalog {
	products := make([]socialexchange.Product, 0, len(catalog.ExchangeProducts))
	for _, product := range catalog.ExchangeProducts {
		products = append(products, socialexchange.Product{ID: product.ID, GiftID: product.GiftID, SellPrice: product.SellPrice})
	}
	gifts := make([]socialexchange.ExchangeGift, 0, len(catalog.ExchangeProducts))
	for _, gift := range catalog.Gifts {
		if len(gift.Drops) == 1 {
			gifts = append(gifts, socialexchange.ExchangeGift{ID: gift.ID, DropboxID: gift.Drops[0]})
		}
	}
	dropboxes := make([]socialexchange.Dropbox, 0, len(catalog.Dropboxes))
	for _, dropbox := range catalog.Dropboxes {
		rolls := make([]socialexchange.Drop, 0, len(dropbox.Rolls))
		for _, roll := range dropbox.Rolls {
			rolls = append(rolls, socialexchange.Drop{ID: roll.ID, ItemID: roll.ItemID, ItemNum: roll.ItemNum, Rate: roll.DropRate})
		}
		dropboxes = append(dropboxes, socialexchange.Dropbox{ID: dropbox.ID, Rolls: rolls})
	}
	return socialexchange.Catalog{ExchangeLimit: catalog.ExchangeLimit, Products: products, Gifts: gifts, Dropboxes: dropboxes}
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

func proofOperation(t *testing.T) operation.Context {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var seed [32]byte
	for index := range seed {
		seed[index] = byte(index + 1)
	}
	return operation.Context{ID: identifier, StartedAt: time.Unix(1_700_000_000, 0).UTC(), EntropySeed: seed}
}
