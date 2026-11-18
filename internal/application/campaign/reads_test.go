package campaign

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type starsStore struct {
	Store
	record d.Record
}

func (s starsStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Record, error) {
	return s.record, nil
}

type starsContent struct {
	Content
	catalog d.Catalog
}

func (s starsContent) CampaignCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return s.catalog, nil
}

func builtinCatalog(t *testing.T) d.Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/campaign_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog d.Catalog
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err = decoder.Decode(&catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func TestMainChainStarsSumsNormalSuperAndChallenge(t *testing.T) {
	catalog := builtinCatalog(t)
	progress := d.Progress{Nodes: map[int64]d.NodeState{}}
	for _, kind := range []int64{d.Normal, d.Super, d.Challenge} {
		chain := catalog.Chain(kind)
		if len(chain) == 0 {
			t.Fatalf("kind %d has no chain", kind)
		}
		progress.Nodes[chain[0]] = d.NodeState{CampaignID: chain[0], Star: 2}
	}
	mode := Mode{Store: starsStore{record: d.Record{Progress: progress}}, Content: starsContent{catalog: catalog}}
	stars, err := mode.MainChainStarsTx(context.Background(), nil, identity.PlayerID(100001), "unused")
	if err != nil || stars != 6 {
		t.Fatalf("stars = %d, err %v", stars, err)
	}
}
