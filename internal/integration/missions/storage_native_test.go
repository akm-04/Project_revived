//go:build postgres

package missions_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func missionPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I94_DSN")
	if dsn == "" {
		t.Fatal("GXB_I94_DSN required")
	}
	p, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	config := p.Raw().Config().ConnConfig
	if !strings.HasPrefix(config.Database, "i94_") || config.Port != 55853 {
		t.Fatal("native mission tests require isolated i94 database on 55853")
	}
	return p
}

func missionPlayer(t *testing.T, p *pg.Pool) identity.PlayerID {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err := tr.Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)
VALUES(1,'i94-native',true,true,true,125001,199999,clock_timestamp()) ON CONFLICT(logical_server_id) DO NOTHING`); err != nil {
		t.Fatal(err)
	}
	var player int64
	if err := tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&player); err != nil {
		t.Fatal(err)
	}
	if _, err := tr.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',clock_timestamp())`, account.String(), account.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := tr.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,clock_timestamp(),'i94-native')`, player, account.String()); err != nil {
		t.Fatal(err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return identity.PlayerID(player)
}

// storageObservations isolates storage/reducer qualification; it is not proof of canonical owner-read composition.
type storageObservations struct{}

func (storageObservations) MissionPartnerTemplatesTx(context.Context, tx.Queryer, i5.MissionScope) ([]int64, error) {
	return nil, nil
}
func (storageObservations) ObserveMissionTx(_ context.Context, _ tx.Queryer, _ i5.MissionScope, definition objective.MissionDefinition, _ int64) (i5.MissionObservation, error) {
	return i5.MissionObservation{GatePassed: definition.ObjectiveID == 10002 || definition.ObjectiveID == 50001 || definition.ObjectiveID == 50002, Value: 100}, nil
}

func TestMissionStorageNativeMaterializationAndRollover(t *testing.T) {
	p := missionPool(t)
	player := missionPlayer(t, p)
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 10, 25, 20, 59, 59, 0, time.UTC)
	scope := i5.MissionScope{PlayerID: player, ContentRevision: catalog.RevisionID(), DecisionAt: at}
	store := i5store.Store{}
	materializer := i5.MissionMaterializer{Store: store, Catalog: contentstore.Store{}, Observations: storageObservations{}}
	apply := func() i5.MissionView {
		t.Helper()
		ctx := context.Background()
		tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		defer tr.Rollback(ctx)
		view, err := materializer.MaterializeTx(ctx, tr, scope)
		if err != nil {
			t.Fatal(err)
		}
		if err := tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
		return view
	}
	view := apply()
	if len(view.Instances) != 2 {
		t.Fatalf("materialized rows %d, want 2", len(view.Instances))
	}
	for _, row := range view.Instances {
		if row.ObjectiveID == 50001 && row.CompletedAt == nil {
			t.Fatal("high-water row incomplete at creation")
		}
	}
	if repeated := apply(); len(repeated.Instances) != 2 {
		t.Fatal("repeated read duplicated rows")
	}
	old := view.Instances[0].GenerationID
	scope.DecisionAt = at.Add(time.Second)
	view = apply()
	if len(view.Instances) != 2 || view.Instances[0].GenerationID == old || view.Root.StateVersion != 2 {
		t.Fatalf("rollover failed: %+v", view)
	}
}

func TestMissionStorageNativeConcurrentRootCreation(t *testing.T) {
	p := missionPool(t)
	player := missionPlayer(t, p)
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	errors := make(chan error, 2)
	start := make(chan struct{})
	for range 2 {
		go func() {
			<-start
			tr, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
			if err != nil {
				errors <- err
				return
			}
			defer tr.Rollback(ctx)
			store := i5store.Store{}
			root, err := store.LockMissionRootTx(ctx, tr, player, time.Date(2026, 10, 26, 3, 0, 0, 0, time.UTC))
			if err == nil {
				old := root.StateVersion
				root.DayHuoyue++
				root.StateVersion++
				err = store.SaveMissionRootTx(ctx, tr, root, old)
			}
			if err == nil {
				err = tr.Commit(ctx)
			}
			errors <- err
		}()
	}
	close(start)
	for range 2 {
		if err := <-errors; err != nil {
			t.Fatal(err)
		}
	}
	root, err := (i5store.Store{}).ReadMissionRootTx(ctx, p, player)
	if err != nil || root.DayHuoyue != 2 || root.StateVersion != 3 {
		t.Fatalf("concurrent root updates lost: %+v %v", root, err)
	}
}
