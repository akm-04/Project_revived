//go:build postgres

package playerdisplay_test

import (
	"errors"
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// presetlessPlayer is a genuine open Top Floor user who owns none of the preset girls.
func presetlessPlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) identity.ActorContext {
	t.Helper()
	actor := rankingActor(t, p, server, true)
	revision := installed(t, p)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,4,$2,'function.lua:4:1|10',clock_timestamp()-interval '1 minute')`, int64(actor.PlayerID), revision)
	return actor
}

func readPresetPlayer(t *testing.T, p *pg.Pool, player identity.PlayerID) d.Player {
	t.Helper()
	saved, found, err := (topfloorstore.Store{}).ReadPlayerTx(ctx, p, player, false)
	if err != nil || !found {
		t.Fatalf("top floor player %d: found=%v err=%v", player, found, err)
	}
	return saved
}

// D511: a first Top Floor entry with no saved defense writes the owned subset of
// the preset girls, and the player can attack without saving one manually.
func TestI9_10TopFloorPresetDefenseAdmissionNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor, revision, aquaris := topFloorPlayer(t, pool, server)
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}
	view, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	saved := readPresetPlayer(t, pool, actor.PlayerID)
	if !slices.Equal(saved.Defense, []int64{aquaris.PartnerID}) || saved.DefensePet != 0 || saved.DefenseSetAt == nil {
		t.Fatalf("preset defense %v pet=%d set_at=%v, want only Aquaris %d", saved.Defense, saved.DefensePet, saved.DefenseSetAt, aquaris.PartnerID)
	}
	enemy := view.Enemies[0]
	fight, err := service.Start(ctx, actor, app.StartCommand{Formation: []int64{aquaris.PartnerID}, Enemy: enemy.Occupant.TableID()}, op())
	if err != nil || fight.Report == nil {
		t.Fatalf("preset defense must admit an attack: report=%d err=%v", len(fight.Report), err)
	}
}

// D511: a player owning several preset girls gets each one in policy slot order,
// including an awakened table id resolved through its base origin.
func TestI9_10TopFloorPresetDefenseOwnedSubsetNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor, revision, aquaris := topFloorPlayer(t, pool, server)
	archie := bornHero(t, pool, actor, revision, 10001019, 2004)
	lightning := bornHeroCard(t, pool, actor, revision, 11001004, 10001004, 2003)
	pandaria := bornHero(t, pool, actor, revision, 10001003, 2002)
	lavia := bornHero(t, pool, actor, revision, 10001002, 2001)

	if _, err := service.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	saved := readPresetPlayer(t, pool, actor.PlayerID)
	want := []int64{aquaris.PartnerID, lavia.PartnerID, pandaria.PartnerID, lightning.PartnerID, archie.PartnerID}
	if !slices.Equal(saved.Defense, want) {
		t.Fatalf("preset defense %v, want policy order %v", saved.Defense, want)
	}
}

// D511: the preset is written once. A later saved defense survives repeats of
// entry and refresh, and a repeated entry does not rewrite the stamp.
func TestI9_10TopFloorPresetDefenseOnceNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor, revision, aquaris := topFloorPlayer(t, pool, server)
	lavia := bornHero(t, pool, actor, revision, 10001002, 2001)
	if _, err := service.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	first := readPresetPlayer(t, pool, actor.PlayerID)
	if !slices.Equal(first.Defense, []int64{aquaris.PartnerID, lavia.PartnerID}) || first.DefenseSetAt == nil {
		t.Fatalf("first entry preset %v set_at=%v", first.Defense, first.DefenseSetAt)
	}
	if err := service.SaveDefense(ctx, actor, []int64{lavia.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	chosen := readPresetPlayer(t, pool, actor.PlayerID)
	if _, err := service.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Refresh(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	repeated := readPresetPlayer(t, pool, actor.PlayerID)
	if !slices.Equal(repeated.Defense, []int64{lavia.PartnerID}) || !repeated.DefenseSetAt.Equal(*chosen.DefenseSetAt) {
		t.Fatalf("repeat entry rewrote defense %v set_at=%v, want %v set_at=%v", repeated.Defense, repeated.DefenseSetAt, chosen.Defense, chosen.DefenseSetAt)
	}
}

// D511: a player owning none of the five gets no preset and keeps the D487
// refusal until saving a defense.
func TestI9_10TopFloorPresetDefenseNoneNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor := presetlessPlayer(t, pool, server)
	view, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	saved := readPresetPlayer(t, pool, actor.PlayerID)
	if len(saved.Defense) != 0 || saved.DefenseSetAt != nil {
		t.Fatalf("owner of no preset girl got defense %v set_at=%v", saved.Defense, saved.DefenseSetAt)
	}
	enemy := view.Enemies[0]
	if _, err = service.Start(ctx, actor, app.StartCommand{Formation: []int64{1}, Enemy: enemy.Occupant.TableID()}, op()); !errors.Is(err, d.ErrDefenseRequired) {
		t.Fatalf("attack without any defense: %v, want ErrDefenseRequired", err)
	}
}

// D511: the board/ranking team popup (MID291) displays the preset defense and
// the power derived from those displayed heroes.
func TestI9_10TopFloorPresetDefenseBoardNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actor, revision, aquaris := topFloorPlayer(t, pool, server)
	lavia := bornHero(t, pool, actor, revision, 10001002, 2001)
	if _, err := service.Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	display, err := service.Formation(ctx, actor, int64(actor.PlayerID))
	if err != nil {
		t.Fatal(err)
	}
	if display.Occupant.Player != actor.PlayerID || len(display.Heroes) != 2 {
		t.Fatalf("board player %+v heroes=%d", display.Occupant, len(display.Heroes))
	}
	partners := []int64{}
	var power int64
	for _, hero := range display.Heroes {
		partners = append(partners, formValue(t, hero, "partner_id"))
		if _, ok := hero["force"]; ok {
			power += formValue(t, hero, "force")
		}
	}
	if !slices.Equal(partners, []int64{aquaris.PartnerID, lavia.PartnerID}) || display.Force != power {
		t.Fatalf("board partners %v force=%d want power %d from %v", partners, display.Force, power, []int64{aquaris.PartnerID, lavia.PartnerID})
	}
}
