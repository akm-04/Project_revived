//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	combat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// fixtureRoom is the I8 test SHARED_ROOM_CORE capability (D24c): it admits
// exactly one member set, in any seat order.
type fixtureRoom struct {
	members []identity.PlayerID
}

func (r fixtureRoom) AdmitTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, admission combat.Admission) error {
	want, got := slices.Sorted(slices.Values(r.members)), slices.Sorted(slices.Values(admission.Members))
	if !slices.Equal(want, got) {
		return d.ErrRoomRefused
	}
	return nil
}

type memberFixture struct {
	pool    *pg.Pool
	rev     string
	service combat.Service
	members []identity.ActorContext
	heroes  []character.HeroRef
}

// newMemberFixture: three genuine owners, each with a Hero born through the
// production chain, admitted together by the fixture room.
func newMemberFixture(t *testing.T) memberFixture {
	pool := pool(t)
	f := memberFixture{pool: pool, service: combatService(t, pool)}
	server := rankingServer(t, pool)
	room := fixtureRoom{}
	for range 3 {
		member, rev, hero := combatOwner(t, pool, server)
		f.members, f.heroes, f.rev = append(f.members, member), append(f.heroes, hero), rev
		room.members = append(room.members, member.PlayerID)
	}
	f.service.Inputs.Rooms = room
	return f
}

func (f memberFixture) locator(scope string) d.Locator {
	return d.Locator{DomainKind: "i8-6c-fixture-mode", AuthorityScope: scope, DomainLocator: fmt.Sprint(f.members[0].PlayerID)}
}

// request has member `convener` start the room's fight: every member fields
// its own Hero against the single monster wave of fight 10000.
func (f memberFixture) request(t *testing.T, scope string, convener int) combat.StartRequest {
	t.Helper()
	locator := f.locator(scope)
	request := combat.StartRequest{Actor: f.members[convener], Locator: locator, GenerationRef: "fixture-generation-1", StartFingerprint: fingerprint(locator.AuthorityScope + locator.DomainLocator),
		Battle: combat.BattleRequest{CampaignType: 1, BattleID: singleWaveFight, WavesB: must(combat.MonsterWaves(f.service.Rules, singleWaveFight))(t, "monster waves")}}
	for i := range f.members {
		seat := (convener + i) % len(f.members)
		origin := d.OwnedMember
		if i == 0 {
			origin = d.OwnedSelf
		}
		request.Members = append(request.Members, f.members[seat].PlayerID)
		request.Battle.TeamA = append(request.Battle.TeamA, combat.Participant{Origin: origin, Kind: d.HeroActor, Player: f.members[seat].PlayerID, Identity: f.heroes[seat].PartnerID})
	}
	return request
}

func (f memberFixture) attempts(t *testing.T) int64 {
	return scalar(t, f.pool, `SELECT count(*) FROM combat_attempts WHERE domain_kind='i8-6c-fixture-mode' AND domain_locator=$1`, fmt.Sprint(f.members[0].PlayerID))
}

func (f memberFixture) roster(t *testing.T, attempt d.Attempt) []identity.PlayerID {
	t.Helper()
	var out []identity.PlayerID
	for _, member := range must((combatstore.Store{}).ReadMembersTx(ctx, f.pool, attempt.ID))(t, "roster") {
		out = append(out, identity.PlayerID(member))
	}
	return out
}

func (f memberFixture) settlements(t *testing.T, attempt d.Attempt) int64 {
	return scalar(t, f.pool, `SELECT count(*) FROM combat_member_settlements WHERE attempt_id=$1`, attempt.ID.String())
}

// settle is the mode's per-member fan-out step after its single terminal.
func (f memberFixture) settle(t *testing.T, attempt d.Attempt, member identity.PlayerID, receipt string) (combat.MemberSettled, error) {
	t.Helper()
	var settled combat.MemberSettled
	runner := tx.Runner{DB: f.pool}
	_, err := runner.Run(ctx, opPinned(f.rev), combatTestProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, scope tx.Scope) error {
		var err error
		settled, err = f.service.SettleMemberTx(c, scope.Tx, combat.MemberSettleRequest{Locator: attempt.Locator, AttemptID: attempt.ID, Member: member, SemanticReceiptID: receipt, At: time.Now()})
		return err
	})
	return settled, err
}

// resolve retries a saturated worker pool; duplicates race the same attempt.
func (f memberFixture) resolve(t *testing.T, attempt d.Attempt) (combat.Resolved, error) {
	for {
		resolved, err := f.service.Resolve(ctx, op(), attempt.ID)
		if !errors.Is(err, combat.ErrWorkerSaturated) {
			return resolved, err
		}
		time.Sleep(200 * time.Millisecond)
	}
}

// B8-01, B8-02, B8-05: roster START, refusals with zero writes, and a
// duplicate scheduler tick replaying the terminal and member settlement.
func TestI8_6CMemberAttemptNative(t *testing.T) {
	f := newMemberFixture(t)
	s := f.service
	request := f.request(t, "members", 0)

	// B8-01: the convener freezes OWNED_SELF and each member OWNED_MEMBER in its
	// own view; the roster is stored by seat and a replay freezes nothing.
	started := must(fixtureStart(t, s, f.rev, request, f.pool))(t, "member START")
	raw := must((combatstore.Store{}).ReadSnapshotTx(ctx, f.pool, started.Attempt.SnapshotHash))(t, "snapshot")
	snapshot := must(d.DecodeSnapshot(raw, started.Attempt.SnapshotHash))(t, "decode")
	for i, a := range snapshot.Battle.TeamA {
		want := d.OwnedMember
		if i == 0 {
			want = d.OwnedSelf
		}
		if a.Origin != want || a.Player != int64(f.members[i].PlayerID) || a.OwnerStateVersion <= 0 || len(a.BattleTotals) == 0 {
			t.Fatalf("B8-01 actor %d %+v", i, a)
		}
	}
	if len(snapshot.Players) != 3 || !slices.Equal(f.roster(t, started.Attempt), request.Members) {
		t.Fatal("B8-01 players or roster", snapshot.Players, f.roster(t, started.Attempt))
	}
	again := must(fixtureStart(t, s, f.rev, request, f.pool))(t, "replay")
	if !again.Replayed || again.Attempt.ID != started.Attempt.ID {
		t.Fatal("B8-01 replay")
	}
	reordered := request
	reordered.Members = []identity.PlayerID{request.Members[0], request.Members[2], request.Members[1]}
	if _, err := fixtureStart(t, s, f.rev, reordered, f.pool); !errors.Is(err, d.ErrStartConflict) {
		t.Fatal("B8-01 a changed roster must not replay", err)
	}

	// B8-02: refused rosters and actors write nothing.
	before := f.attempts(t)
	stranger, _, strangerHero := combatOwner(t, f.pool, rankingServer(t, f.pool))
	refusals := map[string]struct {
		mutate func(*combat.StartRequest)
		want   error
	}{
		"room refuses": {func(r *combat.StartRequest) {
			r.Members = append(r.Members, stranger.PlayerID)
			r.Battle.TeamA = append(r.Battle.TeamA, combat.Participant{Origin: d.OwnedMember, Kind: d.HeroActor, Player: stranger.PlayerID, Identity: strangerHero.PartnerID})
		}, d.ErrRoomRefused},
		"non-member actor": {func(r *combat.StartRequest) {
			r.Battle.TeamA[2] = combat.Participant{Origin: d.OwnedMember, Kind: d.HeroActor, Player: stranger.PlayerID, Identity: strangerHero.PartnerID}
		}, d.ErrInvalid},
		"member without actor": {func(r *combat.StartRequest) { r.Battle.TeamA = r.Battle.TeamA[:2] }, d.ErrInvalid},
		"member as enemy": {func(r *combat.StartRequest) {
			r.Battle.WavesB = [][]combat.Participant{{{Origin: d.OwnedForeign, Kind: d.HeroActor, Player: f.members[2].PlayerID, Identity: f.heroes[2].PartnerID}}}
		}, d.ErrInvalid},
		"member origin without roster": {func(r *combat.StartRequest) { r.Members = nil }, d.ErrInvalid},
		"convener not seat 0":          {func(r *combat.StartRequest) { r.Members[0], r.Members[1] = r.Members[1], r.Members[0] }, d.ErrInvalid},
		"duplicate member":             {func(r *combat.StartRequest) { r.Members[2] = r.Members[1] }, d.ErrInvalid},
		"over the member limit": {func(r *combat.StartRequest) {
			for i := range d.MemberLimit - 2 {
				r.Members = append(r.Members, stranger.PlayerID+identity.PlayerID(1000000+i))
			}
		}, d.ErrInvalid},
	}
	for name, refusal := range refusals {
		r := f.request(t, "refused-"+name, 0)
		refusal.mutate(&r)
		if _, err := fixtureStart(t, s, f.rev, r, f.pool); !errors.Is(err, refusal.want) {
			t.Fatal("B8-02", name, err)
		}
	}
	closed := s
	closed.Inputs.Rooms = nil
	if _, err := fixtureStart(t, closed, f.rev, f.request(t, "no-capability", 0), f.pool); !errors.Is(err, d.ErrProviderUnavailable) {
		t.Fatal("B8-02 no room capability", err)
	}
	if f.attempts(t) != before {
		t.Fatal("B8-02 a refused START wrote", f.attempts(t), before)
	}

	// B8-05 (H-46): a duplicate scheduler tick replays the terminal and each
	// member's settlement under the same receipts; a different receipt,
	// a non-member and a non-terminal attempt are refused.
	if _, err := f.settle(t, started.Attempt, f.members[1].PlayerID, "member-1"); !errors.Is(err, d.ErrNotReady) {
		t.Fatal("B8-05 settle before terminal", err)
	}
	must(f.resolve(t, started.Attempt))(t, "resolve")
	for tick := range 2 {
		settled := must(fixtureTerminal(t, s, f.pool, f.members[0], request.Locator, "i8-6c-receipt", f.pool, opPinned(f.rev)))(t, "tick terminal")
		if settled.Replayed != (tick == 1) || settled.Attempt.ID != started.Attempt.ID {
			t.Fatal("B8-05 tick", tick, settled.Replayed)
		}
		for i, member := range f.members {
			done := must(f.settle(t, started.Attempt, member.PlayerID, fmt.Sprint("member-", i)))(t, "member settle")
			if done.Replayed != (tick == 1) {
				t.Fatal("B8-05 member settle", tick, i, done.Replayed)
			}
		}
	}
	if _, err := f.settle(t, started.Attempt, f.members[1].PlayerID, "other-receipt"); !errors.Is(err, d.ErrMemberSettled) {
		t.Fatal("B8-05 different receipt", err)
	}
	if _, err := f.settle(t, started.Attempt, stranger.PlayerID, "stranger"); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("B8-05 non-member", err)
	}
	if f.settlements(t, started.Attempt) != 3 {
		t.Fatal("B8-05 settlements", f.settlements(t, started.Attempt))
	}
}

// B8-03 and B8-04 (H-25): members race to convene one locator and exactly one
// attempt exists; duplicate autonomous workers resolve, terminate and settle
// each member exactly once.
func TestI8_6CConcurrentMembersNative(t *testing.T) {
	f := newMemberFixture(t)
	results := make([]combat.Started, len(f.members))
	failures := make([]error, len(results))
	var wait sync.WaitGroup
	for i := range results {
		wait.Add(1)
		go func() {
			defer wait.Done()
			results[i], failures[i] = fixtureStart(t, f.service, f.rev, f.request(t, "race", i), f.pool)
		}()
	}
	wait.Wait()
	var winner d.Attempt
	for i, err := range failures {
		switch {
		case err == nil && winner.ID.IsZero():
			winner = results[i].Attempt
		case !errors.Is(err, d.ErrStartConflict):
			t.Fatal("B8-03 competing convener", i, err)
		}
	}
	if f.attempts(t) != 1 || winner.ID.IsZero() {
		t.Fatal("B8-03 attempts", f.attempts(t))
	}

	workers := 3
	resolutions := make([]combat.Resolved, workers)
	terminals := make([]combat.Settled, workers)
	errs := make([]error, workers)
	parallel := func(work func(int)) {
		var group sync.WaitGroup
		for i := range workers {
			group.Add(1)
			go func() {
				defer group.Done()
				work(i)
			}()
		}
		group.Wait()
		for i, err := range errs {
			if err != nil {
				t.Fatal("B8-04 worker", i, err)
			}
		}
	}
	parallel(func(i int) { resolutions[i], errs[i] = f.resolve(t, winner) })
	parallel(func(i int) {
		terminals[i], errs[i] = fixtureTerminal(t, f.service, f.pool, identity.ActorContext{PlayerID: identity.PlayerID(winner.ActorPlayer)}, winner.Locator, "i8-6c-race-receipt", f.pool, opPinned(f.rev))
	})
	fresh := 0
	for i := range workers {
		if resolutions[i].Attempt.ResolutionHash != resolutions[0].Attempt.ResolutionHash || resolutions[i].Attempt.ResolutionHash == "" {
			t.Fatal("B8-04 resolutions diverged", i)
		}
		if !terminals[i].Replayed {
			fresh++
		}
	}
	if fresh != 1 || scalar(t, f.pool, `SELECT count(*) FROM combat_resolutions WHERE attempt_id=$1`, winner.ID.String()) != 1 {
		t.Fatal("B8-04 one resolution and one terminal", fresh)
	}
	for seat, member := range f.roster(t, winner) {
		settled := make([]combat.MemberSettled, workers)
		parallel(func(i int) { settled[i], errs[i] = f.settle(t, winner, member, fmt.Sprint("race-member-", seat)) })
		if replays := len(slices.DeleteFunc(settled, func(s combat.MemberSettled) bool { return !s.Replayed })); replays != workers-1 {
			t.Fatal("B8-04 member settled more than once", seat, replays)
		}
	}
	if f.settlements(t, winner) != int64(len(f.members)) {
		t.Fatal("B8-04 settlements", f.settlements(t, winner))
	}
}
