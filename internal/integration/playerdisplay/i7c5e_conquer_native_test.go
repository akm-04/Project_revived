//go:build postgres

package playerdisplay_test

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/conquerschool"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func conquerMode(t *testing.T, p *pg.Pool) app.Mode {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	grants := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c5e-conquer-native-fixture-secret0")}
	return app.Mode{Facts: conquerService(p), Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Store: conquerstore.Store{}, Content: content,
		Fence: values, Functions: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Grants: grants, Mail: i5.SettlementMail{Store: values},
		Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Projection: i4store.DirectoryLevelProjection{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// conquerPlayer is a level-100 owner with function 48 open and 15 girls.
func conquerPlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, []int64) {
	t.Helper()
	a, heroes := oneOnOnePlayer(t, p, server)
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,48,$2,'function.lua:48:1|100',clock_timestamp()-interval '1 minute')`, int64(a.PlayerID), installed(t, p))
	return a, heroes
}

// conquerWin beats one team with the given girls.
func conquerWin(t *testing.T, s app.Mode, a identity.ActorContext, mission, team int64, girls []int64, alive, damage int64) d.ResultView {
	t.Helper()
	if _, err := s.Start(ctx, a, girls, 0, op()); err != nil {
		t.Fatal("start", mission, team, err)
	}
	v, err := s.Result(ctx, a, d.Result{CampaignID: mission, TeamID: team, Win: true, Formation: girls, Alive: alive, Damage: damage}, json.RawMessage(`{"fighter":{}}`), op())
	if err != nil {
		t.Fatal("result", mission, team, err)
	}
	return v
}

func TestI7C5EConquerProgressionNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := conquerMode(t, pool)
	server := rankingServer(t, pool)
	a, girls := conquerPlayer(t, pool, server)
	rev := installed(t, pool)

	// E01: function 48 (Lv100) gates the mode; the first INFO starts run 1 at mission 10001.
	low, _, _ := combatOwner(t, pool, server)
	if _, err := s.Info(ctx, low, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("closed function entered", err)
	}
	info, err := s.Info(ctx, a, op())
	if err != nil || info.Run.Loop != 1 || info.Run.CurrentID != 10001 || info.Run.PassedID != 0 || info.Mode.LeftTimes != 10 || info.Teams != 1 {
		t.Fatalf("first info %+v %v", info, err)
	}
	facts, err := (conquerstore.Store{}).ReadFactsTx(ctx, pool, a.PlayerID)
	if err != nil || facts.Payload.Kind != d.Retained || facts.Payload.Run == nil || *facts.Payload.Progress != (d.Progress{Level: 0, Loop: 1}) {
		t.Fatalf("facts after first info %+v %v", facts, err)
	}

	// E02: START validates owned girls; a loss spends the chance and adds one buff.
	if _, err = s.Start(ctx, a, []int64{999999}, 0, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unowned girl", err)
	}
	if _, err = s.Start(ctx, a, girls[:2], 0, op()); err != nil {
		t.Fatal(err)
	}
	lost, err := s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Formation: girls[:2]}, json.RawMessage(`{}`), op())
	if err != nil || lost.Promoted || lost.Info.Mode.Buff != 1 || lost.Info.Mode.LeftTimes != 9 {
		t.Fatalf("loss %+v %v", lost, err)
	}
	if _, err = s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Formation: girls[:2], Win: true}, json.RawMessage(`{}`), op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("result without an open attempt", err)
	}

	// E03: beating mission 1 promotes: I5 reward, facts progress/run, directory, MID1 17, kept report.
	won := conquerWin(t, s, a, 10001, 1, girls[:2], 2, 5000)
	if !won.Promoted || won.Progress != (d.Progress{Level: 1, Loop: 1}) || won.Info.Run.CurrentID != 10002 || won.Info.Mode.Buff != 0 || won.Info.Mode.LeftTimes != 10 {
		t.Fatalf("promotion %+v", won)
	}
	if scalar(t, pool, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=20001157`, int64(a.PlayerID)) < 1 ||
		scalar(t, pool, `SELECT conquer_lev FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM conquer_school_reports WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM gxb_operation_receipts WHERE domain='conquer-school' AND owner_key=$1`, fmt.Sprint(int64(a.PlayerID))) != 2 {
		t.Fatal("promotion effects")
	}
	detail := map[string]any{"17": map[string]any{}}
	if err = (conquerstore.BootstrapProjection{Content: contentstore.Store{Queryer: pool}}).OverlayMID1(ctx, pool, a, false, won.Info.Mode.UpdatedAt, detail); err != nil {
		t.Fatal(err)
	}
	if mid17 := detail["17"].(map[string]any); mid17["conquer_lev"] != int64(1) || mid17["conquer_loop_id"] != int64(1) || mid17["conquer_region"] != int64(0) {
		t.Fatal("MID17", mid17)
	}

	// E04: a won team's girls are used for the mission; RESET clears them and keeps the buff.
	conquerWin(t, s, a, 10002, 1, girls[:1], 1, 10)
	if _, err = s.Start(ctx, a, girls[:1], 0, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("used girl started", err)
	}
	reset, err := s.Reset(ctx, a, op())
	if err != nil || len(reset.Mode.BeatenTeams) != 0 || len(reset.Mode.UsedHeroes) != 0 {
		t.Fatalf("reset %+v %v", reset, err)
	}

	// E05: BUY needs the monthly card (the baseline provider has none).
	if _, err = s.Buy(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("buy without monthly card", err)
	}

	// E06: progress through mission 20 opens region 1 for the Combat conquer contribution.
	catalog, err := (contentstore.Store{Queryer: pool}).ConquerModeCatalogTx(ctx, pool, rev)
	if err != nil {
		t.Fatal(err)
	}
	for _, mission := range catalog.Missions[1:20] {
		for team := int64(1); team <= mission.Teams; team++ {
			conquerWin(t, s, a, mission.ID, team, girls[team*2:team*2+2], 1, 1)
		}
	}
	observed, err := conquerRead(t, pool, conquerService(pool), a, rev, girls[0])
	if err != nil || observed.Observation.Facts.Payload.Progress.Level != 20 || observed.Observation.Contributions[5] != 100 || observed.Observation.Contributions[6] != 200 {
		t.Fatalf("combat conquer contribution %+v %v", observed.Observation, err)
	}

	// E07 (2J amendment): facts written under an earlier registered revision stay readable.
	raw := make([]byte, 32)
	rand.Read(raw)
	earlier := hex.EncodeToString(raw)
	exec(t, pool, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)VALUES($1,decode($1,'hex'),1,'i7c5e-native-earlier','native',
jsonb_build_object('revision_id',$1::text,'schema_version',1,'compiler_version','i7c5e-native-earlier','parser_version','native'))`, earlier)
	exec(t, pool, `UPDATE player_conquer_facts SET content_revision=$2 WHERE player_id=$1`, int64(a.PlayerID), earlier)
	if observed, err = conquerRead(t, pool, conquerService(pool), a, rev, girls[0]); err != nil || observed.Observation.Contributions[5] != 100 {
		t.Fatalf("earlier-revision facts %+v %v", observed.Observation, err)
	}
	if _, err = s.Info(ctx, a, op()); err != nil {
		t.Fatal("mode after a content deploy", err)
	}
}

func TestI7C5EConquerConcurrencyAndReportViewsNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := conquerMode(t, pool)
	server := rankingServer(t, pool)
	a, girls := conquerPlayer(t, pool, server)
	viewers := []identity.ActorContext{}
	for range 2 {
		v, _ := conquerPlayer(t, pool, server)
		viewers = append(viewers, v)
	}
	if _, err := s.Info(ctx, a, op()); err != nil {
		t.Fatal(err)
	}

	// E08: two RESULTs of one attempt serialize: one settles, the other is refused; one grant.
	// The damage grows per run so this run's report outranks earlier runs' equal-alive reports.
	damage := time.Now().UnixNano() % d.MaxDamage
	if _, err := s.Start(ctx, a, girls[:3], 0, op()); err != nil {
		t.Fatal(err)
	}
	var wait sync.WaitGroup
	errs := make([]error, 2)
	for i := range errs {
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, errs[i] = s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Win: true, Formation: girls[:3], Alive: 6, Damage: damage}, json.RawMessage(`{"fighter":{}}`), op())
		}()
	}
	wait.Wait()
	if (errs[0] == nil) == (errs[1] == nil) || scalar(t, pool, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=20001157`, int64(a.PlayerID)) != 1 {
		t.Fatal("concurrent results", errs)
	}

	// E09: report list answers the kept report; a viewer's first view mails the owner, a repeat does not.
	reports, err := s.Reports(ctx, 1, 10001, 1, op())
	if err != nil || len(reports) == 0 {
		t.Fatal("reports", reports, err)
	}
	key := ""
	for _, r := range reports {
		if r.Owner == a.PlayerID {
			key = r.Key
		}
	}
	if key == "" {
		t.Fatal("owner report missing from the best three")
	}
	mails := func() int64 {
		return scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='CONQUER_SCHOOL_REPORT_VIEW'`, int64(a.PlayerID))
	}
	for range 2 {
		if _, err = s.Report(ctx, viewers[0], key, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.Report(ctx, a, key, op()); err != nil || mails() != 1 {
		t.Fatal("first view reward", mails(), err)
	}

	// E10: rewarded views stop at report_reward_limit (10) per owner per day.
	exec(t, pool, `UPDATE conquer_school_players SET state=jsonb_set(state,'{report_award_times}','10') WHERE player_id=$1`, int64(a.PlayerID))
	if _, err = s.Report(ctx, viewers[1], key, op()); err != nil || mails() != 1 {
		t.Fatal("view reward over the daily limit", mails(), err)
	}
	if _, err = s.Report(ctx, viewers[1], "not-a-key", op()); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("malformed report key", err)
	}
}
