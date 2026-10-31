package i5

import (
	"context"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fixedAwakeningStore struct {
	AwakeningStore
	root objective.AwakeRoot
}

func (s fixedAwakeningStore) ReadAwakeningTx(context.Context, tx.Queryer, identity.PlayerID) (objective.AwakeRoot, error) {
	return s.root, nil
}

type fixedAwakeningContent struct{ catalog objective.AwakeCatalog }

func (c fixedAwakeningContent) AwakeningCatalogTx(context.Context, tx.Queryer, string) (objective.AwakeCatalog, error) {
	return c.catalog, nil
}

func occultMaterialService(active objective.AwakeInstance) Service {
	root := objective.NewAwakeRoot()
	root.Active[0] = active
	catalog := objective.AwakeCatalog{Definitions: []objective.AwakeDefinition{{ID: 1171001, Type: 1, Stage: 1}}}
	return Service{Awakening: &AwakeningRuntime{Store: fixedAwakeningStore{root: root}, Content: fixedAwakeningContent{catalog}, Heroes: struct{ AwakeningHeroes }{}, Pets: struct{ AwakeningPets }{}}}
}

func TestOccultMaterialFreezesByMissionOnlyForTheActiveOrdinaryOccurrence(t *testing.T) {
	active := objective.AwakeInstance{Mission: 1171001, Type: 1, OwnerID: 7, Generation: 3, Revision: strings.Repeat("ab", 32)}
	routes := []MaterialRoute{{Mission: 1171001, Item: 60001170, Count: 1}}
	ctx, player := context.Background(), identity.PlayerID(9)
	drop, err := occultMaterialService(active).FreezeAwakeningOccultMaterialTx(ctx, nil, player, routes)
	if err != nil || drop == nil || drop.ItemID != 60001170 || drop.Occurrence != active {
		t.Fatalf("drop=%+v err=%v", drop, err)
	}
	foreign := []MaterialRoute{{Mission: 1176001, Item: 60001174, Count: 1}}
	if drop, err = occultMaterialService(active).FreezeAwakeningOccultMaterialTx(ctx, nil, player, foreign); drop != nil || err != nil {
		t.Fatalf("a route for another mission must not freeze: %+v %v", drop, err)
	}
	finished := active
	finished.Complete = true
	if drop, err = occultMaterialService(finished).FreezeAwakeningOccultMaterialTx(ctx, nil, player, routes); drop != nil || err != nil {
		t.Fatalf("a finished mission gets nothing: %+v %v", drop, err)
	}
	if drop, err = occultMaterialService(objective.AwakeInstance{}).FreezeAwakeningOccultMaterialTx(ctx, nil, player, routes); drop != nil || err != nil {
		t.Fatalf("no active mission gets nothing: %+v %v", drop, err)
	}
	frozen := objective.AwakeFrozenDrop{Occurrence: active, ItemID: 60001170, Rate: 10000, Count: 1}
	if ok, err := occultMaterialService(active).CheckAwakeningOccultMaterialTx(ctx, nil, player, frozen); !ok || err != nil {
		t.Fatalf("same occurrence must revalidate: %v %v", ok, err)
	}
	moved := active
	moved.Generation = 4
	if ok, _ := occultMaterialService(moved).CheckAwakeningOccultMaterialTx(ctx, nil, player, frozen); ok {
		t.Fatal("a new generation must not honour the old freeze")
	}
	if _, err := occultMaterialService(active).CheckAwakeningPetMaterialTx(ctx, nil, player, frozen); err == nil {
		t.Fatal("an ordinary freeze is not pet material")
	}
}
