//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/summon"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fixedVIP int64

func (v fixedVIP) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{ProviderRevision: "test", VIPLevel: int64(v), SkillPointNaturalCap: 10}, nil
}

func TestI9_3FPremiumNative(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	catalog, e := (contentstore.Store{}).SummonCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	a := companionActor(t, p)
	s := summonMode(p)
	if _, e = s.Summon(ctx, a, app.Pull{Type: 4, Index: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("SX below VIP 9", e)
	}
	s.Privileges = fixedVIP(9)
	if _, e = s.Summon(ctx, a, app.Pull{Type: 4, Index: 3}, op()); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("SX selector beyond main_ids", e)
	}
	info, e := s.Load(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	hotspot := info["main_ids"].([]int64)[0]
	exec(t, p, `UPDATE player_currency_balances SET amount=388*25 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	for pull := 1; pull <= 25; pull++ {
		body, e := s.Summon(ctx, a, app.Pull{Type: 4, Index: 1}, op())
		if e != nil || len(summonRows(t, body)) != 6 {
			t.Fatal("SX is six rows", pull, body, e)
		}
	}
	var crystal, owned int64
	if e = p.QueryRow(ctx, `SELECT (SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'),(SELECT count(*) FROM player_heroes WHERE player_id=$1 AND origin_table_id=$2)`, int64(a.PlayerID), hotspot).Scan(&crystal, &owned); e != nil || crystal != 0 || owned != 1 {
		t.Fatal("25 SX purchases cost 388 each and the pity guarantees the hotspot", crystal, owned, e)
	}
	if got := stackQuantity(t, p, a.PlayerID, 50001005); got != 25 {
		t.Fatal("one SX Juice per purchase (D155)", got)
	}

	b := companionActor(t, p)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(b.PlayerID))
	content, heroes, values := contentstore.Store{Queryer: p}, characterstore.Store{Queryer: p}, i5store.Store{Queryer: p}
	vows := hero.Service{Runner: tx.Runner{DB: p}, Store: heroes, Fencer: values, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AcquisitionStore: heroes, Acquisition: content, Progression: content, MaterialCosts: i5.MaterialCostDebiter{Store: values, Content: content}, PlayerLevel: i5.CrossOwner{Store: values}, CollectionAdmission: hero.CatalogCollectionAdmission{Content: content}}
	if _, e = vows.CreateVows(ctx, b, 11001, op()); !errors.Is(e, hero.ErrHeroPrerequisites) {
		t.Fatal("305 without prerequisites", e)
	}
	prerequisites, e := content.HeroSuperPrerequisitesTx(ctx, p, rev, 11001)
	if e != nil {
		t.Fatal(e)
	}
	for i, id := range prerequisites {
		if id != 10001001 {
			skillHero(t, p, b, rev, id, int64(100+i))
		}
	}
	if v, e := vows.CreateVows(ctx, b, 11001, op()); e != nil || v.Kind != character.SuperHero {
		t.Fatal("305 through production collection admission", v, e)
	}

	if _, e = s.SwitchMagic(ctx, b, 11002, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("71 needs an owned target", e)
	}
	if body, e := s.SwitchMagic(ctx, b, 11001, op()); e != nil || body["partner_id"] != int64(11001) {
		t.Fatal("71", body, e)
	}
	if info, e = s.Load(ctx, b, op()); e != nil || info["directional_show_id"] != int64(11001) {
		t.Fatal("56 shows the Magic target", info, e)
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=5500 WHERE player_id=$1 AND resource_key='crystal'`, int64(b.PlayerID))
	if _, e = s.Magic(ctx, b, app.MagicPull{Times: 1, Target: 11002}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("70 for a target other than the stored one", e)
	}
	if _, e = s.Magic(ctx, b, app.MagicPull{Times: 3, Target: 11001}, op()); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("70 summon_time 3", e)
	}
	stone, _ := catalog.MagicFragment(11001)
	body, e := s.Magic(ctx, b, app.MagicPull{Times: 1, Target: 11001}, op())
	if e != nil || len(summonRows(t, body)) != 1 || fmt.Sprint(body["stick_items"]) != fmt.Sprintf("[map[item_id:%d item_num:5]]", stone) || stackQuantity(t, p, b.PlayerID, stone) != 5 || fmt.Sprint(body["reward"]) != "map[item_id:50005182 item_num:1]" {
		t.Fatal("70 single", body, e)
	}
	if body, e = s.Magic(ctx, b, app.MagicPull{Times: 10, Target: 11001}, op()); e != nil || len(summonRows(t, body)) != 10 || stackQuantity(t, p, b.PlayerID, stone) <= 5 {
		t.Fatal("70 ten", body, e)
	}

	scroll, _ := catalog.VowsScroll(11001)
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50001666,250,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(b.PlayerID))
	if _, e = s.ExchangeVows(ctx, b, app.VowsExchange{TableID: 10001001, Times: 1}, op()); !errors.Is(e, d.ErrInvalid) {
		t.Fatal("306 for a non-Vows hero", e)
	}
	before := stackQuantity(t, p, b.PlayerID, scroll)
	if body, e = s.ExchangeVows(ctx, b, app.VowsExchange{TableID: 11001, Times: 2}, op()); e != nil || fmt.Sprint(body["awards"]) != fmt.Sprintf("[map[item_num:2 table_id:%d]]", scroll) || stackQuantity(t, p, b.PlayerID, 50001666) != 50 || stackQuantity(t, p, b.PlayerID, scroll) != before+2 {
		t.Fatal("306", body, e)
	}
	if _, e = s.ExchangeVows(ctx, b, app.VowsExchange{TableID: 11001, Times: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("306 without essence", e)
	}
}
