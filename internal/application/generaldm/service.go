package generaldm

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type BindingReader interface {
	ReadBindings(context.Context, tx.Queryer, identity.PlayerID, time.Time) ([]Binding, error)
}
type PrivacyReader interface {
	ReadGeneralBlockTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (int64, bool, error)
}
type OwnerReader interface {
	ReadOwnerFenceTx(context.Context, tx.Queryer) (int64, error)
}
type Store interface {
	InsertTx(context.Context, tx.Tx, Intent) error
	UpdateTx(context.Context, tx.Tx, Intent, int64, time.Time) error
	Find(context.Context, tx.Queryer, string) (Intent, bool, error)
	Lock(context.Context, tx.Tx, string) (Intent, bool, error)
	Page(context.Context, tx.Queryer, string, string, int) ([]string, error)
	HighWater(context.Context, tx.Queryer) (string, error)
}
type Service struct {
	Timed        gen.TimedRunner
	Queryer      tx.Queryer
	Store        Store
	Bindings     BindingReader
	Privacy      PrivacyReader
	Players      playerroot.TxLocker
	Presentation playerpresentation.TxReader
	Observer     playerpresentation.TxObserver
	Owner        OwnerReader
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I7A6B_GENERAL_DM", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: time.Second, TransactionTimeout: 2 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 2 * time.Second}
}
func Retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 10 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}
}
func (s Service) valid() bool {
	return s.Queryer != nil && s.Store != nil && s.Bindings != nil && s.Privacy != nil && s.Players != nil && s.Presentation != nil && s.Observer != nil && s.Owner != nil && s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil
}
func (s Service) lockPlan(c context.Context, t tx.Tx, sender, recipient int64) (int64, bool, error) {
	ordered, e := playerroot.CanonicalPlayerIDs([]identity.PlayerID{identity.PlayerID(sender), identity.PlayerID(recipient)})
	if e != nil {
		return 0, false, e
	}
	for n := 0; n < len(ordered); {
		server, e := sr.CanonicalServer(ordered[n])
		if e != nil {
			return 0, false, e
		}
		j := n + 1
		for j < len(ordered) {
			next, e := sr.CanonicalServer(ordered[j])
			if e != nil {
				return 0, false, e
			}
			if next != server {
				break
			}
			j++
		}
		roots, e := s.Players.LockPlayerRootsTx(c, t, server, ordered[n:j])
		if e != nil {
			return 0, false, e
		}
		if len(roots) != j-n {
			return 0, false, ErrUnavailable
		}
		for k, r := range roots {
			if r.Validate() != nil || r.PlayerID != ordered[n+k] || r.LogicalServerID != server {
				return 0, false, ErrInvalid
			}
		}
		n = j
	}
	return s.Privacy.ReadGeneralBlockTx(c, t, identity.PlayerID(sender), identity.PlayerID(recipient))
}
func (s Service) observe(c context.Context, t tx.Tx, decision, last time.Time) (time.Time, error) {
	now, e := s.Observer.ObserveTx(c, t)
	if e != nil {
		return time.Time{}, e
	}
	if now.IsZero() || now.Before(decision) || now.Sub(decision) > 2*time.Second || now.Before(last) {
		return time.Time{}, ErrTimeInvalid
	}
	return now.UTC(), nil
}

type receiptResolver struct {
	s          Service
	id, digest string
	version    int64
	status     Status
}

func (r receiptResolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	i, ok, e := r.s.Store.Find(c, r.s.Queryer, r.id)
	if e != nil {
		return tx.Resolution{}, e
	}
	if ok && i.Digest == r.digest && (r.version == 0 || i.StateVersion >= r.version && i.Status == r.status) {
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: i.ID}, nil
	}
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}
func (s Service) Accept(c context.Context, sender, recipient int64, message string, op operation.Context) (Intent, error) {
	if !s.valid() {
		return Intent{}, ErrUnavailable
	}
	if sender == recipient || sender < 1 || recipient < 1 || ValidateMessage(message) != nil || op.ID.IsZero() {
		return Intent{}, ErrInvalid
	}
	digest := Digest(sender, recipient, message)
	var out Intent
	_, res, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), receiptResolver{s: s, id: op.ID.String(), digest: digest}, func(c context.Context, sc gen.TimedScope) error {
		out = Intent{}
		known, ok, e := s.Store.Find(c, sc.Tx, op.ID.String())
		if e != nil {
			return e
		}
		if ok {
			if known.Digest != digest {
				return ErrInvalid
			}
			out = known
			return nil
		}
		version, blocked, e := s.lockPlan(c, sc.Tx, sender, recipient)
		if e != nil {
			return e
		}
		if blocked {
			return ErrPrivacySuppressed
		}
		at, e := s.observe(c, sc.Tx, sc.Operation.DecisionAt(), sc.Operation.DecisionAt())
		if e != nil {
			return e
		}
		fence, e := s.Owner.ReadOwnerFenceTx(c, sc.Tx)
		if e != nil || fence < 1 {
			return ErrUnavailable
		}
		bindings, e := s.Bindings.ReadBindings(c, sc.Tx, identity.PlayerID(recipient), at)
		if e != nil {
			return e
		}
		if len(bindings) == 0 || len(bindings) > MaxBindings {
			return ErrUnavailable
		}
		for _, b := range bindings {
			if !b.Valid() || b.OwnerFence != fence {
				return ErrAdmissionRetired
			}
		}
		var b playerpresentation.Batch
		if atReader, ok := s.Presentation.(playerpresentation.TxReaderAt); ok {
			b, e = atReader.ReadManyAtTx(c, sc.Tx, []identity.PlayerID{identity.PlayerID(sender)}, sc.Operation.DecisionAt())
		} else {
			b, e = s.Presentation.ReadManyTx(c, sc.Tx, []identity.PlayerID{identity.PlayerID(sender)})
		}
		if e != nil {
			return e
		}
		p, ok := b.Players[identity.PlayerID(sender)]
		if !ok || p.Minimal.PlayerID != identity.PlayerID(sender) || p.Minimal.Validate() != nil {
			return ErrUnavailable
		}
		m := p.Minimal
		out = Intent{ID: op.ID.String(), Digest: digest, Sender: sender, Recipient: recipient, Message: message, SenderTitleInfo: m.TitleInfo, SenderBubbleInfo: m.BubbleInfo, SenderName: m.Name, SenderType: m.PlayerType, SenderAvatarID: m.AvatarID, SenderAvatarFrameID: m.AvatarFrameID, SenderLevel: m.Level, SenderConquerLevel: m.ConquerLevel, SenderConquerLoopID: m.ConquerLoopID, AcceptedAt: sc.Operation.DecisionAt(), ExpiresAt: sc.Operation.DecisionAt().Add(IntentLifetime), BlockVersion: version, Bindings: bindings, Status: Pending, StateVersion: 1, LastObservedAt: at}
		if out.Validate() != nil {
			return ErrInvalid
		}
		return s.Store.InsertTx(c, sc.Tx, out)
	})
	if e != nil {
		return Intent{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Intent{}, ErrUnavailable
	}
	if res.Reconciled {
		i, ok, e := s.Store.Find(c, s.Queryer, op.ID.String())
		if e != nil || !ok || i.Digest != digest {
			return Intent{}, ErrUnavailable
		}
		return i, nil
	}
	return out, nil
}
func matching(captured, current []Binding) []Binding {
	out := []Binding{}
	for _, a := range captured {
		for _, b := range current {
			if a == b {
				out = append(out, a)
				break
			}
		}
	}
	return out
}

type Transition string

const (
	ClaimTransition       Transition = "CLAIM"
	AttemptTransition     Transition = "ATTEMPT"
	FinishTransition      Transition = "FINISH"
	TimeInvalidTransition Transition = "TIME_INVALID"
)

func (s Service) advance(c context.Context, id string, fence, claim int64, kind Transition, wrote bool, upper time.Time, op operation.Context) (Intent, error) {
	if !s.valid() || id == "" || fence < 1 {
		return Intent{}, ErrUnavailable
	}
	snapshot, ok, e := s.Store.Find(c, s.Queryer, id)
	if e != nil || !ok {
		return Intent{}, ErrUnavailable
	}
	var out Intent
	resolver := receiptResolver{s: s, id: id, digest: snapshot.Digest}
	var positiveResolver gen.TimedUnknownCommitResolver
	if kind == FinishTransition {
		positiveResolver = &resolver
	}
	_, res, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), positiveResolver, func(c context.Context, sc gen.TimedScope) error {
		out = Intent{}
		version, blocked, e := s.lockPlan(c, sc.Tx, snapshot.Sender, snapshot.Recipient)
		if e != nil {
			return e
		}
		currentFence, e := s.Owner.ReadOwnerFenceTx(c, sc.Tx)
		if e != nil {
			return e
		}
		at, e := s.observe(c, sc.Tx, sc.Operation.DecisionAt(), snapshot.LastObservedAt)
		if e != nil {
			return e
		}
		current, e := s.Bindings.ReadBindings(c, sc.Tx, identity.PlayerID(snapshot.Recipient), at)
		if e != nil {
			return e
		}
		i, ok, e := s.Store.Lock(c, sc.Tx, id)
		if e != nil || !ok {
			return ErrUnavailable
		}
		if i.StateVersion != snapshot.StateVersion {
			return tx.MarkDefiniteAbort(ErrChanged)
		}
		if i.Status.Terminal() {
			out = i
			return nil
		}
		eligible := matching(i.Bindings, current)
		kept := eligible[:0]
		for _, b := range eligible {
			if b.OwnerFence == fence {
				kept = append(kept, b)
			}
		}
		eligible = kept
		next := i
		switch {
		case at.Before(i.LastObservedAt):
			next = i.Terminal(TimeInvalid, at)
		case blocked || version != i.BlockVersion:
			next = i.Terminal(PrivacySuppressed, at)
		case currentFence != fence || len(eligible) == 0:
			next = i.Terminal(AdmissionRetired, at)
		case !at.Before(i.ExpiresAt):
			next = i.Terminal(Expired, at)
		default:
			switch kind {
			case ClaimTransition:
				if i.Status == Attempting {
					next = i.Terminal(Unknown, at)
					break
				}
				if i.Status == Claimed {
					if i.LeaseExpiresAt != nil && at.Before(*i.LeaseExpiresAt) {
						return ErrUnavailable
					}
					i.Status = Pending
				}
				next, e = i.Claim(at, fence)
				if e != nil {
					return e
				}
			case AttemptTransition:
				if i.OwnerFence != fence || i.ClaimGeneration != claim {
					return ErrChanged
				}
				next, e = i.BeginAttempt(at)
				if e != nil {
					return e
				}
			case TimeInvalidTransition:
				if i.OwnerFence != fence || i.ClaimGeneration != claim {
					return ErrChanged
				}
				next = i.Terminal(TimeInvalid, at)
			case FinishTransition:
				if i.OwnerFence != fence || i.ClaimGeneration != claim {
					return ErrChanged
				}
				next, e = i.Finish(at, upper, wrote)
				if e != nil && next.Status != TimeInvalid {
					return e
				}
			default:
				return ErrInvalid
			}
		}
		next.LastObservedAt = at
		if e = s.Store.UpdateTx(c, sc.Tx, next, snapshot.StateVersion, at); e != nil {
			return e
		}
		out = next
		resolver.version = next.StateVersion
		resolver.status = next.Status
		return nil
	})
	if e != nil {
		return Intent{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return Intent{}, ErrUnavailable
	}
	if res.Reconciled {
		i, ok, e := s.Store.Find(c, s.Queryer, id)
		if e != nil || !ok {
			return Intent{}, ErrUnavailable
		}
		return i, nil
	}
	return out, nil
}

// Claim never takes over an active claim. ATTEMPTING recovery is terminal and
// cannot trigger a second network attempt.
func (s Service) Claim(c context.Context, id string, fence int64, op operation.Context) (Intent, bool, error) {
	i, e := s.advance(c, id, fence, 0, ClaimTransition, false, time.Time{}, op)
	return i, e == nil && i.Status == Claimed && i.OwnerFence == fence, e
}
func (s Service) BeginAttempt(c context.Context, i Intent, op operation.Context) (Intent, error) {
	return s.advance(c, i.ID, i.OwnerFence, i.ClaimGeneration, AttemptTransition, false, time.Time{}, op)
}
func (s Service) Finish(c context.Context, i Intent, wrote bool, upper time.Time, op operation.Context) (Intent, error) {
	return s.advance(c, i.ID, i.OwnerFence, i.ClaimGeneration, FinishTransition, wrote, upper, op)
}

// Wait observes only canonical receipts. A timeout cannot turn durable admission
// or a queued frame into HTTP success.
func (s Service) Wait(c context.Context, i Intent) (Intent, error) {
	tick := time.NewTicker(100 * time.Millisecond)
	defer tick.Stop()
	for {
		if c.Err() != nil {
			return Intent{}, c.Err()
		}
		current, ok, e := s.Store.Find(c, s.Queryer, i.ID)
		if e != nil || !ok {
			return Intent{}, ErrUnavailable
		}
		if current.Digest != i.Digest {
			return Intent{}, ErrInvalid
		}
		if current.Status == WrittenBeforeDeadline {
			return current, nil
		}
		if current.Status.Terminal() {
			return Intent{}, ErrUnavailable
		}
		now, e := s.Timed.Binder.Time.Now(c)
		if e != nil {
			return Intent{}, e
		}
		if !now.Before(i.ExpiresAt) {
			return Intent{}, ErrUnavailable
		}
		select {
		case <-c.Done():
			return Intent{}, c.Err()
		case <-tick.C:
		}
	}
}

// Recover terminalizes expired payloads and crash-ambiguous ATTEMPTING locally,
// without acquiring another owner's locks or inventing a new target admission.
func (s Service) Recover(c context.Context, id string, op operation.Context) (bool, error) {
	var done bool
	_, res, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		i, ok, e := s.Store.Lock(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if !ok || i.Status.Terminal() {
			done = true
			return nil
		}
		now, e := s.Observer.ObserveTx(c, sc.Tx)
		if e != nil {
			return e
		}
		status := Status("")
		if now.Before(i.LastObservedAt) {
			status = TimeInvalid
		} else if !now.Before(i.ExpiresAt) {
			status = Expired
		} else if i.Status == Attempting {
			status = Unknown
		}
		if status == "" {
			return nil
		}
		next := i.Terminal(status, now)
		if now.Before(i.LastObservedAt) {
			next.LastObservedAt = i.LastObservedAt
		}
		if e = s.Store.UpdateTx(c, sc.Tx, next, i.StateVersion, next.LastObservedAt); e != nil {
			return e
		}
		done = true
		return nil
	})
	if e != nil || res.Outcome != tx.DefiniteCommit {
		if e == nil {
			e = ErrUnavailable
		}
		return false, e
	}
	return done, nil
}

func (s Service) InvalidateTime(c context.Context, i Intent, op operation.Context) (Intent, error) {
	return s.advance(c, i.ID, i.OwnerFence, i.ClaimGeneration, TimeInvalidTransition, false, time.Time{}, op)
}
