//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// G50: a skin item mailed by the operator reaches the bag on claim and the
// backpack entry the stock client uses (MID 60 SKIN_ON) writes the girl's
// entitlement, with the item's own duration as expiry.
func TestI11AG6b2MailedSkinItemUnlocksTheGirlEntitlement(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	actor := bornActor(t, p)
	unit := skillHero(t, p, actor, rev, 10001006, 7)
	service := compositeI5(p)
	bus := o3Bus(t, p, service, service)
	const timedSkinItem = 50001807
	const timedSkinModel = 40002006

	payload, err := json.Marshal(map[string]any{
		"target":      map[string]any{"player_ids": []int64{int64(actor.PlayerID)}},
		"title":       "Skin gift",
		"body":        "A temporary skin",
		"attachments": []map[string]any{{"id": "stack_item:50001807", "amount": 1}},
		"expire":      map[string]any{"after_read": 3600},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandMailSend, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "G6b2 skin delivery native", SemanticKey: uuid().String()}, payload)
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	if outcome.State != operator.StateApplied {
		t.Fatalf("mail.send state = %s", outcome.State)
	}
	list, err := service.ListMail(context.Background(), actor, time.Now().UTC(), 20)
	if err != nil || list.Total != 1 || len(list.MailList) != 1 {
		t.Fatalf("mailbox = %+v err=%v", list, err)
	}
	claimed, err := service.ClaimMail(context.Background(), actor, list.MailList[0].Address, op())
	if err != nil || !claimed.Changed {
		t.Fatalf("claim = %+v err=%v", claimed, err)
	}
	stack, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, actor.PlayerID, timedSkinItem)
	if err != nil || !found || stack.Quantity != 1 {
		t.Fatalf("skin stack = %+v found=%v err=%v", stack, found, err)
	}

	content := contentstore.Store{Queryer: p}
	appearance := hero.Service{Runner: tx.Runner{DB: p}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: characterstore.Store{Queryer: p}, Fencer: i5store.Store{Queryer: p}, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AppearanceMutationStore: characterstore.Store{Queryer: p}, AppearanceMutationContent: content, MaterialCosts: i5.MaterialCostDebiter{Store: i5store.Store{Queryer: p}, Content: content}}
	unlocked, err := appearance.SkinOn(context.Background(), actor, unit.PartnerID, timedSkinItem, op())
	if err != nil || !unlocked.Mutated || !unlocked.RemoveItem {
		t.Fatalf("SkinOn = %+v err=%v", unlocked, err)
	}
	stack, found, err = (i5store.Store{}).ReadStackTx(context.Background(), p, actor.PlayerID, timedSkinItem)
	if err != nil || found {
		t.Fatalf("skin stack after use = %+v found=%v err=%v", stack, found, err)
	}
	entitlements, err := (characterstore.Store{Queryer: p}).ListHeroSkinEntitlements(context.Background(), actor.PlayerID, unit.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	var entitlement *time.Time
	for index := range entitlements {
		if entitlements[index].ModelID == timedSkinModel {
			entitlement = entitlements[index].ExpiresAt
		}
	}
	if entitlement == nil {
		t.Fatalf("skin entitlement = %+v", entitlements)
	}
	if remaining := time.Until(*entitlement); remaining < 71*time.Hour || remaining > 73*time.Hour {
		t.Fatalf("skin expiry = %s, want the item's three days", *entitlement)
	}
}
