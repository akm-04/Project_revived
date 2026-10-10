package guildinvitetarget

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	appinvite "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

func invalidationIdentity(m gi.Marker, v gi.Issue) receipt.Identity {
	key, _ := v.Tuple.SourceKey()
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(v.Tuple.Recipient), 10), Domain: "social-inbox", Operation: "guild_invite_invalidate", SemanticKey: m.Operation.ID.String() + ":" + key}
}

func invalidationFingerprint(m gi.Marker, v gi.Issue) ([32]byte, error) {
	mfp, e := m.Fingerprint()
	if e != nil {
		return [32]byte{}, e
	}
	sfp, e := v.Fingerprint()
	if e != nil {
		return [32]byte{}, e
	}
	raw, e := json.Marshal(struct{ Marker, Source [32]byte }{mfp, sfp})
	if e != nil {
		return [32]byte{}, e
	}
	return sha256.Sum256(raw), nil
}

func (s Service) completeInvalidation(c context.Context, q tx.Queryer, m gi.Marker, v gi.Issue, root playerroot.RecipientRoot) (gi.InvalidationProof, bool, error) {
	var empty gi.InvalidationProof
	applies, e := m.AppliesTo(v)
	if e != nil || !applies {
		return empty, false, gi.ErrEvidence
	}
	// This also rejects a partial target restore beside a retained Materialized
	// receipt, even when cleanup would otherwise see an absent/inactive Notice.
	if _, _, e = s.completeMaterialization(c, q, v, root); e != nil {
		return empty, false, e
	}
	p, hasP, e := s.Store.ReadInviteInvalidationTx(c, q, m.Operation.ID, v.Operation.ID)
	if e != nil {
		return p, false, e
	}
	rr, hasR, e := s.Receipts.FindTx(c, q, invalidationIdentity(m, v))
	if e != nil {
		return p, false, e
	}
	if !hasP && !hasR {
		return p, false, nil
	}
	if !hasP || !hasR || p.Matches(m, v) != nil {
		return p, false, gi.ErrEvidence
	}
	fp, e := invalidationFingerprint(m, v)
	if e != nil {
		return p, false, e
	}
	decoded, de := gi.DecodeInvalidationProof(rr.ResultPayload)
	if de != nil || decoded != p || rr.Validate() != nil || rr.RetainUntil != nil || rr.ID != p.ReceiptID || rr.Identity != invalidationIdentity(m, v) || rr.OperationClass != "I7A8B_GUILD_INVALIDATION" || rr.ResultSchema != "gxb.guild-invite.invalidate.v1" || rr.RequestFingerprint != fp || rr.PolicyVersion != m.PolicyID || rr.OperationStartedAt.UnixMicro() != m.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(m.Operation.Policies) || rr.ActorAccountUID != m.ActorAccountUID || rr.ContextID != m.Core.ContextID {
		return p, false, gi.ErrEvidence
	}
	key, _ := v.Tuple.SourceKey()
	n, hasN, e := s.Store.ReadInviteNoticeSourceTx(c, q, v.Tuple.Recipient, socialinbox.SourceKey{Kind: gi.SourceKind, Key: key})
	if e != nil {
		return p, false, e
	}
	if p.NoticeID == 0 {
		if hasN {
			return p, false, gi.ErrEvidence
		}
	} else if !hasN {
		if !root.NonReusedAbsent {
			return p, false, gi.ErrEvidence
		}
	} else {
		if root.NonReusedAbsent || socialinbox.MatchInvite(n, v) != nil || int64(n.NoticeID) != p.NoticeID || n.Active || n.StateVersion != p.NoticeStateVersion || p.Consumed && (n.DismissedAt == nil || n.DismissedAt.UnixMicro() != p.DecisionAt.UnixMicro()) {
			return p, false, gi.ErrEvidence
		}
	}
	if !root.NonReusedAbsent && p.RootVersion > 0 {
		r, ok, e := s.Roots.ReadTx(c, q, v.Tuple.Recipient)
		if e != nil {
			return p, false, e
		}
		if !ok || r.StateVersion < p.RootVersion {
			return p, false, gi.ErrEvidence
		}
	}
	return p, true, nil
}

func (s Service) ReadInviteInvalidationProofTx(c context.Context, q tx.Queryer, marker, source ids.UUID) (gi.InvalidationProof, bool, error) {
	if !s.valid() {
		return gi.InvalidationProof{}, false, gi.ErrEvidence
	}
	m, e := s.Sources.ReadMarkerEvidenceTx(c, q, marker)
	if e != nil {
		return gi.InvalidationProof{}, false, e
	}
	v, e := s.Sources.ReadIssueEvidenceTx(c, q, source)
	if e != nil {
		return gi.InvalidationProof{}, false, e
	}
	r, e := s.Players.ReadBoundRecipientTx(c, q, v.Server, v.Tuple.Recipient)
	if e != nil {
		return gi.InvalidationProof{}, false, e
	}
	return s.completeInvalidation(c, q, m, v, r)
}

func (s Service) readInvalidation(c context.Context, marker, source ids.UUID) (gi.InvalidationProof, bool, error) {
	var out gi.InvalidationProof
	var found bool
	_, e := s.Reads.Run(c, operation.Context{}, InviteTargetProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, found, e = s.ReadInviteInvalidationProofTx(c, sc.Tx, marker, source)
		return e
	})
	return out, found, e
}

type invalidationResolver struct {
	Service        Service
	Marker, Source ids.UUID
}

func (r invalidationResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	p, ok, e := r.Service.readInvalidation(c, r.Marker, r.Source)
	if e != nil {
		return tx.Resolution{}, e
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: p}, nil
}

func (s Service) Invalidate(c context.Context, marker, source ids.UUID) (gi.InvalidationProof, error) {
	if !s.valid() || marker.IsZero() || source.IsZero() {
		return gi.InvalidationProof{}, gi.ErrEvidence
	}
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	var initial gi.Marker
	_, e := s.Reads.Run(c, operation.Context{}, InviteTargetProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		initial, e = s.Sources.ReadMarkerEvidenceTx(c, sc.Tx, marker)
		return e
	})
	if e != nil {
		return gi.InvalidationProof{}, e
	}
	var out gi.InvalidationProof
	first := false
	_, result, e := s.Timed.Run(c, initial.Operation, InviteTargetProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, invalidationResolver{Service: s, Marker: marker, Source: source}, func(c context.Context, sc gen.TimedScope) error {
		first = false
		m, e := s.Sources.ReadMarkerEvidenceTx(c, sc.Tx, marker)
		if e != nil {
			return e
		}
		v, e := s.Sources.ReadIssueEvidenceTx(c, sc.Tx, source)
		if e != nil {
			return e
		}
		root, e := s.Players.LockBoundRecipientTx(c, sc.Tx, v.Server, v.Tuple.Recipient)
		if e != nil {
			return e
		}
		prior, found, e := s.completeInvalidation(c, sc.Tx, m, v, root)
		if e != nil {
			return e
		}
		if found {
			out = prior
			return nil
		}
		at := sc.Operation.DecisionAt()
		if at.Before(m.DecisionAt) || at.Before(v.DecisionAt) {
			return gi.ErrEvidence
		}
		mfp, _ := m.Fingerprint()
		sfp, _ := v.Fingerprint()
		sourceKey, _ := v.Tuple.SourceKey()
		out = gi.InvalidationProof{MarkerID: marker, SourceID: source, SourceSerial: v.Serial, SourceKey: sourceKey, Recipient: v.Tuple.Recipient, MarkerFingerprint: mfp, SourceFingerprint: sfp, DecisionAt: at}
		if !root.NonReusedAbsent {
			plan, e := s.Roots.PrepareTx(c, sc.Tx, root.Root)
			if e != nil {
				return e
			}
			current, hasRoot := plan.Existing()
			if hasRoot {
				if at.Before(current.UpdatedAt) {
					return gi.ErrEvidence
				}
				out.RootVersion = current.StateVersion
			}
			key, _ := v.Tuple.SourceKey()
			n, hasN, e := s.Store.LockNoticeSourceTx(c, sc.Tx, v.Tuple.Recipient, socialinbox.SourceKey{Kind: gi.SourceKind, Key: key})
			if e != nil {
				return e
			}
			if hasN {
				if !hasRoot || socialinbox.MatchInvite(n, v) != nil {
					return gi.ErrEvidence
				}
				out.NoticeID = int64(n.NoticeID)
				out.NoticeStateVersion = n.StateVersion
				if n.Active {
					if socialinbox.PreflightConsumption(n, at) != nil {
						return gi.ErrEvidence
					}
					changed, e := s.Roots.ApplyChangeTx(c, sc.Tx, plan, at)
					if e != nil {
						return e
					}
					if e = s.Store.ConsumeInviteNoticeTx(c, sc.Tx, n, at); e != nil {
						return e
					}
					out.Consumed = true
					out.NoticeStateVersion++
					out.RootVersion = changed.StateVersion
				}
			}
		}
		fp, e := invalidationFingerprint(m, v)
		if e != nil {
			return e
		}
		rr, e := receipt.New(m.Operation, invalidationIdentity(m, v), "I7A8B_GUILD_INVALIDATION", "gxb.guild-invite.invalidate.v1", json.RawMessage(`{}`), fp)
		if e != nil {
			return e
		}
		out.ReceiptID = rr.ID
		if out.Matches(m, v) != nil {
			return gi.ErrEvidence
		}
		rr.ResultPayload, e = json.Marshal(out)
		if e != nil {
			return e
		}
		rr.PolicyVersion = m.PolicyID
		rr.ActorAccountUID = m.ActorAccountUID
		rr.ContextID = m.Core.ContextID
		stored, e := s.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !stored.Inserted || stored.Receipt.ID != out.ReceiptID {
			return gi.ErrEvidence
		}
		if e = s.Store.InsertInviteInvalidationTx(c, sc.Tx, out); e != nil {
			return e
		}
		first = out.Consumed
		return nil
	})
	if e != nil {
		return gi.InvalidationProof{}, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return gi.InvalidationProof{}, gi.ErrEvidence
	}
	if result.Reconciled {
		p, ok := result.Evidence.(gi.InvalidationProof)
		if !ok || p.MarkerID != marker || p.SourceID != source || p.Validate() != nil {
			return gi.InvalidationProof{}, gi.ErrEvidence
		}
		out = p
	}
	if first && !result.Reconciled && s.Emitter != nil {
		s.Emitter.Emit(c, []socialreloadref.ReloadReference{{Recipient: out.Recipient, Actor: initial.Actor, RootVersion: out.RootVersion, Purpose: socialreloadref.ReloadInviteInvalidated, SourceID: source, MarkerID: marker}})
	}
	return out, nil
}

var _ appinvite.Target = Service{}

func (s Service) ValidateCoveredInviteInvalidationsTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64, expected gi.SetWitness) error {
	if !s.valid() || expected.Validate() != nil {
		return gi.ErrEvidence
	}
	got, missing, e := s.Store.ReadInviteInvalidationSetTx(c, q, m, cursor)
	if e != nil {
		return e
	}
	if got != expected {
		return gi.ErrEvidence
	}
	for _, pid := range missing {
		root, e := s.Players.ReadBoundRecipientTx(c, q, m.Server, pid)
		if e != nil {
			return e
		}
		if !root.NonReusedAbsent {
			return gi.ErrEvidence
		}
	}
	return nil
}

var _ appinvite.ProgressTarget = Service{}

func (s Service) CoveredTargetPayloadsTx(c context.Context, q tx.Queryer, m gi.Marker, cursor int64) (gi.OwnerPayloadSet, error) {
	if !s.valid() {
		return gi.OwnerPayloadSet{}, gi.ErrEvidence
	}
	return s.Store.ReadCoveredInvitePayloadsTx(c, q, m, cursor)
}
