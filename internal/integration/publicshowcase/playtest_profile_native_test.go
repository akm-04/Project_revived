//go:build postgres

package publicshowcase_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func seedProfileHeroes(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string, firstPartner int64, count int) {
	t.Helper()
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	// assets() already owns the first three Normal one-star templates.
	used := map[int64]bool{}
	seeded := 0
	for _, hero := range catalog.HeroCore.Templates {
		if hero.HeroKind == "NORMAL" && hero.InitialStar == 1 && seeded < 3 {
			used[hero.TableID] = true
			seeded++
		}
	}
	templates := make([]int64, 0, count)
	for _, hero := range catalog.HeroCore.Templates {
		if hero.HeroKind == "NORMAL" && !used[hero.TableID] && len(templates) < count {
			templates = append(templates, hero.TableID)
		}
	}
	if len(templates) != count {
		t.Fatalf("normal hero templates %d", len(templates))
	}
	earlier := time.Now().UTC().Add(-time.Hour)
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `UPDATE player_hero_roots SET next_partner_id=GREATEST(next_partner_id,$2) WHERE player_id=$1`, int64(player), firstPartner+int64(count)); err != nil {
		t.Fatal(err)
	}
	for index, table := range templates {
		hero := character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: player, PartnerID: firstPartner + int64(index), TableID: table, OriginTableID: table,
			Star: 5, Level: 1, Color: 1, CreationContentRevision: revision, IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: earlier, UpdatedAt: earlier}
		if err = (characterstore.Store{}).InsertHeroTx(ctx, tr, hero); err != nil {
			t.Fatal(err)
		}
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestPlaytestMID1829ReadsProfileOfPlayerWith123Heroes(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	requester, target := profileActor(t, p), profileActor(t, p)
	assets(t, p, target, revision)
	seedProfileHeroes(t, p, target.PlayerID, revision, 4, 120)
	dispatcher := stockruntime.PublicProfileReadDispatcher{Authority: bookmarkAuthority{requester}, Service: composer(t, p)}
	r := bookmarkRequest(1829, requester, map[string]any{"to_player_id": int64(target.PlayerID), "sub_type": 1, "v_": "1.0.0", "app_v": "1.0.0", "platform": "android"})
	started := time.Now()
	response := dispatcher.Dispatch(ctx, r)
	t.Logf("MID1829 with 123 heroes: status=%d elapsed=%s body_keys=%d", response.HTTPStatus, time.Since(started), len(response.Body))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID1829 refused a 123-hero player: %+v", response)
	}
	if response.Body["show_types"] == nil || response.Body["player_info"] == nil {
		t.Fatalf("MID1829 reply %+v", response.Body)
	}
}
