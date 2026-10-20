package combat

import (
	"context"
	"errors"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrAttemptNotFound = errors.New("combat: no attempt for locator; RESULT cannot create one")

type StartRequest struct {
	Actor            identity.ActorContext
	Locator          d.Locator
	GenerationRef    string
	StartFingerprint string
	ResultDeadline   time.Time
	Battle           BattleRequest
}

type Started struct {
	Attempt  d.Attempt
	Replayed bool
}

// StartTx runs inside the mode's START transaction, which holds the mode roots
// (601..608) before combat's locator lock (609). The scope must witness that
// same transaction; START commits before any resolver work.
func (s Service) StartTx(ctx context.Context, t tx.Tx, scope ca.CoherentReadScope, request StartRequest) (Started, error) {
	return s.start(ctx, t, scope, request, s.newFreezer(scope, request.Actor.PlayerID))
}

// StartManyTx stages several attempts of one actor in the caller transaction
// (for example the rounds of one match); owner inputs are read once and shared.
func (s Service) StartManyTx(ctx context.Context, t tx.Tx, scope ca.CoherentReadScope, requests []StartRequest) ([]Started, error) {
	if len(requests) == 0 {
		return nil, d.ErrInvalid
	}
	f := s.newFreezer(scope, requests[0].Actor.PlayerID)
	out := make([]Started, 0, len(requests))
	for _, r := range requests {
		if r.Actor != requests[0].Actor {
			return nil, d.ErrInvalid
		}
		started, err := s.start(ctx, t, scope, r, f)
		if err != nil {
			return nil, err
		}
		out = append(out, started)
	}
	return out, nil
}

func (s Service) start(ctx context.Context, t tx.Tx, scope ca.CoherentReadScope, request StartRequest, f *freezer) (Started, error) {
	if t == nil || scope.Validate() != nil || scope.Queryer() != tx.Queryer(t) || !request.Actor.PlayerID.Valid() || request.Actor.ContextID.UUID().IsZero() || !request.Locator.Valid() || request.GenerationRef == "" || len(request.StartFingerprint) != 64 || !request.ResultDeadline.After(scope.ObservedAt) {
		return Started{}, d.ErrInvalid
	}
	if err := s.Store.LockLocatorTx(ctx, t, request.Locator); err != nil {
		return Started{}, err
	}
	existing, found, err := s.Store.FindUnresolvedTx(ctx, t, request.Locator)
	if err != nil {
		return Started{}, err
	}
	if found {
		if existing.StartFingerprint != request.StartFingerprint || existing.ActorPlayer != int64(request.Actor.PlayerID) || existing.GenerationRef != request.GenerationRef {
			return Started{}, d.ErrStartConflict
		}
		return Started{Attempt: existing, Replayed: true}, nil
	}
	if err = s.contentPin(ctx, scope); err != nil {
		return Started{}, err
	}
	snapshot, err := f.freeze(ctx, request.Battle)
	if err != nil {
		return Started{}, err
	}
	raw, hash, err := snapshot.Canonical()
	if err != nil {
		return Started{}, err
	}
	if err = s.Store.InsertSnapshotTx(ctx, t, hash, raw); err != nil {
		return Started{}, err
	}
	id, err := ids.NewUUID()
	if err != nil {
		return Started{}, err
	}
	version, key, err := s.Keys.Current()
	if err != nil {
		return Started{}, fmt.Errorf("%w: %v", d.ErrKeyUnavailable, err)
	}
	// Derive once now so a missing or short key refuses START before commit.
	if _, err = d.EntropyRoot(key, id, hash); err != nil {
		return Started{}, err
	}
	attempt := d.Attempt{ID: id, Locator: request.Locator, ActorPlayer: int64(request.Actor.PlayerID), GameplayContextID: request.Actor.ContextID.UUID().String(), GenerationRef: request.GenerationRef,
		StartFingerprint: request.StartFingerprint, SnapshotHash: hash, EntropyKeyVersion: version, RulesCorpusID: s.Rules.ID(),
		ResolverStatus: d.ResolverPending, State: d.Staged, StartedAt: scope.ObservedAt.UTC(), ResultDeadline: request.ResultDeadline.UTC(), StateVersion: 1}
	if err = attempt.Validate(); err != nil {
		return Started{}, err
	}
	return Started{Attempt: attempt}, s.Store.InsertAttemptTx(ctx, t, attempt)
}

// contentPin requires the operation's pinned revision to be active and built
// from the same source archive as the embedded rules corpus.
func (s Service) contentPin(ctx context.Context, scope ca.CoherentReadScope) error {
	active, err := s.Content.ActiveRevision(ctx, scope.Queryer())
	if err != nil {
		return err
	}
	archive, err := s.Content.SourceArchiveTx(ctx, scope.Queryer(), scope.ContentRevision)
	if err != nil {
		return err
	}
	if active != scope.ContentRevision || archive != s.Rules.SourceArchiveSHA256() {
		return d.ErrContentMismatch
	}
	return nil
}

// StartEvidenceTx is positive evidence for an ambiguous START commit.
func (s Service) StartEvidenceTx(ctx context.Context, q tx.Queryer, locator d.Locator, fingerprint string) (d.Attempt, bool, error) {
	a, found, err := s.Store.FindUnresolvedTx(ctx, q, locator)
	if err != nil || !found || a.StartFingerprint != fingerprint {
		return d.Attempt{}, false, err
	}
	return a, true, nil
}

type Resolved struct {
	Attempt    d.Attempt
	Resolution d.Resolution
	Report     []byte
}

func resolveProfile() tx.Profile {
	return tx.Profile{Name: "combat-resolution", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 20 * time.Second}
}

// Resolve runs after START commits and holds no database lock while the
// worker runs. A replay loads the persisted resolution and never reruns entropy.
func (s Service) Resolve(ctx context.Context, op operation.Context, attemptID ids.UUID) (Resolved, error) {
	attempt, found, err := s.Store.ReadAttemptTx(ctx, s.Fresh, attemptID)
	if err != nil {
		return Resolved{}, err
	}
	if !found {
		return Resolved{}, ErrAttemptNotFound
	}
	if attempt.State != d.Staged && attempt.ResolutionHash == "" {
		return Resolved{Attempt: attempt}, d.ErrNotReady
	}
	if attempt.State != d.Staged {
		return s.loadTx(ctx, s.Fresh, attempt)
	}
	if !attempt.Runnable() {
		return Resolved{Attempt: attempt}, fmt.Errorf("%w: %s", d.ErrResolverPermanent, attempt.ResolverFailure)
	}
	snapshot, err := s.Store.ReadSnapshotTx(ctx, s.Fresh, attempt.SnapshotHash)
	if err != nil {
		return Resolved{}, err
	}
	key, err := s.Keys.Key(attempt.EntropyKeyVersion)
	if err != nil {
		return Resolved{}, fmt.Errorf("%w: %v", d.ErrKeyUnavailable, err)
	}
	root, err := d.EntropyRoot(key, attempt.ID, attempt.SnapshotHash)
	if err != nil {
		return Resolved{}, err
	}
	output, workerErr := s.Worker.Resolve(ctx, snapshot, attempt.SnapshotHash, root)
	if workerErr != nil {
		permanent := errors.Is(workerErr, d.ErrResolverPermanent)
		if !permanent && !errors.Is(workerErr, d.ErrResolverRetryable) {
			workerErr = fmt.Errorf("%w: %v", d.ErrResolverRetryable, workerErr)
		}
		return Resolved{}, errors.Join(workerErr, s.recordFailure(ctx, op, attempt.ID, permanent, workerErr.Error()))
	}
	resolution := d.Resolution{AttemptID: attempt.ID.String(), SnapshotHash: attempt.SnapshotHash, RulesCorpusID: output.CorpusID, Outcome: output.Outcome,
		ReportSHA256: d.ReportHash(output.Report), ReportBytes: int64(len(output.Report)), ReportEncoding: d.ReportEncoding, EntropyDraws: output.EntropyDraws, EntropyReseeds: output.EntropyReseeds}
	if err = resolution.Validate(attempt, output.Report); err != nil {
		return Resolved{}, err
	}
	hash, _, err := resolution.Hash()
	if err != nil {
		return Resolved{}, err
	}
	var out Resolved
	evidence := resolutionEvidence{store: s.Store, reader: s.Fresh, attempt: attempt.ID, hash: hash}
	result, err := s.Runner.Run(ctx, op, resolveProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, evidence, func(ctx context.Context, scope tx.Scope) error {
		current, err := s.Store.LockAttemptTx(ctx, scope.Tx, attempt.ID)
		if err != nil {
			return err
		}
		if current.State != d.Staged {
			if current.ResolutionHash != hash {
				return d.ErrIntegrity
			}
			out = Resolved{Attempt: current, Resolution: resolution, Report: output.Report}
			return nil
		}
		next, err := current.Resolve(hash)
		if err != nil {
			return err
		}
		if err = s.Store.InsertResolutionTx(ctx, scope.Tx, hash, resolution, output.Report); err != nil {
			return err
		}
		out = Resolved{Attempt: next, Resolution: resolution, Report: output.Report}
		return s.Store.SaveAttemptTx(ctx, scope.Tx, next, current.StateVersion)
	})
	if err != nil {
		return Resolved{}, err
	}
	if result.Reconciled {
		return s.loadByID(ctx, attempt.ID)
	}
	return out, nil
}

func (s Service) recordFailure(ctx context.Context, op operation.Context, id ids.UUID, permanent bool, reason string) error {
	if len(reason) > 512 {
		reason = reason[:512]
	}
	_, err := s.Runner.Run(ctx, op, resolveProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		current, err := s.Store.LockAttemptTx(ctx, scope.Tx, id)
		if err != nil || !current.Runnable() {
			return err
		}
		next, err := current.FailResolution(permanent, reason)
		if err != nil {
			return err
		}
		return s.Store.SaveAttemptTx(ctx, scope.Tx, next, current.StateVersion)
	})
	return err
}

func (s Service) loadByID(ctx context.Context, id ids.UUID) (Resolved, error) {
	attempt, found, err := s.Store.ReadAttemptTx(ctx, s.Fresh, id)
	if err != nil {
		return Resolved{}, err
	}
	if !found || attempt.State == d.Staged {
		return Resolved{}, d.ErrNotReady
	}
	return s.loadTx(ctx, s.Fresh, attempt)
}

// resolutionEvidence resolves an ambiguous resolution COMMIT only from the
// positive postcondition: the attempt carries this exact resolution hash.
type resolutionEvidence struct {
	store   Store
	reader  tx.Queryer
	attempt ids.UUID
	hash    string
}

func (e resolutionEvidence) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	a, found, err := e.store.ReadAttemptTx(ctx, e.reader, e.attempt)
	if err != nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	if found && a.ResolutionHash == e.hash {
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: a.ResolutionHash}, nil
	}
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}

type TerminalRequest struct {
	Locator           d.Locator
	GenerationRef     string
	TerminalKind      string
	SemanticReceiptID string
	At                time.Time
}

type Settled struct {
	Resolved
	Replayed bool
}

// TerminalTx runs inside the mode's terminal transaction after the mode roots
// and before I5 Grant locks. It settles once; a repeat with the same semantic
// receipt reconstructs the recorded result without a second settlement.
func (s Service) TerminalTx(ctx context.Context, t tx.Tx, request TerminalRequest) (Settled, error) {
	if t == nil || !request.Locator.Valid() || request.GenerationRef == "" || request.TerminalKind == "" || request.SemanticReceiptID == "" || request.At.IsZero() {
		return Settled{}, d.ErrInvalid
	}
	if err := s.Store.LockLocatorTx(ctx, t, request.Locator); err != nil {
		return Settled{}, err
	}
	open, found, err := s.Store.FindUnresolvedTx(ctx, t, request.Locator)
	if err != nil {
		return Settled{}, err
	}
	if !found {
		done, found, err := s.Store.FindTerminalTx(ctx, t, request.Locator, request.SemanticReceiptID)
		if err != nil {
			return Settled{}, err
		}
		if !found {
			return Settled{}, ErrAttemptNotFound
		}
		if done.TerminalKind != request.TerminalKind || done.ResolutionHash == "" {
			return Settled{}, d.ErrStale
		}
		resolved, err := s.loadTx(ctx, t, done)
		return Settled{Resolved: resolved, Replayed: true}, err
	}
	if open.GenerationRef != request.GenerationRef {
		return Settled{}, d.ErrStale
	}
	if open.State != d.ResolutionReady {
		return Settled{}, d.ErrNotReady
	}
	current, err := s.Store.LockAttemptTx(ctx, t, open.ID)
	if err != nil {
		return Settled{}, err
	}
	next, err := current.Terminate(request.TerminalKind, request.SemanticReceiptID, request.At)
	if err != nil {
		return Settled{}, err
	}
	if err = s.Store.SaveAttemptTx(ctx, t, next, current.StateVersion); err != nil {
		return Settled{}, err
	}
	resolved, err := s.loadTx(ctx, t, next)
	return Settled{Resolved: resolved}, err
}

type Closed struct {
	Attempt  d.Attempt
	Replayed bool
}

// CloseTx ends the locator's unresolved attempt without settlement inside the
// mode's transaction, under the mode's own expiry or supersession rule. Only a
// permanently failed attempt or one past its result deadline is closable.
func (s Service) CloseTx(ctx context.Context, t tx.Tx, request TerminalRequest) (Closed, error) {
	if t == nil || !request.Locator.Valid() || request.GenerationRef == "" || request.TerminalKind == "" || request.SemanticReceiptID == "" || request.At.IsZero() {
		return Closed{}, d.ErrInvalid
	}
	if err := s.Store.LockLocatorTx(ctx, t, request.Locator); err != nil {
		return Closed{}, err
	}
	open, found, err := s.Store.FindUnresolvedTx(ctx, t, request.Locator)
	if err != nil {
		return Closed{}, err
	}
	if !found {
		done, found, err := s.Store.FindTerminalTx(ctx, t, request.Locator, request.SemanticReceiptID)
		if err != nil || !found {
			return Closed{}, errors.Join(err, ErrAttemptNotFound)
		}
		if done.TerminalKind != request.TerminalKind {
			return Closed{}, d.ErrStale
		}
		return Closed{Attempt: done, Replayed: true}, nil
	}
	if open.GenerationRef != request.GenerationRef {
		return Closed{}, d.ErrStale
	}
	current, err := s.Store.LockAttemptTx(ctx, t, open.ID)
	if err != nil {
		return Closed{}, err
	}
	next, err := current.Close(request.TerminalKind, request.SemanticReceiptID, request.At)
	if err != nil {
		return Closed{}, err
	}
	return Closed{Attempt: next}, s.Store.SaveAttemptTx(ctx, t, next, current.StateVersion)
}

func (s Service) loadTx(ctx context.Context, q tx.Queryer, attempt d.Attempt) (Resolved, error) {
	resolution, report, err := s.Store.ReadResolutionTx(ctx, q, attempt.ResolutionHash)
	if err != nil {
		return Resolved{}, err
	}
	if err = resolution.Validate(attempt, report); err != nil {
		return Resolved{}, err
	}
	return Resolved{Attempt: attempt, Resolution: resolution, Report: report}, nil
}

// TerminalEvidenceTx is positive evidence for an ambiguous terminal commit.
func (s Service) TerminalEvidenceTx(ctx context.Context, q tx.Queryer, locator d.Locator, semanticReceiptID string) (d.Attempt, bool, error) {
	return s.Store.FindTerminalTx(ctx, q, locator, semanticReceiptID)
}

// ResultTx reads a terminal attempt's persisted resolution and report for replay.
func (s Service) ResultTx(ctx context.Context, q tx.Queryer, id ids.UUID) (Resolved, error) {
	attempt, found, err := s.Store.ReadAttemptTx(ctx, q, id)
	if err != nil {
		return Resolved{}, err
	}
	if !found {
		return Resolved{}, ErrAttemptNotFound
	}
	if attempt.State != d.Terminal || attempt.ResolutionHash == "" {
		return Resolved{Attempt: attempt}, d.ErrNotReady
	}
	return s.loadTx(ctx, q, attempt)
}

// AttemptTx reads one attempt so its owning mode can decide closure.
func (s Service) AttemptTx(ctx context.Context, q tx.Queryer, id ids.UUID) (d.Attempt, bool, error) {
	return s.Store.ReadAttemptTx(ctx, q, id)
}
