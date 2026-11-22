//go:build postgres

package playerdisplay_test

import (
	"slices"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestI9_10ArenaPresetDefenseRequiresCompleteTeamNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := arenaService(t, pool)
	partialActor, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))

	if _, err := service.Info(ctx, partialActor, op()); err != nil {
		t.Fatal(err)
	}
	if saved := arenaPlayer(t, pool, partialActor.PlayerID); len(saved.Defense.Heroes) != 0 {
		t.Fatalf("four preset girls produced an incomplete Arena defense %v", saved.Defense.Heroes)
	}

	revision := installed(t, pool)
	bornHero(t, pool, partialActor, revision, 10001019, 2000)
	info, err := service.Info(ctx, partialActor, op())
	if err != nil {
		t.Fatal(err)
	}
	if len(info.Player.Defense.Heroes) != 0 {
		t.Fatalf("Arena entry filled a defense after the player's first entry: %v", info.Player.Defense.Heroes)
	}

	completeActor, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	bornHero(t, pool, completeActor, revision, 10001019, 2000)
	info, err = service.Info(ctx, completeActor, op())
	if err != nil {
		t.Fatal(err)
	}
	wantPreset := []int64{10001001, 10001002, 10001003, 10001004, 10001019}
	if !slices.Equal(info.Player.Defense.Heroes, wantPreset) {
		t.Fatalf("Arena defense %v, want D511 team %v", info.Player.Defense.Heroes, wantPreset)
	}
	if saved := arenaPlayer(t, pool, completeActor.PlayerID); !slices.Equal(saved.Defense.Heroes, wantPreset) {
		t.Fatalf("persisted Arena defense %v, want %v", saved.Defense.Heroes, wantPreset)
	}

	attacker, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	if _, err = service.Info(ctx, attacker, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(completeActor.PlayerID))
	enemy, err := service.Match(ctx, attacker, false, op())
	if err != nil || enemy.Face.Player != completeActor.PlayerID || len(enemy.Heroes) != 5 {
		t.Fatalf("seeded Arena defense was not matchable: face=%+v heroes=%d err=%v", enemy.Face, len(enemy.Heroes), err)
	}

	manualDefense := []int64{10001001, 10001002, 10001003, 10001004, 10001005}
	if _, err = service.ModifyDefence(ctx, completeActor, manualDefense, 0, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = service.Info(ctx, completeActor, op()); err != nil {
		t.Fatal(err)
	}
	if saved := arenaPlayer(t, pool, completeActor.PlayerID); !slices.Equal(saved.Defense.Heroes, manualDefense) {
		t.Fatalf("Arena entry replaced saved defense %v with %v", saved.Defense.Heroes, manualDefense)
	}
}

func arenaPlayer(t *testing.T, pool *pg.Pool, player identity.PlayerID) d.Player {
	t.Helper()
	stored, found, err := (arenastore.Store{}).ReadPlayerTx(ctx, pool, player, false)
	if err != nil || !found {
		t.Fatalf("Arena player %d found=%v err=%v", player, found, err)
	}
	return stored
}
