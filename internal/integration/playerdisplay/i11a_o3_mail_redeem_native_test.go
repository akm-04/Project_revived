//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	opcatalogsource "gxb.local/backend/v2/internal/adapters/operatorcatalog"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func redeemService(p *pg.Pool) i5.Service {
	svc := compositeI5(p)
	svc.RedeemSecret = []byte("i11a-o3-native-redeem-secret-0001")
	return svc
}

func o3Catalogue(t *testing.T) operatorcatalog.Document {
	t.Helper()
	document, err := opcatalogsource.Load(clock.System{}.Now().UTC())
	if err != nil {
		t.Fatal(err)
	}
	return document
}

func o3Bus(t *testing.T, p *pg.Pool, mailOwner operatorgrant.MailOwner, redeemOwner operatorgrant.RedeemOwner) operator.Bus {
	t.Helper()
	catalogue := o3Catalogue(t)
	store := operatorstore.Store{}
	mailCommands := operatorgrant.MailCommands{Catalogue: catalogue, Store: store, Directory: i4store.PlayerDirectoryReader{}, Mail: mailOwner, LineCap: 1000}
	redeemCommands := operatorgrant.RedeemCommands{Catalogue: catalogue, Redeem: redeemOwner, LineCap: 1000}
	handlers := map[string]operator.Handler{}
	for name, handler := range mailCommands.Handlers() {
		handlers[name] = handler
	}
	for name, handler := range redeemCommands.Handlers() {
		handlers[name] = handler
	}
	return operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: store, Handlers: handlers}
}

func readMailRow(t *testing.T, p *pg.Pool, player identity.PlayerID, address mail.Address) (readAt, expiresAt *time.Time) {
	t.Helper()
	if err := p.QueryRow(ctx, `SELECT read_at,expires_at FROM mail_records WHERE recipient_player_id=$1 AND namespace=$2 AND wire_id=$3`, int64(player), address.Namespace.String(), address.WireID).Scan(&readAt, &expiresAt); err != nil {
		t.Fatal(err)
	}
	return readAt, expiresAt
}

func TestI11AO3InlineMailReplaysWithoutASecondMail(t *testing.T) {
	p := pool(t)
	mailOwner := compositeI5(p)
	bus := o3Bus(t, p, mailOwner, compositeI5(p))
	first, second := bornActor(t, p), bornActor(t, p)
	key := uuid().String()
	payload, err := json.Marshal(map[string]any{
		"target":      map[string]any{"player_ids": []int64{int64(first.PlayerID), int64(second.PlayerID)}},
		"title":       "Server gift",
		"body":        "Thank you for playing",
		"attachments": []map[string]any{{"id": "stack_item:50001010", "amount": 2}},
		"expire":      map[string]any{"after_read": 3600},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandMailSend, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "O3 inline native", SemanticKey: key}, payload)
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
	for _, player := range []identity.ActorContext{first, second} {
		list, err := mailOwner.ListMail(context.Background(), player, time.Now().UTC(), 20)
		if err != nil || list.Total != 1 || len(list.MailList) != 1 {
			t.Fatalf("mailbox %d = %+v err=%v", player.PlayerID, list, err)
		}
		if len(list.MailList[0].Attachments) != 1 || list.MailList[0].Attachments[0].Line.Amount != 2 {
			t.Fatalf("attachments = %+v", list.MailList[0].Attachments)
		}
	}
	replay, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	if !replay.Replayed {
		t.Fatalf("same key was not a replay: %+v", replay)
	}
	list, err := mailOwner.ListMail(context.Background(), first, time.Now().UTC(), 20)
	if err != nil || list.Total != 1 {
		t.Fatalf("replay doubled the mailbox: %+v err=%v", list, err)
	}
}

func TestI11AO3ServerMailThroughTheRiverPath(t *testing.T) {
	p := pool(t)
	mailOwner := compositeI5(p)
	bus := o3Bus(t, p, mailOwner, compositeI5(p))
	actors := make([]identity.ActorContext, 0, operatorgrant.InlineRecipientLimit+1)
	for i := 0; i <= operatorgrant.InlineRecipientLimit; i++ {
		actors = append(actors, bornActor(t, p))
	}
	key := uuid().String()
	payload, err := json.Marshal(map[string]any{
		"target": map[string]any{"server_id": 1},
		"title":  "Server mail",
		"body":   "River path",
		"expire": map[string]any{"on_read": true},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandMailSend, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "server:1", Reason: "O3 server native", SemanticKey: key}, payload)
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatal(err)
	}
	var submitted operatorgrant.GrantResult
	if err := json.Unmarshal(outcome.Result, &submitted); err != nil {
		t.Fatal(err)
	}
	if !submitted.Bulk || submitted.State != operatorgrant.StatePending || submitted.PlayerCount < len(actors) {
		t.Fatalf("submit = %+v", submitted)
	}
	applier := operatorgrant.Applier{Runner: tx.Runner{DB: p}, Operations: operation.Factory{Clock: clock.System{}}, Store: operatorstore.Store{}, Mail: mailOwner, Catalogue: o3Catalogue(t), LineCap: 1000}
	finished, err := applier.ApplyPending(context.Background())
	if err != nil || finished != 1 {
		t.Fatalf("apply finished=%d err=%v", finished, err)
	}
	read := operatorgrant.BulkReadService{Runner: tx.Runner{DB: p}, Operations: operation.Factory{Clock: clock.System{}}, Store: operatorstore.Store{}}
	progress, err := read.Show(context.Background(), key)
	if err != nil {
		t.Fatal(err)
	}
	if progress.State != operatorgrant.StateDone || progress.Refused != 0 || progress.Applied != submitted.PlayerCount {
		t.Fatalf("progress = %+v", progress)
	}
	for _, actor := range actors {
		list, err := mailOwner.ListMail(context.Background(), actor, time.Now().UTC(), 20)
		if err != nil || list.Total != 1 {
			t.Fatalf("server mail missing for %d: %+v err=%v", actor.PlayerID, list, err)
		}
	}
}

func TestI11AO3AfterReadAndOnReadExpiry(t *testing.T) {
	p := pool(t)
	svc := compositeI5(p)
	actor := bornActor(t, p)
	admin := i5.AdminOperator{ID: "root-op", ReasonCode: "O3 expiry native"}
	afterRead := int64(3600)
	created, err := svc.AdminSendMail(context.Background(), admin, actor.PlayerID, mail.Normal, "after-read", "Expiry", "GM", "read me", "operator-mail-v1", nil, nil, &afterRead, op())
	if err != nil {
		t.Fatal(err)
	}
	read, err := svc.ClaimMail(context.Background(), actor, created.Address, op())
	if err != nil || !read.Changed {
		t.Fatalf("read = %+v err=%v", read, err)
	}
	readAt, expiresAt := readMailRow(t, p, actor.PlayerID, created.Address)
	if readAt == nil || expiresAt == nil {
		t.Fatalf("read_at/expires_at = %v/%v", readAt, expiresAt)
	}
	if delta := expiresAt.Sub(*readAt); delta != time.Hour {
		t.Fatalf("expiry delta = %v", delta)
	}
	later, err := svc.ListMail(context.Background(), actor, expiresAt.Add(time.Minute), 20)
	if err != nil || later.Total != 0 {
		t.Fatalf("expired mail still listed: %+v err=%v", later, err)
	}

	zero := int64(0)
	opened, err := svc.AdminSendMail(context.Background(), admin, actor.PlayerID, mail.Normal, "on-read", "Opened", "GM", "open me", "operator-mail-v1", nil, nil, &zero, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.ClaimMail(context.Background(), actor, opened.Address, op()); err != nil {
		t.Fatal(err)
	}
	openedReadAt, openedExpiresAt := readMailRow(t, p, actor.PlayerID, opened.Address)
	if openedExpiresAt == nil || openedReadAt == nil || !openedExpiresAt.Equal(*openedReadAt) {
		t.Fatalf("on_read expiry = %v read = %v", openedExpiresAt, openedReadAt)
	}
	list, err := svc.ListMail(context.Background(), actor, time.Now().UTC().Add(time.Second), 20)
	if err != nil {
		t.Fatal(err)
	}
	for _, record := range list.MailList {
		if record.Address == opened.Address {
			t.Fatalf("on_read mail still listed: %+v", record)
		}
	}

	claimExpired := int64(600)
	expiring, err := svc.AdminSendMail(context.Background(), admin, actor.PlayerID, mail.Normal, "claim-expired", "Claim", "GM", "claim me", "operator-mail-v1", []grant.Line{{Kind: grant.StackItem, ItemID: 50001010, Amount: 1}}, nil, &claimExpired, op())
	if err != nil {
		t.Fatal(err)
	}
	// The read path sets the expiry from read_at; reproduce the state it leaves
	// once the delay has passed.
	exec(t, p, `UPDATE mail_records SET created_at=clock_timestamp()-interval '2 hours', read_at=clock_timestamp()-interval '1 hour', expires_at=clock_timestamp()-interval '1 minute' WHERE mail_uuid=$1::uuid`, expiring.MailUUID)
	if _, err := svc.ClaimMail(context.Background(), actor, expiring.Address, op()); !errors.Is(err, i5.ErrMailNotClaimable) {
		t.Fatalf("claim after expiry err = %v", err)
	}
}

func TestI11AO3RedeemCreateOnceDisableAndList(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	svc := redeemService(p)
	actor := bornActor(t, p)
	compositeLevel(t, p, actor, rev, 10)
	admin := i5.AdminOperator{ID: "root-op", ReasonCode: "O3 redeem native"}
	expires := time.Now().UTC().Add(24 * time.Hour)
	totalCap := int64(10)
	result, err := svc.OperatorCreateRedeem(context.Background(), admin, i5.RedeemCreateRequest{Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001010, Amount: 2}}, ExpiresAt: &expires, TotalCap: &totalCap}, op())
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Code) != 12 || result.PerSubjectCap != 1 || result.State != "ACTIVE" {
		t.Fatalf("create = %+v", result)
	}
	if _, err := svc.OperatorCreateRedeem(context.Background(), admin, i5.RedeemCreateRequest{Code: result.Code, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001010, Amount: 2}}}, op()); !errors.Is(err, i5.ErrRedeemCodeTaken) {
		t.Fatalf("duplicate code err = %v", err)
	}
	redeemOp := opPinned(rev)
	if _, err := svc.Redeem(context.Background(), actor, result.Code, "android", redeemOp); err != nil {
		t.Fatalf("first use: %v", err)
	}
	// Stock MID 230 carries no request nonce, so an identical retry by the same
	// player is the stored reply (D11 at-most-once), not a second grant.
	repeat, err := svc.Redeem(context.Background(), actor, result.Code, "android", opPinned(rev))
	if err != nil || !repeat.Replayed {
		t.Fatalf("second use = %+v err=%v", repeat, err)
	}
	stack, found, err := (i5store.Store{}).ReadStackTx(context.Background(), p, actor.PlayerID, 50001010)
	if err != nil || !found || stack.Quantity != 2 {
		t.Fatalf("second use granted again: %+v found=%v err=%v", stack, found, err)
	}

	second, err := svc.OperatorCreateRedeem(context.Background(), admin, i5.RedeemCreateRequest{Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001010, Amount: 1}}}, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.OperatorDisableRedeem(context.Background(), admin, second.Code, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Redeem(context.Background(), actor, second.Code, "android", redeemOp); !errors.Is(err, i5.ErrRedeemInvalid) {
		t.Fatalf("disabled code use err = %v", err)
	}
	if _, err := svc.OperatorDisableRedeem(context.Background(), admin, "NO-SUCH-CODE", op()); !errors.Is(err, i5.ErrRedeemUnknown) {
		t.Fatalf("unknown disable err = %v", err)
	}

	read := i5.OperatorRedeemRead{Runner: tx.Runner{DB: p}, Operations: operation.Factory{Clock: clock.System{}}, Store: i5store.Store{}}
	page, err := read.List(context.Background(), "", 1)
	if err != nil || len(page.Entries) != 1 || page.Next == "" {
		t.Fatalf("first page = %+v err=%v", page, err)
	}
	next, err := read.List(context.Background(), page.Next, 10)
	if err != nil || len(next.Entries) != 1 {
		t.Fatalf("next page = %+v err=%v", next, err)
	}
	var used int64
	for _, entry := range next.Entries {
		if entry.Code == result.Code {
			used = entry.UsedCount
			if entry.State != "ACTIVE" || len(entry.Lines) != 1 || entry.TotalCap == nil {
				t.Fatalf("entry = %+v", entry)
			}
		}
	}
	if used != 1 {
		t.Fatalf("used count = %d", used)
	}
}
