package socialexchange

import (
	"encoding/json"
	domain "gxb.local/backend/v2/internal/domain/socialexchange"
	"reflect"
	"testing"
)

func sourceCatalog() domain.Catalog {
	return domain.Catalog{ExchangeLimit: 10, Products: []domain.Product{{ID: 1, GiftID: 11, SellPrice: 100}}, Gifts: []domain.ExchangeGift{{ID: 11, DropboxID: 21}}, Dropboxes: []domain.Dropbox{{ID: 21, Rolls: []domain.Drop{{ID: 1, ItemID: 31, ItemNum: 1, Rate: 10000}}}}}
}
func TestValidatedOverridePreservesSourceAndRejectsWholeInvalidPayload(t *testing.T) {
	source := sourceCatalog()
	raw := json.RawMessage(`{"version":1,"revision":"operator-1","products":[{"id":1,"off":false,"price":120,"limit":3,"items":[{"item_id":31,"item_num":2}]}]}`)
	catalog, off, revision := effectiveCatalog(source, 1, raw)
	if off || revision != "operator-1" || catalog.Products[0].SellPrice != 120 || catalog.ExchangeLimit != 3 || catalog.Dropboxes[0].Rolls[0].ItemNum != 2 {
		t.Fatal(catalog, off, revision)
	}
	if !reflect.DeepEqual(source, sourceCatalog()) {
		t.Fatal("source mutated")
	}
	for _, invalid := range []string{`{`, `{"version":1,"revision":"x","products":[{"id":1,"price":9223372036854775807}]}`, `{"version":1,"revision":"x","unknown":1}`, `{"version":1,"revision":"x","products":[{"id":2,"off":true}]}`, `{"version":1,"revision":"x","products":[{"id":1,"price":0}]}`, `{"version":1,"revision":"x","products":[{"id":1,"items":[{"item_id":999,"item_num":1}]}]}`} {
		catalog, off, revision = effectiveCatalog(source, 1, json.RawMessage(invalid))
		if off || revision != "source" || !reflect.DeepEqual(catalog, source) {
			t.Fatalf("invalid overlay did not fall back: %s", invalid)
		}
	}
	_, off, revision = effectiveCatalog(source, 1, json.RawMessage(`{"version":1,"revision":"off","products":[{"id":1,"off":true}]}`))
	if !off || revision != "off" {
		t.Fatal("off ignored")
	}
}

func TestValidatedOverrideMatrixKeepsSourcePolicyOnAnyInvalidOverlay(t *testing.T) {
	source := sourceCatalog()
	valid := `{"version":1,"revision":"ok","products":[{"id":1,"off":false,"price":120,"limit":3,"items":[{"item_id":31,"item_num":2}]}]}`
	invalid := []string{
		valid + `{}`,
		`{"version":2,"revision":"x","products":[{"id":1}]}`,
		`{"version":1,"revision":"","products":[{"id":1}]}`,
		`{"version":1,"revision":"x","products":[]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"perk":true}]}`,
		`{"version":1,"revision":"x","products":[{"id":1},{"id":1}]}`,
		`{"version":1,"revision":"x","products":[{"id":1},{"id":2,"off":true}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"limit":0}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"limit":11}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"price":-1}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"price":9223372036854775807,"limit":2}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"items":[{"item_id":31,"item_num":0}]}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"items":[{"item_id":31,"item_num":9223372036854775807,"limit":2}]}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"items":[{"item_id":31},{"item_id":31}]}]}`,
		`{"version":1,"revision":"x","products":[{"id":1,"items":[{"item_id":999,"item_num":1}]}]}`,
	}
	for _, payload := range invalid {
		catalog, off, revision := effectiveCatalog(source, 1, json.RawMessage(payload))
		if off || revision != "source" || !reflect.DeepEqual(catalog, source) {
			t.Fatalf("invalid overlay did not fall back: %s", payload)
		}
		if !reflect.DeepEqual(source, sourceCatalog()) {
			t.Fatal("source mutated")
		}
	}
	notSelected, off, revision := effectiveCatalog(source, 2, json.RawMessage(valid))
	if off || revision != "source" || !reflect.DeepEqual(notSelected, source) {
		t.Fatal("unselected product overlay applied")
	}
	tuned, off, revision := effectiveCatalog(source, 1, json.RawMessage(valid))
	if off || revision != "ok" || tuned.ExchangeLimit != 3 || tuned.Products[0].SellPrice != 120 || tuned.Products[0].GiftID != 11 || tuned.Dropboxes[0].Rolls[0].Rate != 10000 || tuned.Dropboxes[0].Rolls[0].ItemNum != 2 {
		t.Fatal("valid tuning lost source weights or identity", tuned, off, revision)
	}
}
