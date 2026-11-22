package operatorgrant

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type redeemingOwner struct {
	created    []appi5.RedeemCreateRequest
	disabled   []string
	createErr  error
	disableErr error
}

func (f *redeemingOwner) OperatorCreateRedeemTx(_ context.Context, _ tx.Tx, _ appi5.AdminOperator, request appi5.RedeemCreateRequest, _ operation.Context) (appi5.RedeemCreateResult, error) {
	if f.createErr != nil {
		return appi5.RedeemCreateResult{}, f.createErr
	}
	f.created = append(f.created, request)
	return appi5.RedeemCreateResult{Code: request.Code, PerSubjectCap: 1, State: "ACTIVE"}, nil
}

func (f *redeemingOwner) OperatorDisableRedeemTx(_ context.Context, _ tx.Tx, _ appi5.AdminOperator, code string, _ operation.Context) (appi5.RedeemDisableResult, error) {
	if f.disableErr != nil {
		return appi5.RedeemDisableResult{}, f.disableErr
	}
	f.disabled = append(f.disabled, code)
	return appi5.RedeemDisableResult{Code: code, State: "DISABLED"}, nil
}

func redeemCommand(t *testing.T, name, key string, payload any) operator.Command {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root-op", Role: operator.RoleRoot, Scope: "global", Reason: "redeem native", SemanticKey: key}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func TestRedeemCreatePassesCatalogueLinesAndExpiry(t *testing.T) {
	owner := &redeemingOwner{}
	commands := RedeemCommands{Catalogue: testCatalogue(t), Redeem: owner, LineCap: 10}
	expires := time.Unix(1000, 0).UTC().Format(time.RFC3339)
	payload := map[string]any{
		"code":       "HELLO2026",
		"lines":      []map[string]any{{"id": "stack_item:50001010", "amount": 4}},
		"expires_at": expires,
		"total_cap":  100,
	}
	outcome, err := commands.createHandler(context.Background(), testScope(), redeemCommand(t, CommandRedeemCreate, "redeem-create-1", payload))
	if err != nil {
		t.Fatal(err)
	}
	if result := outcome.(appi5.RedeemCreateResult); result.Code != "HELLO2026" || result.PerSubjectCap != 1 {
		t.Fatalf("result = %+v", result)
	}
	if len(owner.created) != 1 {
		t.Fatalf("created = %d", len(owner.created))
	}
	request := owner.created[0]
	if request.Code != "HELLO2026" || request.TotalCap == nil || *request.TotalCap != 100 || request.ExpiresAt == nil {
		t.Fatalf("request = %+v", request)
	}
	if len(request.Lines) != 1 || request.Lines[0].ItemID != 50001010 || request.Lines[0].Amount != 4 {
		t.Fatalf("lines = %+v", request.Lines)
	}
}

func TestRedeemCreateRefusals(t *testing.T) {
	cases := []struct {
		name    string
		payload map[string]any
		owner   *redeemingOwner
		code    string
	}{
		{"unknown line", map[string]any{"lines": []map[string]any{{"id": "stack_item:404", "amount": 1}}}, &redeemingOwner{}, CodeGrantNotGrantable},
		{"no lines", map[string]any{"lines": []map[string]any{}}, &redeemingOwner{}, CodeGrantLines},
		{"past expiry", map[string]any{"lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}, "expires_at": time.Unix(1, 0).UTC().Format(time.RFC3339)}, &redeemingOwner{}, CodeRedeemExpiry},
		{"bad expiry", map[string]any{"lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}, "expires_at": "soon"}, &redeemingOwner{}, CodeRedeemExpiry},
		{"zero cap", map[string]any{"lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}, "total_cap": 0}, &redeemingOwner{}, CodeRedeemCap},
		{"long code", map[string]any{"code": string(make([]byte, MaxRedeemCodeLength+1)), "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}, &redeemingOwner{}, CodeRedeemCode},
		{"duplicate code", map[string]any{"code": "TAKEN", "lines": []map[string]any{{"id": "stack_item:50001010", "amount": 1}}}, &redeemingOwner{createErr: appi5.ErrRedeemCodeTaken}, CodeRedeemCodeTaken},
	}
	commands := RedeemCommands{Catalogue: testCatalogue(t), Redeem: cases[0].owner, LineCap: 10}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			commands.Redeem = testCase.owner
			_, err := commands.createHandler(context.Background(), testScope(), redeemCommand(t, CommandRedeemCreate, testCase.name, testCase.payload))
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) || refusal.Code != testCase.code {
				t.Fatalf("error = %v, want %s", err, testCase.code)
			}
		})
	}
}

func TestRedeemDisableRefusesAnUnknownCode(t *testing.T) {
	owner := &redeemingOwner{}
	commands := RedeemCommands{Catalogue: testCatalogue(t), Redeem: owner, LineCap: 10}
	if _, err := commands.disableHandler(context.Background(), testScope(), redeemCommand(t, CommandRedeemDisable, "redeem-disable-1", map[string]any{"code": "NOPE"})); err != nil {
		t.Fatal(err)
	}
	if len(owner.disabled) != 1 || owner.disabled[0] != "NOPE" {
		t.Fatalf("disabled = %v", owner.disabled)
	}
	owner.disableErr = appi5.ErrRedeemUnknown
	_, err := commands.disableHandler(context.Background(), testScope(), redeemCommand(t, CommandRedeemDisable, "redeem-disable-2", map[string]any{"code": "NOPE"}))
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeRedeemUnknown {
		t.Fatalf("error = %v", err)
	}
	if _, err := commands.disableHandler(context.Background(), testScope(), redeemCommand(t, CommandRedeemDisable, "redeem-disable-3", map[string]any{"code": ""})); err == nil {
		t.Fatal("an empty code was accepted")
	}
}
