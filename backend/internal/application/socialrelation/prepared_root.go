package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"reflect"
	"time"
)

// PreparedRootStore adds a creation effect under already fenced315/360
// absence. It must not insert then acquire another lower-ranked root lock.
type PreparedRootStore interface {
	ReadPreparedRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, bool, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	InsertPreparedRootTx(context.Context, tx.Tx, Root) error
	TouchRootTx(context.Context, tx.Tx, Root, time.Time) error
}

type PreparedRoot struct {
	caller            tx.Tx
	root              Root
	present, prepared bool
}

func (p PreparedRoot) Existing() (Root, bool) { return p.root, p.present }

type RootService struct{ Store PreparedRootStore }

func (s RootService) ReadTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (Root, bool, error) {
	if s.Store == nil || q == nil || !pid.Valid() {
		return Root{}, false, ErrInvalidState
	}
	return s.Store.ReadPreparedRootTx(c, q, pid)
}

func (s RootService) PrepareTx(c context.Context, t tx.Tx, f playerroot.Root) (PreparedRoot, error) {
	if t == nil || s.Store == nil || f.Validate() != nil {
		return PreparedRoot{}, ErrInvalidState
	}
	r, ok, e := s.Store.LockRootTx(c, t, f.PlayerID)
	if e != nil {
		return PreparedRoot{}, e
	}
	if ok && (r.Validate() != nil || r.PlayerID != f.PlayerID) {
		return PreparedRoot{}, ErrInvalidState
	}
	if !ok {
		r = Root{PlayerID: f.PlayerID}
	}
	return PreparedRoot{caller: t, root: r, present: ok, prepared: true}, nil
}
func (s RootService) ApplyChangeTx(c context.Context, t tx.Tx, p PreparedRoot, at time.Time) (Root, error) {
	a, b := reflect.ValueOf(t), reflect.ValueOf(p.caller)
	if s.Store == nil || !p.prepared || !a.IsValid() || !b.IsValid() || a.Type() != b.Type() || !a.Comparable() || !a.Equal(b) || at.IsZero() {
		return Root{}, ErrInvalidState
	}
	r := p.root
	if p.present {
		if r.Validate() != nil || r.StateVersion == math.MaxInt64 || at.Before(r.UpdatedAt) {
			return Root{}, ErrInvalidState
		}
		if e := s.Store.TouchRootTx(c, t, r, at.UTC()); e != nil {
			return Root{}, e
		}
		r.StateVersion++
		r.UpdatedAt = at.UTC()
	} else {
		r.StateVersion = 1
		r.CreatedAt = at.UTC()
		r.UpdatedAt = at.UTC()
		if e := s.Store.InsertPreparedRootTx(c, t, r); e != nil {
			return Root{}, e
		}
	}
	return r, r.Validate()
}
