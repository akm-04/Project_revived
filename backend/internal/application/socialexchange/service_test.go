package socialexchange

import (
	"context"
	"encoding/json"
	"errors"
	generation "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
	"time"
)

type testTag int64

func (tag testTag) RowsAffected() int64 { return int64(tag) }

type testRow struct{}

func (testRow) Scan(...any) error { return nil }

type fixture struct {
	dropCommitReceipt bool
	receiptCollision  bool
	events            []string
	stored            receipt.Receipt
	pending           receipt.Receipt
	catalogError      error
	tuningError       error
	putError          error
	commitError       error
	tuning            json.RawMessage
	prepares          int
	applies           int
	rolledBack        bool
}

func (fixture *fixture) Begin(context.Context, tx.Options) (tx.Tx, error) {
	fixture.pending = receipt.Receipt{}
	return fixture, nil
}
func (*fixture) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (*fixture) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (fixture *fixture) Commit(context.Context) error {
	if !fixture.pending.ID.IsZero() && !fixture.dropCommitReceipt {
		fixture.stored = fixture.pending
	}
	return fixture.commitError
}
func (fixture *fixture) Rollback(context.Context) error {
	fixture.rolledBack = true
	fixture.pending = receipt.Receipt{}
	return nil
}
func (*fixture) Now(context.Context) (time.Time, error) { return time.Unix(1700000000, 0).UTC(), nil }
func (fixture *fixture) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	fixture.events = append(fixture.events, "fence")
	return nil
}
func (fixture *fixture) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	fixture.events = append(fixture.events, "root")
	return []playerroot.Root{{PlayerID: players[0], LogicalServerID: server}}, nil
}
func (fixture *fixture) FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error) {
	fixture.events = append(fixture.events, "receipt")
	return fixture.stored, !fixture.stored.ID.IsZero(), nil
}
func (fixture *fixture) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return fixture.stored, !fixture.stored.ID.IsZero(), nil
}
func (fixture *fixture) PutTx(_ context.Context, _ tx.Tx, value receipt.Receipt) (receipt.PutResult, error) {
	if fixture.putError != nil {
		return receipt.PutResult{}, fixture.putError
	}
	if fixture.receiptCollision {
		return receipt.PutResult{Inserted: false}, nil
	}
	fixture.pending = value
	return receipt.PutResult{Inserted: true, Receipt: value}, nil
}
func (fixture *fixture) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	fixture.events = append(fixture.events, "active")
	return revision, fixture.catalogError
}
func (fixture *fixture) SocialExchangeCatalogTx(context.Context, tx.Queryer, string) (domain.Catalog, error) {
	fixture.events = append(fixture.events, "catalog")
	return sourceCatalog(), fixture.catalogError
}
func (fixture *fixture) TuningTx(context.Context, tx.Queryer) (json.RawMessage, error) {
	fixture.events = append(fixture.events, "tuning")
	return fixture.tuning, fixture.tuningError
}
func (fixture *fixture) PrepareMaterialExchangeTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, request i5.MaterialExchangeRequest, _ operation.Context) (*i5.PreparedMaterialExchange, error) {
	fixture.prepares++
	if request.Cost.Scalars[0].ResourceKey != "friendship_coin" || !request.AllowOverflowMail {
		return nil, errors.New("wrong material request")
	}
	return &i5.PreparedMaterialExchange{}, nil
}
func (fixture *fixture) ApplyMaterialExchangeTx(ctx context.Context, _ tx.Tx, _ *i5.PreparedMaterialExchange) (i5.MaterialExchangeResult, error) {
	fixture.applies++
	changes.Balance(ctx, "friendship_coin", 900)
	return i5.MaterialExchangeResult{Debit: i5.MaterialDebitResult{Scalars: []economy.ScalarBalance{{PlayerID: 7, ResourceKey: "friendship_coin", Amount: 900}}}, Restoration: i5.GrantResult{Awards: []i5.Award{{TableID: 31, ItemNum: 1}}}}, nil
}

const revision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func setup(t *testing.T) (Service, *fixture, identity.ActorContext, operation.Context, context.Context) {
	t.Helper()
	store := &fixture{}
	identifier, _ := ids.NewUUID()
	contextIdentifier, _ := identity.ContextIDFrom(identifier)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1, AccountUID: "account", ContextID: contextIdentifier}
	identifier, _ = ids.NewUUID()
	op := operation.Context{ID: identifier, StartedAt: time.Unix(1700000000, 0).UTC()}
	service := Service{Timed: generation.TimedRunner{Binder: generation.Binder{Time: store}, Runner: tx.Runner{DB: store}}, Fence: store, Players: store, Content: store, Settings: store, Materials: store, Receipts: store, ReceiptReader: store}
	ctx, _ := changes.Track(context.Background())
	return service, store, actor, op, ctx
}
func TestExchangeSerializesBeforeReceiptAndReplaysBeforeUnavailableSettings(t *testing.T) {
	service, store, actor, op, ctx := setup(t)
	first, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(store.events, []string{"fence", "root", "receipt", "active", "catalog", "tuning"}) {
		t.Fatal(store.events)
	}
	store.events = nil
	store.catalogError = errors.New("removed content")
	store.tuningError = errors.New("operator unavailable")
	again, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op)
	if err != nil || !reflect.DeepEqual(first, again) || store.prepares != 1 || store.applies != 1 || !reflect.DeepEqual(store.events, []string{"fence", "root", "receipt"}) {
		t.Fatal(first, again, err, store.events)
	}
	_, err = service.Exchange(ctx, actor, Request{ProductID: 1, Count: 2}, op)
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) {
		t.Fatal("mismatched replay", err)
	}
}
func TestExchangePropagatesSettingsFailureAndRollsBackOuterReceiptFailure(t *testing.T) {
	service, store, actor, op, ctx := setup(t)
	store.tuningError = errors.New("database failed")
	if _, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op); err == nil || store.prepares != 0 {
		t.Fatal(err)
	}
	store.tuningError = nil
	store.putError = errors.New("receipt write failed")
	if _, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op); err == nil || !store.rolledBack || !store.stored.ID.IsZero() {
		t.Fatal(err, store)
	}
}
func TestExchangeUnknownCommitRecoversOnlyValidatedPositiveReceipt(t *testing.T) {
	service, store, actor, op, ctx := setup(t)
	store.commitError = errors.New("lost commit ack")
	result, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op)
	if err != nil || result == nil || store.applies != 1 {
		t.Fatal(result, err)
	}
	store.stored.ResultSchema = "foreign"
	if _, err = service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op); !errors.Is(err, ErrProof) {
		t.Fatal(err)
	}
}
func TestExchangeRejectsCallerContentPinDrift(t *testing.T) {
	service, _, actor, op, ctx := setup(t)
	if _, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op); err != nil {
		t.Fatal(err)
	}
	op.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"})
	if _, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, op); !errors.Is(err, ErrProof) {
		t.Fatal(err)
	}
}

func TestExchangeUnknownCommitAbsenceNeverRetriesSpend(t *testing.T) {
	service, store, actor, operation, ctx := setup(t)
	store.commitError = errors.New("lost commit ack")
	store.dropCommitReceipt = true
	_, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, operation)
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) || store.applies != 1 || store.prepares != 1 {
		t.Fatal(err, store.applies, store.prepares)
	}
}
func TestExchangeReceiptCollisionAbortsAndStoredTimeUsesDatabasePrecision(t *testing.T) {
	service, store, actor, operation, ctx := setup(t)
	store.receiptCollision = true
	_, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, operation)
	var conflict *receipt.ConflictError
	if !errors.As(err, &conflict) || !store.rolledBack || !store.stored.ID.IsZero() {
		t.Fatal(err)
	}
	store.receiptCollision = false
	operation.StartedAt = operation.StartedAt.Add(123456789 * time.Nanosecond)
	first, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, operation)
	if err != nil {
		t.Fatal(err)
	}
	store.stored.OperationStartedAt = store.stored.OperationStartedAt.Truncate(time.Microsecond)
	again, err := service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, operation)
	if err != nil || !reflect.DeepEqual(first, again) {
		t.Fatal(err)
	}
	operation.EntropySeed[0]++
	if _, err = service.Exchange(ctx, actor, Request{ProductID: 1, Count: 1}, operation); !errors.Is(err, ErrProof) {
		t.Fatal("entropy drift accepted", err)
	}
}
