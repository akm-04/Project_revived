//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/missioninputs"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type missionClock struct{ at time.Time }

func (c *missionClock) Now(context.Context) (time.Time, error) { return c.at, nil }

func runtimeActor(t *testing.T, p *pg.Pool, at time.Time) identity.ActorContext {
	t.Helper()
	ctx := context.Background()
	pid := missionPlayer(t, p)
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	game, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	var account string
	if err = p.QueryRow(ctx, `SELECT account_id::text FROM players WHERE player_id=$1`, int64(pid)).Scan(&account); err != nil {
		t.Fatal(err)
	}
	for _, row := range []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i94', $3,$3)`, []any{session.String(), account, at.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,$5)`, []any{game.String(), session.String(), account, int64(pid), at.Add(-time.Hour)}},
	} {
		if _, err = p.Raw().Exec(ctx, row.sql, row.args...); err != nil {
			t.Fatal(err)
		}
	}
	accountUUID, err := ids.ParseUUID(account)
	if err != nil {
		t.Fatal(err)
	}
	if err = nativebirth.PersistBare(ctx, p, accountUUID, 1, pid); err != nil {
		t.Fatal(err)
	}
	if _, err = p.Raw().Exec(ctx, `UPDATE player_progression SET level=10,exp=0,updated_at=$2 WHERE player_id=$1`, int64(pid), at.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	aid, _ := identity.AccountIDFrom(accountUUID)
	sid, _ := identity.SessionIDFrom(session)
	cid, _ := identity.ContextIDFrom(game)
	return identity.ActorContext{PlayerID: pid, AccountID: aid, AccountUID: identity.AccountUID(account), SessionID: sid, ContextID: cid, LogicalServerID: 1, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}

func runtimeService(p *pg.Pool, time *missionClock) i5.Service {
	store := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}
	materializer := &i5.MissionMaterializer{Store: store, Catalog: content, Observations: missioninputs.Reader{Heroes: characterstore.Store{Queryer: p}, Progression: store, Campaigns: campaignstore.Store{}, Privileges: privileges}}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: store, Content: content, Privileges: privileges, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Functions: i5.LevelFunctionAnnouncements{}, Missions: materializer, MissionTime: time, MissionFresh: p}
}

func runtimeOperation(t *testing.T, at time.Time) operation.Context {
	t.Helper()
	factory := operation.Factory{Clock: clock.Fixed{T: at}}
	op, err := factory.New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return op
}

func TestMissionRuntimeNativeClaimFactReplayConcurrencyAndRollover(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 20, 59, 50, 0, time.UTC)
	a := runtimeActor(t, p, at)
	ticker := &missionClock{at: at}
	service := runtimeService(p, ticker)

	trSeed, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	campaignStore := campaignstore.Store{}
	campaignRecord, err := campaignStore.LockTx(ctx, trSeed, a.PlayerID, at)
	if err != nil {
		trSeed.Rollback(ctx)
		t.Fatal(err)
	}
	campaignRecord.Progress.Nodes = map[int64]campaign.NodeState{100015: {CampaignID: 100015, Star: 1, ClearCountFloor: 1, ClearCountExact: true}}
	if err = campaignStore.SaveTx(ctx, trSeed, a.PlayerID, campaignRecord, []int64{100015}, at); err != nil {
		trSeed.Rollback(ctx)
		t.Fatal(err)
	}
	if err = trSeed.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := service.ReadMissions(ctx, a, objective.Daily, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	if _, err := service.ClaimMission(ctx, a, 10002, "", runtimeOperation(t, at)); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("incomplete claim: %v", err)
	}
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	op := runtimeOperation(t, at)
	op.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: catalog.RevisionID()})
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		t.Fatal(err)
	}
	facts := i5.ObjectiveFacts{Owner: service, Open: i5store.Store{}}
	apply := func(tr tx.Tx, source string, delta int64) error {
		prepared, err := facts.PrepareTx(ctx, tr, a.PlayerID, timed)
		if err != nil {
			return err
		}
		return facts.RecordTx(prepared, tr, op, objective.Fact{PlayerID: a.PlayerID, SourceDomain: "campaign", SourceBusinessKey: source, Kind: "CAMPAIGN_NORMAL_WIN", Delta: delta})
	}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = apply(tr, "rollback", 20); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	tr.Rollback(ctx)
	for i := 0; i < 2; i++ {
		tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		if err = apply(tr, "battle-1", 20); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	var progress int64
	if err = p.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=10002 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID)).Scan(&progress); err != nil || progress != 20 {
		t.Fatalf("fact deduplication: %d %v", progress, err)
	}
	var wg sync.WaitGroup
	failures := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := service.ClaimMission(ctx, a, 10002, "", runtimeOperation(t, at))
			failures <- err
		}()
	}
	wg.Wait()
	close(failures)
	for err := range failures {
		if err != nil {
			t.Fatal(err)
		}
	}
	root, err := service.Missions.Store.ReadMissionRootTx(ctx, p, a.PlayerID)
	if err != nil || root.DayHuoyue != 20 {
		t.Fatalf("claim once medals %+v %v", root, err)
	}

	if _, err = service.ClaimMission(ctx, a, 50001, "", runtimeOperation(t, at)); err != nil {
		t.Fatalf("chain grant: %v", err)
	}
	var nextComplete bool
	if err = p.QueryRow(ctx, `SELECT completed_at IS NOT NULL FROM player_mission_instances WHERE player_id=$1 AND objective_id=50002 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID)).Scan(&nextComplete); err != nil || !nextComplete {
		t.Fatalf("chain high-water at creation: %v %v", nextComplete, err)
	}
	var itemCount int64
	if err = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=40001008`, int64(a.PlayerID)).Scan(&itemCount); err != nil || itemCount != 10 {
		t.Fatalf("chain reward %d %v", itemCount, err)
	}
	if _, err = service.ClaimMission(ctx, a, 50001, "", runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	if err = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=40001008`, int64(a.PlayerID)).Scan(&itemCount); err != nil || itemCount != 10 {
		t.Fatalf("replayed chain reward %d %v", itemCount, err)
	}
	// Crossing the reset is test-only; production keeps PostgreSQL AuthoritativeTime.
	ticker.at = at.Add(20 * time.Second)
	if _, err = service.ReadMissions(ctx, a, objective.Daily, runtimeOperation(t, ticker.at)); err != nil {
		t.Fatal(err)
	}
	if err = p.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=10002 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID)).Scan(&progress); err != nil || progress != 0 {
		t.Fatalf("daily reset %d %v", progress, err)
	}
	timed, err = gen.NewTimedOperation(op, ticker.at)
	if err != nil {
		t.Fatal(err)
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = apply(tr, "battle-1", 20); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err = p.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=10002 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID)).Scan(&progress); err != nil || progress != 0 {
		t.Fatalf("old fact credited new day %d %v", progress, err)
	}
}

type lostMissionCommit struct{ tx.Tx }

func (t lostMissionCommit) Commit(ctx context.Context) error {
	if err := t.Tx.Commit(ctx); err != nil {
		return err
	}
	return errors.New("test-only lost COMMIT acknowledgement")
}

type loseFirstMissionCommit struct {
	db   tx.Beginner
	lost bool
}

func (b *loseFirstMissionCommit) Begin(ctx context.Context, options tx.Options) (tx.Tx, error) {
	tr, err := b.db.Begin(ctx, options)
	if err != nil {
		return nil, err
	}
	if !b.lost {
		b.lost = true
		return lostMissionCommit{tr}, nil
	}
	return tr, nil
}

func TestMissionRuntimeNativeLostCommitReconcilesWithoutSecondGrant(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 5, 0, 0, 0, time.UTC)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	// A source-backed meal has a genuine temporal reward and needs no fabricated completion.
	service.Runner.DB = &loseFirstMissionCommit{db: p}
	result, err := service.ClaimMission(ctx, a, 10011, "", runtimeOperation(t, at))
	if err != nil || !result.Replayed || result.Grant == nil {
		t.Fatalf("committed receipt recovery: %+v %v", result, err)
	}
	var first int64
	if err = p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID)).Scan(&first); err != nil {
		t.Fatal(err)
	}
	if _, err = service.ClaimMission(ctx, a, 10011, "", runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	var second int64
	if err = p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`, int64(a.PlayerID)).Scan(&second); err != nil || second != first {
		t.Fatalf("replay temporal grant %d -> %d %v", first, second, err)
	}
}
