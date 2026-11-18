//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func TestBackpackSortMID88PersistsProjectsAndLeavesHeroSort(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := actor(t, p)
	exec(t, p, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)
		VALUES($1,1,3,1,clock_timestamp(),clock_timestamp()) ON CONFLICT (player_id) DO UPDATE SET sort_type=3`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (spiritstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, revision, time.Now().UTC()); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}

	heroes := privateHeroService(p)
	heroDispatcher := stockruntime.HeroDispatcher{Authority: playtestAuthority{a}, Service: heroes}
	root := func() character.HeroRoot {
		t.Helper()
		r, e := (characterstore.Store{Queryer: p}).ReadRoot(ctx, a.PlayerID)
		if e != nil {
			t.Fatal(e)
		}
		return r
	}

	if got := heroDispatcher.Dispatch(ctx, playtestRequest(a, 88, map[string]any{"sort_type": int64(4)})); got.HTTPStatus != 200 {
		t.Fatalf("MID88 valid=%+v", got)
	}
	if r := root(); r.BackpackSortType != 4 || r.SortType != 3 {
		t.Fatalf("MID88 persisted backpack=%d hero=%d", r.BackpackSortType, r.SortType)
	}
	if got := heroDispatcher.Dispatch(ctx, playtestRequest(a, 88, map[string]any{"sort_type": int64(character.MaxBackpackSortType + 1)})); got.HTTPStatus != 409 {
		t.Fatalf("MID88 out of range=%+v", got)
	}
	if r := root(); r.BackpackSortType != 4 || r.SortType != 3 {
		t.Fatalf("MID88 refusal changed backpack=%d hero=%d", r.BackpackSortType, r.SortType)
	}

	spiritApp := spiritService(p, p)
	i5Dispatcher := stockruntime.I5Dispatcher{
		Authority:      playtestAuthority{a},
		Service:        spiritI5(p, spiritApp),
		BackpackSort:   characterstore.Store{Queryer: p},
		SpiritBackpack: stockruntime.SpiritBackpackProjection{Service: spiritApp, Sort: characterstore.Store{Queryer: p}},
	}
	load := i5Dispatcher.Dispatch(ctx, playtestRequest(a, 81, map[string]any{}))
	if load.HTTPStatus != 200 {
		t.Fatalf("MID81=%+v", load)
	}
	replyconformance.Check(t, 81, load.Body)
	if load.Body["sort_type"] != int64(4) {
		t.Fatalf("MID81 sort_type=%#v", load.Body["sort_type"])
	}

	exec(t, p, `INSERT INTO player_story_cursors(player_id,updated_at)VALUES($1,clock_timestamp())`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_guide_return_state(player_id,updated_at)VALUES($1,clock_timestamp())`, int64(a.PlayerID))
	detail := map[string]any{"17": map[string]any{}}
	projection := i5store.BootstrapProjection{Content: contentstore.Store{Queryer: p}, Privileges: appi5.BaselinePrivilegeProvider{}, MaxHeroColor: appi5.PreservationMaxHeroColorProvider{}, BackpackSort: characterstore.Store{Queryer: p}}
	if e = projection.OverlayMID1(ctx, p, a, false, time.Now().UTC(), detail); e != nil {
		t.Fatal(e)
	}
	bag, ok := detail["81"].(map[string]any)
	if !ok || bag["sort_type"] != int64(4) {
		t.Fatalf("MID1 detail 81=%#v", detail["81"])
	}

	if got := heroDispatcher.Dispatch(ctx, playtestRequest(a, 89, map[string]any{"sort_type": int64(5)})); got.HTTPStatus != 200 {
		t.Fatalf("MID89=%+v", got)
	}
	if r := root(); r.SortType != 5 || r.BackpackSortType != 4 {
		t.Fatalf("MID89 hero=%d backpack=%d", r.SortType, r.BackpackSortType)
	}
}
