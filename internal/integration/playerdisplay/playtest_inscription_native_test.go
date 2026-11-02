//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
)

func TestPlaytestInscriptionExchangeWithoutCertificateRows(t *testing.T) {
	p := pool(t)
	a, _, service := inscriptionFixture(t, p)
	exec(t, p, `DELETE FROM player_currency_balances WHERE player_id=$1 AND resource_key IN ('degree_cer','graduate_cer','patent_cer')`, int64(a.PlayerID))
	exec(t, p, `DELETE FROM player_item_stacks WHERE player_id=$1 AND item_id IN (50001344,50001345,50001346)`, int64(a.PlayerID))
	dispatcher := stockruntime.InscriptionDispatcher{Authority: playtestAuthority{a}, Service: service}
	response := dispatcher.Dispatch(ctx, playtestRequest(a, 1407, map[string]any{}))
	if response.HTTPStatus != 200 {
		t.Fatalf("exchange after a committed change answered %+v", response)
	}
	values, ok := response.Body["economy_"].(map[string]any)
	if !ok {
		t.Fatalf("economy_ %+v", response.Body)
	}
	balance := func(key string) int64 {
		var amount int64
		if err := p.QueryRow(ctx, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2),0)`, int64(a.PlayerID), key).Scan(&amount); err != nil {
			t.Fatal(err)
		}
		return amount
	}
	for _, key := range []string{"mana", "crystal", "degree_cer", "graduate_cer", "patent_cer"} {
		got, present := values[key]
		if !present {
			t.Fatalf("missing balance %s in %+v", key, values)
		}
		if got != balance(key) {
			t.Fatalf("%s = %v, stored %d", key, got, balance(key))
		}
	}
	if balance("degree_cer") <= 0 {
		t.Fatal("one exchange material credited no certificate")
	}
}
