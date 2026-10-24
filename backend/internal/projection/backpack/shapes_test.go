package backpack

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestBuildUsesAcquiredAtAndDeterministicItemOrder(t *testing.T) {
	acquired := time.Unix(1_700_000_000, 0).UTC()
	updated := acquired.Add(3 * time.Hour)
	got, err := Build([]economy.StackState{
		{PlayerID: identity.PlayerID(100001), ItemID: 20, Quantity: 2, StateVersion: 4, AcquiredAt: acquired, UpdatedAt: updated},
		{PlayerID: identity.PlayerID(100001), ItemID: 10, Quantity: 7, StateVersion: 1, AcquiredAt: acquired.Add(time.Minute), UpdatedAt: updated},
	})
	if err != nil {
		t.Fatal(err)
	}
	list := got["list"].([]any)
	if len(list) != 2 {
		t.Fatalf("list len=%d", len(list))
	}
	first := list[0].(map[string]any)
	if first["table_id"] != int64(10) || first["item_num"] != int64(7) {
		t.Fatalf("unexpected first row: %#v", first)
	}
	second := list[1].(map[string]any)
	if second["time"] != acquired.Unix() {
		t.Fatalf("time=%v want acquired=%d", second["time"], acquired.Unix())
	}
	if second["time"] == updated.Unix() {
		t.Fatal("projection used UpdatedAt instead of AcquiredAt")
	}
	if spirit := got["spirit_list"].([]any); len(spirit) != 0 {
		t.Fatalf("spirit_list=%v", spirit)
	}
}
