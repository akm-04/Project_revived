package socialgift

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"sort"
	"time"
)

type Service struct {
	Timed          gen.TimedRunner
	Reads          tx.Runner
	Store          Store
	Content        ContentReader
	Players        playerroot.TxLocker
	Relations      RelationOwner
	Privacy        socialrelation.FriendDMPrivacyReader
	Inbox          socialinbox.GiftService
	NoticeEvidence NoticeEvidence
	Grants         GrantOwner
	Admission      ActorAdmission
	Fence          ActorFence
}

func Profile() tx.Profile {
	p := socialrelation.DefaultCommandProfile()
	p.Name = "I7A7A_SOCIAL_GIFT"
	return p
}
func (s Service) validate(actor identity.ActorContext) error {
	server, e := socialrelation.CanonicalServer(actor.PlayerID)
	if e != nil || server != actor.LogicalServerID || actor.AccountID.UUID().IsZero() || !actor.AccountUID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || actor.ContextGeneration < 1 || actor.SessionLivenessVersion < 1 || actor.ContextLivenessVersion < 1 || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Store == nil || s.Content == nil || s.Players == nil || s.Relations == nil || s.Privacy == nil || s.Inbox.Store == nil || s.NoticeEvidence == nil || s.Grants == nil || s.Admission == nil || s.Fence == nil {
		return ErrInvalid
	}
	return nil
}
func (s Service) read(c context.Context, op operation.Context, body func(context.Context, tx.Queryer) error) error {
	_, e := s.Reads.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error { return body(c, sc.Tx) })
	return e
}
func bind(op operation.Context, c Content) (operation.Context, error) {
	refs := op.Policies.Refs()
	for _, r := range []policy.Ref{{Name: "content", Version: c.Revision}, {Name: "social-gift-day", Version: DayPolicy}, {Name: "social-gift-claim", Version: ClaimPolicy}} {
		v, ok := op.Policies.Get(r.Name)
		if ok {
			if v != r.Version {
				return operation.Context{}, ErrConflict
			}
		} else {
			refs = append(refs, r)
		}
	}
	p, e := policy.NewSet(refs...)
	if e != nil {
		return operation.Context{}, e
	}
	op.Policies = p
	return op, nil
}
func (s Service) admit(c context.Context, op operation.Context) (Content, operation.Context, error) {
	var out Content
	e := s.read(c, op, func(c context.Context, q tx.Queryer) error {
		rev, ok := op.Policies.Get("content")
		if !ok {
			var e error
			rev, e = s.Content.ActiveRevision(c, q)
			if e != nil {
				return e
			}
		}
		var e error
		out, e = s.Content.ReadGiftContent(c, q, rev)
		return e
	})
	if e != nil {
		return out, op, e
	}
	if e = out.Validate(); e != nil {
		return out, op, e
	}
	bound, e := bind(op, out)
	return out, bound, e
}
func (s Service) players(c context.Context, t tx.Tx, pids []identity.PlayerID) error {
	ids, e := playerroot.CanonicalPlayerIDs(pids)
	if e != nil {
		return e
	} // Numeric player order is canonical across logical server namespaces.
	for _, pid := range ids {
		server, e := socialrelation.CanonicalServer(pid)
		if e != nil {
			return e
		}
		roots, e := s.Players.LockPlayerRootsTx(c, t, server, []identity.PlayerID{pid})
		if e != nil {
			return e
		}
		if len(roots) != 1 || roots[0].PlayerID != pid || roots[0].LogicalServerID != server || roots[0].Validate() != nil {
			return ErrConflict
		}
	}
	return nil
}
func (s Service) root(c context.Context, t tx.Tx, pid identity.PlayerID) (socialrelation.Root, error) {
	r, ok, e := s.Relations.LockRootTx(c, t, pid)
	if e != nil {
		return r, e
	}
	if !ok {
		return socialrelation.Root{}, nil
	}
	if r.PlayerID != pid || r.Validate() != nil {
		return r, ErrConflict
	}
	return r, nil
}
func preflightRoot(r socialrelation.Root, at time.Time) error {
	if r.StateVersion == math.MaxInt64 || at.Before(r.UpdatedAt) || at.Before(r.CreatedAt) {
		return ErrClock
	}
	return nil
}
func (s Service) epoch(c context.Context, t tx.Tx, pid identity.PlayerID, day string, op operation.Context, at time.Time) (Epoch, bool, error) {
	e, ok, last, have, err := s.Store.LockEpoch(c, t, pid, day)
	if err != nil {
		return e, ok, err
	}
	if have && (last.Day > day || at.Before(last.UpdatedAt) || last.Version == math.MaxInt64) {
		return e, ok, ErrClock
	}
	if ok {
		if e.Version == math.MaxInt64 || at.Before(e.UpdatedAt) {
			return e, ok, ErrClock
		}
		return e, true, nil
	}
	e, err = NewEpoch(pid, day, op, at)
	return e, false, err
}
func (s Service) sendProof(c context.Context, q tx.Queryer, actor identity.ActorContext, recipient identity.PlayerID, fp string, op operation.Context) (Result, bool, error) {
	v, ok, e := s.Store.ReadSend(c, q, op.ID)
	if e != nil || !ok {
		return Result{}, ok, e
	}
	if v.Sender != actor.PlayerID || v.Recipient != recipient || v.RequestFingerprint != fp || !v.StartedAt.Equal(op.StartedAt) {
		return Result{}, false, ErrConflict
	}
	issued, e := s.Content.ReadGiftContent(c, q, v.RewardRevision)
	if e != nil || !issued.Compatible(v) {
		return Result{}, false, ErrContent
	}
	epoch, exists, e := s.Store.ReadEpoch(c, q, v.Sender, v.SenderDay)
	if e != nil || !exists || epoch.Generation != v.SenderGeneration {
		return Result{}, false, ErrConflict
	}
	recipientEpoch, exists, e := s.Store.ReadEpoch(c, q, v.Recipient, v.SenderDay)
	if e != nil || !exists || recipientEpoch.Validate() != nil {
		return Result{}, false, ErrConflict
	}
	n, exists, e := s.NoticeEvidence.ReadNoticeEvidenceTx(c, q, v.Recipient, v.NoticeID)
	if e != nil || !exists || socialinbox.MatchGift(n, v.Descriptor()) != nil || n.Active != v.ClaimOperation.IsZero() {
		return Result{}, false, ErrConflict
	}
	return Result{NoticeIDs: []socialinbox.NoticeID{v.NoticeID}, TransferIDs: []string{v.ID.String()}, Revision: v.RewardRevision}, true, nil
}
func (s Service) claimProof(c context.Context, q tx.Queryer, actor identity.ActorContext, fp string, op operation.Context) (Result, bool, error) {
	v, ok, e := s.Store.ReadClaim(c, q, op.ID)
	if e != nil || !ok {
		return Result{}, ok, e
	}
	if v.Recipient != actor.PlayerID || v.Fingerprint != fp || !v.StartedAt.Equal(op.StartedAt) {
		return Result{}, false, ErrConflict
	}
	return s.completeClaim(c, q, v)
}
func (s Service) completeClaim(c context.Context, q tx.Queryer, v ClaimOperation) (Result, bool, error) {
	settlement, e := s.Content.ReadGiftContent(c, q, v.Revision)
	if e != nil {
		return Result{}, false, e
	}
	ts, e := s.Store.ClaimTransfers(c, q, v.ID)
	if e != nil {
		return Result{}, false, e
	}
	if int64(len(ts))*5 != v.Result.Amount || len(ts) != len(v.Result.TransferIDs) || len(ts) > 10 {
		return Result{}, false, ErrConflict
	}
	wanted := map[string]bool{}
	for _, id := range v.Result.TransferIDs {
		if wanted[id] {
			return Result{}, false, ErrConflict
		}
		wanted[id] = true
	}
	gifts := map[socialinbox.NoticeID]Transfer{}
	for _, t := range ts {
		if !wanted[t.ID.String()] || t.Recipient != v.Recipient || t.ClaimOperation != v.ID || t.ClaimDay != v.Day || t.ClaimGeneration != v.Generation || t.GrantReceiptID != v.Result.GrantReceiptID || t.ClaimContentRevision != v.Revision || t.ClaimedAt == nil || !t.ClaimedAt.Equal(v.DecisionAt) {
			return Result{}, false, ErrConflict
		}
		issued, e := s.Content.ReadGiftContent(c, q, t.RewardRevision)
		if e != nil || !issued.Compatible(t) || !settlement.Compatible(t) {
			return Result{}, false, ErrContent
		}
		gifts[t.NoticeID] = t
		senderEpoch, ok, e := s.Store.ReadEpoch(c, q, t.Sender, t.SenderDay)
		if e != nil || !ok || senderEpoch.Generation != t.SenderGeneration {
			return Result{}, false, ErrConflict
		}
	}
	if len(ts) > 0 {
		epoch, ok, e := s.Store.ReadEpoch(c, q, v.Recipient, v.Day)
		if e != nil || !ok || epoch.Generation != v.Generation {
			return Result{}, false, ErrConflict
		}
		r, ok, e := s.Grants.ReadGrantEvidenceTx(c, q, GrantPlan(v.Recipient, v.ID, v.Result.Amount))
		if e != nil || !ok || r.ReceiptID != v.Result.GrantReceiptID || len(r.Awards) != 1 || r.Awards[0].ResourceKey != "friendship_coin" || r.Awards[0].TableID != 0 || r.Awards[0].ItemNum != v.Result.Amount || r.Effects == nil || r.Effects.ContentRevision != v.Revision || r.Effects.OperationID != v.ID.String() || !r.Effects.OperationStartedAt.Equal(v.StartedAt) {
			return Result{}, false, ErrConflict
		}
		if e := s.Grants.VerifyGiftBalanceTx(c, q, v.Recipient); e != nil {
			return Result{}, false, e
		}
	} else if v.Generation.Valid() || v.Result.GrantReceiptID != "" {
		return Result{}, false, ErrConflict
	}
	seen := map[socialinbox.NoticeID]bool{}
	for _, id := range v.Result.NoticeIDs {
		if !id.WireSafe() || seen[id] {
			return Result{}, false, ErrConflict
		}
		seen[id] = true
		n, ok, e := s.NoticeEvidence.ReadNoticeEvidenceTx(c, q, v.Recipient, id)
		if e != nil || !ok || n.Active {
			return Result{}, false, ErrConflict
		}
		if t, ok := gifts[id]; ok {
			if socialinbox.MatchGift(n, t.Descriptor()) != nil {
				return Result{}, false, ErrConflict
			}
			delete(gifts, id)
		} else if !socialinbox.RelationFamily(n.Source) || socialinbox.ValidateRelationLifecycle(n) != nil {
			return Result{}, false, ErrConflict
		}
	}
	if len(gifts) != 0 {
		return Result{}, false, ErrConflict
	}
	return v.Result, true, nil
}
func (s Service) Send(c context.Context, actor identity.ActorContext, recipient identity.PlayerID, op operation.Context) (Result, error) {
	c, cancel := context.WithTimeout(c, Profile().OperationTimeout)
	defer cancel()
	if e := c.Err(); e != nil {
		return Result{}, e
	}
	if e := s.validate(actor); e != nil {
		return Result{}, e
	}
	if !recipient.Valid() || recipient == actor.PlayerID {
		return Result{}, ErrInvalid
	}
	fp, e := fingerprint("send", actor, recipient, op)
	if e != nil {
		return Result{}, e
	}
	if e = s.Admission.ValidateActor(c, actor, op.StartedAt); e != nil {
		return Result{}, e
	}
	var answer Result
	var known bool
	e = s.read(c, op, func(c context.Context, q tx.Queryer) error {
		var e error
		answer, known, e = s.sendProof(c, q, actor, recipient, fp, op)
		return e
	})
	if e != nil || known {
		return answer, e
	}
	content, bound, e := s.admit(c, op)
	if e != nil {
		return Result{}, e
	}
	resolver := resolution{service: s, original: op, actor: actor, recipient: recipient, fingerprint: fp, send: true}
	_, outcome, e := s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, resolver, func(c context.Context, sc gen.TimedScope) error {
		answer = Result{}
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, actor, at); e != nil {
			return e
		}
		if e := s.players(c, sc.Tx, []identity.PlayerID{actor.PlayerID, recipient}); e != nil {
			return e
		}
		privacy, e := s.Privacy.PrepareFriendDMPrivacyTx(c, sc.Tx, recipient, []identity.PlayerID{actor.PlayerID})
		if e != nil {
			return e
		}
		v := privacy.BySender[actor.PlayerID]
		if at.Before(v.LatestRelationAt) {
			return ErrClock
		}
		if !privacy.RecipientRootPresent || !v.Eligible {
			return ErrNotEligible
		} // Privacy already owns all 360/361/363 locks. Pure root reread avoids a lower-rank acquisition.
		roots, e := s.Relations.ReadRootsTx(c, sc.Tx, []identity.PlayerID{actor.PlayerID, recipient})
		if e != nil {
			return e
		}
		for _, pid := range []identity.PlayerID{actor.PlayerID, recipient} {
			if e := preflightRoot(roots[pid], at); e != nil {
				return e
			}
		}
		transferID, e := TransferID(op)
		if e != nil {
			return e
		}
		d := socialinbox.GiftDescriptor{TransferID: transferID, Sender: actor.PlayerID, Recipient: recipient, IssuedAt: at}
		p, e := s.Inbox.PrepareTx(c, sc.Tx, socialinbox.RecipientFence{PlayerID: recipient, StateVersion: roots[recipient].StateVersion}, d)
		if e != nil {
			return e
		}
		day, e := Day(at)
		if e != nil {
			return e
		}
		epochOrder := []identity.PlayerID{actor.PlayerID, recipient}
		sort.Slice(epochOrder, func(i, j int) bool {
			a, _ := EpochKey(epochOrder[i])
			b, _ := EpochKey(epochOrder[j])
			return lockkey.Compare(a, b) < 0
		})
		epochs := map[identity.PlayerID]Epoch{}
		existingEpochs := map[identity.PlayerID]bool{}
		for _, pid := range epochOrder {
			v, exists, e := s.epoch(c, sc.Tx, pid, day, bound, at)
			if e != nil {
				return e
			}
			epochs[pid] = v
			existingEpochs[pid] = exists
		}
		epoch := epochs[actor.PlayerID]
		prior, ok, e := s.Store.LockTransfer(c, sc.Tx, actor.PlayerID, recipient, day)
		if e != nil {
			return e
		}
		if ok {
			if prior.SendOperation == op.ID && prior.RequestFingerprint == fp {
				r, yes, e := s.sendProof(c, sc.Tx, actor, recipient, fp, op)
				if e != nil {
					return e
				}
				if !yes {
					return ErrConflict
				}
				answer = r
				return nil
			}
			return ErrDuplicate
		}
		if _, yes := p.Existing(); yes {
			return ErrConflict
		}
		sent, _, e := s.Store.Counts(c, sc.Tx, actor.PlayerID, day)
		if e != nil {
			return e
		}
		if sent >= content.Catalog.SendCap {
			return ErrQuota
		} // Complete lower lock/preflight plan is now held. All effects use this Tx.
		for _, pid := range epochOrder {
			if e := s.Store.PutEpoch(c, sc.Tx, epochs[pid], existingEpochs[pid], at); e != nil {
				return e
			}
		}
		n, e := s.Inbox.ApplyTx(c, sc.Tx, p)
		if e != nil {
			return e
		}
		t := Transfer{ID: transferID, Sender: actor.PlayerID, Recipient: recipient, SenderDay: day, SenderGeneration: epoch.Generation, SendOperation: op.ID, RequestFingerprint: fp, StartedAt: op.StartedAt.UTC(), IssuedAt: at, FriendshipGeneration: v.FriendshipGeneration, RecipientBlockVersion: v.RecipientBlockVersion, RewardRevision: content.Revision, VectorFingerprint: content.Catalog.VectorFingerprint, Amount: content.Catalog.Amount, NoticeID: n.NoticeID, Version: 1}
		if e := s.Store.InsertTransfer(c, sc.Tx, t); e != nil {
			return e
		}
		for _, pid := range []identity.PlayerID{actor.PlayerID, recipient} {
			if e := s.Relations.TouchRootTx(c, sc.Tx, roots[pid], at); e != nil {
				return e
			}
		}
		answer = Result{NoticeIDs: []socialinbox.NoticeID{n.NoticeID}, TransferIDs: []string{t.ID.String()}, Revision: content.Revision}
		return nil
	})
	return resolved(answer, outcome, e)
}
func (s Service) Claim(c context.Context, actor identity.ActorContext, input []socialinbox.NoticeID, op operation.Context) (Result, error) {
	c, cancel := context.WithTimeout(c, Profile().OperationTimeout)
	defer cancel()
	if e := c.Err(); e != nil {
		return Result{}, e
	}
	if e := s.validate(actor); e != nil {
		return Result{}, e
	}
	if e := c.Err(); e != nil {
		return Result{}, e
	}
	requested, e := CanonicalIDs(input)
	if e != nil {
		return Result{}, e
	}
	fp, e := fingerprint("claim", actor, requested, op)
	if e != nil {
		return Result{}, e
	}
	if e = s.Admission.ValidateActor(c, actor, op.StartedAt); e != nil {
		return Result{}, e
	}
	var answer Result
	var known bool
	e = s.read(c, op, func(c context.Context, q tx.Queryer) error {
		var e error
		answer, known, e = s.claimProof(c, q, actor, fp, op)
		if e != nil || known {
			return e
		}
		exists, e := s.Grants.GiftGrantIdentityExistsTx(c, q, actor.PlayerID, op.ID)
		if e != nil {
			return e
		}
		if exists {
			return ErrConflict
		}
		return nil
	})
	if e != nil || known {
		return answer, e
	}
	content, bound, e := s.admit(c, op)
	if e != nil {
		return Result{}, e
	}
	resolver := resolution{service: s, original: op, actor: actor, fingerprint: fp}
	_, outcome, e := s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, resolver, func(c context.Context, sc gen.TimedScope) error {
		answer = Result{NoticeIDs: []socialinbox.NoticeID{}, TransferIDs: []string{}, Revision: content.Revision}
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, actor, at); e != nil {
			return e
		}
		if e := s.players(c, sc.Tx, []identity.PlayerID{actor.PlayerID}); e != nil {
			return e
		}
		root, e := s.root(c, sc.Tx, actor.PlayerID)
		if e != nil {
			return e
		}
		r, yes, e := s.claimProof(c, sc.Tx, actor, fp, op)
		if e != nil {
			return e
		}
		if yes {
			answer = r
			return nil
		}
		orphan, e := s.Grants.GiftGrantIdentityExistsTx(c, sc.Tx, actor.PlayerID, op.ID)
		if e != nil {
			return e
		}
		if orphan {
			return ErrConflict
		}
		order := append([]socialinbox.NoticeID(nil), requested...)
		sort.Slice(order, func(i, j int) bool {
			a, _ := socialinbox.NoticeLockKey(actor.PlayerID, order[i])
			b, _ := socialinbox.NoticeLockKey(actor.PlayerID, order[j])
			return lockkey.Compare(a, b) < 0
		})
		notices := map[socialinbox.NoticeID]socialinbox.Notice{}
		transfers := []Transfer{}
		for _, id := range order {
			if e := c.Err(); e != nil {
				return e
			}
			n, ok, e := s.Inbox.Store.LockNoticeTx(c, sc.Tx, actor.PlayerID, id)
			if e != nil {
				return e
			}
			if !ok {
				continue
			}
			switch {
			case socialinbox.RelationFamily(n.Source):
				if socialinbox.ValidateRelationLifecycle(n) != nil {
					return ErrConflict
				}
				if n.Active && socialinbox.PreflightConsumption(n, at) != nil {
					return ErrClock
				}
				notices[id] = n
			case n.Source.Kind == socialinbox.GiftSourceKind:
				if socialinbox.ValidateGiftLifecycle(n) != nil {
					return ErrConflict
				}
				u, e := ids.ParseUUID(n.Source.Key)
				if e != nil {
					return ErrConflict
				}
				v, ok, e := s.Store.ReadTransfer(c, sc.Tx, u)
				if e != nil || !ok || v.Recipient != actor.PlayerID || v.NoticeID != id || socialinbox.MatchGift(n, v.Descriptor()) != nil {
					return ErrConflict
				}
				if !n.Active || !v.ClaimOperation.IsZero() {
					return ErrConflict
				}
				if socialinbox.PreflightConsumption(n, at) != nil || v.Version == math.MaxInt64 || at.Before(v.IssuedAt) {
					return ErrClock
				}
				issuedEpoch, haveEpoch, e := s.Store.ReadEpoch(c, sc.Tx, v.Sender, v.SenderDay)
				if e != nil || !haveEpoch || issuedEpoch.Generation != v.SenderGeneration {
					return ErrConflict
				}
				issued, e := s.Content.ReadGiftContent(c, sc.Tx, v.RewardRevision)
				if e != nil || !issued.Compatible(v) || !content.Compatible(v) {
					return ErrContent
				}
				notices[id] = n
				transfers = append(transfers, v)
			default: // Other owner families are ignored, never acknowledged as value.
			}
		}
		for _, n := range notices {
			if n.Active {
				if root.Validate() != nil {
					return ErrConflict
				}
				if e := preflightRoot(root, at); e != nil {
					return e
				}
				break
			}
		}
		day, e := Day(at)
		if e != nil {
			return e
		}
		var epoch Epoch
		var exists bool
		if len(transfers) > 0 {
			if e := preflightRoot(root, at); e != nil {
				return e
			}
			epoch, exists, e = s.epoch(c, sc.Tx, actor.PlayerID, day, bound, at)
			if e != nil {
				return e
			}
			_, claimed, e := s.Store.Counts(c, sc.Tx, actor.PlayerID, day)
			if e != nil {
				return e
			}
			if claimed+int64(len(transfers)) > content.Catalog.ClaimCap {
				return ErrQuota
			}
			sort.Slice(transfers, func(i, j int) bool {
				a, _ := TransferKey(transfers[i].Sender, transfers[i].Recipient, transfers[i].SenderDay)
				b, _ := TransferKey(transfers[j].Sender, transfers[j].Recipient, transfers[j].SenderDay)
				return lockkey.Compare(a, b) < 0
			})
			for _, v := range transfers {
				got, ok, e := s.Store.LockTransfer(c, sc.Tx, v.Sender, v.Recipient, v.SenderDay)
				if e != nil || !ok || got.ID != v.ID || got.Version != v.Version || !got.ClaimOperation.IsZero() {
					return ErrConflict
				}
			}
		}
		consumptions := map[socialinbox.NoticeID]socialinbox.PreparedGiftConsumption{}
		for _, v := range transfers {
			p, e := s.Inbox.PrepareConsumptionTx(c, sc.Tx, socialinbox.RecipientFence{PlayerID: actor.PlayerID, StateVersion: root.StateVersion}, notices[v.NoticeID], v.Descriptor(), at)
			if e != nil {
				return e
			}
			consumptions[v.NoticeID] = p
		}
		for _, id := range requested {
			if _, ok := notices[id]; ok {
				answer.NoticeIDs = append(answer.NoticeIDs, id)
			}
		}
		answer.Amount = int64(len(transfers)) * content.Catalog.Amount
		for _, id := range requested {
			for _, v := range transfers {
				if v.NoticeID == id {
					answer.TransferIDs = append(answer.TransferIDs, v.ID.String())
				}
			}
		} // All source/quota/content/lifecycle checks precede the single I5 settlement.
		if len(transfers) > 0 {
			gr, e := s.Grants.SettleGrantTx(c, sc.Tx, actor, GrantPlan(actor.PlayerID, op.ID, answer.Amount), sc.Operation.Operation(), i5.GrantTxOptions{AllowOverflowMail: false})
			if e != nil {
				return e
			}
			answer.GrantReceiptID = gr.ReceiptID
			if e := s.Store.PutEpoch(c, sc.Tx, epoch, exists, at); e != nil {
				return e
			}
			for _, v := range transfers {
				old := v.Version
				v.Version++
				v.ClaimOperation = op.ID
				v.ClaimDay = day
				v.ClaimGeneration = epoch.Generation
				v.ClaimedAt = &at
				v.GrantReceiptID = gr.ReceiptID
				v.ClaimContentRevision = content.Revision
				if e := s.Store.ClaimTransfer(c, sc.Tx, v, old); e != nil {
					return e
				}
			}
		}
		changed := len(transfers) > 0
		for _, id := range requested {
			n, ok := notices[id]
			if !ok || !n.Active {
				continue
			}
			changed = true
			if n.Source.Kind == socialinbox.GiftSourceKind {
				if e := s.Inbox.ApplyConsumptionTx(c, sc.Tx, consumptions[id]); e != nil {
					return e
				}
			} else {
				if e := s.Inbox.Store.DismissNoticeTx(c, sc.Tx, n, at); e != nil {
					return e
				}
			}
		}
		if changed {
			if e := preflightRoot(root, at); e != nil {
				return e
			}
			if e := s.Relations.TouchRootTx(c, sc.Tx, root, at); e != nil {
				return e
			}
		}
		return s.Store.InsertClaim(c, sc.Tx, ClaimOperation{ID: op.ID, Recipient: actor.PlayerID, Fingerprint: fp, StartedAt: op.StartedAt.UTC(), DecisionAt: at, Day: day, Generation: epoch.Generation, Revision: content.Revision, Result: answer})
	})
	return resolved(answer, outcome, e)
}

type resolution struct {
	service     Service
	original    operation.Context
	actor       identity.ActorContext
	recipient   identity.PlayerID
	fingerprint string
	send        bool
}

func (r resolution) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	var result Result
	var found bool
	e := r.service.read(c, r.original, func(c context.Context, q tx.Queryer) error {
		var e error
		if r.send {
			result, found, e = r.service.sendProof(c, q, r.actor, r.recipient, r.fingerprint, r.original)
		} else {
			result, found, e = r.service.claimProof(c, q, r.actor, r.fingerprint, r.original)
		}
		return e
	})
	if e != nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, e
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: result}, nil
}
func resolved(answer Result, outcome tx.Result, e error) (Result, error) {
	if e != nil {
		return Result{}, e
	}
	if outcome.Reconciled {
		r, ok := outcome.Evidence.(Result)
		if !ok {
			return Result{}, ErrConflict
		}
		return r, nil
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return Result{}, errors.New("SocialGift outcome unresolved")
	}
	return answer, nil
}

// SnapshotTx is a pure observation: it neither creates an epoch nor refreshes a
// counter. I7A7B must call it before the FriendDM destructive drain at rank380.
func (s Service) SnapshotTx(c context.Context, q tx.Queryer, pid identity.PlayerID, observedAt time.Time) (sent, claimed int64, err error) {
	day, e := Day(observedAt)
	if e != nil {
		return 0, 0, e
	}
	return s.Store.Counts(c, q, pid, day)
}

type Snapshot struct {
	Day, Policy    string
	Sent, Claimed  int64
	SentRecipients []identity.PlayerID
}

// GiftSnapshotTx supplies the future176 composition with one pure observation:
// counts and directed occupancy share the caller snapshot and observed instant.
func (s Service) GiftSnapshotTx(c context.Context, q tx.Queryer, pid identity.PlayerID, observedAt time.Time) (Snapshot, error) {
	if q == nil || s.Store == nil || !pid.Valid() {
		return Snapshot{}, ErrInvalid
	}
	day, e := Day(observedAt)
	if e != nil {
		return Snapshot{}, e
	}
	sent, claimed, e := s.Store.Counts(c, q, pid, day)
	if e != nil {
		return Snapshot{}, e
	}
	recipients, e := s.Store.SentRecipients(c, q, pid, day)
	if e != nil {
		return Snapshot{}, e
	}
	if sent < 0 || claimed < 0 || sent > 10 || claimed > 10 || int64(len(recipients)) != sent {
		return Snapshot{}, ErrConflict
	}
	for i, id := range recipients {
		if !id.Valid() || id == pid || i > 0 && recipients[i-1] >= id {
			return Snapshot{}, ErrConflict
		}
	}
	return Snapshot{Day: day, Policy: DayPolicy, Sent: sent, Claimed: claimed, SentRecipients: recipients}, nil
}
