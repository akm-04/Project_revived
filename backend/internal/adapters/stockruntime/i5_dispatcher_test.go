package stockruntime

import (
	"context"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type i5WireFake struct {
	I5ServicePort
	claimed    mail.Address
	batch      []mail.Address
	projection appi5.SettlementProjection
}

func (f *i5WireFake) ListBackpack(_ context.Context, actor identity.ActorContext) ([]economy.StackState, error) {
	base := time.Unix(1_700_000_000, 0).UTC()
	return []economy.StackState{{PlayerID: actor.PlayerID, ItemID: 9001, Quantity: 3, StateVersion: 2, AcquiredAt: base, UpdatedAt: base.Add(time.Hour)}}, nil
}
func (f *i5WireFake) ClaimMail(_ context.Context, _ identity.ActorContext, a mail.Address, _ operation.Context) (appi5.MID369Result, error) {
	f.claimed = a
	return appi5.MID369Result{Changed: true, IsNew: 0, IsShown: 0, Rewards: []appi5.Award{{ResourceKey: "gold", ItemNum: 2}}, Projection: f.projection}, nil
}
func (f *i5WireFake) ClaimMailBatch(_ context.Context, _ identity.ActorContext, a []mail.Address, _ operation.Context) (appi5.MID370Result, error) {
	f.batch = append([]mail.Address(nil), a...)
	return appi5.MID370Result{Awards: []appi5.Award{{TableID: 9001, ItemNum: 3}}, Mail: appi5.MailListResult{}, Projection: f.projection}, nil
}
func (f *i5WireFake) ClaimObjectiveByID(_ context.Context, _ identity.ActorContext, _ int64, _ string, _ operation.Context) (appi5.ObjectiveClaimResult, error) {
	return appi5.ObjectiveClaimResult{Awards: []appi5.Award{{ItemNum: 10}}, Projection: f.projection}, nil
}
func (f *i5WireFake) Redeem(_ context.Context, _ identity.ActorContext, _, _ string, _ operation.Context) (appi5.RedeemResult, error) {
	return appi5.RedeemResult{Awards: []appi5.Award{{ItemNum: 10}}, Projection: f.projection}, nil
}
func (f *i5WireFake) ListObjectives(_ context.Context, _ identity.ActorContext, _ objective.StockFamily, _ time.Time) ([]objective.Instance, []appi5.ObjectiveDefinition, error) {
	return nil, nil, nil
}

func i5Req(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestI5MID81ProjectsCanonicalBackpackAcquiredTime(t *testing.T) {
	now := time.Unix(1_700_000_100, 0).UTC()
	svc := &i5WireFake{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	got := d.Dispatch(context.Background(), i5Req(81, map[string]any{}, now))
	if got.HTTPStatus != 200 {
		t.Fatalf("%+v", got)
	}
	list, ok := got.Body["list"].([]any)
	if !ok || len(list) != 1 {
		t.Fatalf("list=%#v", got.Body["list"])
	}
	row := list[0].(map[string]any)
	if row["table_id"] != int64(9001) || row["item_num"] != int64(3) || row["time"] != int64(1_700_000_000) {
		t.Fatalf("row=%#v", row)
	}
	if got.Body["sort_type"] != int64(0) {
		t.Fatalf("sort_type=%#v", got.Body["sort_type"])
	}
	if spirit, ok := got.Body["spirit_list"].([]any); !ok || len(spirit) != 0 {
		t.Fatalf("spirit_list=%#v", got.Body["spirit_list"])
	}
}

func TestI5MID369PreservesFalseNormalNamespaceAndNamedReward(t *testing.T) {
	now := time.Unix(700, 0).UTC()
	svc := &i5WireFake{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	got := d.Dispatch(context.Background(), i5Req(369, map[string]any{"id": int64(7), "is_region": false}, now))
	if got.HTTPStatus != 200 {
		t.Fatalf("%+v", got)
	}
	if svc.claimed != (mail.Address{Namespace: mail.Normal, WireID: 7}) {
		t.Fatalf("address=%+v", svc.claimed)
	}
	rewards, ok := got.Body["rewards"].([]map[string]any)
	if !ok || len(rewards) != 1 || rewards[0]["item"] != "gold" || rewards[0]["num"] != int64(2) {
		t.Fatalf("rewards=%#v", got.Body["rewards"])
	}
}

func TestI5MID370CanonicalizesCompoundAddressSetAndNumericAwards(t *testing.T) {
	now := time.Unix(701, 0).UTC()
	svc := &i5WireFake{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	got := d.Dispatch(context.Background(), i5Req(370, map[string]any{"normal_ids": "2|1|2", "region_ids": "1"}, now))
	if got.HTTPStatus != 200 {
		t.Fatalf("%+v", got)
	}
	want := []mail.Address{{Namespace: mail.Normal, WireID: 1}, {Namespace: mail.Normal, WireID: 2}, {Namespace: mail.Region, WireID: 1}}
	if len(svc.batch) != len(want) {
		t.Fatalf("batch=%+v", svc.batch)
	}
	for i := range want {
		if svc.batch[i] != want[i] {
			t.Fatalf("batch=%+v", svc.batch)
		}
	}
	awards, ok := got.Body["awards"].([]map[string]any)
	if !ok || len(awards) != 1 || awards[0]["table_id"] != int64(9001) || awards[0]["item_num"] != int64(3) {
		t.Fatalf("awards=%#v", got.Body["awards"])
	}
}

func TestI5R5SettlementSidebandsAreGlobalAndDoNotInventNumericAwards(t *testing.T) {
	now := time.Unix(702, 0).UTC()
	proj := appi5.SettlementProjection{Economy: map[string]int64{"exp": 123, "lev": 7, "energy": 88}, NewFunctionIDs: []int64{12, 33}}
	for _, tc := range []struct {
		mid    uint16
		params map[string]any
	}{
		{mid: 161, params: map[string]any{"table_id": int64(7)}},
		{mid: 230, params: map[string]any{"code": "ABC", "platform": int64(1)}},
	} {
		svc := &i5WireFake{projection: proj}
		d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
		got := d.Dispatch(context.Background(), i5Req(tc.mid, tc.params, now))
		if got.HTTPStatus != 200 {
			t.Fatalf("mid %d: %+v", tc.mid, got)
		}
		economy, ok := got.Body["economy_"].(map[string]int64)
		if !ok || economy["exp"] != 123 || economy["lev"] != 7 || economy["energy"] != 88 {
			t.Fatalf("mid %d economy_=%#v", tc.mid, got.Body["economy_"])
		}
		funcs, ok := got.Body["new_funcs_"].([]int64)
		if !ok || len(funcs) != 2 || funcs[0] != 12 || funcs[1] != 33 {
			t.Fatalf("mid %d new_funcs_=%#v", tc.mid, got.Body["new_funcs_"])
		}
		awards, ok := got.Body["awards"].([]map[string]any)
		if !ok || len(awards) != 0 {
			t.Fatalf("mid %d fabricated numeric award=%#v", tc.mid, got.Body["awards"])
		}
		if _, nested := got.Body["result"]; nested {
			t.Fatalf("mid %d sidebands nested unexpectedly: %#v", tc.mid, got.Body)
		}
	}
}

func TestI5MID369GlobalSidebandsPreserveNamedReward(t *testing.T) {
	now := time.Unix(703, 0).UTC()
	svc := &i5WireFake{projection: appi5.SettlementProjection{Economy: map[string]int64{"gold": 9}}}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: svc}
	got := d.Dispatch(context.Background(), i5Req(369, map[string]any{"id": int64(7), "is_region": false}, now))
	if got.HTTPStatus != 200 || got.Body["economy_"] == nil {
		t.Fatalf("response=%+v", got)
	}
	rewards, ok := got.Body["rewards"].([]map[string]any)
	if !ok || len(rewards) != 1 || rewards[0]["item"] != "gold" {
		t.Fatalf("named reward lost: %#v", got.Body["rewards"])
	}
}
