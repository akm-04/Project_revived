//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// G27: equipment (client item type 1) and girl scrolls (type 3) are ordinary
// grantable stacks, so an operator mail carrying both is accepted and the
// claim settles both into the player's stacks.
func TestI11AG5aMailSendGrantsEquipmentAndGirlScroll(t *testing.T) {
	p := pool(t)
	service := compositeI5(p)
	bus := o3Bus(t, p, service, service)
	actor := bornActor(t, p)
	payload, err := json.Marshal(map[string]any{
		"target": map[string]any{"player_ids": []int64{int64(actor.PlayerID)}},
		"title":  "Equipment and scrolls",
		"body":   "Take these",
		"attachments": []map[string]any{
			{"id": "stack_item:20001001", "amount": 1},
			{"id": "stack_item:41001", "amount": 80},
		},
		"expire": map[string]any{"after_read": 3600},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandMailSend, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "G5a picker native", SemanticKey: uuid().String()}, payload)
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
	if outcome.State != operator.StateApplied || result.Applied != 1 || result.Refused != 0 {
		t.Fatalf("mail.send result = %+v state=%s", result, outcome.State)
	}
	list, err := service.ListMail(context.Background(), actor, time.Now().UTC(), 20)
	if err != nil || list.Total != 1 || len(list.MailList) != 1 {
		t.Fatalf("mailbox = %+v err=%v", list, err)
	}
	record := list.MailList[0]
	if len(record.Attachments) != 2 {
		t.Fatalf("attachments = %+v", record.Attachments)
	}
	if record.Attachments[0].Line.ItemID != 20001001 || record.Attachments[0].Line.Amount != 1 {
		t.Fatalf("first attachment = %+v", record.Attachments[0])
	}
	if record.Attachments[1].Line.ItemID != 41001 || record.Attachments[1].Line.Amount != 80 {
		t.Fatalf("second attachment = %+v", record.Attachments[1])
	}
	claimed, err := service.ClaimMail(context.Background(), actor, record.Address, op())
	if err != nil || !claimed.Changed {
		t.Fatalf("claim = %+v err=%v", claimed, err)
	}
	equipment, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, actor.PlayerID, 20001001)
	if err != nil || !found || equipment.Quantity != 1 {
		t.Fatalf("equipment stack = %+v found=%v err=%v", equipment, found, err)
	}
	scroll, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, actor.PlayerID, 41001)
	if err != nil || !found || scroll.Quantity != 80 {
		t.Fatalf("scroll stack = %+v found=%v err=%v", scroll, found, err)
	}
}

// G27: a horcrux (client item type 24) is a SPECIALIZED_DOMAIN fail-closed row,
// so the operator grant keeps refusing it with the catalogue code.
func TestI11AG5aHorcruxGrantIsRefused(t *testing.T) {
	p := pool(t)
	commands := operatorgrant.Commands{Catalogue: o3Catalogue(t), Store: operatorstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Grants: compositeI5(p), LineCap: 1000}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
	player := bornActor(t, p)
	payload, err := json.Marshal(map[string]any{
		"target": map[string]any{"player_ids": []int64{int64(player.PlayerID)}},
		"lines":  []map[string]any{{"id": "specialized:item:250000111", "amount": 1}},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandGrantItems, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "G5a horcrux refusal", SemanticKey: uuid().String()}, payload)
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
	if _, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, player.PlayerID, 250000111); err != nil || found {
		t.Fatalf("refused horcrux grant created a stack: found=%v err=%v", found, err)
	}
}
