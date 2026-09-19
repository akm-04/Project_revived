package economy

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func TestScalarDebitNeverTrustsProjectedBalance(t *testing.T) {
	b := ScalarBalance{PlayerID: identity.PlayerID(100001), ResourceKey: "crystal", Amount: 9, StateVersion: 1, UpdatedAt: time.Unix(1, 0)}
	if _, e := b.Debit(10, time.Unix(2, 0)); !errors.Is(e, ErrInsufficientBalance) {
		t.Fatalf("err=%v", e)
	}
	n, e := b.Debit(4, time.Unix(2, 0))
	if e != nil || n.Amount != 5 || n.StateVersion != 2 {
		t.Fatalf("n=%+v e=%v", n, e)
	}
}
func TestTemporalMaterializeUsesSuppliedServerTimeAndCap(t *testing.T) {
	p := TemporalPolicy{Version: "p1", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10}
	s := TemporalState{PlayerID: identity.PlayerID(100001), ResourceKey: "energy", StoredAmount: 7, RegenAnchorAt: anchorUTC(time.Unix(100, 0)), PolicyVersion: "p1", StateVersion: 1, UpdatedAt: time.Unix(100, 0)}
	m, e := s.Materialize(time.Unix(100, 0).Add(30*time.Minute), p)
	if e != nil {
		t.Fatal(e)
	}
	if m.Amount != 10 || m.State.RegenAnchorAt != nil {
		t.Fatalf("m=%+v", m)
	}
}
func TestStackOverflowMailIsExplicitAndNoSilentLoss(t *testing.T) {
	now := time.Unix(1, 0)
	s := StackState{PlayerID: identity.PlayerID(100001), ItemID: 42, Quantity: 8, StateVersion: 1, AcquiredAt: now, UpdatedAt: now}
	r, e := s.PlanCredit(5, StackDefinition{ItemID: 42, StackCap: 10, OverflowToMail: true}, now.Add(time.Second))
	if e != nil {
		t.Fatal(e)
	}
	if r.Fit != 2 || r.Overflow != 3 || r.State.Quantity != 10 {
		t.Fatalf("r=%+v", r)
	}
	_, e = s.PlanCredit(5, StackDefinition{ItemID: 42, StackCap: 10}, now.Add(time.Second))
	if !errors.Is(e, ErrStackCapacity) {
		t.Fatalf("err=%v", e)
	}
}

func TestR5RebindLegacyPolicyMaterializesOldPolicyBeforeImmutableBoundary(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	old := TemporalPolicy{Version: "legacy-spirit-v1", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	newp := TemporalPolicy{Version: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 20, AllowExplicitGrantAboveNaturalCap: true}
	s := TemporalState{PlayerID: identity.PlayerID(100001), ResourceKey: "spirit_energy", StoredAmount: 7, RegenAnchorAt: anchorUTC(start), PolicyVersion: old.Version, StateVersion: 4, UpdatedAt: start}
	now := start.Add(7 * time.Minute)
	got, err := s.RebindLegacyPolicy(newp.Version, now, old, newp)
	if err != nil {
		t.Fatal(err)
	}
	// One complete legacy interval accrues before the immutable boundary. The
	// two-minute qualified remainder is retained because cadence is unchanged.
	wantAnchor := start.Add(5 * time.Minute)
	if got.StoredAmount != 8 || got.RegenAnchorAt == nil || !got.RegenAnchorAt.Equal(wantAnchor) {
		t.Fatalf("legacy materialization/remainder lost: %+v", got)
	}
	if got.ContentRevision != newp.Version || got.PolicyVersion != newp.Version || got.StateVersion != 5 || !got.UpdatedAt.Equal(now) {
		t.Fatalf("immutable bind mismatch: %+v", got)
	}
}

func TestR5RebindLegacyPolicyChangedCadenceStartsNewCadenceAtBoundary(t *testing.T) {
	start := time.Unix(1700000100, 0).UTC()
	old := TemporalPolicy{Version: "legacy-skill-v1", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	newp := TemporalPolicy{Version: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", RegenEvery: 6 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	s := TemporalState{PlayerID: identity.PlayerID(100001), ResourceKey: "skill_point", StoredAmount: 2, RegenAnchorAt: anchorUTC(start), PolicyVersion: old.Version, StateVersion: 9, UpdatedAt: start}
	now := start.Add(7 * time.Minute)
	got, err := s.RebindLegacyPolicy(newp.Version, now, old, newp)
	if err != nil {
		t.Fatal(err)
	}
	if got.StoredAmount != 3 || got.RegenAnchorAt == nil || !got.RegenAnchorAt.Equal(now) {
		t.Fatalf("changed cadence did not begin at explicit boundary: %+v", got)
	}
}

func TestR5RebindLegacyPolicyRejectsAlreadyImmutableOrWrongLegacyPolicy(t *testing.T) {
	now := time.Unix(1700000200, 0).UTC()
	old := TemporalPolicy{Version: "legacy-v1", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	newp := TemporalPolicy{Version: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	immutable := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 10, PolicyVersion: newp.Version, ContentRevision: newp.Version, StateVersion: 2, UpdatedAt: now}
	if _, err := immutable.RebindLegacyPolicy(newp.Version, now, old, newp); err == nil {
		t.Fatal("already immutable temporal row was rebound")
	}
	legacy := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 9, PolicyVersion: "other-legacy", StateVersion: 2, UpdatedAt: now}
	if _, err := legacy.RebindLegacyPolicy(newp.Version, now, old, newp); err == nil {
		t.Fatal("legacy row was reinterpreted through mismatched old policy")
	}
}

func TestR5TemporalAcceptanceRemainderPauseOvercapZeroAndClockRollback(t *testing.T) {
	start := time.Unix(1700010000, 0).UTC()
	p := TemporalPolicy{Version: "p1", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}

	running := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 7, RegenAnchorAt: anchorUTC(start), PolicyVersion: p.Version, StateVersion: 1, UpdatedAt: start}
	m, err := running.Materialize(start.Add(7*time.Minute), p)
	if err != nil || m.Amount != 8 || m.State.RegenAnchorAt == nil || !m.State.RegenAnchorAt.Equal(start.Add(5*time.Minute)) {
		t.Fatalf("running remainder: m=%+v err=%v", m, err)
	}

	full := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 10, RegenAnchorAt: nil, PolicyVersion: p.Version, StateVersion: 3, UpdatedAt: start}
	m, err = full.Materialize(start.Add(time.Hour), p)
	if err != nil || m.Amount != 10 || m.State.RegenAnchorAt != nil || m.State.StateVersion != 3 {
		t.Fatalf("full pause changed: m=%+v err=%v", m, err)
	}

	over := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 12, RegenAnchorAt: nil, PolicyVersion: p.Version, StateVersion: 5, UpdatedAt: start}
	spent, err := over.Debit(3, start.Add(time.Minute), p)
	if err != nil || spent.StoredAmount != 9 || spent.RegenAnchorAt == nil || !spent.RegenAnchorAt.Equal(start.Add(time.Minute)) {
		t.Fatalf("overcap debit did not rearm below cap: %+v err=%v", spent, err)
	}

	zero := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 0, RegenAnchorAt: nil, PolicyVersion: p.Version, StateVersion: 7, UpdatedAt: start}
	m, err = zero.Materialize(start.Add(2*time.Minute), p)
	if err != nil || m.Amount != 0 || m.State.RegenAnchorAt == nil || !m.State.RegenAnchorAt.Equal(start.Add(2*time.Minute)) {
		t.Fatalf("zero/belowcap paused state did not rearm without catchup: %+v err=%v", m, err)
	}
	if _, err := zero.Debit(1, start.Add(2*time.Minute), p); !errors.Is(err, ErrInsufficientBalance) {
		t.Fatalf("shortage=%v", err)
	}

	future := start.Add(time.Hour)
	rollback := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 4, RegenAnchorAt: &future, PolicyVersion: p.Version, StateVersion: 9, UpdatedAt: start}
	m, err = rollback.Materialize(start.Add(10*time.Minute), p)
	if err != nil || m.Amount != 4 || m.State.RegenAnchorAt == nil || !m.State.RegenAnchorAt.Equal(start.Add(10*time.Minute)) {
		t.Fatalf("future anchor rollback repair: %+v err=%v", m, err)
	}
}

func TestR5TemporalAcceptanceKnownCapIncreaseRearmsAtBoundary(t *testing.T) {
	now := time.Unix(1700011000, 0).UTC()
	old := TemporalPolicy{Version: "old", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 10, AllowExplicitGrantAboveNaturalCap: true}
	newp := TemporalPolicy{Version: "new", RegenEvery: 5 * time.Minute, RegenAmount: 1, NaturalCap: 20, AllowExplicitGrantAboveNaturalCap: true}
	s := TemporalState{PlayerID: 100001, ResourceKey: "energy", StoredAmount: 10, RegenAnchorAt: nil, PolicyVersion: old.Version, StateVersion: 4, UpdatedAt: now.Add(-time.Hour)}
	got, err := s.ApplyLevelTransition(0, now, old, newp)
	if err != nil || got.StoredAmount != 10 || got.PolicyVersion != newp.Version || got.RegenAnchorAt == nil || !got.RegenAnchorAt.Equal(now) {
		t.Fatalf("known cap increase did not rearm at boundary: %+v err=%v", got, err)
	}
}
