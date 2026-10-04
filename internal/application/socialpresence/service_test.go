package socialpresence

import (
	"context"
	"errors"
	"math"
	"testing"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type testTag int64

func (t testTag) RowsAffected() int64 { return int64(t) }

type testRow struct{}

func (testRow) Scan(...any) error { return nil }

type testTx struct{}

func (*testTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (*testTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (*testTx) Commit(context.Context) error                                { return nil }
func (*testTx) Rollback(context.Context) error                              { return nil }

type testDB struct{}

func (*testDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return &testTx{}, nil }

type testTime struct {
	at    time.Time
	calls int
}

func (t *testTime) Now(context.Context) (time.Time, error) { t.calls++; return t.at, nil }

type fakeStore struct {
	settle       ExpiredSummary
	deleteExpiry time.Time
	deleteFound  bool
	advanced     []time.Time
	upserts      int
}

func (*fakeStore) EnsureAndLockRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) error {
	return nil
}
func (s *fakeStore) SettleExpiredTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (ExpiredSummary, error) {
	return s.settle, nil
}
func (s *fakeStore) UpsertLeaseTx(context.Context, tx.Tx, LeaseRef, time.Time, time.Time) error {
	s.upserts++
	return nil
}
func (s *fakeStore) DeleteExactLeaseTx(context.Context, tx.Tx, LeaseRef) (time.Time, bool, error) {
	return s.deleteExpiry, s.deleteFound, nil
}
func (s *fakeStore) AdvanceLastSeenTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, at time.Time, _ time.Time) (bool, error) {
	s.advanced = append(s.advanced, at)
	return true, nil
}

type fakeObservationStore struct {
	gotAt time.Time
	out   map[identity.PlayerID]Observation
}

func (s *fakeObservationStore) ReadManyAt(_ context.Context, _ []identity.PlayerID, at time.Time) (map[identity.PlayerID]Observation, error) {
	s.gotAt = at
	return s.out, nil
}

func testUUID(t *testing.T, raw string) ids.UUID {
	t.Helper()
	u, err := ids.ParseUUID(raw)
	if err != nil {
		t.Fatal(err)
	}
	return u
}
func testRef(t *testing.T) LeaseRef {
	t.Helper()
	cid, _ := identity.ContextIDFrom(testUUID(t, "11111111-1111-4111-8111-111111111111"))
	return LeaseRef{PlayerID: 200001, ContextID: cid, Role: domainrt.World, RealtimeInstanceID: testUUID(t, "22222222-2222-4222-8222-222222222222"), ConnectionGeneration: 7}
}
func testOp(t *testing.T) operation.Context {
	t.Helper()
	return operation.Context{ID: testUUID(t, "33333333-3333-4333-8333-333333333333"), StartedAt: time.Unix(100, 0).UTC()}
}
func testService(t *testing.T, store Store, at time.Time) (Service, *testTime) {
	tm := &testTime{at: at}
	runner := tx.Runner{DB: &testDB{}}
	return Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: tm}, Runner: runner}, Store: store}, tm
}

func TestAdmitSettlesExpiredBoundaryBeforeInstallingLease(t *testing.T) {
	expired := time.Unix(900, 0).UTC()
	store := &fakeStore{settle: ExpiredSummary{MaxExpiredAt: &expired, HasLiveLease: false}}
	svc, tm := testService(t, store, time.Unix(1000, 0).UTC())
	if err := svc.Admit(context.Background(), testOp(t), testRef(t), 20*time.Minute); err != nil {
		t.Fatal(err)
	}
	if tm.calls != 1 || store.upserts != 1 {
		t.Fatalf("time=%d upserts=%d", tm.calls, store.upserts)
	}
	if len(store.advanced) != 1 || !store.advanced[0].Equal(expired) {
		t.Fatalf("advanced=%v", store.advanced)
	}
}

func TestRetireFinalLeaseUsesEarlierExpiryBoundary(t *testing.T) {
	expiry := time.Unix(950, 0).UTC()
	store := &fakeStore{deleteExpiry: expiry, deleteFound: true}
	svc, _ := testService(t, store, time.Unix(1000, 0).UTC())
	if err := svc.Retire(context.Background(), testOp(t), testRef(t)); err != nil {
		t.Fatal(err)
	}
	if len(store.advanced) != 1 || !store.advanced[0].Equal(expiry) {
		t.Fatalf("advanced=%v", store.advanced)
	}
}

func TestRetireDoesNotAdvanceWhileAnotherLeaseIsLive(t *testing.T) {
	store := &fakeStore{deleteExpiry: time.Unix(1100, 0).UTC(), deleteFound: true, settle: ExpiredSummary{HasLiveLease: true}}
	svc, _ := testService(t, store, time.Unix(1000, 0).UTC())
	if err := svc.Retire(context.Background(), testOp(t), testRef(t)); err != nil {
		t.Fatal(err)
	}
	if len(store.advanced) != 0 {
		t.Fatalf("unexpected last-seen advance %v", store.advanced)
	}
}

func TestLeaseGenerationAbovePostgresBigintRejected(t *testing.T) {
	ref := testRef(t)
	ref.ConnectionGeneration = uint64(math.MaxInt64) + 1
	if !errors.Is(ref.Validate(), ErrInvalidLease) {
		t.Fatalf("validate=%v", ref.Validate())
	}
}

func TestReaderBindsOneAuthoritativeInstantForBatch(t *testing.T) {
	at := time.Unix(2000, 0).UTC()
	tm := &testTime{at: at}
	store := &fakeObservationStore{out: map[identity.PlayerID]Observation{200001: {PlayerID: 200001}}}
	r := Reader{Time: tm, Store: store}
	got, err := r.ReadMany(context.Background(), []identity.PlayerID{200001})
	if err != nil {
		t.Fatal(err)
	}
	if tm.calls != 1 || !store.gotAt.Equal(at) || got[200001].PlayerID != 200001 {
		t.Fatalf("calls=%d at=%v got=%v", tm.calls, store.gotAt, got)
	}
}
