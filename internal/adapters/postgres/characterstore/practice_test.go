package characterstore

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func practiceTestUUID(t *testing.T, b byte) ids.UUID {
	t.Helper()
	id, err := ids.NewUUIDFrom(strings.NewReader(strings.Repeat(string([]byte{b}), 16)))
	if err != nil {
		t.Fatal(err)
	}
	return id
}

func TestProposalArgsPreserveReplacementGenerationTimes(t *testing.T) {
	sid, err := identity.SessionIDFrom(practiceTestUUID(t, 's'))
	if err != nil {
		t.Fatal(err)
	}
	cid, err := identity.ContextIDFrom(practiceTestUUID(t, 'c'))
	if err != nil {
		t.Fatal(err)
	}
	refs, err := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)}, policy.Ref{Name: "practice.bounds", Version: "PRACTICE_BOUNDS_V1"})
	if err != nil {
		t.Fatal(err)
	}
	created := time.Date(2026, 9, 18, 1, 2, 3, 0, time.UTC)
	updated := created.Add(5 * time.Second)
	p := apppractice.Proposal{
		PlayerID: identity.PlayerID(7), SessionID: sid, ActorID: 99, ActorStateVersion: 4,
		Proposed: character.PracticeAttrs{11, 12, 13}, GenerationOperationID: practiceTestUUID(t, 'o'),
		GenerationContextID: cid, GenerationKind: apppractice.PendingManual,
		GenerationContentRevision: strings.Repeat("a", 64), GenerationPolicyRefs: refs,
		CreatedAt: created, UpdatedAt: updated,
	}
	args, err := proposalArgs(p)
	if err != nil {
		t.Fatal(err)
	}
	if len(args) != 14 {
		t.Fatalf("arg count=%d want=14", len(args))
	}
	if got, ok := args[12].(time.Time); !ok || !got.Equal(created) {
		t.Fatalf("created arg=%#v want=%s", args[12], created)
	}
	if got, ok := args[13].(time.Time); !ok || !got.Equal(updated) {
		t.Fatalf("updated arg=%#v want=%s", args[13], updated)
	}
}

type practiceAccountingTag int64

func (t practiceAccountingTag) RowsAffected() int64 { return int64(t) }

type practiceAccountingRow struct{}

func (practiceAccountingRow) Scan(...any) error { return errors.New("unexpected row") }

type practiceAccountingTx struct {
	rows  int64
	query string
	args  []any
}

func (t *practiceAccountingTx) Exec(_ context.Context, query string, args ...any) (tx.CommandTag, error) {
	t.query = query
	t.args = append([]any(nil), args...)
	return practiceAccountingTag(t.rows), nil
}
func (*practiceAccountingTx) QueryRow(context.Context, string, ...any) tx.Row {
	return practiceAccountingRow{}
}
func (*practiceAccountingTx) Commit(context.Context) error   { return nil }
func (*practiceAccountingTx) Rollback(context.Context) error { return nil }

func TestSaveAccountingTxPersistsFullRootInOneCAS(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	created := now.Add(-24 * time.Hour)
	free := now.Add(-2 * time.Hour)
	epoch := now.Add(-12 * time.Hour)
	vip := int64(5)
	root := apppractice.Root{
		PlayerID: identity.PlayerID(7), FreeLastConsumedAt: &free, DailyEpochStartAt: &epoch,
		DailyEpochPolicyVersion: apppractice.DailyEpochPolicyV1,
		BlessRemaining:          30, BlessCapacityAtEpoch: 100, BlessVIPLevelAtEpoch: &vip,
		BlessPrivilegeProviderRevision: "vip-test/v1", BlessContentRevision: strings.Repeat("a", 64),
		BaseMana: 70000, BaseCrystal: 15, StateVersion: 5, CreatedAt: created, UpdatedAt: now,
	}
	txv := &practiceAccountingTx{rows: 1}
	if err := (Store{}).SaveAccountingTx(context.Background(), txv, root, 4); err != nil {
		t.Fatal(err)
	}
	if len(txv.args) != 13 {
		t.Fatalf("arg count=%d want=13", len(txv.args))
	}
	if txv.args[0] != int64(7) || txv.args[9] != int64(70000) || txv.args[10] != int64(15) || txv.args[12] != int64(4) {
		t.Fatalf("unexpected accounting args=%#v", txv.args)
	}
}

func TestSaveAccountingTxReportsRootCASConflict(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	root := apppractice.Root{PlayerID: identity.PlayerID(7), StateVersion: 2, CreatedAt: now.Add(-time.Hour), UpdatedAt: now}
	txv := &practiceAccountingTx{rows: 0}
	if err := (Store{}).SaveAccountingTx(context.Background(), txv, root, 1); !errors.Is(err, apppractice.ErrStaleVersion) {
		t.Fatalf("err=%v want ErrStaleVersion", err)
	}
}

func TestPracticeActorCASMapsLostRaceToTypedStaleVersion(t *testing.T) {
	now := time.Date(2026, 9, 18, 12, 0, 0, 0, time.UTC)
	txv := &practiceAccountingTx{rows: 0}
	ref := character.HeroRef{PlayerID: identity.PlayerID(7), PartnerID: 9}
	err := (Store{}).CompareAndSwapHeroPracticeTx(context.Background(), txv, ref, 3, character.PracticeAttrs{1, 2, 3}, now)
	if !errors.Is(err, apppractice.ErrActorStaleVersion) {
		t.Fatalf("err=%v want ErrActorStaleVersion", err)
	}
}
