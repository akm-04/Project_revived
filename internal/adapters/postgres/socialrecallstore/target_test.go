package socialrecallstore_test

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/privilege"
	domainrecall "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var targetAt = time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
var targetRevision = strings.Repeat("a", 64)

type snapshotQueryer struct {
	expiredAt     *time.Time
	presenceCells string
	presenceIDs   []int64
	observedAt    time.Time
	queries       int
}

func (q *snapshotQueryer) QueryRow(_ context.Context, _ string, args ...any) tx.Row {
	q.queries++
	if len(args) == 2 {
		if values, ok := args[0].([]int64); ok {
			q.presenceIDs = append([]int64{}, values...)
		}
		if observedAt, ok := args[1].(time.Time); ok {
			q.observedAt = observedAt
		}
	}
	return snapshotRow{raw: q.presenceCells, expiredAt: q.expiredAt}
}

func (*snapshotQueryer) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("snapshot queryer is read-only")
}
func (*snapshotQueryer) Commit(context.Context) error   { return nil }
func (*snapshotQueryer) Rollback(context.Context) error { return nil }

type snapshotRow struct {
	raw       string
	expiredAt *time.Time
}

func (r snapshotRow) Scan(dest ...any) error {
	if len(dest) != 1 {
		return errors.New("unexpected scan shape")
	}
	if target, ok := dest[0].(*any); ok {
		if r.expiredAt != nil {
			*target = *r.expiredAt
		}
		return nil
	}
	target, ok := dest[0].(*string)
	if !ok {
		return errors.New("unexpected scan destination")
	}
	*target = r.raw
	return nil
}

type progressionRecorder struct {
	value  player.Progression
	err    error
	got    tx.Queryer
	player identity.PlayerID
}

func (r *progressionRecorder) ReadProgressionTx(_ context.Context, q tx.Queryer, player identity.PlayerID) (player.Progression, error) {
	r.got = q
	r.player = player
	return r.value, r.err
}

type rosterRecorder struct {
	value    characterasset.RosterMetricPopulation
	err      error
	got      characterasset.CoherentReadScope
	player   identity.PlayerID
	family   string
	revision string
	at       time.Time
}

func (r *rosterRecorder) ReadRosterMetricsTx(_ context.Context, scope characterasset.CoherentReadScope, player identity.PlayerID, family string) (characterasset.RosterMetricPopulation, error) {
	r.got = scope
	r.player = player
	r.family = family
	r.revision = scope.ContentRevision
	r.at = scope.ObservedAt
	return r.value, r.err
}

type privilegeRecorder struct {
	value    privilege.Snapshot
	err      error
	got      tx.Queryer
	player   identity.PlayerID
	revision string
	at       time.Time
}

func (r *privilegeRecorder) ReadCosmeticPrivilegeTx(_ context.Context, q tx.Queryer, player identity.PlayerID, revision string, at time.Time) (privilege.Snapshot, error) {
	r.got = q
	r.player = player
	r.revision = revision
	r.at = at
	return r.value, r.err
}

type relationRecorder struct {
	value  []socialrelation.CandidateState
	err    error
	got    tx.Tx
	caller identity.PlayerID
	ids    []identity.PlayerID
}

func (r *relationRecorder) CandidateStatesTx(_ context.Context, t tx.Tx, caller identity.PlayerID, ids []identity.PlayerID) ([]socialrelation.CandidateState, error) {
	r.got = t
	r.caller = caller
	r.ids = append([]identity.PlayerID{}, ids...)
	return r.value, r.err
}

type activityRecorder struct {
	value   bootstrap.PlayerActivityObservation
	known   bool
	err     error
	queryer tx.Queryer
	player  identity.PlayerID
	at      time.Time
}

func (r *activityRecorder) ReadPlayerActivityTx(_ context.Context, q tx.Queryer, p identity.PlayerID, at time.Time) (bootstrap.PlayerActivityObservation, bool, error) {
	r.queryer = q
	r.player = p
	r.at = at
	return r.value, r.known, r.err
}

type targetFixture struct {
	activity    *activityRecorder
	queryer     *snapshotQueryer
	progression *progressionRecorder
	roster      *rosterRecorder
	privilege   *privilegeRecorder
	relations   *relationRecorder
	reader      socialrecallstore.TargetReader
	scope       tx.Scope
	caller      identity.PlayerID
	target      identity.PlayerID
}

func newTargetFixture(t *testing.T) *targetFixture {
	t.Helper()
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	pins, err := policy.NewSet(policy.Ref{Name: "content", Version: targetRevision}, policy.Ref{Name: "roster-metrics", Version: characterasset.RosterMetricPolicy})
	if err != nil {
		t.Fatal(err)
	}
	queryer := &snapshotQueryer{presenceCells: `[{"player_id":100002,"last_seen_at":"2026-11-04T12:00:00Z","latest_connected_at":null}]`}
	fixture := &targetFixture{
		queryer:     queryer,
		progression: &progressionRecorder{value: player.Progression{PlayerID: 100002, Level: 51, Exp: 10, StateVersion: 2, UpdatedAt: targetAt.Add(-time.Hour)}},
		roster: &rosterRecorder{value: characterasset.RosterMetricPopulation{
			PlayerID: 100002, Family: "Hero", Revision: targetRevision, ObservedAt: targetAt, RootVersion: 7,
			Rows: []characterasset.RosterMetricRow{{InstanceID: 1, OriginTableID: 10, TableID: 20, Star: 3, Version: 1}, {InstanceID: 2, OriginTableID: 11, TableID: 21, Star: 4, Version: 1}},
		}},
		privilege: &privilegeRecorder{value: validPrivilegeSnapshot()},
		relations: &relationRecorder{value: []socialrelation.CandidateState{{PlayerID: 100002, Friend: true}}},
		caller:    100001,
		target:    100002,
		scope: tx.Scope{
			Tx:        queryer,
			Operation: operation.Context{ID: operationID, StartedAt: targetAt, Policies: pins},
			Attempt:   1,
			Options:   tx.Options{Isolation: tx.Serializable},
		},
	}
	fixture.activity = &activityRecorder{known: true, value: bootstrap.PlayerActivityObservation{PlayerID: fixture.target, LogicalServerID: 1, LastLoginAt: targetAt.Add(-9 * 24 * time.Hour), LatestActivityAt: targetAt.Add(-9 * 24 * time.Hour), ObservedAt: targetAt, StateVersion: 1}}
	fixture.reader = socialrecallstore.TargetReader{Activity: fixture.activity, Progression: fixture.progression, Roster: fixture.roster, Privilege: fixture.privilege, Relations: fixture.relations}
	return fixture
}

func validPrivilegeSnapshot() privilege.Snapshot {
	state := privilege.State{
		PlayerID: 100002, LogicalServerID: 1, Charge: 100, VIPLevel: 3,
		MonthlyState: privilege.MonthlyAbsent, ContentRevision: targetRevision,
		PolicyVersion: privilege.ManualPolicy, OriginClass: privilege.ManualClass,
		Issuer: "qualified-test", Reason: "qualified-test", StateVersion: 1,
		CreatedAt: targetAt.Add(-2 * time.Hour), UpdatedAt: targetAt.Add(-time.Hour),
	}
	return privilege.Snapshot{State: state, ObservationRevision: targetRevision, ObservedAt: targetAt, SkillPointCap: 10, ProviderRevision: privilege.ManualPolicy + "/" + targetRevision}
}

func (f *targetFixture) read() (socialrecall.TargetSnapshot, error) {
	return f.reader.ReadRecallTargetTx(context.Background(), f.scope, f.caller, f.target, targetRevision, targetAt)
}

func TestRecallTargetReadsEveryOwnerThroughOneSerializableSnapshot(t *testing.T) {
	fixture := newTargetFixture(t)
	snapshot, err := fixture.read()
	if err != nil {
		t.Fatal(err)
	}
	if fixture.progression.got != fixture.scope.Tx || fixture.privilege.got != fixture.scope.Tx || fixture.relations.got != fixture.scope.Tx {
		t.Fatal("owner port did not receive the caller queryer")
	}
	if fixture.roster.got.Queryer() != fixture.scope.Tx || fixture.roster.got.ContentRevision != targetRevision || !fixture.roster.got.ObservedAt.Equal(targetAt) || fixture.roster.got.Isolation != tx.Serializable {
		t.Fatal("roster port did not receive the coherent caller scope", fixture.roster.got)
	}
	if fixture.progression.player != fixture.target || fixture.roster.player != fixture.target || fixture.roster.family != "Hero" || fixture.roster.revision != targetRevision || !fixture.roster.at.Equal(targetAt) {
		t.Fatalf("progression/roster received the wrong target matter: progress=%d roster=%d family=%q revision=%s at=%v", fixture.progression.player, fixture.roster.player, fixture.roster.family, fixture.roster.revision, fixture.roster.at)
	}
	if fixture.privilege.player != fixture.target || fixture.privilege.revision != targetRevision || !fixture.privilege.at.Equal(targetAt) {
		t.Fatalf("privilege received the wrong target matter: player=%d revision=%s at=%v", fixture.privilege.player, fixture.privilege.revision, fixture.privilege.at)
	}
	if fixture.relations.caller != fixture.caller {
		t.Fatalf("relation read used caller %d, want %d", fixture.relations.caller, fixture.caller)
	}
	if fixture.activity.queryer != fixture.scope.Tx || fixture.activity.player != fixture.target || !fixture.activity.at.Equal(targetAt) {
		t.Fatalf("activity received the wrong target matter: player=%d at=%v", fixture.activity.player, fixture.activity.at)
	}
	if fixture.queryer.queries != 2 || fixture.queryer.observedAt != targetAt || len(fixture.queryer.presenceIDs) != 1 || fixture.queryer.presenceIDs[0] != int64(fixture.target) {
		t.Fatal("presence did not observe the target at the captured instant", fixture.queryer.queries, fixture.queryer.observedAt, fixture.queryer.presenceIDs)
	}
	if len(fixture.relations.ids) != 1 || fixture.relations.ids[0] != fixture.target {
		t.Fatal("relation read did not ask exactly for the target", fixture.relations.ids)
	}
	want := socialrecall.TargetSnapshot{
		PlayerID: 100002, Revision: targetRevision, ObservedAt: targetAt, IsFriend: true,
		Online: false, OfflineSince: targetAt.Add(-24 * time.Hour),
		Baseline: domainrecall.Baseline{AcademyLevel: 51, OwnedHeroCount: 2, ChargeTotal: 100},
	}
	if snapshot.PlayerID != want.PlayerID || snapshot.Revision != want.Revision || !snapshot.ObservedAt.Equal(want.ObservedAt) || snapshot.IsFriend != want.IsFriend || snapshot.Online != want.Online || !snapshot.OfflineSince.Equal(want.OfflineSince) || snapshot.Baseline != want.Baseline {
		t.Fatal(snapshot)
	}
}

func TestRecallTargetBlockedAndUnknownOfflineAreReportedNotGuessed(t *testing.T) {
	blocked := newTargetFixture(t)
	blocked.relations.value = []socialrelation.CandidateState{{PlayerID: 100002, Friend: true, Blocked: true}}
	snapshot, err := blocked.read()
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.IsFriend {
		t.Fatal("blocked target reported as friend")
	}

	unknown := newTargetFixture(t)
	unknown.activity.known = false
	unknown.queryer.presenceCells = `[{"player_id":100002,"last_seen_at":null,"latest_connected_at":null}]`
	snapshot, err = unknown.read()
	if err != nil {
		t.Fatal(err)
	}
	if unknown.queryer.queries != 1 {
		t.Fatal("unknown canonical history read unused expired leases")
	}
	if !snapshot.OfflineSince.IsZero() || snapshot.Online {
		t.Fatal("unknown offline start was invented", snapshot.OfflineSince, snapshot.Online)
	}

	online := newTargetFixture(t)
	online.queryer.presenceCells = `[{"player_id":100002,"last_seen_at":"2026-11-04T12:00:00Z","latest_connected_at":"2026-11-05T11:59:00Z"}]`
	snapshot, err = online.read()
	if err != nil {
		t.Fatal(err)
	}
	if !snapshot.Online {
		t.Fatal("live presence not reported")
	}
}

func TestRecallTargetRejectsScopeWithoutRequiredCoherence(t *testing.T) {
	for _, name := range []string{"read-committed", "repeatable-read", "read-only", "missing-content-pin", "wrong-content-pin", "missing-roster-pin", "wrong-roster-pin"} {
		t.Run(name, func(t *testing.T) {
			fixture := newTargetFixture(t)
			switch name {
			case "read-committed":
				fixture.scope.Options.Isolation = tx.ReadCommitted
			case "repeatable-read":
				fixture.scope.Options.Isolation = tx.RepeatableRead
			case "read-only":
				fixture.scope.Options.ReadOnly = true
			case "missing-content-pin":
				fixture.scope.Operation.Policies, _ = policy.NewSet(policy.Ref{Name: "roster-metrics", Version: characterasset.RosterMetricPolicy})
			case "wrong-content-pin":
				fixture.scope.Operation.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("b", 64)}, policy.Ref{Name: "roster-metrics", Version: characterasset.RosterMetricPolicy})
			case "missing-roster-pin":
				fixture.scope.Operation.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: targetRevision})
			case "wrong-roster-pin":
				fixture.scope.Operation.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: targetRevision}, policy.Ref{Name: "roster-metrics", Version: "C4C_OTHER_V1"})
			}
			if _, err := fixture.read(); !errors.Is(err, socialrecall.ErrStartFacts) {
				t.Fatal(err)
			}
			if fixture.queryer.queries != 0 || fixture.progression.got != nil || fixture.privilege.got != nil || fixture.relations.got != nil {
				t.Fatal("invalid scope still reached an owner port")
			}
		})
	}
}

func TestRecallTargetRejectsMalformedOwnerFacts(t *testing.T) {
	cases := []struct {
		name    string
		mutate  func(*targetFixture)
		wantErr error
	}{
		{"foreign-progression", func(f *targetFixture) { f.progression.value.PlayerID = 100003 }, socialrecall.ErrStartFacts},
		{"future-progression", func(f *targetFixture) { f.progression.value.UpdatedAt = targetAt.Add(time.Minute) }, socialrecall.ErrStartFacts},
		{"invalid-progression", func(f *targetFixture) { f.progression.value.Level = 0 }, socialrecall.ErrStartFacts},
		{"missing-progression", func(f *targetFixture) { f.progression.err = errors.New("no progression row") }, nil},
		{"foreign-roster", func(f *targetFixture) { f.roster.value.PlayerID = 100003 }, socialrecall.ErrStartFacts},
		{"future-roster", func(f *targetFixture) { f.roster.value.ObservedAt = targetAt.Add(time.Minute) }, socialrecall.ErrStartFacts},
		{"wrong-roster-revision", func(f *targetFixture) { f.roster.value.Revision = strings.Repeat("b", 64) }, socialrecall.ErrStartFacts},
		{"missing-roster-root", func(f *targetFixture) { f.roster.value.RootVersion = 0 }, socialrecall.ErrStartFacts},
		{"duplicate-roster-origin", func(f *targetFixture) {
			f.roster.value.Rows = append(f.roster.value.Rows, characterasset.RosterMetricRow{InstanceID: 3, OriginTableID: 10, TableID: 21, Star: 1, Version: 1})
		}, socialrecall.ErrStartFacts},
		{"wrong-roster-family", func(f *targetFixture) { f.roster.value.Family = "Pet" }, socialrecall.ErrStartFacts},
		{"unavailable-charge", func(f *targetFixture) { f.privilege.err = privilege.ErrUnavailable }, privilege.ErrUnavailable},
		{"foreign-privilege", func(f *targetFixture) { f.privilege.value.State.PlayerID = 100003 }, socialrecall.ErrStartFacts},
		{"future-privilege", func(f *targetFixture) { f.privilege.value.State.UpdatedAt = targetAt.Add(time.Minute) }, socialrecall.ErrStartFacts},
		{"negative-charge", func(f *targetFixture) { f.privilege.value.State.Charge = -1 }, socialrecall.ErrStartFacts},
		{"foreign-relation", func(f *targetFixture) {
			f.relations.value = []socialrelation.CandidateState{{PlayerID: 100003, Friend: true}}
		}, socialrecall.ErrStartFacts},
		{"duplicate-relation", func(f *targetFixture) {
			f.relations.value = []socialrelation.CandidateState{{PlayerID: 100002, Friend: true}, {PlayerID: 100002, Friend: true}}
		}, socialrecall.ErrStartFacts},
		{"missing-relation", func(f *targetFixture) { f.relations.value = nil }, socialrecall.ErrStartFacts},
		{"future-presence", func(f *targetFixture) {
			f.queryer.presenceCells = `[{"player_id":100002,"last_seen_at":"2026-11-05T12:30:00Z","latest_connected_at":null}]`
		}, socialrecall.ErrStartFacts},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			fixture := newTargetFixture(t)
			testCase.mutate(fixture)
			snapshot, err := fixture.read()
			if err == nil {
				t.Fatal("malformed facts accepted", snapshot)
			}
			if testCase.wantErr != nil && !errors.Is(err, testCase.wantErr) {
				t.Fatal(err)
			}
			if snapshot.PlayerID.Valid() {
				t.Fatal("malformed facts returned a snapshot", snapshot)
			}
		})
	}
}

func TestRecallTargetUsesCanonicalActivityAndUnsettledLeaseExpiry(t *testing.T) {
	for _, name := range []string{"recent-login-without-tcp", "expired-lease-newer-than-last-seen", "missing-canonical-history"} {
		t.Run(name, func(t *testing.T) {
			f := newTargetFixture(t)
			f.queryer.presenceCells = `[{"player_id":100002,"last_seen_at":"2026-10-20T12:00:00Z","latest_connected_at":null}]`
			want := targetAt.Add(-time.Hour)
			switch name {
			case "recent-login-without-tcp":
				f.activity.value.LastLoginAt = want
				f.activity.value.LatestActivityAt = want
			case "expired-lease-newer-than-last-seen":
				f.queryer.expiredAt = &want
			case "missing-canonical-history":
				f.activity.known = false
				want = time.Time{}
			}
			got, err := f.read()
			if err != nil || !got.OfflineSince.Equal(want) {
				t.Fatal(got, err, want)
			}
			if f.activity.queryer != f.scope.Tx || f.activity.player != f.target || !f.activity.at.Equal(targetAt) {
				t.Fatal("activity escaped coherent target scope")
			}
		})
	}
}
func TestRecallTargetRejectsBadActivityAndScopeBeforeOwnerReads(t *testing.T) {
	for _, name := range []string{"foreign-player", "foreign-server", "future", "wrong-instant", "unavailable", "nil-owner", "missing-attempt", "missing-operation", "missing-operation-time"} {
		t.Run(name, func(t *testing.T) {
			f := newTargetFixture(t)
			early := false
			switch name {
			case "foreign-player":
				f.activity.value.PlayerID++
			case "foreign-server":
				f.activity.value.LogicalServerID = 2
			case "future":
				f.activity.value.LatestActivityAt = targetAt.Add(time.Minute)
			case "wrong-instant":
				f.activity.value.ObservedAt = targetAt.Add(-time.Second)
			case "unavailable":
				f.activity.err = errors.New("activity unavailable")
			case "nil-owner":
				f.reader.Activity = nil
				early = true
			case "missing-attempt":
				f.scope.Attempt = 0
				early = true
			case "missing-operation":
				f.scope.Operation.ID = ids.UUID{}
				early = true
			case "missing-operation-time":
				f.scope.Operation.StartedAt = time.Time{}
				early = true
			}
			if _, err := f.read(); err == nil {
				t.Fatal("accepted invalid activity/scope")
			}
			if early && (f.progression.got != nil || f.queryer.queries != 0) {
				t.Fatal("invalid scope reached owner")
			}
		})
	}
}
