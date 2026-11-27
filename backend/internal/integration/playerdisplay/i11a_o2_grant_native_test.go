//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/adapters/operatorcatalog"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestI11AO2InlineGrantReplaysWithoutASecondEffect runs the real operator bus,
// the real i5 AdminGrant and the compiled catalogue over two born players.
func TestI11AO2InlineGrantReplaysWithoutASecondEffect(t *testing.T) {
	p := pool(t)
	catalogue, err := operatorcatalog.Load(clock.System{}.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	commands := operatorgrant.Commands{Catalogue: catalogue, Store: operatorstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Grants: compositeI5(p), LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	first, second := bornActor(t, p), bornActor(t, p)
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	payload, err := json.Marshal(map[string]any{
		"target": map[string]any{"player_ids": []int64{int64(first.PlayerID), int64(second.PlayerID)}},
		"lines":  []map[string]any{{"id": "stack_item:50001010", "amount": 2}},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandGrantItems, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "O2 inline native", SemanticKey: key.String()}, payload)
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	var result operatorgrant.GrantResult
	if err := json.Unmarshal(outcome.Result, &result); err != nil {
		t.Fatal(err)
	}
	if result.Bulk || result.Applied != 2 || result.Refused != 0 || outcome.Replayed {
		t.Fatalf("first result = %+v replayed=%v", result, outcome.Replayed)
	}
	for _, player := range []identity.PlayerID{first.PlayerID, second.PlayerID} {
		stack, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, player, 50001010)
		if err != nil || !found || stack.Quantity != 2 {
			t.Fatalf("stack %d = %+v found=%v err=%v", player, stack, found, err)
		}
	}
	replay, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed {
		t.Fatalf("same key was not a replay: %+v", replay)
	}
	stack, _, err := (i5store.Store{}).ReadStackTx(context.Background(), p, first.PlayerID, 50001010)
	if err != nil || stack.Quantity != 2 {
		t.Fatalf("replay doubled the stack: %+v err=%v", stack, err)
	}
}

// TestI11AO2GrantRefusalIsA409 proves the catalogue refusal reaches the bus as
// a typed permanent refusal.
func TestI11AO2GrantRefusalIsA409(t *testing.T) {
	p := pool(t)
	catalogue, err := operatorcatalog.Load(clock.System{}.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	commands := operatorgrant.Commands{Catalogue: catalogue, Store: operatorstore.Store{}, Grants: compositeI5(p), LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	player := bornActor(t, p)
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	payload, _ := json.Marshal(map[string]any{"target": map[string]any{"player_ids": []int64{int64(player.PlayerID)}}, "lines": []map[string]any{{"id": "stack_item:404", "amount": 1}}})
	command, err := operator.NewCommand(operatorgrant.CommandGrantItems, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "O2 refusal native", SemanticKey: key.String()}, payload)
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	if outcome.State != operator.StateRefused {
		t.Fatalf("state = %s", outcome.State)
	}
	var refusal operator.Refusal
	if err := json.Unmarshal(outcome.Result, &refusal); err != nil {
		t.Fatal(err)
	}
	if refusal.Code != operatorgrant.CodeGrantNotGrantable {
		t.Fatalf("refusal = %+v", refusal)
	}
	if _, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, player.PlayerID, 404); err != nil || found {
		t.Fatalf("refused grant created a stack: found=%v err=%v", found, err)
	}
}
