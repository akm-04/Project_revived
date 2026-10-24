package guildinvite

import (
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

const DefaultCleanupBatch = 32

type Cleanup struct {
	Timed    gen.TimedRunner
	Reads    tx.Runner
	Sources  SourceReader
	Store    Store
	Players  playerroot.RecipientLocker
	Target   ProgressTarget
	Receipts receipt.Store
	Enqueue  obligation.Queue
}

func (v Cleanup) valid() bool {
	return v.Timed.Runner.DB != nil && v.Timed.Binder.Time != nil && v.Reads.DB != nil && v.Sources.Store != nil && v.Store != nil && v.Players != nil && v.Target != nil && v.Receipts != nil && v.Enqueue != nil
}

func (v Cleanup) load(c context.Context, q tx.Queryer, id ids.UUID) (gi.Marker, gi.MarkerProgress, error) {
	m, e := v.Sources.ReadMarkerEvidenceTx(c, q, id)
	if e != nil {
		return m, gi.MarkerProgress{}, e
	}
	_, p, ok, e := v.Store.ReadMarkerTx(c, q, id)
	if e != nil {
		return m, p, e
	}
	if !ok || p.Validate() != nil {
		return m, p, gi.ErrEvidence
	}
	if p.CursorProof != nil {
		if e = v.Target.ValidateCoveredInviteInvalidationsTx(c, q, m, p.CursorSerial, p.CursorProof.Request.Covered); e != nil {
			return m, p, e
		}
	}
	if e = v.Sources.ValidateCoveredEvidenceTx(c, q, v.Target, m, p); e != nil {
		return m, p, e
	}
	return m, p, nil
}

type cleanupAckResolver struct {
	Cleanup  Cleanup
	Marker   ids.UUID
	To       int64
	Complete bool
}

func (r cleanupAckResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	positive := false
	_, e := r.Cleanup.Reads.Run(c, operation.Context{}, ProgressProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, p, e := r.Cleanup.load(c, sc.Tx, r.Marker)
		if e != nil {
			return e
		}
		positive = p.CursorSerial >= r.To && (!r.Complete || p.Complete)
		return nil
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if !positive {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted}, nil
}

// RunBatch performs a finite target page before a separately committed source
// ACK. A partial page never advances the source cursor; committed target proof
// makes the repeated page safe after process loss.
func (v Cleanup) RunBatch(c context.Context, id ids.UUID, limit int) error {
	if !v.valid() || id.IsZero() || limit < 1 || limit > 1000 {
		return gi.ErrEvidence
	}
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	var marker gi.Marker
	var before gi.MarkerProgress
	var page []gi.Issue
	_, e := v.Reads.Run(c, operation.Context{}, ProgressProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		marker, before, e = v.load(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if before.Complete {
			return nil
		}
		page, e = v.Store.ReadMarkerPageTx(c, sc.Tx, marker, before, limit)
		return e
	})
	if e != nil {
		return e
	}
	if before.Complete {
		return nil
	}
	proofs := make([]gi.InvalidationProof, 0, len(page))
	for _, s := range page {
		p, e := v.Target.Invalidate(c, id, s.Operation.ID)
		if e != nil {
			return e
		}
		if p.Matches(marker, s) != nil {
			return gi.ErrEvidence
		}
		proofs = append(proofs, p)
	}
	to := before.CursorSerial
	if len(page) > 0 {
		to = page[len(page)-1].Serial
	}
	complete := len(page) < limit || to == marker.MaxIssueSerial
	if complete {
		to = marker.MaxIssueSerial
	}
	_, _, e = v.Timed.Run(c, marker.Operation, ProgressProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, cleanupAckResolver{Cleanup: v, Marker: id, To: to, Complete: complete}, func(c context.Context, sc gen.TimedScope) error {
		// Acquire every distinct315 in global order before any source350 leaf.
		pids := []identity.PlayerID{}
		seen := map[identity.PlayerID]bool{}
		for _, s := range page {
			if !seen[s.Tuple.Recipient] {
				seen[s.Tuple.Recipient] = true
				pids = append(pids, s.Tuple.Recipient)
			}
		}
		sort.Slice(pids, func(i, j int) bool { return pids[i] < pids[j] })
		for _, pid := range pids {
			if _, e := v.Players.LockBoundRecipientTx(c, sc.Tx, marker.Server, pid); e != nil {
				return e
			}
		}
		for i, s := range page {
			p, ok, e := v.Target.ReadInviteInvalidationProofTx(c, sc.Tx, id, s.Operation.ID)
			if e != nil {
				return e
			}
			if !ok || p != proofs[i] || p.Matches(marker, s) != nil {
				return gi.ErrEvidence
			}
		}
		current, progress, ok, e := v.Store.LockMarkerTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if !ok {
			return gi.ErrEvidence
		}
		fp, _ := marker.Fingerprint()
		cfp, fe := current.Fingerprint()
		if fe != nil || cfp != fp {
			return gi.ErrEvidence
		}
		if e = v.Sources.ValidateCursorEvidenceTx(c, sc.Tx, current, progress); e != nil {
			return e
		}
		if progress.CursorProof != nil {
			if e = v.Target.ValidateCoveredInviteInvalidationsTx(c, sc.Tx, current, progress.CursorSerial, progress.CursorProof.Request.Covered); e != nil {
				return e
			}
		}
		if e = v.Sources.ValidateCoveredEvidenceTx(c, sc.Tx, v.Target, current, progress); e != nil {
			return e
		}
		if progress.Complete || progress.CursorSerial > to || progress.CursorSerial == to && !complete {
			return nil
		}
		if progress.CursorSerial < before.CursorSerial {
			return gi.ErrEvidence
		}
		covered, e := v.Store.SourceSetThroughCursorTx(c, sc.Tx, current, to)
		if e != nil {
			return e
		}
		if e = v.Target.ValidateCoveredInviteInvalidationsTx(c, sc.Tx, current, to, covered); e != nil {
			return e
		}
		evidence, e := v.Sources.CoveredEvidenceTx(c, sc.Tx, v.Target, current, to, covered)
		if e != nil {
			return e
		}
		request := gi.CursorRequest{MarkerID: id, MarkerFingerprint: fp, From: progress.CursorSerial, To: to, Complete: complete, Covered: covered, Evidence: evidence}
		requestFP, e := request.Fingerprint(current)
		if e != nil {
			return e
		}
		rr, e := receipt.New(current.Operation, CursorReceiptIdentity(current, request), "I7A8B_GUILD_MARKER_ACK", "gxb.guild-invite.marker-ack.v1", json.RawMessage(`{}`), requestFP)
		if e != nil {
			return e
		}
		proof := gi.CursorProof{Request: request, ReceiptID: rr.ID, DecisionAt: sc.Operation.DecisionAt()}
		if proof.Validate(current) != nil {
			return gi.ErrEvidence
		}
		rr.ResultPayload, e = json.Marshal(proof)
		if e != nil {
			return e
		}
		rr.PolicyVersion = current.PolicyID
		rr.ActorAccountUID = current.ActorAccountUID
		rr.ContextID = current.Core.ContextID
		stored, e := v.Receipts.PutTx(c, sc.Tx, rr)
		if e != nil {
			return e
		}
		if !stored.Inserted || stored.Receipt.ID != rr.ID {
			return gi.ErrEvidence
		}
		if e = v.Store.AdvanceProvenMarkerTx(c, sc.Tx, progress, proof); e != nil {
			return e
		}
		if !complete {
			job, e := MarkerObligation(id, sc.Operation.DecisionAt())
			if e != nil {
				return e
			}
			return v.Enqueue.InsertTx(c, sc.Tx, job)
		}
		return nil
	})
	return e
}
