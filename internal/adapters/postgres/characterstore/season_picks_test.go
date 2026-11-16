package characterstore

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type seasonPicksStub map[int64]int64

func (s seasonPicksStub) SeasonPicksTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error) {
	return s, nil
}

// ARENA_HERO_PICKS_V1: every roster row carries the count of the girl's
// pre-awaken table id, so an awakened copy shows the base girl's fights.
func TestHeroBootstrapProjectionCarriesSeasonArenaPicksByBaseTable(t *testing.T) {
	root, h := heroBootstrapFixture()
	h.TableID, h.OriginTableID = 10001041, 10001040
	q := &heroBootstrapQueryer{root: root, heroes: []character.Hero{h}}
	content := heroBootstrapContent{revision: h.CreationContentRevision, core: true, equipment: true, fumo: true, appearance: true, kind: character.NormalHero}
	detail := map[string]any{"49": map[string]any{"sort_type": int64(0), "heros": map[string]any{}}}
	p := HeroBootstrapProjection{Content: content, SeasonPicks: seasonPicksStub{10001040: 2}}
	if err := p.OverlayMID1(context.Background(), q, identity.ActorContext{PlayerID: 7}, false, time.Unix(200, 0).UTC(), detail); err != nil {
		t.Fatal(err)
	}
	wire := detail["49"].(map[string]any)["heros"].(map[string]any)["1"].(map[string]any)
	if wire["region_arena_times"] != int64(2) {
		t.Fatalf("region_arena_times = %#v, want 2", wire["region_arena_times"])
	}
}
