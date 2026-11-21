package worldboss

import (
	"testing"

	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type (
	guardFresh       struct{ tx.Queryer }
	guardStore       struct{ Store }
	guardContent     struct{ Content }
	guardFence       struct{ Fence }
	guardPlayers     struct{ Players }
	guardDirectory   struct{ Directory }
	guardPopulation  struct{ Population }
	guardHeroes      struct{ Heroes }
	guardCombat      struct{ Combat }
	guardPrivileges  struct{ i5.PrivilegeSnapshotProvider }
	guardCosts       struct{ Costs }
	guardMail        struct{ Mail }
	guardReceipts    struct{ receipt.Store }
	guardReceiptRead struct{ receipt.Reader }
	guardBattleCount struct{ BattleCountObserver }
)

// The Girls Log observer is mandatory: a composition that omits it must fail
// closed at the readiness guard instead of nil-panicking inside a settlement.
func TestReadyRequiresTheGirlsLogObserver(t *testing.T) {
	mode := Mode{Fresh: guardFresh{}, Store: guardStore{}, Content: guardContent{}, Fence: guardFence{},
		Players: guardPlayers{}, Directory: guardDirectory{}, Population: guardPopulation{},
		Heroes: guardHeroes{}, Combat: guardCombat{}, Privileges: guardPrivileges{},
		Costs: guardCosts{}, Mail: guardMail{}, Receipts: guardReceipts{}, ReceiptRead: guardReceiptRead{}}
	if mode.ready() {
		t.Fatal("ready without the Girls Log observer")
	}
	mode.BattleCounts = guardBattleCount{}
	if !mode.ready() {
		t.Fatal("not ready with every port wired")
	}
}
