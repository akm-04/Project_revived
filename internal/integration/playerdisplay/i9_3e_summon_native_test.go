//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/summonstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/summon"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

func summonMode(p *pg.Pool) app.Mode {
	values, content, heroes := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}, characterstore.Store{Queryer: p}
	return app.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: summonstore.Store{}, Content: content, Fence: values,
		Heroes:   hero.Service{AcquisitionStore: heroes, Acquisition: content, CollectionAdmission: hero.CatalogCollectionAdmission{Content: content}, FreshFacets: characterbirth.FreshHeroFacets()},
		HeroWire: heroproj.StockHero, Grants: compositeI5(p), Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Facts: i5.ObjectiveFacts{Owner: compositeI5(p), Open: values}, Privileges: i5.BaselinePrivilegeProvider{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func summonRows(t *testing.T, body map[string]any) []map[string]any {
	t.Helper()
	raw, _ := json.Marshal(body["result"])
	var rows []map[string]any
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	if e := decoder.Decode(&rows); e != nil {
		t.Fatal(e)
	}
	return rows
}

func TestI9_3ESummonNative(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := companionActor(t, p)
	var owned int64
	if e := p.QueryRow(ctx, `SELECT table_id FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)).Scan(&owned); e != nil || owned != 10001001 {
		t.Fatal("birth companion (D139)", owned, e)
	}
	s := summonMode(p)
	info, e := s.Load(ctx, a, op())
	if e != nil || fmt.Sprint(info["mana_free_num"]) != "5" || fmt.Sprint(info["crystal_free_time"]) != "0" || len(info["main_ids"].([]int64)) != 2 || info["partner_id"].(int64) == 0 {
		t.Fatal("fresh 56", info, e)
	}

	tutorial := op()
	body, e := s.Summon(ctx, a, app.Pull{Type: 1, Index: 1}, tutorial)
	rows := summonRows(t, body)
	if e != nil || len(rows) != 1 || rows[0]["is_partner"] != true || fmt.Sprint(rows[0]["table_id"]) != "10001002" || fmt.Sprint(body["reward"]) != "map[item_id:50001002 item_num:10]" {
		t.Fatal("Small tutorial pull is Lavia with summon_reward", body, e)
	}
	replay, e := summonMode(p).Summon(ctx, a, app.Pull{Type: 1, Index: 1}, tutorial)
	if e != nil || fmt.Sprint(summonRows(t, replay)) != fmt.Sprint(rows) {
		t.Fatal("receipt replay", replay, e)
	}
	if _, e = s.Summon(ctx, a, app.Pull{Type: 1, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("Small free inside 600 s", e)
	}
	body, e = s.Summon(ctx, a, app.Pull{Type: 3, Index: 1}, op())
	rows = summonRows(t, body)
	if e != nil || len(rows) != 1 || fmt.Sprint(rows[0]["table_id"]) != "10001003" || body["reward"] != nil {
		t.Fatal("Medium free tutorial pull is Pandaria", body, e)
	}
	if _, e = s.Summon(ctx, a, app.Pull{Type: 3, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("Medium free inside 46 h", e)
	}
	var heroes, gift int64
	if e = p.QueryRow(ctx, `SELECT (SELECT count(*) FROM player_heroes WHERE player_id=$1),(SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id=50001002)`, int64(a.PlayerID)).Scan(&heroes, &gift); e != nil || heroes != 3 || gift < 10 {
		t.Fatal("three heroes and the tutorial reward once", heroes, gift, e)
	}

	exec(t, p, `UPDATE player_currency_balances SET amount=2600 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	body, e = s.Summon(ctx, a, app.Pull{Type: 2, Index: 2}, op())
	rows = summonRows(t, body)
	hasHero := false
	for _, row := range rows {
		hasHero = hasHero || row["is_partner"] == true || row["to_stone"] == true
	}
	if e != nil || len(rows) != 10 || !hasHero {
		t.Fatal("Medium ten holds a hero", body, e)
	}
	var crystal int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&crystal); e != nil || crystal != 10 {
		t.Fatal("Medium ten costs 2590", crystal, e)
	}
	if body, e = s.Summon(ctx, a, app.Pull{Type: 2, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("unpaid Medium", body, e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50001024,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	body, e = s.Summon(ctx, a, app.Pull{Type: 6, Index: 1}, op())
	if e != nil || len(summonRows(t, body)) != 1 || stackQuantity(t, p, a.PlayerID, 50001024) != 0 {
		t.Fatal("D143 ticket pull spends its ticket", body, e)
	}
	if _, e = s.Summon(ctx, a, app.Pull{Type: 6, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("ticket pull without a ticket", e)
	}
	if _, e = s.Summon(ctx, a, app.Pull{Type: 4, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("SX below VIP 9", e)
	}
	if _, e = s.Summon(ctx, a, app.Pull{Type: 9, Index: 1}, op()); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("unknown button", e)
	}

	catalog, e := (contentstore.Store{}).SummonCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	girls := map[int64]bool{}
	for _, pool := range catalog.Pools {
		for _, row := range pool.Rows {
			girls[row[0]] = pool.Kind == d.HeroKind
		}
	}
	for _, id := range append(append(catalog.Policy.Cohorts.MediumFeatured, catalog.Policy.Cohorts.MediumExtension...), catalog.Policy.Cohorts.SX...) {
		girls[id] = true
	}
	for id, isHero := range girls {
		if !isHero {
			continue
		}
		rule, e := (contentstore.Store{}).HeroNormalSummonTx(ctx, p, rev, id)
		if e != nil || rule.Template.Kind != character.NormalHero {
			t.Fatal("girl catalogue lacks a gacha girl", id, e)
		}
	}

	pinned := catalog.Policy.Cohorts.MediumFeatured[5]
	exec(t, p, `INSERT INTO summon_tuning(payload,updated_at)VALUES(jsonb_build_object('version',1,'partner_id',$1::bigint),now())`, pinned)
	if info, e = s.Load(ctx, a, op()); e != nil || info["partner_id"] != pinned {
		t.Fatal("operator pin", info, e)
	}
	exec(t, p, `UPDATE summon_tuning SET payload='{"version":2,"partner_id":50001002}'`)
	if info, e = s.Load(ctx, a, op()); e != nil || info["partner_id"] == int64(50001002) {
		t.Fatal("rejected tuning must leave the source calendar", info, e)
	}
	exec(t, p, `DELETE FROM summon_tuning`)
}
