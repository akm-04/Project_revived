package socialrelationstore

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type relationTestTag int64

func (t relationTestTag) RowsAffected() int64 { return int64(t) }

type relationTestRow struct{ scan func(...any) error }

func (r relationTestRow) Scan(v ...any) error { return r.scan(v...) }

type relationTestTx struct {
	execQuery string
	execArgs  []any
	row       func(string, ...any) tx.Row
}

func (t *relationTestTx) Exec(_ context.Context, q string, args ...any) (tx.CommandTag, error) {
	t.execQuery, t.execArgs = q, args
	return relationTestTag(1), nil
}
func (t *relationTestTx) QueryRow(_ context.Context, q string, args ...any) tx.Row {
	return t.row(q, args...)
}
func (*relationTestTx) Commit(context.Context) error   { return nil }
func (*relationTestTx) Rollback(context.Context) error { return nil }

func TestEnsureRootUsesOwnerInsertThenRowLock(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	fake := &relationTestTx{}
	fake.row = func(q string, args ...any) tx.Row {
		if q != lockRootSQL {
			t.Fatalf("query=%q", q)
		}
		return relationTestRow{scan: func(v ...any) error {
			*(v[0].(*int64)) = 100001
			*(v[1].(*int64)) = 1
			*(v[2].(*time.Time)) = now
			*(v[3].(*time.Time)) = now
			return nil
		}}
	}
	got, err := (Store{}).EnsureRootTx(context.Background(), fake, 100001, now)
	if err != nil || got.PlayerID != 100001 || got.StateVersion != 1 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if !strings.Contains(fake.execQuery, "INSERT INTO player_social_roots") || !strings.Contains(fake.execQuery, "ON CONFLICT(player_id) DO NOTHING") {
		t.Fatalf("exec=%q", fake.execQuery)
	}
	if len(fake.execArgs) != 2 || fake.execArgs[0] != int64(100001) {
		t.Fatalf("args=%v", fake.execArgs)
	}
}

func TestLockFriendshipCanonicalizesPairAndMissingIsNotAnError(t *testing.T) {
	fake := &relationTestTx{row: func(q string, args ...any) tx.Row {
		if q != lockFriendshipSQL || len(args) != 2 || args[0] != int64(100001) || args[1] != int64(200001) {
			t.Fatalf("q=%q args=%v", q, args)
		}
		return relationTestRow{scan: func(...any) error { return kernelstore.ErrNoRows }}
	}}
	_, ok, err := (Store{}).LockFriendshipTx(context.Background(), fake, 200001, 100001)
	if err != nil || ok {
		t.Fatalf("ok=%v err=%v", ok, err)
	}
}

func TestLockRequestRejectsSelfAndPropagatesUnexpectedErrors(t *testing.T) {
	fake := &relationTestTx{row: func(string, ...any) tx.Row {
		return relationTestRow{scan: func(...any) error { return errors.New("boom") }}
	}}
	if _, _, err := (Store{}).LockRequestTx(context.Background(), fake, 100001, 100001); err == nil {
		t.Fatal("self request lock accepted")
	}
	if _, _, err := (Store{}).LockRequestTx(context.Background(), fake, 100001, 200001); err == nil || err.Error() != "boom" {
		t.Fatalf("err=%v", err)
	}
}
