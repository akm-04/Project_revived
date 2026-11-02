package i5

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type workplaceContent struct{ *testContent }

func (c workplaceContent) ResolveResourceTx(ctx context.Context, q tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	if line.ResourceKey != WorkplaceSPKey {
		return c.testContent.ResolveResourceTx(ctx, q, revision, line)
	}
	return ResourcePolicy{Kind: grant.Temporal, PolicyVersion: revision, Descriptor: &TemporalDescriptor{Revision: revision, ResourceKey: WorkplaceSPKey, RegenEvery: 20 * time.Minute, RegenAmount: 1, CapRule: "STATIC", StaticCap: 50}}, nil
}

type workplaceStore struct{ *testStore }

func (s workplaceStore) InsertWorkplaceSPTx(_ context.Context, _ tx.Tx, state economy.TemporalState) error {
	if _, exists := s.temporal[state.ResourceKey]; exists {
		return errors.New("duplicate temporal row")
	}
	if s.temporal == nil {
		s.temporal = map[string]economy.TemporalState{}
	}
	s.temporal[state.ResourceKey] = state
	return nil
}

func TestWorkplaceSPUsesCanonicalOwnerAndDoesNotRefillOnReload(t *testing.T) {
	ctx := context.Background()
	actor := testActor(t)
	now := time.Unix(1700002000, 0).UTC()
	store := workplaceStore{&testStore{progression: player.Progression{PlayerID: actor.PlayerID, Level: 14, StateVersion: 1, UpdatedAt: now}}}
	svc := Service{Store: store, Content: workplaceContent{&testContent{}}, Privileges: BaselinePrivilegeProvider{}}
	op, err := bindContentRevision(operation.Context{ID: testUUID(155), StartedAt: now}, testContentRevisionA)
	if err != nil {
		t.Fatal(err)
	}
	read := func(at time.Time) economy.MaterializedTemporal {
		t.Helper()
		op.StartedAt = at
		value, err := svc.WorkplaceSPTx(ctx, &testTx{}, actor.PlayerID, op)
		if err != nil {
			t.Fatal(err)
		}
		return value
	}
	first := read(now)
	if first.Amount != 50 || first.State.StateVersion != 1 || first.State.RegenAnchorAt != nil {
		t.Fatalf("initial full-cap policy %+v", first)
	}
	if _, err := svc.DebitTemporalTx(ctx, &testTx{}, actor.PlayerID, WorkplaceSPKey, 10, op); err != nil {
		t.Fatal(err)
	}
	if value := read(now); value.Amount != 40 {
		t.Fatalf("reload refilled spent stamina: %+v", value)
	}
	value := read(now.Add(43 * time.Minute))
	if value.Amount != 42 || value.State.RegenAnchorAt == nil || !value.State.RegenAnchorAt.Equal(now.Add(40*time.Minute)) {
		t.Fatalf("offline remainder %+v", value)
	}
	writes := store.saveTemporalCalls
	if replay := read(now.Add(43 * time.Minute)); replay.Amount != 42 || store.saveTemporalCalls != writes {
		t.Fatalf("same-time replay changed stamina %+v", replay)
	}
	if rollback := read(now.Add(30 * time.Minute)); rollback.Amount != 42 || rollback.State.RegenAnchorAt == nil || !rollback.State.RegenAnchorAt.Equal(now.Add(30*time.Minute)) {
		t.Fatalf("rollback did not use canonical rebase policy %+v", rollback)
	}
	if capped := read(now.Add(4 * time.Hour)); capped.Amount != 50 || capped.State.RegenAnchorAt != nil {
		t.Fatalf("offline cap %+v", capped)
	}
	stale, _ := bindContentRevision(operation.Context{ID: testUUID(156), StartedAt: now.Add(4 * time.Hour)}, testContentRevisionB)
	if _, err := svc.WorkplaceSPTx(ctx, &testTx{}, actor.PlayerID, stale); !errors.Is(err, ErrContentRevisionConflict) {
		t.Fatalf("mixed revision accepted: %v", err)
	}
	if err := svc.RepinTemporalTx(ctx, &testTx{}, actor.PlayerID, testContentRevisionB, stale.StartedAt); err != nil {
		t.Fatal(err)
	}
	if got, err := svc.WorkplaceSPTx(ctx, &testTx{}, actor.PlayerID, stale); err != nil || got.Amount != 50 || got.State.ContentRevision != testContentRevisionB {
		t.Fatalf("deployment repin did not include workplace: %+v %v", got, err)
	}
}
