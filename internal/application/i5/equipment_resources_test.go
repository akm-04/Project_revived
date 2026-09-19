package i5

import (
	"context"
	"reflect"
	"testing"
)

func TestNeutralEquipmentResourceSeamPreservesAcceptedHeroMechanics(t *testing.T) {
	d, store, content, pid, op := heroEquipmentFixture(t)
	var neutral TxEquipmentResourceDebiter = d
	prepared, err := neutral.PrepareEquipmentResourcesTx(context.Background(), &testTx{}, pid, EquipmentResourceRequest{PotentialStackItemIDs: []int64{100, 20, 3}}, op)
	if err != nil {
		t.Fatal(err)
	}
	locks := append([]string(nil), store.lockTrace...)
	resolves := content.resolveCalls
	got, err := neutral.ApplyEquipmentResourceDebitTx(context.Background(), &testTx{}, prepared, EquipmentResourceDebit{
		Mana:   100,
		Stacks: []EquipmentStackDebit{{ItemID: 20, Count: 2}},
	})
	if err != nil {
		t.Fatal(err)
	}
	if got.Mana.Amount != 900 || got.PlayerLevel != 80 || store.stacks[20].Quantity != 5 {
		t.Fatalf("neutral result=%+v stack20=%+v", got, store.stacks[20])
	}
	if !reflect.DeepEqual(locks, store.lockTrace) || resolves != content.resolveCalls {
		t.Fatalf("neutral Apply discovered new read/lock: before=%v/%d after=%v/%d", locks, resolves, store.lockTrace, content.resolveCalls)
	}
}
