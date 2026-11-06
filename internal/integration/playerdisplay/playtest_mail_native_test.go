//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
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

	// AdminGrant is the system settlement producer: its overflow mail waits
	// without an expiry until the owner's next login stamps one.
	admin := genuineGrants(p)
	admin.Audit = audit.NopEmitter{}
	if _, err = admin.AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "i9-10-playtest-system", []grant.Line{{Kind: grant.StackItem, ItemID: item, Amount: 3}}, opPinned(revision)); err != nil {
		t.Fatalf("system overflow grant: %v", err)
	}
	beforeLogin, _, _, err := values.ListMail(ctx, a.PlayerID, time.Now().UTC(), 20)
	if err != nil {
		t.Fatal(err)
	}
	var systemMail *mail.Record
	for index := range beforeLogin {
		if beforeLogin[index].SourceKind == "GRANT_OVERFLOW" && beforeLogin[index].ExpiresAt == nil {
			systemMail = &beforeLogin[index]
			break
		}
	}
	if systemMail == nil {
		t.Fatal("system overflow mail not written")
	}
	if systemMail.ClaimedAt != nil {
		t.Fatalf("system overflow mail claimed: %+v", systemMail)
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
		if record.MailUUID != systemMail.MailUUID {
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

func TestPlaytestClaimedMailHiddenFromListAndCounts(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	values := i5store.Store{Queryer: p}
	mailService := i5.SettlementMail{Store: values}
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	addresses := make([]mail.Address, 0, 6)
	for index := range 5 {
		record, _, deliverErr := mailService.DeliverTx(ctx, transaction, i5.SettlementMailRequest{Recipient: a.PlayerID, SourceKind: "PLAYTEST_MAIL", SourceKey: fmt.Sprintf("attachment-%d", index), Title: "Playtest attachment", Sender: "Academy", Body: "Claim this reward", PolicyVersion: "i9-10-playtest-v1", Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50005182, Amount: 1}}, At: time.Now().UTC()})
		if deliverErr != nil {
			transaction.Rollback(ctx)
			t.Fatal(deliverErr)
		}
		addresses = append(addresses, record.Address)
	}
	readOnly, _, err := mailService.DeliverNoticeTx(ctx, transaction, i5.SettlementMailRequest{Recipient: a.PlayerID, SourceKind: "PLAYTEST_MAIL", SourceKey: "read-only", Title: "Playtest notice", Sender: "Academy", Body: "Read this notice", PolicyVersion: "i9-10-playtest-v1", At: time.Now().UTC()})
	if err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	addresses = append(addresses, readOnly.Address)
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	dispatcher := stockruntime.I5Dispatcher{Authority: playtestAuthority{a}, Service: genuineGrants(p)}
	claim := func(address mail.Address) httpedge.Response {
		return dispatcher.Dispatch(ctx, playtestRequest(a, 369, map[string]any{"id": address.WireID, "is_region": false}))
	}
	if response := claim(addresses[0]); response.HTTPStatus != 200 {
		t.Fatalf("single claim: %+v", response)
	}
	batch := dispatcher.Dispatch(ctx, playtestRequest(a, 370, map[string]any{"normal_ids": strconv.FormatInt(addresses[1].WireID, 10) + "|" + strconv.FormatInt(addresses[2].WireID, 10), "region_ids": ""}))
	if batch.HTTPStatus != 200 {
		t.Fatalf("batch claim: %+v", batch)
	}
	if response := claim(addresses[1]); response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("single after batch should be a conflict: %+v", response)
	}
	page := dispatcher.Dispatch(ctx, playtestRequest(a, 368, map[string]any{"load_num": int64(2)}))
	if page.HTTPStatus != 200 || page.Body["total"] != int64(3) || page.Body["new_mail_total"] != int64(3) {
		t.Fatalf("paged mail counts: %+v", page)
	}
	rows, ok := page.Body["mail_list"].([]any)
	if !ok || len(rows) != 2 {
		t.Fatalf("mail page: %#v", page.Body["mail_list"])
	}
	if scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='PLAYTEST_MAIL'`, int64(a.PlayerID)) != 6 ||
		scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='PLAYTEST_MAIL' AND NOT shown`, int64(a.PlayerID)) != 3 {
		t.Fatal("hidden claimed mail rows were deleted or not hidden")
	}
	batchPage, ok := batch.Body["mail_list"].(map[string]any)
	batchRows, rowsOK := batchPage["mail_list"].([]any)
	if !ok || !rowsOK || len(batchRows) != 3 || batchPage["total"] != int64(3) || batchPage["new_mail_total"] != int64(3) {
		t.Fatalf("batch response counts: %#v", batch.Body)
	}
}
