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

// revisionedContent answers the temporal descriptor of whichever revision is asked for.
type revisionedContent struct {
	*testContent
}

func (c revisionedContent) ResolveResourceTx(_ context.Context, _ tx.Queryer, revision string, line grant.Line) (ResourcePolicy, error) {
	d := &TemporalDescriptor{Revision: revision, ResourceKey: line.ResourceKey, RegenEvery: 6 * time.Minute, RegenAmount: 1, CapRule: "STATIC", StaticCap: 180, AllowExplicitGrantAboveNaturalCap: true}
	return ResourcePolicy{Kind: grant.Temporal, Descriptor: d, PolicyVersion: revision}, nil
}

func TestRepinTemporalMovesStaleRowsOnceAndKeepsAccrual(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700001000, 0).UTC()
	anchor := now.Add(-13 * time.Minute)
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 5, StateVersion: 1, UpdatedAt: anchor},
		temporal: map[string]economy.TemporalState{
			"spirit_energy": {PlayerID: actor.PlayerID, ResourceKey: "spirit_energy", StoredAmount: 100, RegenAnchorAt: &anchor, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 2, UpdatedAt: anchor},
		},
	}
	svc := Service{Store: store, Content: revisionedContent{&testContent{}}, Privileges: BaselinePrivilegeProvider{}}
	if err := svc.RepinTemporalTx(context.Background(), &testTx{}, actor.PlayerID, testContentRevisionB, now); err != nil {
		t.Fatal(err)
	}
	got := store.temporal["spirit_energy"]
	if got.ContentRevision != testContentRevisionB || got.PolicyVersion != testContentRevisionB || got.StoredAmount != 102 || got.RegenAnchorAt == nil || !got.RegenAnchorAt.Equal(anchor.Add(12*time.Minute)) || got.StateVersion != 3 {
		t.Fatalf("repin state=%+v", got)
	}
	if err := svc.RepinTemporalTx(context.Background(), &testTx{}, actor.PlayerID, testContentRevisionB, now.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if store.saveTemporalCalls != 1 {
		t.Fatalf("second repin wrote again: calls=%d", store.saveTemporalCalls)
	}
}

func TestDebitTemporalSpendsAtOperationTimeAndRefusesShortOrStaleRows(t *testing.T) {
	actor := testActor(t)
	now := time.Unix(1700002000, 0).UTC()
	store := &testStore{
		progression: player.Progression{PlayerID: actor.PlayerID, Level: 5, StateVersion: 1, UpdatedAt: now},
		temporal: map[string]economy.TemporalState{
			"spirit_energy": {PlayerID: actor.PlayerID, ResourceKey: "spirit_energy", StoredAmount: 10, PolicyVersion: testContentRevisionA, ContentRevision: testContentRevisionA, StateVersion: 1, UpdatedAt: now},
		},
	}
	svc := Service{Store: store, Content: revisionedContent{&testContent{}}, Privileges: BaselinePrivilegeProvider{}}
	op, err := bindContentRevision(operation.Context{ID: testUUID(150), StartedAt: now}, testContentRevisionA)
	if err != nil {
		t.Fatal(err)
	}
	got, err := svc.DebitTemporalTx(context.Background(), &testTx{}, actor.PlayerID, "spirit_energy", 6, op)
	if err != nil || got.StoredAmount != 4 || store.temporal["spirit_energy"].StoredAmount != 4 {
		t.Fatalf("debit=%+v err=%v", got, err)
	}
	if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, actor.PlayerID, "spirit_energy", 5, op); !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("short debit err=%v", err)
	}
	stale, _ := bindContentRevision(operation.Context{ID: testUUID(151), StartedAt: now}, testContentRevisionB)
	if _, err := svc.DebitTemporalTx(context.Background(), &testTx{}, actor.PlayerID, "spirit_energy", 1, stale); !errors.Is(err, ErrContentRevisionConflict) {
		t.Fatalf("stale revision err=%v", err)
	}
}
