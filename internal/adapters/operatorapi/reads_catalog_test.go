package operatorapi

import (
	"context"
	"errors"
	"net/url"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
)

func catalogDocument(t *testing.T) operatorcatalog.Document {
	t.Helper()
	document, err := operatorcatalog.Build([]operatorcatalog.Resource{
		{DefinitionKey: "stack_item:20001001", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 20001001, ItemType: 1},
		{DefinitionKey: "stack_item:41001", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 41001, ItemType: 3},
		{DefinitionKey: "scalar_currency:crystal", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4"},
	}, nil, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	return document
}

func TestCatalogSearchFiltersByCategory(t *testing.T) {
	reply, err := CatalogSearch(catalogDocument(t))(context.Background(), url.Values{"category": {"1"}})
	if err != nil {
		t.Fatal(err)
	}
	page := reply.(operatorcatalog.SearchPage)
	if len(page.Entries) != 1 || page.Entries[0].ID != "stack_item:20001001" {
		t.Fatalf("category 1 page = %+v", page.Entries)
	}
	if len(page.Categories) != 2 || page.Categories[0].ItemType != 1 || page.Categories[1].ItemType != 3 {
		t.Fatalf("categories = %+v", page.Categories)
	}
}

func TestCatalogSearchFiltersBySubType(t *testing.T) {
	document, err := operatorcatalog.Build([]operatorcatalog.Resource{
		{DefinitionKey: "stack_item:50001040", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 50001040, ItemType: 4},
		{DefinitionKey: "stack_item:50000001", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 50000001, ItemType: 4},
	}, []operatorcatalog.ItemPresentation{
		{ID: 50001040, Name: "Stadium Star", SubType: 8, SkinHeroName: "Tennese"},
		{ID: 50000001, Name: "Potion", SubType: 1},
	}, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	skins, err := CatalogSearch(document)(context.Background(), url.Values{"category": {"4"}, "sub_type": {"8"}})
	if err != nil {
		t.Fatal(err)
	}
	page := skins.(operatorcatalog.SearchPage)
	if len(page.Entries) != 1 || page.Entries[0].ID != "stack_item:50001040" {
		t.Fatalf("skin page = %+v", page.Entries)
	}
	consumables, err := CatalogSearch(document)(context.Background(), url.Values{"category": {"4"}, "sub_type": {"0"}})
	if err != nil {
		t.Fatal(err)
	}
	page = consumables.(operatorcatalog.SearchPage)
	if len(page.Entries) != 1 || page.Entries[0].ID != "stack_item:50000001" {
		t.Fatalf("consumables page = %+v", page.Entries)
	}
}

func TestCatalogSearchRefusesAMalformedSubType(t *testing.T) {
	for _, raw := range []string{"-1", "abc"} {
		_, err := CatalogSearch(catalogDocument(t))(context.Background(), url.Values{"sub_type": {raw}})
		var refusal *operator.Refusal
		if err == nil || !errors.As(err, &refusal) || refusal.Code != operator.CodeReadInvalid {
			t.Fatalf("sub_type %q err = %v", raw, err)
		}
	}
}

func TestCatalogSearchRefusesAMalformedCategory(t *testing.T) {
	for _, raw := range []string{"-1", "abc"} {
		_, err := CatalogSearch(catalogDocument(t))(context.Background(), url.Values{"category": {raw}})
		var refusal *operator.Refusal
		if err == nil || !errors.As(err, &refusal) || refusal.Code != operator.CodeReadInvalid {
			t.Fatalf("category %q err = %v", raw, err)
		}
	}
}
