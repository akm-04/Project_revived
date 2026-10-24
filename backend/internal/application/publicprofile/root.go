package publicprofile

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"reflect"
	"time"
)

var ErrInvalidState = errors.New("invalid PublicProfile root/prepared transaction")
var ErrStaleRoot = errors.New("PublicProfile root CAS conflict")

type PreparedRoot struct {
	caller            tx.Tx
	root              Root
	present, prepared bool
}

func (p PreparedRoot) Existing() (Root, bool) { return p.root.Clone(), p.present }

type RootService struct{ Store Store }

// Caller must hold canonical315 for this exact player/server and order391 after all lower keys.
func (s RootService) PrepareRootTx(c context.Context, t tx.Tx, f playerroot.Root) (PreparedRoot, error) {
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
		r = Root{PlayerID: f.PlayerID, Preferences: profile.Defaults()}
	}
	return PreparedRoot{caller: t, root: r.Clone(), present: ok, prepared: true}, nil
}
func (s RootService) PreparePreferencesTx(c context.Context, t tx.Tx, f playerroot.Root) (PreparedRoot, error) {
	return s.PrepareRootTx(c, t, f)
}
func (s RootService) valid(t tx.Tx, p PreparedRoot) bool {
	a, b := reflect.ValueOf(t), reflect.ValueOf(p.caller)
	return s.Store != nil && p.prepared && a.IsValid() && b.IsValid() && a.Type() == b.Type() && a.Comparable() && a.Equal(b)
}
func (s RootService) ApplyPreferencesTx(c context.Context, t tx.Tx, p PreparedRoot, change profile.Change, at time.Time) (Root, bool, error) {
	if !s.valid(t, p) || at.IsZero() {
		return Root{}, false, ErrInvalidState
	}
	prefs, e := p.root.Preferences.Apply(change)
	if e != nil {
		return Root{}, false, e
	}
	if prefs.Equal(p.root.Preferences) {
		fresh, present, err := s.Store.ReadRootTx(c, t, p.root.PlayerID)
		if err != nil {
			return Root{}, false, err
		}
		if present != p.present || (present && fresh.StateVersion != p.root.StateVersion) {
			return Root{}, false, ErrStaleRoot
		}
		return p.root.Clone(), p.present, nil
	}
	r, e := s.apply(c, t, p, prefs, at)
	return r, e == nil, e
}

// An actual later owned-child change shares this root version; this port does not create child facts.
func (s RootService) TouchForChildChangeTx(c context.Context, t tx.Tx, p PreparedRoot, at time.Time) (Root, error) {
	if !s.valid(t, p) || at.IsZero() {
		return Root{}, ErrInvalidState
	}
	return s.apply(c, t, p, p.root.Preferences.Clone(), at)
}
func (s RootService) apply(c context.Context, t tx.Tx, p PreparedRoot, prefs profile.Preferences, at time.Time) (Root, error) {
	r := p.root.Clone()
	r.Preferences = prefs
	r.UpdatedAt = at.UTC()
	if p.present {
		if r.StateVersion == math.MaxInt64 || at.Before(p.root.UpdatedAt) {
			return Root{}, ErrInvalidState
		}
		r.StateVersion++
		if e := r.Validate(); e != nil {
			return Root{}, e
		}
		if e := s.Store.UpdateRootTx(c, t, p.root, r); e != nil {
			return Root{}, e
		}
	} else {
		r.StateVersion = 1
		r.CreatedAt = at.UTC()
		if e := r.Validate(); e != nil {
			return Root{}, e
		}
		if e := s.Store.InsertRootTx(c, t, r); e != nil {
			return Root{}, e
		}
	}
	return r.Clone(), nil
}
