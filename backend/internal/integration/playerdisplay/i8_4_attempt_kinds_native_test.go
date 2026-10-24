//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	combat "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errRollbackFixture = errors.New("i8-4 fixture rollback")

// kindStart is fixtureStart with a caller-chosen retry budget: concurrent
// STARTs on one locator abort as serialization failures and retry.
func (f kindFixture) start(request combat.StartRequest, attempts int) (combat.Started, error) {
	var started combat.Started
	s, rev := f.service, f.rev
	evidence := startEvidence{service: s, q: s.Fresh, locator: request.Locator, fingerprint: request.StartFingerprint}
	_, err := (tx.Runner{DB: f.pool}).Run(ctx, opPinned(rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: attempts, RetryDefiniteAbort: true}, evidence, func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		sc, err := ca.NewCoherentReadScope(scope, rev, at)
		if err != nil {
			return err
		}
		request.ResultDeadline = at.Add(time.Hour)
		started, err = s.StartTx(c, scope.Tx, sc, request)
		return err
	})
	return started, err
}

func (f kindFixture) attest(request combat.AttestRequest) (combat.Attested, error) {
	var attested combat.Attested
	s := f.service
	_, err := (tx.Runner{DB: f.pool}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		var err error
		attested, err = s.AttestTx(c, scope.Tx, request)
		return err
	})
	return attested, err
}

type kindFixture struct {
	pool    *pg.Pool
	actor   identity.ActorContext
	rev     string
	partner int64
	service combat.Service
	locator d.Locator
	builds  *atomic.Int32
}

func newKindFixture(t *testing.T, scope string) kindFixture {
	pool := pool(t)
	a, rev, ref := combatOwner(t, pool, rankingServer(t, pool))
	return kindFixture{pool: pool, actor: a, rev: rev, partner: ref.PartnerID, service: combatService(t, pool), builds: &atomic.Int32{},
		locator: d.Locator{DomainKind: "i8-4-fixture-mode", AuthorityScope: scope, DomainLocator: fmt.Sprint(a.PlayerID)}}
}

// request is a client-derived START: the server issues three seeds and the
// family answers a duplicate RESULT with FightExist.
func (f kindFixture) request(stage, generation string) combat.StartRequest {
	return combat.StartRequest{Actor: f.actor, Locator: f.locator, GenerationRef: generation, StartFingerprint: fingerprint(f.locator.AuthorityScope + "/" + stage),
		TrustProfile: d.ServerEntropyClientDerived, Replay: d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode},
		Package: func(stream *d.Stream) (any, error) {
			f.builds.Add(1)
			seeds := make([]int64, 3)
			for i := range seeds {
				seed, err := stream.Between(1, 1<<31-1)
				if err != nil {
					return nil, err
				}
				seeds[i] = seed
			}
			return map[string]any{"seeds": seeds}, nil
		},
		Battle: combat.BattleRequest{CampaignType: 1, TeamA: []combat.Participant{{Origin: d.OwnedSelf, Kind: d.HeroActor, Player: f.actor.PlayerID, Identity: f.partner}},
			WavesB: [][]combat.Participant{{{Origin: d.Template, Kind: d.HeroActor, Identity: 10001002, TemplateParams: templateParams(10001002)}}}}}
}

func (f kindFixture) attestRequest(generation, receipt string) combat.AttestRequest {
	return combat.AttestRequest{TerminalRequest: combat.TerminalRequest{Locator: f.locator, GenerationRef: generation, TerminalKind: "FIXTURE_ATTESTED", SemanticReceiptID: receipt, At: time.Now().UTC()},
		ValidatorID: "I8_4_FIXTURE_VALIDATOR_V1", ValidatorVersion: 1, Verdict: d.VerdictAccepted, Summary: map[string]any{"damage": 1234, "star": 3}}
}

func (f kindFixture) rows(t *testing.T, table string) int {
	t.Helper()
	var n int
	query := `SELECT count(*) FROM ` + table + ` r JOIN combat_attempts a USING(attempt_id) WHERE a.domain_kind=$1 AND a.authority_scope=$2 AND a.domain_locator=$3`
	if table == "combat_attempts" {
		query = `SELECT count(*) FROM combat_attempts WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3`
	}
	if err := f.service.Fresh.QueryRow(ctx, query, f.locator.DomainKind, f.locator.AuthorityScope, f.locator.DomainLocator).Scan(&n); err != nil {
		t.Fatal(table, err)
	}
	return n
}

// PASS120/PASS418 through the shared owner: a same-stage START replays the
// frozen package, a different stage supersedes, RESULT attests once and a
// duplicate RESULT answers from the pinned FightExist spec.
func TestI8_4ClientAttestedAttemptNative(t *testing.T) {
	f := newKindFixture(t, "attested")
	s := f.service
	first, err := f.start(f.request("stage-1", "g1"), 3)
	if err != nil {
		t.Fatal(err)
	}
	attempt := first.Attempt
	if attempt.ResolverStatus != d.ResolverNotRequired || attempt.TrustProfile != d.ServerEntropyClientDerived || first.Package == nil || first.Package.Draws == 0 || first.Superseded != nil {
		t.Fatal("client-derived START", attempt, first.Package)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, s.Fresh, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := d.DecodeSnapshot(raw, attempt.SnapshotHash)
	if err != nil || snapshot.Schema != d.SnapshotSchema || snapshot.TrustProfile != d.ServerEntropyClientDerived.ID {
		t.Fatal("schema 3 snapshot", snapshot.Schema, snapshot.TrustProfile, err)
	}
	builds := f.builds.Load()
	again, err := f.start(f.request("stage-1", "g1"), 3)
	if err != nil || !again.Replayed || again.Attempt.ID != attempt.ID || again.Package == nil || !bytes.Equal(again.Package.Canonical, first.Package.Canonical) || f.builds.Load() != builds {
		t.Fatal("same-stage START must replay the stored package without drawing", err)
	}
	if _, err = s.Resolve(ctx, op(), attempt.ID); !errors.Is(err, d.ErrNotReady) {
		t.Fatal("client-run attempt reached the resolver", err)
	}
	server := f.request("stage-1", "g1")
	server.TrustProfile, server.Replay, server.Package = d.TrustProfile{}, d.ReplaySpec{}, nil
	if _, err = f.start(server, 1); !errors.Is(err, d.ErrStartConflict) {
		t.Fatal("a different kind on the locator must conflict", err)
	}
	second, err := f.start(f.request("stage-2", "g2"), 3)
	if err != nil || second.Superseded == nil || second.Superseded.ID != attempt.ID || second.Attempt.SupersedesAttemptID != attempt.ID || second.Package == nil {
		t.Fatal("different-stage START must supersede", err)
	}
	old, found, err := s.AttemptTx(ctx, s.Fresh, attempt.ID)
	if err != nil || !found || old.State != d.Terminal || old.TerminalKind != d.SupersededKind || old.SemanticReceiptID != "superseded-by:"+second.Attempt.ID.String() {
		t.Fatal("superseded attempt", old, err)
	}
	if _, err = f.attest(f.attestRequest("g1", "late-result")); !errors.Is(err, d.ErrStale) {
		t.Fatal("late RESULT of a superseded stage must be refused", err)
	}
	done, err := f.attest(f.attestRequest("g2", "result-1"))
	if err != nil || done.Replayed || done.Attempt.State != d.Terminal || done.Attempt.ResolutionHash != "" || done.Attestation.Verdict != d.VerdictAccepted {
		t.Fatal("attest", done, err)
	}
	duplicate, err := f.attest(f.attestRequest("g2", "result-1"))
	if err != nil || !duplicate.Replayed || duplicate.Attempt.ID != second.Attempt.ID || !bytes.Equal(duplicate.Attestation.Summary, done.Attestation.Summary) || duplicate.Attempt.Replay != (d.ReplaySpec{Response: d.ReplayFightExist, ErrorCode: d.FightExistCode}) {
		t.Fatal("duplicate RESULT must replay FightExist", duplicate, err)
	}
	if _, err = s.ResultTx(ctx, s.Fresh, second.Attempt.ID); !errors.Is(err, d.ErrNotReady) {
		t.Fatal("attested attempt has no server report", err)
	}
	if n := [3]int{f.rows(t, "combat_attempts"), f.rows(t, "combat_start_packages"), f.rows(t, "combat_attestations")}; n != [3]int{2, 2, 1} {
		t.Fatal("rows", n)
	}
}

// Competing different-stage STARTs serialize on the rank-609 fence: one open
// attempt remains and the superseded ones form one linear chain.
func TestI8_4ConcurrentSupersedeNative(t *testing.T) {
	f := newKindFixture(t, "concurrent-supersede")
	initial, err := f.start(f.request("stage-0", "g0"), 3)
	if err != nil {
		t.Fatal(err)
	}
	const racers = 6
	var wg sync.WaitGroup
	errs := make([]error, racers)
	for i := range racers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, errs[i] = f.start(f.request(fmt.Sprint("stage-", i+1), fmt.Sprint("g", i+1)), 4*racers)
		}(i)
	}
	wg.Wait()
	if err = errors.Join(errs...); err != nil {
		t.Fatal(err)
	}
	links := map[string]string{}
	rows, err := f.pool.Raw().Query(ctx, `SELECT attempt_id::text,COALESCE(supersedes_attempt_id::text,''),state,COALESCE(terminal_kind,'') FROM combat_attempts WHERE domain_kind=$1 AND authority_scope=$2 AND domain_locator=$3`, f.locator.DomainKind, f.locator.AuthorityScope, f.locator.DomainLocator)
	if err != nil {
		t.Fatal(err)
	}
	open := ""
	for rows.Next() {
		var id, previous, state, kind string
		if err = rows.Scan(&id, &previous, &state, &kind); err != nil {
			t.Fatal(err)
		}
		links[previous] = id
		if state != string(d.Terminal) {
			open = id
		} else if kind != d.SupersededKind {
			t.Fatal("terminal attempt not superseded", id, kind)
		}
	}
	rows.Close()
	walk, hops := initial.Attempt.ID.String(), 0
	for links[walk] != "" {
		walk, hops = links[walk], hops+1
	}
	if len(links) != racers+1 || walk != open || hops != racers {
		t.Fatal("supersede chain", len(links), hops, walk, open)
	}
	same := f.request("stage-same", "g-same")
	started := make([]combat.Started, racers)
	for i := range racers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			started[i], errs[i] = f.start(same, 4*racers)
		}(i)
	}
	wg.Wait()
	for i := range racers {
		if errs[i] != nil || started[i].Attempt.ID != started[0].Attempt.ID || !bytes.Equal(started[i].Package.Canonical, started[0].Package.Canonical) {
			t.Fatal("concurrent same-stage START", i, errs[i])
		}
	}
	if n := f.rows(t, "combat_start_packages"); n != racers+2 {
		t.Fatal("one package per attempt", n)
	}
}

// The schema refuses what the domain refuses, and a rolled-back START leaves
// no attempt, snapshot reference or package behind.
func TestI8_4SchemaGuardsNative(t *testing.T) {
	f := newKindFixture(t, "guards")
	s := f.service
	started, err := f.start(f.request("stage-1", "g1"), 3)
	if err != nil {
		t.Fatal(err)
	}
	id := started.Attempt.ID.String()
	update := func(set string) string {
		return `UPDATE combat_attempts SET ` + set + `,state_version=state_version+1 WHERE attempt_id=$1`
	}
	// A copy of the row with one field changed; CHECKs run before the unique indexes.
	copied := func(fields string) string {
		return `INSERT INTO combat_attempts SELECT (jsonb_populate_record(NULL::combat_attempts,to_jsonb(a)||jsonb_build_object('attempt_id',gen_random_uuid(),` + fields + `))).* FROM combat_attempts a WHERE attempt_id=$1`
	}
	refused := map[string][2]string{
		"profile change":       {update(`trust_profile_id='CLIENT_SUMMARY_ATTESTED_V1'`), "transition refused"},
		"replay change":        {update(`replay_response='OK',replay_error_code=0`), "transition refused"},
		"entropy policy":       {update(`entropy_policy_version='X'`), "transition refused"},
		"chain change":         {update(`supersedes_attempt_id=gen_random_uuid()`), "transition refused"},
		"leave NOT_REQUIRED":   {update(`resolver_status='PENDING'`), "transition refused"},
		"package update":       {`UPDATE combat_start_packages SET draws=draws+1 WHERE attempt_id=$1`, "immutable"},
		"package delete":       {`DELETE FROM combat_start_packages WHERE attempt_id=$1`, "immutable"},
		"unknown profile":      {copied(`'trust_profile_id','CLIENT_GUESS_V1'`), "combat_attempts_trust_profile_id_check"},
		"server NOT_REQUIRED":  {copied(`'trust_profile_id','SERVER_REPORT_AUTHORITATIVE_V1'`), "combat_attempts_server_resolution"},
		"stored report client": {copied(`'replay_response','STORED_REPORT','replay_error_code',0`), "combat_attempts_replay_report"},
		"FightExist uncoded":   {copied(`'replay_error_code',0`), "combat_attempts_replay_code"},
		"chain to itself":      {copied(`'attempt_id','00000000-0000-4000-8000-0000000000aa','supersedes_attempt_id','00000000-0000-4000-8000-0000000000aa'`), "combat_attempts_supersede_chain"},
	}
	for name, case_ := range refused {
		if _, err = f.pool.Raw().Exec(ctx, case_[0], id); err == nil || !strings.Contains(err.Error(), case_[1]) {
			t.Fatal("schema accepted", name, err)
		}
	}
	rolledBack := f.request("stage-rollback", "g-rollback")
	rolledBack.Locator.DomainLocator += "/rollback"
	_, err = (tx.Runner{DB: f.pool}).Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		var at time.Time
		if err := scope.Tx.QueryRow(c, "SELECT clock_timestamp()").Scan(&at); err != nil {
			return err
		}
		sc, err := ca.NewCoherentReadScope(scope, f.rev, at)
		if err != nil {
			return err
		}
		rolledBack.ResultDeadline = at.Add(time.Hour)
		if _, err = s.StartTx(c, scope.Tx, sc, rolledBack); err != nil {
			return err
		}
		return errRollbackFixture
	})
	if !errors.Is(err, errRollbackFixture) {
		t.Fatal("rollback fixture", err)
	}
	var n int
	if err = s.Fresh.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE domain_locator=$1`, rolledBack.Locator.DomainLocator).Scan(&n); err != nil || n != 0 {
		t.Fatal("rolled-back START left an attempt", n, err)
	}
}

// Rows written before 00073 read back unchanged: every attempt validates as a
// server-report attempt answering with its stored report, every snapshot keeps
// its bytes and every terminal resolution replays. GXB_I8_4_EXPECT_LEGACY=1
// (G1 populated upgrade) requires schema 1 rows from the frozen 747 product.
func TestI8_4UpgradedRowsReadableNative(t *testing.T) {
	pool := pool(t)
	s := combatService(t, pool)
	snapshots := map[int]int{}
	rows, err := pool.Raw().Query(ctx, `SELECT snapshot_hash,canonical FROM combat_snapshots`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var hash string
		var raw []byte
		if err = rows.Scan(&hash, &raw); err != nil {
			t.Fatal(err)
		}
		snapshot, err := d.DecodeSnapshot(raw, hash)
		if err != nil {
			t.Fatal("snapshot", hash, err)
		}
		snapshots[snapshot.Schema]++
	}
	rows.Close()
	var attemptIDs []string
	rows, err = pool.Raw().Query(ctx, `SELECT attempt_id::text FROM combat_attempts WHERE trust_profile_id='SERVER_REPORT_AUTHORITATIVE_V1'`)
	if err != nil {
		t.Fatal(err)
	}
	for rows.Next() {
		var id string
		if err = rows.Scan(&id); err != nil {
			t.Fatal(err)
		}
		attemptIDs = append(attemptIDs, id)
	}
	rows.Close()
	replayed := 0
	for _, raw := range attemptIDs {
		id, err := ids.ParseUUID(raw)
		if err != nil {
			t.Fatal(err)
		}
		attempt, found, err := s.AttemptTx(ctx, pool, id)
		if err != nil || !found || attempt.Replay != (d.ReplaySpec{Response: d.ReplayStoredReport}) || !attempt.SupersedesAttemptID.IsZero() {
			t.Fatal("server attempt", raw, attempt.Replay, err)
		}
		if attempt.State != d.Terminal || attempt.ResolutionHash == "" {
			continue
		}
		if _, err = s.ResultTx(ctx, pool, id); err != nil {
			t.Fatal("stored report", raw, err)
		}
		replayed++
	}
	t.Logf("snapshots by schema %v; server attempts %d; stored reports replayed %d", snapshots, len(attemptIDs), replayed)
	if os.Getenv("GXB_I8_4_EXPECT_LEGACY") == "1" && (snapshots[d.LegacySnapshotSchema] == 0 || replayed == 0) {
		t.Fatal("populated upgrade carried no legacy combat rows")
	}
}
