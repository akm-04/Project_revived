package guildinvitetarget

import (
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	appinvite "gxb.local/backend/v2/internal/application/guildinvite"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

type InvitePlayers interface {
	playerroot.RecipientLocker
	playerroot.RecipientReader
}

// Service accepts canonical immutable UUID references only.
// It commits SocialInbox independently; Guild ACK is a separate command.
type ReloadEmitter interface {
	Emit(context.Context, []socialreloadref.ReloadReference)
}
type Service struct {
	Emitter  ReloadEmitter
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Sources  appinvite.ImmutableReader
	Players  InvitePlayers
	Roots    socialrelation.RootService
	Store    socialinbox.GuildInviteStore
	Receipts receipt.Store
}

func InviteTargetProfile() tx.Profile {
	return tx.Profile{Name: "I7A8B_SOCIAL_INVITE_TARGET", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) valid() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Reads.DB != nil && s.Sources != nil && s.Players != nil && s.Roots.Store != nil && s.Store != nil && s.Receipts != nil
}

func inviteTargetIdentity(v gi.Issue) receipt.Identity {
	key, _ := v.Tuple.SourceKey()
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(v.Tuple.Recipient), 10), Domain: "social-inbox", Operation: "guild_invite_materialize", SemanticKey: key}
}

func (s Service) completeMaterialization(c context.Context, q tx.Queryer, v gi.Issue, root playerroot.RecipientRoot) (gi.TargetProof, bool, error) {
	delivery, e := s.Sources.ReadIssueDeliveryEvidenceTx(c, q, v.Operation.ID)
	if e != nil {
		return gi.TargetProof{}, false, e
	}
	p, hasP, e := s.Store.ReadInviteMaterializationTx(c, q, v.Operation.ID)
	if e != nil {
		return p, false, e
	}
	rr, hasR, e := s.Receipts.FindTx(c, q, inviteTargetIdentity(v))
	if e != nil {
		return p, false, e
	}
	key, _ := v.Tuple.SourceKey()
	n, hasN, e := s.Store.ReadInviteNoticeSourceTx(c, q, v.Tuple.Recipient, socialinbox.SourceKey{Kind: gi.SourceKind, Key: key})
	if e != nil {
		return p, false, e
	}
	if !hasP && !hasR {
		if hasN || delivery.State != gi.Pending {
			return p, false, gi.ErrEvidence
		}
		return p, false, nil
	}
	if !hasP || !hasR || p.Matches(v) != nil || delivery.Matches(p) != nil {
		return p, false, gi.ErrEvidence
	}
	fp, _ := v.Fingerprint()
	decoded, de := gi.DecodeTargetProof(rr.ResultPayload)
	if de != nil || decoded != p || rr.Validate() != nil || rr.RetainUntil != nil || rr.ID != p.ReceiptID || rr.Identity != inviteTargetIdentity(v) || rr.OperationClass != "I7A8B_GUILD_NOTICE" || rr.ResultSchema != "gxb.guild-invite.materialize.v1" || rr.RequestFingerprint != fp || rr.PolicyVersion != v.PolicyID || rr.OperationStartedAt.UnixMicro() != v.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(v.Operation.Policies) || rr.ActorAccountUID != v.ActorAccountUID || rr.ContextID != v.Core.ContextID {
		return p, false, gi.ErrEvidence
	}
	switch p.State {
	case gi.Materialized:
		if hasN {
			if root.NonReusedAbsent || socialinbox.MatchInvite(n, v) != nil || int64(n.NoticeID) != p.NoticeID || n.CreatedAt.UnixMicro() != p.DecisionAt.UnixMicro() {
				return p, false, gi.ErrEvidence
			}
		} else if !root.NonReusedAbsent {
			return p, false, gi.ErrEvidence
		}
	case gi.Suppressed:
		if hasN {
			return p, false, gi.ErrEvidence
		}
	case gi.RecipientGone:
		if !root.NonReusedAbsent || hasN {
			return p, false, gi.ErrEvidence
		}
	default:
		return p, false, gi.ErrEvidence
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

func (s Service) ReadInviteTargetProofTx(c context.Context, q tx.Queryer, id ids.UUID) (gi.TargetProof, bool, error) {
	if !s.valid() {
		return gi.TargetProof{}, false, gi.ErrEvidence
	}
	v, e := s.Sources.ReadIssueEvidenceTx(c, q, id)
	if e != nil {
		return gi.TargetProof{}, false, e
	}
	r, e := s.Players.ReadBoundRecipientTx(c, q, v.Server, v.Tuple.Recipient)
	if e != nil {
		return gi.TargetProof{}, false, e
	}
	return s.completeMaterialization(c, q, v, r)
}

func (s Service) discover(c context.Context, id ids.UUID) (gi.Issue, error) {
	var v gi.Issue
	_, e := s.Reads.Run(c, operation.Context{}, InviteTargetProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		v, e = s.Sources.ReadIssueEvidenceTx(c, sc.Tx, id)
		return e
	})
	return v, e
}

func (s Service) readProof(c context.Context, id ids.UUID) (gi.TargetProof, bool, error) {
	var out gi.TargetProof
	var found bool
	_, e := s.Reads.Run(c, operation.Context{}, InviteTargetProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, found, e = s.ReadInviteTargetProofTx(c, sc.Tx, id)
		return e
	})
	return out, found, e
}

type inviteMaterializeResolver struct {
	Service Service
	ID      ids.UUID
}

func (r inviteMaterializeResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	p, ok, e := r.Service.readProof(c, r.ID)
	if e != nil {
		return tx.Resolution{}, e
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: p}, nil
}

func (s Service) Materialize(c context.Context, id ids.UUID) (gi.TargetProof, error) {
	if !s.valid() || id.IsZero() {
		return gi.TargetProof{}, gi.ErrEvidence
	}
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	initial, e := s.discover(c, id)
	if e != nil {
		return gi.TargetProof{}, e
	}
	var out gi.TargetProof
	first := false
	_, result, e := s.Timed.Run(c, initial.Operation, InviteTargetProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, inviteMaterializeResolver{Service: s, ID: id}, func(c context.Context, sc gen.TimedScope) error {
		first = false
		v, e := s.Sources.ReadIssueEvidenceTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		root, e := s.Players.LockBoundRecipientTx(c, sc.Tx, v.Server, v.Tuple.Recipient)
		if e != nil {
			return e
		}
		prior, found, e := s.completeMaterialization(c, sc.Tx, v, root)
		if e != nil {
			return e
		}
		if found {
			out = prior
			return nil
		}
		at := sc.Operation.DecisionAt()
		if at.Before(v.DecisionAt) {
			return gi.ErrEvidence
		}
		fp, _ := v.Fingerprint()
		out = gi.TargetProof{SourceID: id, Recipient: v.Tuple.Recipient, SourceFingerprint: fp, State: gi.RecipientGone, DecisionAt: at}
		if !root.NonReusedAbsent {
			snapshot, e := s.Sources.ReadInviteSnapshotTx(c, sc.Tx, id)
			if e != nil {
				return e
			}
			eligible, e := snapshot.Eligible(at)
			if e != nil {
				return e
			}
			plan, e := s.Roots.PrepareTx(c, sc.Tx, root.Root)
			if e != nil {
				return e
			}
			key, _ := v.Tuple.SourceKey()
			_, exists, e := s.Store.LockNoticeSourceTx(c, sc.Tx, v.Tuple.Recipient, socialinbox.SourceKey{Kind: gi.SourceKind, Key: key})
			if e != nil {
				return e
			}
			if exists {
				return gi.ErrEvidence
			}
			out.State = gi.Suppressed
			if current, ok := plan.Existing(); ok {
				if at.Before(current.UpdatedAt) {
					return gi.ErrEvidence
				}
				out.RootVersion = current.StateVersion
			}
			if eligible {
				changed, e := s.Roots.ApplyChangeTx(c, sc.Tx, plan, at)
				if e != nil {
					return e
				}
				n, e := s.Store.InsertInviteNoticeTx(c, sc.Tx, v, at)
				if e != nil {
					return e
				}
				out.State = gi.Materialized
				out.NoticeID = int64(n.NoticeID)
				out.RootVersion = changed.StateVersion
			}
		}
		rr, e := receipt.New(v.Operation, inviteTargetIdentity(v), "I7A8B_GUILD_NOTICE", "gxb.guild-invite.materialize.v1", json.RawMessage(`{}`), fp)
		if e != nil {
			return e
		}
		out.ReceiptID = rr.ID
		if out.Matches(v) != nil {
			return gi.ErrEvidence
		}
		rr.ResultPayload, e = json.Marshal(out)
		if e != nil {
			return e
		}
		rr.PolicyVersion = v.PolicyID
		rr.ActorAccountUID = v.ActorAccountUID
		rr.ContextID = v.Core.ContextID
		stored, e := s.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !stored.Inserted || stored.Receipt.ID != out.ReceiptID {
			return gi.ErrEvidence
		}
		if e = s.Store.InsertInviteMaterializationTx(c, sc.Tx, out); e != nil {
			return e
		}
		first = out.State == gi.Materialized
		return nil
	})
	if e != nil {
		return gi.TargetProof{}, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return gi.TargetProof{}, gi.ErrEvidence
	}
	if result.Reconciled {
		p, ok := result.Evidence.(gi.TargetProof)
		if !ok || p.Matches(initial) != nil {
			return gi.TargetProof{}, gi.ErrEvidence
		}
		out = p
	}
	if first && !result.Reconciled && s.Emitter != nil {
		s.Emitter.Emit(c, []socialreloadref.ReloadReference{{Recipient: out.Recipient, Actor: initial.Inviter, RootVersion: out.RootVersion, Purpose: socialreloadref.ReloadInviteMaterialized, SourceID: id}})
	}
	return out, nil
}
