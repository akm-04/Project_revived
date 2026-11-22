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
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recordedGrant struct {
	player int64
	key    string
	lines  []grant.Line
}

type fakeGrants struct {
	byKey   map[string]bool
	calls   []recordedGrant
	effects []grant.Line
}

func (f *fakeGrants) AdminGrantTx(ctx context.Context, _ tx.Tx, admin appi5.AdminOperator, target identity.PlayerID, key, policy string, lines []grant.Line, op operation.Context) (appi5.GrantResult, error) {
	return f.AdminGrant(ctx, admin, target, key, policy, lines, op)
}

func (f *fakeGrants) AdminGrant(_ context.Context, _ appi5.AdminOperator, target identity.PlayerID, key, _ string, lines []grant.Line, _ operation.Context) (appi5.GrantResult, error) {
	f.calls = append(f.calls, recordedGrant{player: int64(target), key: key, lines: lines})
	if f.byKey == nil {
		f.byKey = map[string]bool{}
	}
	if f.byKey[key] {
		return appi5.GrantResult{}, nil
	}
	f.byKey[key] = true
	f.effects = append(f.effects, lines...)
	return appi5.GrantResult{}, nil
}

type fakeStore struct {
	rows map[string]BulkTarget
}

func (f *fakeStore) InsertBulkTx(_ context.Context, _ tx.Tx, target BulkTarget) error {
	if f.rows == nil {
		f.rows = map[string]BulkTarget{}
	}
	f.rows[target.SemanticKey] = target
	return nil
}

func (f *fakeStore) ReadBulkTx(_ context.Context, _ tx.Queryer, key string) (*BulkTarget, error) {
	if f.rows == nil {
		return nil, nil
	}
	target, ok := f.rows[key]
	if !ok {
		return nil, nil
	}
	return &target, nil
}

func (f *fakeStore) ListPendingBulkTx(_ context.Context, _ tx.Queryer, _ int) ([]BulkTarget, error) {
	var out []BulkTarget
	for _, row := range f.rows {
		if row.State == StatePending {
			out = append(out, row)
		}
	}
	return out, nil
}

func (f *fakeStore) SaveBulkProgressTx(_ context.Context, _ tx.Tx, key string, processed, applied, refused int, state string, _ time.Time) error {
	target := f.rows[key]
	target.Processed, target.Applied, target.Refused, target.State = processed, applied, refused, state
	f.rows[key] = target
	return nil
}

type fakeRecipients struct {
	server []identity.PlayerID
	all    []identity.PlayerID
}

func (f fakeRecipients) ServerPlayerIDsTx(context.Context, tx.Queryer, identity.LogicalServerID, int) ([]identity.PlayerID, error) {
	return f.server, nil
}
func (f fakeRecipients) AllPlayerIDsTx(context.Context, tx.Queryer, int) ([]identity.PlayerID, error) {
	return f.all, nil
}

func testCatalogue(t *testing.T) operatorcatalog.Document {
	t.Helper()
	document, err := operatorcatalog.Build([]operatorcatalog.Resource{
		{DefinitionKey: "stack_item:50001010", Class: "STACK_ITEM", Activation: "ENABLED_R4", ItemID: 50001010},
		{DefinitionKey: "specialized:item:250000111", Class: "SPECIALIZED_DOMAIN", Activation: "FAIL_CLOSED", ItemID: 250000111},
	}, nil, time.Unix(100, 0))
	if err != nil {
		t.Fatal(err)
	}
	return document
}

func testCommand(t *testing.T, key string, payload any) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(CommandGrantItems, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "native grant", SemanticKey: key}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func testScope() tx.Scope {
	return tx.Scope{Operation: operation.Context{StartedAt: time.Unix(500, 0)}}
}

func TestGrantItemsInlineAppliesEachRecipientOnceWithItsOwnKey(t *testing.T) {
	grants := &fakeGrants{}
	commands := Commands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Grants: grants, LineCap: 10}
	payload := map[string]any{
		"target": map[string]any{"player_ids": []int64{2, 1}},
		"lines":  []map[string]any{{"id": "stack_item:50001010", "amount": 3}},
	}
	for run := 0; run < 2; run++ {
		command := testCommand(t, "grant-inline-1", payload)
		outcome, err := commands.grantHandler(context.Background(), testScope(), command)
		if err != nil {
			t.Fatal(err)
		}
		result := outcome.(GrantResult)
		if result.Bulk || result.PlayerCount != 2 || result.Applied != 2 || result.Refused != 0 {
			t.Fatalf("run %d result = %+v", run, result)
		}
	}
	if len(grants.calls) != 4 {
		t.Fatalf("grant calls = %d", len(grants.calls))
	}
	keys := map[string]bool{}
	for _, call := range grants.calls {
		keys[call.key] = true
	}
	if len(keys) != 2 {
		t.Fatalf("recipient keys = %v", keys)
	}
	if len(grants.effects) != 2 {
		t.Fatalf("effects = %d, want one per recipient", len(grants.effects))
	}
	if grants.calls[0].lines[0].ItemID != 50001010 || grants.calls[0].lines[0].Amount != 3 {
		t.Fatalf("line = %+v", grants.calls[0].lines)
	}
}

func TestGrantItemsRefusesValidationAndCatalogue(t *testing.T) {
	base := map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	cases := []struct {
		name    string
		payload map[string]any
		code    string
	}{
		{"unknown id", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{{"id": "stack_item:404", "amount": 1}}}, CodeGrantNotGrantable},
		{"fail closed", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{{"id": "specialized:item:250000111", "amount": 1}}}, CodeGrantNotGrantable},
		{"zero amount", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 0}}}, CodeGrantAmount},
		{"over cap", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 11}}}, CodeGrantAmount},
		{"bad target", map[string]any{"target": map[string]any{"global": true, "server_id": 1}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}, CodeGrantTarget},
		{"negative player", map[string]any{"target": map[string]any{"player_ids": []int64{-1}}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}, CodeGrantTarget},
		{"empty lines", map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": []map[string]any{}}, CodeGrantLines},
	}
	commands := Commands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Grants: &fakeGrants{}, LineCap: 10}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			_, err := commands.grantHandler(context.Background(), testScope(), testCommand(t, testCase.name, testCase.payload))
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) || refusal.Code != testCase.code {
				t.Fatalf("error = %v, want %s", err, testCase.code)
			}
		})
	}
	tooMany := make([]map[string]any, 0, MaxLines+1)
	for i := 0; i <= MaxLines; i++ {
		tooMany = append(tooMany, map[string]any{"id": "stack_item:50001010", "amount": 1})
	}
	payload := map[string]any{"target": map[string]any{"player_ids": []int64{1}}, "lines": tooMany}
	if _, err := commands.grantHandler(context.Background(), testScope(), testCommand(t, "too-many-lines", payload)); err == nil {
		t.Fatal("fifty-one lines accepted")
	}
	if _, err := commands.grantHandler(context.Background(), testScope(), testCommand(t, "base-ok", base)); err != nil {
		t.Fatal(err)
	}
}

func TestGrantItemsFreezesAJobAboveTheInlineLimit(t *testing.T) {
	ids := make([]int64, 0, InlineRecipientLimit+1)
	for i := 1; i <= InlineRecipientLimit+1; i++ {
		ids = append(ids, int64(i))
	}
	store := &fakeStore{}
	grants := &fakeGrants{}
	commands := Commands{Catalogue: testCatalogue(t), Store: store, Grants: grants, LineCap: 10}
	payload := map[string]any{"target": map[string]any{"player_ids": ids}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	outcome, err := commands.grantHandler(context.Background(), testScope(), testCommand(t, "grant-bulk-1", payload))
	if err != nil {
		t.Fatal(err)
	}
	result := outcome.(GrantResult)
	if !result.Bulk || result.PlayerCount != InlineRecipientLimit+1 || result.State != StatePending {
		t.Fatalf("result = %+v", result)
	}
	if len(grants.calls) != 0 {
		t.Fatalf("bulk submit granted inline: %d calls", len(grants.calls))
	}
	frozen := store.rows["grant-bulk-1"]
	if frozen.PlayerIDsSHA256 == "" || frozen.Processed != 0 || frozen.Selector != "players" {
		t.Fatalf("frozen = %+v", frozen)
	}
	if !reflect.DeepEqual(frozen.PlayerIDs, ids) {
		t.Fatalf("frozen ids = %v", frozen.PlayerIDs)
	}
}

func TestGrantItemsResolvesServerTarget(t *testing.T) {
	grants := &fakeGrants{}
	commands := Commands{Catalogue: testCatalogue(t), Store: &fakeStore{}, Grants: grants, Directory: fakeRecipients{server: []identity.PlayerID{7, 8, 7}}, LineCap: 10}
	payload := map[string]any{"target": map[string]any{"server_id": 1}, "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}
	outcome, err := commands.grantHandler(context.Background(), testScope(), testCommand(t, "grant-server-1", payload))
	if err != nil {
		t.Fatal(err)
	}
	if result := outcome.(GrantResult); result.Applied != 2 || result.PlayerCount != 2 {
		t.Fatalf("result = %+v", result)
	}
}

func TestLineCapFromEnvironment(t *testing.T) {
	if cap, err := LineCapFromEnvironment(""); err != nil || cap != DefaultLineCap {
		t.Fatalf("default = %d %v", cap, err)
	}
	if cap, err := LineCapFromEnvironment("25"); err != nil || cap != 25 {
		t.Fatalf("set = %d %v", cap, err)
	}
	for _, bad := range []string{"0", "-1", "2000000001", "abc"} {
		if _, err := LineCapFromEnvironment(bad); err == nil {
			t.Fatalf("accepted %q", bad)
		}
	}
}
