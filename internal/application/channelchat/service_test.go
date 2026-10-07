package channelchat

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
)

type fakeTag struct{}

func (fakeTag) RowsAffected() int64 { return 0 }

type fakeTx struct {
	commits     int
	commitError error
}

func (f *fakeTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (f *fakeTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return fakeTag{}, nil }
func (f *fakeTx) Commit(context.Context) error                                { f.commits++; return f.commitError }
func (f *fakeTx) Rollback(context.Context) error                              { return nil }

type fakeDB struct {
	t       *fakeTx
	options tx.Options
	begins  int
}

func (f *fakeDB) Begin(_ context.Context, o tx.Options) (tx.Tx, error) {
	f.begins++
	f.options = o
	return f.t, nil
}

type readFunc func(context.Context, tx.Tx, apprealtime.Admission, bool) (playerpresentation.Minimal, error)

func (f readFunc) ReadTx(c context.Context, t tx.Tx, a apprealtime.Admission, b bool) (playerpresentation.Minimal, error) {
	return f(c, t, a, b)
}
func TestChannelReadDefiniteCommitAndUnknownPrivacy(t *testing.T) {
	for _, ambiguous := range []bool{false, true} {
		t.Run(map[bool]string{false: "definite", true: "unknown"}[ambiguous], func(t *testing.T) {
			ft := &fakeTx{}
			if ambiguous {
				ft.commitError = errors.New("lost commit reply")
			}
			db := &fakeDB{t: ft}
			s := Service{Runner: tx.Runner{DB: db}, Operations: operation.Factory{Clock: clock.System{}}, Reader: readFunc(func(_ context.Context, t tx.Tx, _ apprealtime.Admission, _ bool) (playerpresentation.Minimal, error) {
				if t != ft {
					panic("wrongtransaction")
				}
				return playerpresentation.Minimal{Name: "private", PlayerID: 1}, nil
			})}
			v, e := s.Prepare(context.Background(), apprealtime.Admission{}, "x")
			if db.options != (tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}) || db.begins != 1 || ft.commits != 1 {
				t.Fatal(db, ft)
			}
			if ambiguous {
				if e == nil || v.Name != "" {
					t.Fatal(v, e)
				}
			} else if e != nil || v.Name != "private" {
				t.Fatal(v, e)
			}
		})
	}
}
func TestChannelReadRejectsTextBeforeDatabase(t *testing.T) {
	db := &fakeDB{t: &fakeTx{}}
	s := Service{Runner: tx.Runner{DB: db}}
	if _, e := s.Prepare(context.Background(), apprealtime.Admission{}, ""); e == nil || db.begins != 0 {
		t.Fatal(e, db.begins)
	}
	p := ReadProfile()
	if e := p.Validate(); e != nil {
		t.Fatal(e)
	}
}
