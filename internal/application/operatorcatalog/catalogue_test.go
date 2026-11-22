package operatorcatalog

import (
	"testing"
	"time"
)

func TestBuildJoinsClientNamesAndKeepsFailClosedRows(t *testing.T) {
	resources := []Resource{
		{DefinitionKey: "stack_item:50001010", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 50001010},
		{DefinitionKey: "scalar_currency:crystal", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4"},
		{DefinitionKey: "specialized:item:250000111", Class: "SPECIALIZED_DOMAIN", Activation: "FAIL_CLOSED", ItemID: 250000111},
		{DefinitionKey: "stack_item:999", Class: "STACK_ITEM", Activation: "FAIL_CLOSED", ItemID: 999},
	}
	items := []ItemPresentation{{ID: 50001010, Name: "Manga Toy", Icon: "images/icon/50001010_icon.png"}}
	document, err := Build(resources, items, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	if len(document.Entries) != 4 {
		t.Fatalf("entries = %d", len(document.Entries))
	}
	stack, found := document.Lookup("stack_item:50001010")
	if !found || stack.Grantable != GrantableEnabled || stack.Name != "Manga Toy" || stack.Icon == "" {
		t.Fatalf("stack entry = %+v", stack)
	}
	if stack.ItemID == nil || *stack.ItemID != 50001010 {
		t.Fatalf("stack item id = %v", stack.ItemID)
	}
	currency, _ := document.Lookup("scalar_currency:crystal")
	if currency.ItemID != nil {
		t.Fatalf("a definition without a client item id carries %v", *currency.ItemID)
	}
	if _, found := document.Lookup("specialized:item:250000111"); !found {
		t.Fatal("fail-closed resource dropped from the catalogue")
	}
	failClosed, _ := document.Lookup("specialized:item:250000111")
	if failClosed.Grantable != GrantableFailClosed || failClosed.Reason == "" {
		t.Fatalf("fail-closed entry = %+v", failClosed)
	}
	if document.ContentRevision == "" {
		t.Fatal("content revision missing")
	}
	second, err := Build(resources, items, time.Unix(200, 0))
	if err != nil {
		t.Fatal(err)
	}
	if second.ContentRevision != document.ContentRevision {
		t.Fatal("content revision moved with the export time")
	}
}

func TestGrantLineUsesTheCatalogueKind(t *testing.T) {
	document, err := Build([]Resource{
		{DefinitionKey: "stack_item:50001010", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 50001010},
		{DefinitionKey: "scalar_currency:crystal", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4"},
		{DefinitionKey: "player_exp:exp", Class: "PLAYER_EXP", Activation: "ENABLED_R5"},
		{DefinitionKey: "specialized:item:250000111", Class: "SPECIALIZED_DOMAIN", Activation: "FAIL_CLOSED", ItemID: 250000111},
	}, nil, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	line, _, ok := document.GrantLine("stack_item:50001010", 3)
	if !ok || line.Kind != "STACK_ITEM" || line.ItemID != 50001010 || line.Amount != 3 {
		t.Fatalf("stack line = %+v ok=%v", line, ok)
	}
	line, _, ok = document.GrantLine("scalar_currency:crystal", 5)
	if !ok || line.Kind != "SCALAR_CURRENCY" || line.ResourceKey != "crystal" {
		t.Fatalf("currency line = %+v ok=%v", line, ok)
	}
	if _, _, ok := document.GrantLine("specialized:item:250000111", 1); ok {
		t.Fatal("fail-closed resource grantable")
	}
	if _, _, ok := document.GrantLine("stack_item:404", 1); ok {
		t.Fatal("unknown resource grantable")
	}
}

func TestScalarPresentationAndRarity(t *testing.T) {
	resources := []Resource{
		{DefinitionKey: "stack_item:1", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 1},
		{DefinitionKey: "scalar_currency:mana", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4", ResourceKey: "mana"},
		{DefinitionKey: "player_exp:exp", Class: "PLAYER_EXP", Activation: "ENABLED_R5", ResourceKey: "exp"},
		{DefinitionKey: "scalar_currency:degree_cer", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4", ResourceKey: "degree_cer"},
	}
	items := []ItemPresentation{{ID: 1, Name: "Item", Icon: "images/icon/1.png", Quality: 5}}
	document, err := Build(resources, items, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	item, _ := document.Lookup("stack_item:1")
	if item.Rarity != 5 || item.Icon == "" {
		t.Fatalf("item entry = %+v", item)
	}
	mana, _ := document.Lookup("scalar_currency:mana")
	if mana.Name != "Coin(s)" || mana.Icon != "images/icon/eco/jinbi.png" {
		t.Fatalf("mana entry = %+v", mana)
	}
	exp, _ := document.Lookup("player_exp:exp")
	if exp.Name != "" || exp.Icon != "images/icon/eco/exp.png" {
		t.Fatalf("exp entry = %+v", exp)
	}
	unnamed, _ := document.Lookup("scalar_currency:degree_cer")
	if unnamed.Name != "" || unnamed.Icon != "" {
		t.Fatalf("a resource the client does not present carries %+v", unnamed)
	}
	rarity := int64(5)
	page, err := document.Search(SearchFilter{Rarity: &rarity})
	if err != nil || len(page.Entries) != 1 || page.Entries[0].ID != "stack_item:1" {
		t.Fatalf("rarity search = %+v err=%v", page, err)
	}
	absent := int64(3)
	page, err = document.Search(SearchFilter{Rarity: &absent})
	if err != nil || len(page.Entries) != 0 {
		t.Fatalf("absent rarity search = %+v err=%v", page, err)
	}
}

func TestSearchPagesAndFilters(t *testing.T) {
	document, err := Build([]Resource{
		{DefinitionKey: "stack_item:1", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 1},
		{DefinitionKey: "stack_item:2", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 2},
		{DefinitionKey: "scalar_currency:crystal", Class: "SCALAR_CURRENCY", Activation: "ENABLED_R4"},
	}, []ItemPresentation{{ID: 2, Name: "Juice"}}, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	page, err := document.Search(SearchFilter{Limit: 2})
	if err != nil || len(page.Entries) != 2 || page.NextAfter == "" {
		t.Fatalf("first page = %+v err=%v", page, err)
	}
	next, err := document.Search(SearchFilter{Limit: 2, After: page.NextAfter})
	if err != nil || len(next.Entries) != 1 || next.NextAfter != "" {
		t.Fatalf("second page = %+v err=%v", next, err)
	}
	byName, err := document.Search(SearchFilter{Query: "juice"})
	if err != nil || len(byName.Entries) != 1 || byName.Entries[0].ID != "stack_item:2" {
		t.Fatalf("name search = %+v err=%v", byName, err)
	}
	byKind, err := document.Search(SearchFilter{Kind: "SCALAR_CURRENCY"})
	if err != nil || len(byKind.Entries) != 1 {
		t.Fatalf("kind search = %+v err=%v", byKind, err)
	}
	byItemID, err := document.Search(SearchFilter{Query: "2"})
	if err != nil || len(byItemID.Entries) != 1 || byItemID.Entries[0].ID != "stack_item:2" {
		t.Fatalf("numeric item id search = %+v err=%v", byItemID, err)
	}
	noNumeric, err := document.Search(SearchFilter{Query: "777"})
	if err != nil || len(noNumeric.Entries) != 0 {
		t.Fatalf("unknown numeric search = %+v err=%v", noNumeric, err)
	}
	if _, err := document.Search(SearchFilter{Limit: 201}); err == nil {
		t.Fatal("over-limit search accepted")
	}
}
