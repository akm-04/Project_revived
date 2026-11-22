package operatorgrant

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recordedMail struct {
	player    int64
	key       string
	title     string
	body      string
	lines     []grant.Line
	expires   *time.Time
	afterRead *int64
}

type fakeMail struct {
	byKey        map[string]bool
	calls        []recordedMail
	effects      []int64
	failAt       int64
	failuresLeft int
	err          error
}

func (f *fakeMail) AdminSendMail(ctx context.Context, admin appi5.AdminOperator, target identity.PlayerID, ns mail.Namespace, key, title, sender, body, policy string, lines []grant.Line, expires *time.Time, afterRead *int64, op operation.Context) (appi5.AdminMailResult, error) {
	return f.AdminSendMailTx(ctx, nil, admin, target, ns, key, title, sender, body, policy, lines, expires, afterRead, op)
}

func (f *fakeMail) AdminSendMailTx(_ context.Context, _ tx.Tx, _ appi5.AdminOperator, target identity.PlayerID, _ mail.Namespace, key, title, _ string, body, _ string, lines []grant.Line, expires *time.Time, afterRead *int64, _ operation.Context) (appi5.AdminMailResult, error) {
	f.calls = append(f.calls, recordedMail{player: int64(target), key: key, title: title, body: body, lines: lines, expires: expires, afterRead: afterRead})
	if int64(target) == f.failAt && f.failuresLeft > 0 {
		f.failuresLeft--
		return appi5.AdminMailResult{}, f.err
	}
	if f.byKey == nil {
		f.byKey = map[string]bool{}
	}
	if !f.byKey[key] {
		f.byKey[key] = true
		f.effects = append(f.effects, int64(target))
	}
	return appi5.AdminMailResult{}, nil
}

func mailCommand(t *testing.T, key string, payload any) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(CommandMailSend, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "mail native", SemanticKey: key}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func mailPayloadFor(ids []int64, expire map[string]any) map[string]any {
	return map[string]any{
		"target":      map[string]any{"player_ids": ids},
		"title":       "Server gift",
		"body":        "Thank you for playing",
		"attachments": []map[string]any{{"id": "stack_item:50001010", "amount": 2}},
		"expire":      expire,
	}
}

func TestMailSendRefusesValidationAndCatalogue(t *testing.T) {
	cases := []struct {
		name    string
		payload map[string]any
		code    string
	}{
		{"empty title", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "", "body": "b", "expire": map[string]any{"on_read": true}}, CodeMailTitle},
		{"long title", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": string(make([]rune, MaxMailTitleRunes+1)), "body": "b", "expire": map[string]any{"on_read": true}}, CodeMailTitle},
		{"empty body", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "", "expire": map[string]any{"on_read": true}}, CodeMailBody},
		{"no expire", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b"}, CodeMailExpire},
		{"two forms", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"on_read": true, "after_read": 5}}, CodeMailExpire},
		{"past fixed", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"fixed": time.Unix(1, 0).UTC().Format(time.RFC3339)}}, CodeMailExpire},
		{"bad fixed", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"fixed": "tomorrow"}}, CodeMailExpire},
		{"negative after read", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"after_read": -1}}, CodeMailExpire},
		{"on read false", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"on_read": false}}, CodeMailExpire},
		{"unknown attachment", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"on_read": true}, "attachments": []map[string]any{{"id": "stack_item:404", "amount": 1}}}, CodeGrantNotGrantable},
		{"zero amount", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "title": "t", "body": "b", "expire": map[string]any{"on_read": true}, "attachments": []map[string]any{{"id": "stack_item:50001010", "amount": 0}}}, CodeGrantAmount},
		{"bad target", map[string]any{"target": map[string]any{"global": true, "server_id": 1}, "title": "t", "body": "b", "expire": map[string]any{"on_read": true}}, CodeGrantTarget},
	}
	commands := MailCommands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Mail: &fakeMail{}, LineCap: 10}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			_, err := commands.sendHandler(context.Background(), testScope(), mailCommand(t, testCase.name, testCase.payload))
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) || refusal.Code != testCase.code {
				t.Fatalf("error = %v, want %s", err, testCase.code)
			}
		})
	}
}

func TestMailSendInlineDeliversEachRecipientOnceWithItsOwnKey(t *testing.T) {
	deliveries := &fakeMail{}
	commands := MailCommands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Mail: deliveries, LineCap: 10}
	payload := mailPayloadFor([]int64{2, 1}, map[string]any{"after_read": 60})
	for run := 0; run < 2; run++ {
		outcome, err := commands.sendHandler(context.Background(), testScope(), mailCommand(t, "mail-inline-1", payload))
		if err != nil {
			t.Fatal(err)
		}
		if result := outcome.(GrantResult); result.Bulk || result.Applied != 2 {
			t.Fatalf("run %d result = %+v", run, result)
		}
	}
	if len(deliveries.calls) != 4 {
		t.Fatalf("deliveries = %d", len(deliveries.calls))
	}
	keys := map[string]bool{}
	for _, call := range deliveries.calls {
		keys[call.key] = true
		if call.afterRead == nil || *call.afterRead != 60 {
			t.Fatalf("after_read = %v", call.afterRead)
		}
		if call.expires != nil {
			t.Fatalf("after_read delivery also carried an absolute expiry: %v", call.expires)
		}
	}
	if len(keys) != 2 {
		t.Fatalf("recipient keys = %v", keys)
	}
	if len(deliveries.effects) != 2 {
		t.Fatalf("effects = %d, want one per recipient", len(deliveries.effects))
	}
}

func TestMailSendFreezesAJobAboveTheInlineLimit(t *testing.T) {
	ids := make([]int64, 0, InlineRecipientLimit+1)
	for i := 1; i <= InlineRecipientLimit+1; i++ {
		ids = append(ids, int64(i))
	}
	store := &fakeStore{}
	deliveries := &fakeMail{}
	commands := MailCommands{Catalogue: testCatalogue(t), Store: store, Mail: deliveries, LineCap: 10}
	outcome, err := commands.sendHandler(context.Background(), testScope(), mailCommand(t, "mail-bulk-1", mailPayloadFor(ids, map[string]any{"on_read": true})))
	if err != nil {
		t.Fatal(err)
	}
	if result := outcome.(GrantResult); !result.Bulk || result.PlayerCount != InlineRecipientLimit+1 || result.State != StatePending {
		t.Fatalf("result = %+v", result)
	}
	if len(deliveries.calls) != 0 {
		t.Fatalf("bulk submit delivered inline: %d calls", len(deliveries.calls))
	}
	frozen := store.rows["mail-bulk-1"]
	if frozen.ModuleCommand != CommandMailSend || frozen.PlayerIDsSHA256 == "" || !reflect.DeepEqual(frozen.PlayerIDs, ids) {
		t.Fatalf("frozen = %+v", frozen)
	}
}

func testMailBulkTarget(t *testing.T, key string, ids []int64, payload any) BulkTarget {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	return BulkTarget{SemanticKey: key, ModuleCommand: CommandMailSend, Selector: "players", PlayerIDs: ids, PlayerCount: len(ids), PlayerIDsSHA256: sha256IDs(ids), Payload: raw, Principal: "root-op", Reason: "mail bulk", State: StatePending, CreatedAt: time.Unix(500, 0).UTC()}
}

func mailApplier(t *testing.T, store BulkStore, deliveries *fakeMail) Applier {
	t.Helper()
	return Applier{Runner: tx.Runner{DB: fakeBeginner{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, Mail: deliveries, Catalogue: testCatalogue(t), LineCap: 10}
}

func TestApplyPendingMailResumesATransientRecipientAndShowsLastError(t *testing.T) {
	ids := []int64{11, 22, 33}
	payload := mailPayloadFor(ids, map[string]any{"after_read": 60})
	store := &fakeStore{rows: map[string]BulkTarget{"mail-transient": testMailBulkTarget(t, "mail-transient", ids, payload)}}
	deliveries := &fakeMail{failAt: 22, failuresLeft: 1, err: errors.New("connection reset")}
	applier := mailApplier(t, store, deliveries)

	if _, err := applier.ApplyPending(context.Background()); err == nil {
		t.Fatal("a transient recipient fault must stop the run and be retried")
	}
	saved := store.rows["mail-transient"]
	if saved.Processed != 1 || saved.Applied != 1 || saved.State != StatePending || saved.LastError != "connection reset" {
		t.Fatalf("cursor after the transient fault = %+v", saved)
	}
	progress := progressOf(saved)
	if progress.LastError != "connection reset" {
		t.Fatalf("operator.bulk.show last_error = %q", progress.LastError)
	}
	if _, err := applier.ApplyPending(context.Background()); err != nil {
		t.Fatal(err)
	}
	final := store.rows["mail-transient"]
	if final.State != StateDone || final.Processed != len(ids) || final.Applied != len(ids) || final.LastError != "" {
		t.Fatalf("final = %+v", final)
	}
	for _, playerID := range ids {
		count := 0
		for _, effect := range deliveries.effects {
			if effect == playerID {
				count++
			}
		}
		if count != 1 {
			t.Fatalf("recipient %d delivered %d times", playerID, count)
		}
	}
}

func TestApplyPendingMailCountsAPastFixedExpiryAsPermanent(t *testing.T) {
	ids := []int64{11, 22}
	payload := map[string]any{"target": map[string]any{"player_ids": ids}, "title": "t", "body": "b", "expire": map[string]any{"fixed": time.Unix(600, 0).UTC().Format(time.RFC3339)}}
	store := &fakeStore{rows: map[string]BulkTarget{"mail-expired": testMailBulkTarget(t, "mail-expired", ids, payload)}}
	deliveries := &fakeMail{}
	applier := mailApplier(t, store, deliveries)
	if _, err := applier.ApplyPending(context.Background()); err != nil {
		t.Fatal(err)
	}
	final := store.rows["mail-expired"]
	if final.State != StateDone || final.Refused != 2 || final.Applied != 0 {
		t.Fatalf("final = %+v", final)
	}
	if len(deliveries.calls) != 0 {
		t.Fatalf("expired fixed mail was delivered: %d", len(deliveries.calls))
	}
}

func TestApplyPendingRecordsAnUnsupportedBulkCommandAsFailed(t *testing.T) {
	target := BulkTarget{SemanticKey: "other", ModuleCommand: "grant.other", Selector: "players", PlayerIDs: []int64{1}, PlayerCount: 1, Payload: json.RawMessage(`{}`), State: StatePending}
	store := &fakeStore{rows: map[string]BulkTarget{"other": target}}
	if _, err := mailApplier(t, store, &fakeMail{}).ApplyPending(context.Background()); err != nil {
		t.Fatal(err)
	}
	if saved := store.rows["other"]; saved.State != StateFailed || saved.FailedReason == "" {
		t.Fatalf("saved = %+v", saved)
	}
}
