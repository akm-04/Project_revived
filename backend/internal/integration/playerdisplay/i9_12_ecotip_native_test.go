//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// The stock ShopWindow eco tip reads one SELF_PLAYER field per shop type:
// getShopCostInfo maps a shop type to a model key (ShopWindow.lua:214-266) and
// addTips stores player_[key] as the tip number (ShopWindow.lua:166-200).
// EcoTipsWindow.layout formats that number before it sets tipHeight
// (EcoTipsWindow.lua:42-74), so a nil value aborts layout and the later
// getTipHeight()/2 (ShopWindow.lua:186) crashes the client. SelfPlayer fills
// those model keys from MID 1 detail 17 (SelfPlayer.lua:116-226).
//
// This drives MID 1 through the production bootstrap service and asserts every
// shop currency the tip can read is present with the player's real balance.
func TestI912EcoTipCurrencyFieldsInProductionMID1(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	seeded := map[string]int64{
		"top_coin": 50000, "god_war_coin": 123, "paradise_coin": 77,
		"friend_medal": 9, "tutor_coin": 11, "team_dungeon_coin": 13,
		"summon_coin": 5, "skin_fragment": 21, "honor_coin": 31,
	}
	for key, amount := range seeded {
		exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,$2,$3,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,state_version=player_currency_balances.state_version+1,updated_at=excluded.updated_at`,
			int64(a.PlayerID), key, amount)
	}
	secret := []byte("i9-12-ecotip-native-digest-key-0001")
	sidRaw, loginRaw := clockRollbackCredentials(t, p, a, secret)
	at := time.Now().UTC().Truncate(time.Microsecond)
	service := clockRollbackService(p, &i911cFixedClock{at: at}, secret)
	dispatcher := stockruntime.BootstrapDispatcher{Bootstrap: service}
	operation := op()
	operation.StartedAt = at
	operation.EntropySeed[0] = 11
	response := dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID: 1, Operation: operation,
		Params: map[string]any{"sid": sidRaw, "login_token": loginRaw, "region": int64(1)},
	}})
	if response.HTTPStatus != 200 {
		t.Fatalf("MID 1 status %d body %#v", response.HTTPStatus, response.Body)
	}
	detail, ok := response.Body["detail"].(map[string]any)
	if !ok {
		t.Fatalf("MID 1 detail %T", response.Body["detail"])
	}
	record, ok := detail["17"].(map[string]any)
	if !ok {
		t.Fatalf("MID 1 detail 17 %T", detail["17"])
	}

	// Every shop type the stock ShopWindow maps to a model key, with the reply
	// field SelfPlayer reads for it and the balance the server must return.
	expected := map[string]int64{
		"crystal":           1000, // bornActor seed
		"arena_coin":        0,
		"march_coin":        0,
		"top_coin":          50000,
		"guild_coin":        0,
		"region_coin":       0,
		"honor_coin":        31,
		"god_war_coin":      123,
		"friend_medal":      9,
		"summon_coin":       5,
		"skin_fragment":     21,
		"paradise_coin":     77,
		"team_dungeon_coin": 13,
		"tutor_coin":        11,
	}
	for field, want := range expected {
		value, present := record[field]
		if !present || value == nil {
			t.Fatalf("MID 1 detail 17 omits %q: the stock eco tip would divide a nil tip height", field)
		}
		if got, ok := value.(int64); !ok || got != want {
			t.Fatalf("MID 1 detail 17[%q] = %#v, want %d", field, value, want)
		}
	}
}
