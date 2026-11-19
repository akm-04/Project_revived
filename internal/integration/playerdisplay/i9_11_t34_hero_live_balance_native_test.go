//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// A MID68 dynamic-card unlock with the authoritative crystal below the paid
// LIVE cost answers the named balance refusal through the dispatcher, debits
// nothing and writes no entitlement.
func TestI9_11T34MID68ShortCrystalRefusalNative(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_currency_balances SET amount=10,updated_at=clock_timestamp() WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50005171,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour') ON CONFLICT(player_id,item_id) DO UPDATE SET quantity=excluded.quantity,updated_at=excluded.updated_at`, int64(a.PlayerID))
	heroes := genuineHeroService(p)
	dispatcher := stockruntime.HeroDispatcher{
		Authority: playtestAuthority{a},
		Service:   heroes,
		LIVE:      heroes,
		Economy:   i5.ScalarProjector{Runner: tx.Runner{DB: p}, Store: i5store.Store{Queryer: p}, FloorPolicies: contentstore.Store{Queryer: p}},
	}
	params := map[string]any{"partner_id": int64(1), "model_id": int64(10001001)}
	response := dispatcher.Dispatch(ctx, playtestRequest(a, 68, params))
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(20005) {
		t.Fatalf("MID68 short crystal reply = %+v", response)
	}
	var amount int64
	if err := p.Raw().QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); err != nil || amount != 10 {
		t.Fatal("short refusal debited crystal", amount, err)
	}
	var owned int64
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_hero_live_entitlements WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), int64(1)).Scan(&owned); err != nil || owned != 0 {
		t.Fatal("short refusal wrote an entitlement", owned, err)
	}
	replayed := dispatcher.Dispatch(ctx, playtestRequest(a, 68, map[string]any{"partner_id": int64(1), "model_id": int64(10001001)}))
	if replayed.HTTPStatus != 409 || replayed.Body["error_code"] != int64(20005) {
		t.Fatalf("MID68 short crystal replay = %+v", replayed)
	}
}
