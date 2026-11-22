package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	campaign "gxb.local/backend/v2/internal/application/campaign"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	app "gxb.local/backend/v2/internal/application/itemsenergy"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type itemsEnergyFake struct {
	calls map[string]int
	err   error
	body  map[string]any
}

func newItemsEnergyFake() *itemsEnergyFake {
	return &itemsEnergyFake{calls: map[string]int{}, body: map[string]any{}}
}

func (f *itemsEnergyFake) done(name string) (map[string]any, error) {
	f.calls[name]++
	return f.body, f.err
}

func (f *itemsEnergyFake) UseEnergyItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return f.done("use_energy")
}
func (f *itemsEnergyFake) SellItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return f.done("sell_item")
}
func (f *itemsEnergyFake) SellItems(context.Context, identity.ActorContext, []app.ItemAmount, operation.Context) (map[string]any, error) {
	return f.done("sell_items")
}
func (f *itemsEnergyFake) UseMagicItems(context.Context, identity.ActorContext, []app.ItemAmount, operation.Context) (map[string]any, error) {
	return f.done("magic_items")
}
func (f *itemsEnergyFake) EnergyBuy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return f.done("energy_buy")
}
func (f *itemsEnergyFake) GoldenHand(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return f.done("golden_hand")
}
func (f *itemsEnergyFake) TenfoldGoldenHand(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return f.done("tenfold")
}
func (f *itemsEnergyFake) ExchangeCode(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (map[string]any, error) {
	return f.done("box")
}

type quickFumoFake struct {
	calls  int
	result apphero.QuickFumoResult
	err    error
}

func (f *quickFumoFake) QuickFumo(context.Context, identity.ActorContext, int64, int64, operation.Context) (apphero.QuickFumoResult, error) {
	f.calls++
	return f.result, f.err
}

type campaignFallbackFake struct {
	loads  int
	trials int
}

func (*campaignFallbackFake) TrialLoad(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error) {
	return map[string]any{"buy_times": "0|0|0|0|0|0|0|0|0|0"}, nil
}
func (f *campaignFallbackFake) BuyTrial(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	f.trials++
	return map[string]any{}, nil
}
func (*campaignFallbackFake) Bonus(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) ChapterAward(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) StoryAward(context.Context, identity.ActorContext, campaign.StoryChoice, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Caps(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Sweep(context.Context, identity.ActorContext, campaign.Sweep, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Reset(context.Context, identity.ActorContext, campaign.Reset, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Fight(context.Context, identity.ActorContext, campaign.Fight, operation.Context) (map[string]any, error) {
	return nil, errors.New("unexpected")
}
func (*campaignFallbackFake) Result(context.Context, identity.ActorContext, campaign.Result, operation.Context) (campaign.Settled, error) {
	return campaign.Settled{}, errors.New("unexpected")
}

func itemsEnergyRequest(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	params["token"] = "bearer"
	params["region"] = int64(1)
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: operation.Context{StartedAt: now}, MID: mid, ReceivedAt: now, Params: params, Claims: wire.CredentialClaims{Token: "bearer", Region: 1}}}
}

func TestItemsEnergyDispatcherRoutesEveryMID(t *testing.T) {
	now := time.Now().UTC()
	fake := newItemsEnergyFake()
	fallback := &campaignFallbackFake{}
	dispatcher := ItemsEnergyDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake, Campaign: fallback}
	cases := []struct {
		mid    uint16
		params map[string]any
		call   string
	}{
		{27, map[string]any{"item_id": 1, "item_num": 1}, "use_energy"},
		{82, map[string]any{"item_id": 1, "item_num": 1}, "sell_item"},
		{86, map[string]any{"items": []any{map[string]any{"item_id": 1, "item_num": 1}}, "itemType": "MANA"}, "sell_items"},
		{87, map[string]any{"items": []any{map[string]any{"item_id": 1, "item_num": 1}}}, "magic_items"},
		{96, map[string]any{}, "golden_hand"},
		{97, map[string]any{}, "energy_buy"},
		{241, map[string]any{"item_id": 1, "gift_id": 2}, "box"},
		{29, map[string]any{"consume_id": 1}, "tenfold"},
	}
	for _, cell := range cases {
		response := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(cell.mid, cell.params, now))
		if response.HTTPStatus != 200 || fake.calls[cell.call] != 1 {
			t.Fatalf("MID %d routed to %v: %+v", cell.mid, fake.calls, response)
		}
	}
	fumo := &quickFumoFake{result: apphero.QuickFumoResult{Fumo: 150, Cost: 20}}
	dispatcher.Fumo = fumo
	fumoResponse := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(29, map[string]any{"consume_id": 2, "partner_id": 1, "equip_index": 1}, now))
	if fumoResponse.HTTPStatus != 200 || fumo.calls != 1 || fumoResponse.Body["fumo"] != int64(150) ||
		fumoResponse.Body["cost"] != int64(20) || fumoResponse.Body["trial_info"] == nil {
		t.Fatalf("MID 29 id 2 was not handed to the fumo owner: %+v", fumoResponse)
	}
	if fallback.trials != 0 {
		t.Fatalf("MID 29 id 2 reached campaign: %d", fallback.trials)
	}
	response := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(29, map[string]any{"consume_id": 3}, now))
	if response.HTTPStatus != 200 || fallback.trials != 1 {
		t.Fatalf("MID 29 id 3 was not handed to campaign: %+v", response)
	}
	response = dispatcher.Dispatch(context.Background(), itemsEnergyRequest(28, map[string]any{}, now))
	if response.HTTPStatus != 200 || response.Body["buy_times"] == nil {
		t.Fatalf("MID 28 fallback failed: %+v", response)
	}
}

func TestItemsEnergyDecoratedReplyCarriesEconomy(t *testing.T) {
	now := time.Now().UTC()
	fake := newItemsEnergyFake()
	fake.body = map[string]any{"energy": int64(220), "buy_energy_times": int64(1)}
	dispatcher := ItemsEnergyDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake}
	next := httpedge.DispatcherFunc(func(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
		changes.Balance(ctx, "energy", 220)
		return dispatcher.Dispatch(ctx, req)
	})
	response := Decorated{Next: next}.Dispatch(context.Background(), itemsEnergyRequest(97, map[string]any{}, now))
	economy, _ := response.Body["economy_"].(map[string]any)
	if economy["energy"] != int64(220) {
		t.Fatalf("decorated economy_ %#v", response.Body)
	}
	fake.err = d.ErrRefused
	refusal := Decorated{Next: next}.Dispatch(context.Background(), itemsEnergyRequest(97, map[string]any{}, now))
	if refusal.HTTPStatus != 409 || refusal.Body["economy_"] != nil {
		t.Fatalf("refusal was decorated: %+v", refusal)
	}
}

func TestItemsEnergyDispatcherRefusals(t *testing.T) {
	now := time.Now().UTC()
	fake := newItemsEnergyFake()
	dispatcher := ItemsEnergyDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake}
	for _, params := range []map[string]any{
		{"item_id": 0, "item_num": 1},
		{"item_id": 1},
		{"item_id": 1, "item_num": 1, "price": 1},
		{"items": []any{map[string]any{"item_id": 1}}},
		{"items": []any{}},
	} {
		mid := uint16(27)
		if _, hasItems := params["items"]; hasItems {
			mid = 86
		}
		response := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(mid, params, now))
		if response.HTTPStatus != 400 || response.Body["error"] == nil {
			t.Fatalf("malformed %v accepted: %+v", params, response)
		}
	}
	overflow := map[string]any{"item_id": 1, "gift_id": 2, "num": json.Number("99999999999999999999")}
	if response := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(241, overflow, now)); response.HTTPStatus != 400 || response.Body["error"] == nil {
		t.Fatalf("out-of-range box num was not malformed: %+v", response)
	}
	for _, cell := range []struct {
		err    error
		status int
		code   int64
	}{
		{d.ErrRefused, 409, unprovenRefusalCode},
		{app.ErrEnergyCap, 409, 35031},
		{d.ErrUnavailable, 503, serverBusyCode},
		{economy.InsufficientBalance("crystal"), 409, insufficientDiamondCode},
		{errors.New("unexpected"), 500, unprovenRefusalCode},
	} {
		fake.err = cell.err
		response := dispatcher.Dispatch(context.Background(), itemsEnergyRequest(96, map[string]any{}, now))
		if response.HTTPStatus != cell.status || response.Body["error_code"] != cell.code {
			t.Fatalf("failure %v mapped to %+v", cell.err, response)
		}
	}
}
