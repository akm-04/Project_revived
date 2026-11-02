//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPlaytestOverflowMailIsOpenableClaimableAndExpires(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	values := i5store.Store{Queryer: p}
	svc := genuineGrants(p)

	item := int64(50005182)
	resolved, err := (contentstore.Store{}).ResolveResourceTx(ctx, p, revision, grant.Line{Kind: grant.StackItem, ItemID: item, Amount: 1})
	if err != nil || resolved.Stack == nil {
		t.Fatalf("fixture stack item unresolved: %v", err)
	}
	capacity := resolved.Stack.StackCap
	existing := stackQuantity(t, p, a.PlayerID, item)
	if existing < capacity {
		grantGenuine(t, p, a, revision, "playtest mail full stack", []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: capacity - existing}})
	}
	if got := stackQuantity(t, p, a.PlayerID, item); got != capacity {
		t.Fatalf("fixture stack not full: %d/%d", got, capacity)
	}

	o := opPinned(revision)
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i9-10-playtest", Operation: "overflow", BusinessKey: "overflow-mail", Occurrence: o.ID.String(), PolicyVersion: "i9-10-playtest-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: 3}}}
	before := time.Now().UTC()
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = svc.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{AllowOverflowMail: true}); err != nil {
		tr.Rollback(ctx)
		t.Fatalf("overflow grant: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	listed, _, _, err := values.ListMail(ctx, a.PlayerID, time.Now().UTC(), 20)
	if err != nil {
		t.Fatal(err)
	}
	var overflow *mail.Record
	for index := range listed {
		if listed[index].SourceKind == "GRANT_OVERFLOW" {
			overflow = &listed[index]
			break
		}
	}
	if overflow == nil {
		t.Fatal("overflow mail not listed")
	}
	if overflow.Title != "Items exceed capacity" || overflow.Sender != "Academy" || overflow.Body == "" {
		t.Fatalf("overflow mail text: %+v", overflow)
	}
	if overflow.ExpiresAt == nil || overflow.ExpiresAt.Before(before.Add(59*time.Minute)) || overflow.ExpiresAt.After(before.Add(61*time.Minute)) {
		t.Fatalf("own-request overflow expiry: %v", overflow.ExpiresAt)
	}

	// Make room for one unit so the confirmed claim is a partial fit.
	exec(t, p, `UPDATE player_item_stacks SET quantity=$3,updated_at=clock_timestamp() WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), item, capacity-1)
	claimed, err := svc.ClaimMail(ctx, a, overflow.Address, op())
	if err != nil {
		t.Fatalf("partial claim: %v", err)
	}
	if got := stackQuantity(t, p, a.PlayerID, item); got != capacity {
		t.Fatalf("claim did not save the fitting unit: %d/%d", got, capacity)
	}
	if len(claimed.Rewards) != 1 || claimed.Rewards[0].ItemNum != 1 {
		t.Fatalf("claim reported the discarded excess: %#v", claimed.Rewards)
	}
	after, _, _, err := values.ListMail(ctx, a.PlayerID, time.Now().UTC(), 20)
	if err != nil {
		t.Fatal(err)
	}
	for _, record := range after {
		if record.MailUUID == overflow.MailUUID && record.ClaimedAt == nil {
			t.Fatal("claimed overflow mail is still unclaimed")
		}
	}

	ordinaryAt := time.Now().UTC()
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err = (i5.SettlementMail{Store: values}).DeliverTx(ctx, tr, i5.SettlementMailRequest{Recipient: a.PlayerID, SourceKind: "PLAYTEST_SETTLEMENT", SourceKey: "ordinary", Title: "Playtest reward", Sender: "Academy", Body: "ordinary reward body", PolicyVersion: "i9-10-playtest-v1", Lines: []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: 1}}, At: ordinaryAt}); err != nil {
		tr.Rollback(ctx)
		t.Fatalf("settlement mail: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	ordinaryList, _, _, err := values.ListMail(ctx, a.PlayerID, time.Now().UTC(), 20)
	if err != nil {
		t.Fatal(err)
	}
	ordinary := false
	for _, record := range ordinaryList {
		if record.SourceKind != "PLAYTEST_SETTLEMENT" {
			continue
		}
		ordinary = true
		if record.Title == "" || record.Body == "" {
			t.Fatalf("ordinary mail text: %+v", record)
		}
		if record.ExpiresAt == nil || record.ExpiresAt.Before(ordinaryAt.Add(7*24*time.Hour-time.Second)) || record.ExpiresAt.After(ordinaryAt.Add(7*24*time.Hour+time.Second)) {
			t.Fatalf("ordinary expiry: %v want %v", record.ExpiresAt, ordinaryAt.Add(7*24*time.Hour))
		}
	}
	if !ordinary {
		t.Fatal("settlement mail not listed")
	}

	// A grant settled for a recipient by later system code writes NULL and the
	// login reconciler stamps it. There is no present producer of that shape, so
	// the fixture writes the row directly.
	sourceKey := fmt.Sprintf("offline:%d", a.PlayerID)
	nilExpiry := mail.Record{MailUUID: mustUUID(t), Recipient: a.PlayerID, Address: mail.Address{Namespace: mail.Normal, WireID: 901}, SourceKind: "GRANT_OVERFLOW", SourceKey: sourceKey, Title: "Items exceed capacity", Sender: "Academy", Body: "offline fixture", CreatedAt: time.Now().UTC(), Shown: true, Platform: mail.AnyPlatform, CompatibilityPolicyVersion: "i9-10-playtest-v1", StateVersion: 1, Attachments: []mail.Attachment{{Ordinal: 0, Line: grant.Line{Kind: grant.StackItem, ItemID: item, Amount: 1}}}}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = values.InsertMailTx(ctx, tr, nilExpiry); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	loginAt := time.Now().UTC().Add(time.Minute)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = (i5.MailExpiryLoginReconciler{Store: values}).ReconcileCharacterLogin(ctx, tr, a, op(), loginAt); err != nil {
		tr.Rollback(ctx)
		t.Fatalf("login reconcile: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	reconciled, _, _, err := values.ListMail(ctx, a.PlayerID, time.Now().UTC(), 20)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, record := range reconciled {
		if record.SourceKey != sourceKey {
			continue
		}
		found = true
		if record.ExpiresAt == nil || record.ExpiresAt.Before(loginAt.Add(time.Hour-time.Millisecond)) || record.ExpiresAt.After(loginAt.Add(time.Hour+time.Millisecond)) {
			t.Fatalf("login stamp: %v want %v", record.ExpiresAt, loginAt.Add(time.Hour))
		}
	}
	if !found {
		t.Fatal("reconciled mail not listed")
	}
}

func mustUUID(t *testing.T) ids.UUID {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return id
}
