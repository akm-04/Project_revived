package frienddm

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"time"
)

type Service struct {
	Timed       gen.TimedRunner
	Queryer     tx.Queryer
	Store       Store
	Players     playerroot.TxLocker
	Privacy     sr.FriendDMPrivacyReader
	Observer    playerpresentation.TxObserver
	Content     EmoticonContentReader
	Entitlement EmoticonEntitlementReader
	Owner       OwnerFenceReader
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I7A6A_FRIEND_DM", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: 3 * time.Second, TransactionTimeout: 5 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: 2 * time.Second, OperationTimeout: 12 * time.Second}
}
func Retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 10 * time.Millisecond, DefiniteAbortBackoffMax: 100 * time.Millisecond}
}
func (s Service) valid() bool {
	return s.Queryer != nil && s.Store != nil && s.Players != nil && s.Privacy != nil && s.Observer != nil && s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil
}
func ActorValid(a identity.ActorContext) bool {
	server, e := sr.CanonicalServer(a.PlayerID)
	return e == nil && server == a.LogicalServerID && !a.AccountID.UUID().IsZero() && a.AccountUID.Valid() && !a.SessionID.UUID().IsZero() && !a.ContextID.UUID().IsZero() && a.ContextGeneration > 0 && a.SessionLivenessVersion > 0 && a.ContextLivenessVersion > 0
}
func requestDigest(a, recipient identity.PlayerID, message string) string {
	raw, _ := json.Marshal(struct {
		Sender, Recipient identity.PlayerID
		Message           string
	}{a, recipient, message})
	h := sha256.Sum256(raw)
	return hex.EncodeToString(h[:])
}

// LockPlanTx acquires every 315 root by canonical global key (canonical server
// groups preserve that ordering), then the Social-owned 360/361/363 batch.
func (s Service) LockPlanTx(c context.Context, t tx.Tx, m Manifest) (sr.FriendDMPrivacyPlan, error) {
	if m.Validate() != nil {
		return sr.FriendDMPrivacyPlan{}, ErrInvalid
	}
	senders := []identity.PlayerID{}
	all := []identity.PlayerID{m.Recipient}
	for _, d := range m.Rows {
		senders = append(senders, d.Occurrence.Sender)
		all = append(all, d.Occurrence.Sender)
	}
	return s.lockPlayersAndPrivacy(c, t, m.Recipient, all, senders)
}
func (s Service) lockPlayersAndPrivacy(c context.Context, t tx.Tx, recipient identity.PlayerID, all, senders []identity.PlayerID) (sr.FriendDMPrivacyPlan, error) {
	ordered, e := playerroot.CanonicalPlayerIDs(all)
	if e != nil {
		return sr.FriendDMPrivacyPlan{}, e
	}
	for i := 0; i < len(ordered); {
		server, e := sr.CanonicalServer(ordered[i])
		if e != nil {
			return sr.FriendDMPrivacyPlan{}, e
		}
		j := i + 1
		for j < len(ordered) {
			next, e := sr.CanonicalServer(ordered[j])
			if e != nil {
				return sr.FriendDMPrivacyPlan{}, e
			}
			if next != server {
				break
			}
			j++
		}
		roots, e := s.Players.LockPlayerRootsTx(c, t, server, ordered[i:j])
		if e != nil {
			return sr.FriendDMPrivacyPlan{}, e
		}
		if len(roots) != j-i {
			return sr.FriendDMPrivacyPlan{}, ErrInvalid
		}
		for n, r := range roots {
			if r.Validate() != nil || r.PlayerID != ordered[i+n] || r.LogicalServerID != server {
				return sr.FriendDMPrivacyPlan{}, ErrInvalid
			}
		}
		i = j
	}
	return s.Privacy.PrepareFriendDMPrivacyTx(c, t, recipient, senders)
}
func (s Service) ObserveDecisionTx(c context.Context, t tx.Tx, at time.Time, last time.Time) (time.Time, error) {
	now, e := s.Observer.ObserveTx(c, t)
	if e != nil {
		return time.Time{}, e
	}
	if now.IsZero() || now.Before(at) || now.Sub(at) > 2*time.Second || at.Before(last) {
		return time.Time{}, ErrStale
	}
	return at.UTC(), nil
}
func (s Service) Preflight(c context.Context, id identity.PlayerID, op operation.Context) (Manifest, error) {
	if !s.valid() {
		return Manifest{}, ErrUnavailable
	}
	var m Manifest
	result, e := s.Timed.Runner.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, Retry(), nil, func(c context.Context, sc tx.Scope) error {
		var e error
		m, e = s.Store.Snapshot(c, sc.Tx, id, false)
		return e
	})
	if e != nil {
		return Manifest{}, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return Manifest{}, ErrUnavailable
	}
	return m, nil
}
func (s Service) Accept(c context.Context, a identity.ActorContext, recipient identity.PlayerID, msg friendmessage.Message, op operation.Context) (Occurrence, error) {
	if !s.valid() || !ActorValid(a) || recipient == a.PlayerID || op.ID.IsZero() {
		return Occurrence{}, ErrInvalid
	}
	if _, e := sr.CanonicalServer(recipient); e != nil {
		return Occurrence{}, e
	}
	payload, e := msg.Canonical()
	if e != nil {
		return Occurrence{}, e
	}
	digest := requestDigest(a.PlayerID, recipient, payload)
	var out Occurrence
	resolver := acceptResolver{s: s, id: op.ID.String(), digest: digest}
	_, result, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), resolver, func(c context.Context, sc gen.TimedScope) error {
		out = Occurrence{}
		known, ok, e := s.Store.FindOccurrence(c, sc.Tx, op.ID.String())
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
		privacy, e := s.lockPlayersAndPrivacy(c, sc.Tx, recipient, []identity.PlayerID{a.PlayerID, recipient}, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		binding := privacy.BySender[a.PlayerID]
		if !binding.Eligible {
			return ErrUnavailable
		}
		m, e := s.Store.Snapshot(c, sc.Tx, recipient, true)
		if e != nil {
			return e
		}
		revision := ""
		entitlement := int64(0)
		if msg.Kind == 1 {
			if s.Content == nil || s.Entitlement == nil {
				return ErrUnavailable
			}
			revision, e = s.Content.ActiveRevision(c, sc.Tx)
			if e != nil {
				return e
			}
			def, e := s.Content.ResolveEmoticonTx(c, sc.Tx, revision, msg.EmoticonID)
			if e != nil {
				return e
			}
			if def.ID != msg.EmoticonID || def.Revision != revision || def.ItemID < 0 {
				return ErrUnavailable
			}
			entitlement, e = s.Entitlement.PrepareEmoticonEntitlementTx(c, sc.Tx, a.PlayerID, revision, def.ItemID, sc.Operation.DecisionAt())
			if e != nil {
				return e
			}
			if def.ItemID > 0 && entitlement < 1 || def.ItemID == 0 && entitlement != 0 {
				return ErrUnavailable
			}
		}
		at, e := s.ObserveDecisionTx(c, sc.Tx, sc.Operation.DecisionAt(), m.LastDecisionAt)
		if e != nil {
			return e
		}
		seq := m.NextSequence
		if m.Version == 0 {
			seq = 1
		}
		if seq == math.MaxInt64 || m.Version == math.MaxInt64 {
			return ErrUnavailable
		}
		out = Occurrence{ID: op.ID.String(), Digest: digest, Sender: a.PlayerID, Recipient: recipient, Sequence: seq, AcceptedAt: at, Message: payload, FriendshipGeneration: binding.FriendshipGeneration, RecipientBlockVersion: binding.RecipientBlockVersion, ContentRevision: revision, EmoticonID: msg.EmoticonID, EntitlementVersion: entitlement}
		return s.Store.InsertTx(c, sc.Tx, m, out)
	})
	if e != nil {
		return Occurrence{}, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return Occurrence{}, ErrUnavailable
	}
	if result.Reconciled {
		known, ok, e := s.Store.FindOccurrence(c, s.Queryer, op.ID.String())
		if e != nil || !ok || known.Digest != digest {
			return Occurrence{}, ErrUnavailable
		}
		return known, nil
	}
	return out, nil
}

type acceptResolver struct {
	s          Service
	id, digest string
}

func (r acceptResolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	if req.Operation.Operation().ID.String() != r.id {
		return tx.Resolution{}, ErrInvalid
	}
	o, ok, e := r.s.Store.FindOccurrence(c, r.s.Queryer, r.id)
	if e != nil {
		return tx.Resolution{}, e
	}
	if ok && o.Digest == r.digest {
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: o.ID}, nil
	}
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}

// PreparedDrain is opaque; every provider read and lock has completed before
// ApplyDrainTx. No lower lock, inventory check or content lookup occurs there.
type PreparedDrain struct {
	manifest Manifest
	changes  []Change
	receipt  ProjectionReceipt
}

func (p PreparedDrain) Messages() []Projection { return append([]Projection{}, p.receipt.Messages...) }
func (s Service) qualifyPersistedTx(c context.Context, t tx.Tx, d Delivery) error {
	msg, e := friendmessage.Decode(d.Occurrence.Message)
	if e != nil {
		return ErrInvalid
	}
	canonical, e := msg.Canonical()
	if e != nil || canonical != d.Occurrence.Message || msg.EmoticonID != d.Occurrence.EmoticonID {
		return ErrInvalid
	}
	if msg.Kind == 1 {
		if s.Content == nil || len(d.Occurrence.ContentRevision) != 64 {
			return ErrUnavailable
		}
		def, e := s.Content.ResolveEmoticonTx(c, t, d.Occurrence.ContentRevision, msg.EmoticonID)
		if e != nil {
			return e
		}
		if def.ID != msg.EmoticonID || def.Revision != d.Occurrence.ContentRevision {
			return ErrUnavailable
		}
	}
	return nil
}
func terminal(d Delivery, status Status, at time.Time) Change {
	return Change{Before: d, Status: status, ClaimGeneration: d.ClaimGeneration + 1, At: at}
}
func (s Service) PrepareDrainTx(c context.Context, t tx.Tx, planned Manifest, privacy sr.FriendDMPrivacyPlan, op operation.Context, at time.Time) (PreparedDrain, error) {
	m, e := s.Store.Snapshot(c, t, planned.Recipient, true)
	if e != nil {
		return PreparedDrain{}, e
	}
	if m.Digest() != planned.Digest() {
		return PreparedDrain{}, ErrManifestChanged
	}
	if _, e = s.ObserveDecisionTx(c, t, at, m.LastDecisionAt); e != nil {
		return PreparedDrain{}, e
	}
	if s.Owner == nil {
		return PreparedDrain{}, ErrUnavailable
	}
	currentFence := int64(0)
	if s.Owner != nil {
		currentFence, e = s.Owner.ReadOwnerFenceTx(c, t)
		if e != nil {
			return PreparedDrain{}, e
		}
	}
	p := PreparedDrain{manifest: m, receipt: ProjectionReceipt{OperationID: op.ID.String(), Recipient: m.Recipient, ManifestDigest: m.Digest(), ObservedAt: at, Messages: []Projection{}}}
	for _, d := range m.Rows {
		if !d.Eligible(privacy.BySender[d.Occurrence.Sender]) {
			p.changes = append(p.changes, terminal(d, PrivacySuppressed, at))
			continue
		}
		if d.ActiveLease(at) && d.OwnerFence == currentFence {
			continue
		}
		if e = s.qualifyPersistedTx(c, t, d); e != nil {
			return PreparedDrain{}, e
		}
		p.changes = append(p.changes, terminal(d, OfflineProjected, at))
		p.receipt.Messages = append(p.receipt.Messages, Project(d.Occurrence))
	}
	return p, nil
}
func (s Service) ApplyDrainTx(c context.Context, t tx.Tx, p PreparedDrain) error {
	if e := s.Store.ApplyTx(c, t, p.manifest, p.changes, p.receipt.ObservedAt); e != nil {
		return e
	}
	// Empty offline reads have no semantic writes. A receipt is needed exactly
	// when a projection/suppression mutated the pending window.
	if len(p.changes) == 0 {
		return nil
	}
	return s.Store.InsertProjectionTx(c, t, p.receipt)
}

type Claim struct {
	Delivery Delivery
	Fence    int64
}

func (s Service) Claim(c context.Context, id identity.PlayerID, fence int64, op operation.Context) (Claim, bool, error) {
	if !s.valid() || s.Owner == nil || fence < 1 {
		return Claim{}, false, ErrUnavailable
	}
	for attempt := 0; attempt < 3; attempt++ {
		manifest, e := s.Preflight(c, id, op)
		if e != nil {
			return Claim{}, false, e
		}
		var claimed Claim
		ok := false
		_, result, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			ok = false
			claimed = Claim{}
			if e := s.Owner.AssertOwnerFenceTx(c, sc.Tx, fence); e != nil {
				return e
			}
			privacy, e := s.LockPlanTx(c, sc.Tx, manifest)
			if e != nil {
				return e
			}
			m, e := s.Store.Snapshot(c, sc.Tx, id, true)
			if e != nil {
				return e
			}
			if m.Digest() != manifest.Digest() {
				return ErrManifestChanged
			}
			at, e := s.ObserveDecisionTx(c, sc.Tx, sc.Operation.DecisionAt(), m.LastDecisionAt)
			if e != nil {
				return e
			}
			changes := []Change{}
			for _, d := range m.Rows {
				if !d.Eligible(privacy.BySender[d.Occurrence.Sender]) {
					changes = append(changes, terminal(d, PrivacySuppressed, at))
					continue
				}
				if d.ActiveLease(at) && d.OwnerFence == fence {
					continue
				}
				if ok {
					if d.ExpiresAt != nil {
						changes = append(changes, terminal(d, Pending, at))
					}
					continue
				}
				if e = s.qualifyPersistedTx(c, sc.Tx, d); e != nil {
					return e
				}
				expires := at.Add(LeaseDuration)
				change := Change{Before: d, Status: Pending, ClaimGeneration: d.ClaimGeneration + 1, OwnerFence: fence, ExpiresAt: &expires, At: at}
				changes = append(changes, change)
				d.Version++
				d.ClaimGeneration++
				d.OwnerFence = fence
				d.ExpiresAt = &expires
				d.UpdatedAt = at
				claimed = Claim{Delivery: d, Fence: fence}
				ok = true
			}
			return s.Store.ApplyTx(c, sc.Tx, m, changes, at)
		})
		if errors.Is(e, ErrManifestChanged) {
			continue
		}
		if e != nil {
			return Claim{}, false, e
		}
		if result.Outcome != tx.DefiniteCommit {
			return Claim{}, false, ErrUnavailable
		}
		return claimed, ok, nil
	}
	return Claim{}, false, ErrManifestChanged
}

// CheckClaim commits a fresh canonical privacy/fence/expiry observation before
// bytes are enqueued. The later network attempt is outside all database locks.
func (s Service) CheckClaim(c context.Context, claim Claim, op operation.Context) (bool, error) {
	return s.finish(c, claim, op, false, false)
}
func (s Service) Complete(c context.Context, claim Claim, wrote bool, op operation.Context) (bool, error) {
	return s.finish(c, claim, op, true, wrote)
}
func (s Service) finish(c context.Context, claim Claim, op operation.Context, complete, wrote bool) (bool, error) {
	if !s.valid() || s.Owner == nil || claim.Delivery.Validate() != nil || claim.Fence != claim.Delivery.OwnerFence {
		return false, ErrInvalid
	}
	original := claim.Delivery
	allowed := false
	_, result, e := s.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, Retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		allowed = false
		if e := s.Owner.AssertOwnerFenceTx(c, sc.Tx, claim.Fence); e != nil {
			return e
		}
		privacy, e := s.lockPlayersAndPrivacy(c, sc.Tx, original.Occurrence.Recipient, []identity.PlayerID{original.Occurrence.Recipient, original.Occurrence.Sender}, []identity.PlayerID{original.Occurrence.Sender})
		if e != nil {
			return e
		}
		m, e := s.Store.Snapshot(c, sc.Tx, original.Occurrence.Recipient, true)
		if e != nil {
			return e
		}
		at, e := s.ObserveDecisionTx(c, sc.Tx, sc.Operation.DecisionAt(), m.LastDecisionAt)
		if e != nil {
			return e
		}
		for _, d := range m.Rows {
			if d.Occurrence.ID != original.Occurrence.ID {
				continue
			}
			if d.ClaimGeneration != original.ClaimGeneration || d.OwnerFence != claim.Fence {
				return nil
			}
			if !d.Eligible(privacy.BySender[d.Occurrence.Sender]) {
				return s.Store.ApplyTx(c, sc.Tx, m, []Change{terminal(d, PrivacySuppressed, at)}, at)
			}
			if !d.ActiveLease(at) {
				return s.Store.ApplyTx(c, sc.Tx, m, []Change{terminal(d, Pending, at)}, at)
			}
			if e = s.qualifyPersistedTx(c, sc.Tx, d); e != nil {
				return e
			}
			allowed = true
			if complete {
				status := Pending
				if wrote {
					status = TransportWriteRecorded
				}
				return s.Store.ApplyTx(c, sc.Tx, m, []Change{terminal(d, status, at)}, at)
			}
			return nil
		}
		return nil
	})
	if e != nil {
		return false, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return false, ErrUnavailable
	}
	return allowed, nil
}
