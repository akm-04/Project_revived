package profilefeedback

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"reflect"
	"time"
)

var ErrInvalid = d.ErrInvalid
var ErrConflict = errors.New("ProfileFeedback proof/CAS conflict")
var ErrRequest = errors.New("invalid ProfileFeedback request")
var ErrProvider = errors.New("ProfileFeedback provider unavailable")

const LockRankRoot uint16 = 392
const RootUniqueConstraint = "player_profile_feedback_roots_pkey"

func RootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, ErrInvalid
	}
	return lockkey.New(LockRankRoot, "profile-feedback.root", lockkey.Int64(int64(pid)))
}
func RootCreationFence(pid identity.PlayerID) (lockkey.CreationFence, error) {
	k, e := playerroot.LockKey(pid)
	if e != nil {
		return lockkey.CreationFence{}, e
	}
	f := lockkey.CreationFence{Parent: k, UniqueConstraint: RootUniqueConstraint}
	return f, f.Validate()
}

type Store interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (d.Root, bool, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (d.Root, bool, error)
	InsertRootTx(context.Context, tx.Tx, d.Root) error
	UpdateRootTx(context.Context, tx.Tx, d.Root, d.Root) error
	FindPraiseTx(context.Context, tx.Queryer, identity.PlayerID, identity.PlayerID) (d.Praise, bool, error)
	InsertPraiseTx(context.Context, tx.Tx, d.Praise) error
	CountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
	ListTx(context.Context, tx.Queryer, identity.PlayerID, int64, int64) ([]d.Praise, error)
}
type PreparedRoot struct {
	caller  tx.Tx
	root    d.Root
	present bool
}
type RootService struct{ Store Store }

// Caller holds sorted canonical315 and all lower relation/profile keys before392.
func (s RootService) PrepareTx(c context.Context, t tx.Tx, f playerroot.Root) (PreparedRoot, error) {
	if t == nil || s.Store == nil || f.Validate() != nil {
		return PreparedRoot{}, ErrInvalid
	}
	r, ok, e := s.Store.LockRootTx(c, t, f.PlayerID)
	if e != nil {
		return PreparedRoot{}, e
	}
	if ok && (r.Validate() != nil || r.PlayerID != f.PlayerID) {
		return PreparedRoot{}, ErrInvalid
	}
	if !ok {
		r = d.Root{PlayerID: f.PlayerID}
	}
	return PreparedRoot{t, r, ok}, nil
}
func (s RootService) AddPraiseTx(c context.Context, t tx.Tx, p PreparedRoot, actor identity.PlayerID, at time.Time) (d.Praise, d.Root, bool, error) {
	a, b := reflect.ValueOf(t), reflect.ValueOf(p.caller)
	if s.Store == nil || !a.IsValid() || !b.IsValid() || a.Type() != b.Type() || !a.Comparable() || !a.Equal(b) || at.IsZero() || !actor.Valid() || actor == p.root.PlayerID {
		return d.Praise{}, d.Root{}, false, ErrInvalid
	}
	fresh, ok, e := s.Store.ReadRootTx(c, t, p.root.PlayerID)
	if e != nil {
		return d.Praise{}, d.Root{}, false, e
	}
	if ok != p.present || (ok && fresh.StateVersion != p.root.StateVersion) {
		return d.Praise{}, d.Root{}, false, ErrConflict
	}
	prior, yes, e := s.Store.FindPraiseTx(c, t, p.root.PlayerID, actor)
	if e != nil {
		return d.Praise{}, d.Root{}, false, e
	}
	if yes {
		if !p.present || prior.Validate() != nil || prior.RootVersion > p.root.StateVersion {
			return d.Praise{}, d.Root{}, false, ErrInvalid
		}
		return prior, p.root, false, nil
	}
	r := p.root
	if r.StateVersion == math.MaxInt64 {
		return d.Praise{}, d.Root{}, false, ErrInvalid
	}
	r.StateVersion++
	r.UpdatedAt = at.UTC()
	if p.present {
		if r.UpdatedAt.Before(p.root.UpdatedAt) {
			r.UpdatedAt = p.root.UpdatedAt
		}
		e = s.Store.UpdateRootTx(c, t, p.root, r)
	} else {
		r.CreatedAt = r.UpdatedAt
		e = s.Store.InsertRootTx(c, t, r)
	}
	if e != nil {
		return d.Praise{}, d.Root{}, false, e
	}
	fact := d.Praise{Target: r.PlayerID, Actor: actor, FirstAt: at.UTC(), RootVersion: r.StateVersion}
	if fact.Validate() != nil {
		return d.Praise{}, d.Root{}, false, ErrInvalid
	}
	if e = s.Store.InsertPraiseTx(c, t, fact); e != nil {
		return d.Praise{}, d.Root{}, false, e
	}
	return fact, r, true, nil
}
func (s RootService) ObserveTx(c context.Context, sc tx.Scope, target, actor identity.PlayerID, rev string, at time.Time) (d.Observation, error) {
	out := d.Observation{}
	if s.Store == nil || sc.Tx == nil || sc.Operation.ID.IsZero() || sc.Operation.StartedAt.IsZero() || sc.Attempt < 1 || (sc.Options.Isolation != tx.RepeatableRead && sc.Options.Isolation != tx.Serializable) || !target.Valid() || !actor.Valid() || rev == "" || at.IsZero() {
		return out, ErrInvalid
	}
	r, ok, e := s.Store.ReadRootTx(c, sc.Tx, target)
	if e != nil {
		return out, e
	}
	n, e := s.Store.CountTx(c, sc.Tx, target)
	if e != nil {
		return out, e
	}
	fact, has, e := s.Store.FindPraiseTx(c, sc.Tx, target, actor)
	if e != nil {
		return out, e
	}
	if n < 0 || n > 9007199254740991 || (!ok && (n != 0 || has)) || (ok && (r.Validate() != nil || r.PlayerID != target)) || (has && (fact.Validate() != nil || fact.RootVersion > r.StateVersion || n == 0)) {
		return out, ErrInvalid
	}
	return d.Observation{Target: target, Actor: actor, Count: n, RootVersion: r.StateVersion, HasPraised: has, ContentRevision: rev, ObservedAt: at.UTC()}, nil
}
