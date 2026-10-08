//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"errors"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
	"time"
)

type giftRetryStore struct {
	sg.Store
	writes []sg.Transfer
	epochs []sg.Epoch
	abort  bool
}

func (s *giftRetryStore) PutEpoch(c context.Context, t tx.Tx, e sg.Epoch, ok bool, at time.Time) error {
	s.epochs = append(s.epochs, e)
	return s.Store.PutEpoch(c, t, e, ok, at)
}
func (s *giftRetryStore) InsertTransfer(c context.Context, t tx.Tx, v sg.Transfer) error {
	s.writes = append(s.writes, v)
	e := s.Store.InsertTransfer(c, t, v)
	if e == nil && s.abort {
		s.abort = false
		return tx.MarkDefiniteAbort(giftInjected)
	}
	return e
}

type giftBoundaryClock struct {
	before time.Time
	calls  int
}

func (c *giftBoundaryClock) Now(context.Context) (time.Time, error) {
	c.calls++
	if c.calls == 1 {
		return c.before, nil
	}
	return c.before.Add(time.Second), nil
}
func Test7A_RetryBindingAcrossMidnight(t *testing.T) {
	f, s, a, b := giftFixture(t)
	at := f.now()
	day, _ := sg.Day(at)
	anchor, _ := time.Parse("2006-01-02", day)
	before := anchor.Add(16*time.Hour - time.Second)
	if before.Before(at) {
		before = before.Add(24 * time.Hour)
	}
	clock := &giftBoundaryClock{before: before}
	store := &giftRetryStore{Store: s.Store, abort: true}
	s.Timed.Binder.Time = clock
	s.Store = store
	op := f.op()
	if _, e := s.Send(ctx, a, b.PlayerID, op); e != nil {
		t.Fatal(e)
	}
	if clock.calls != 1 || len(store.writes) != 2 || len(store.epochs) != 4 || !reflect.DeepEqual(store.writes[0].SenderGeneration, store.writes[1].SenderGeneration) || !reflect.DeepEqual(store.epochs[0], store.epochs[2]) || !reflect.DeepEqual(store.epochs[1], store.epochs[3]) {
		t.Fatal(clock.calls, store.writes, store.epochs)
	}
	for _, v := range store.writes {
		if v.SendOperation != op.ID || !v.StartedAt.Equal(op.StartedAt) || !v.IssuedAt.Equal(before) {
			t.Fatal(v)
		}
	}
	if f.number(`SELECT count(*) FROM social_gift_transfers`) != 1 {
		t.Fatal("retry leaked")
	}
	t.Log("REAL_PG first attempt mutates then authoritative definite-abort rollback; retry holds original entropy/StartedAt/content/day/GenerationID/DBDecisionAt across injected midnight")
}

type giftAfterCommit struct {
	tx.Beginner
	after  func()
	begins int
}

func (b *giftAfterCommit) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	b.begins++
	t, e := b.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return &giftLostCommit{Tx: t, after: b.after}, nil
}

type giftLostCommit struct {
	tx.Tx
	after func()
}

func (t giftLostCommit) Commit(c context.Context) error {
	if e := t.Tx.Commit(c); e != nil {
		return e
	}
	t.after()
	return errors.New("injected lost acknowledgement after actual commit")
}

type giftUnavailableStore struct {
	sg.Store
	armed  *bool
	absent bool
}

func (s giftUnavailableStore) ReadSend(c context.Context, q tx.Queryer, id ids.UUID) (sg.Transfer, bool, error) {
	if *s.armed {
		if s.absent {
			return sg.Transfer{}, false, nil
		}
		return sg.Transfer{}, false, errors.New("injected owner evidence unavailable")
	}
	return s.Store.ReadSend(c, q, id)
}
func Test7A_UnknownAbsentUnavailablePartialWitness(t *testing.T) {
	for _, kind := range []string{"absent", "unavailable", "notice"} {
		t.Run(kind, func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			armed := false
			if kind != "notice" {
				s.Store = giftUnavailableStore{s.Store, &armed, kind == "absent"}
			}
			fault := &giftAfterCommit{Beginner: f.p, after: func() {
				armed = true
				if kind == "notice" {
					f.sql(`UPDATE social_notices SET notice_time=notice_time+interval '1 second' WHERE notice_type=4`)
				}
			}}
			s.Timed.Runner.DB = fault
			_, e := s.Send(ctx, a, b.PlayerID, f.op())
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) || fault.begins != 1 || f.number(`SELECT count(*) FROM social_gift_transfers`) != 1 {
				t.Fatal("incomplete evidence caused replay/false success", e)
			}
			t.Log("REAL_PG actual commit with deliberately incomplete/unavailable post-commit evidence; one attempt and unresolved result")
		})
	}
}
