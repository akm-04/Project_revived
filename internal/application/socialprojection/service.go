package socialprojection

import (
	"context"
	"encoding/binary"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

type Service struct {
	Runner       tx.Runner
	PlayerRoots  playerroot.TxLocker
	Relations    socialrelation.ProjectionReader
	Inbox        socialinbox.RelationWindowReader
	Directory    playerdirectory.TxDiscoveryReader
	Presentation playerpresentation.TxReader
	Observer     playerpresentation.TxObserver
}

func DefaultReadProfile() tx.Profile {
	return tx.Profile{Name: "I7A4C_SOCIAL_PROJECTION", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 8 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 2 * time.Second, OperationTimeout: 45 * time.Second}
}
func (s Service) validate(a identity.ActorContext, op operation.Context) error {
	server, e := socialrelation.CanonicalServer(a.PlayerID)
	if e != nil || server != a.LogicalServerID || a.AccountID.UUID().IsZero() || !a.AccountUID.Valid() || a.SessionID.UUID().IsZero() || a.ContextID.UUID().IsZero() || a.ContextGeneration < 1 || a.SessionLivenessVersion < 1 || a.ContextLivenessVersion < 1 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return ErrInvalidRead
	}
	if s.Runner.DB == nil || s.PlayerRoots == nil || s.Relations == nil || s.Inbox == nil || s.Directory == nil || s.Presentation == nil || s.Observer == nil {
		return ErrInvalidRead
	}
	return nil
}

// run keeps output private through aborts and unknown commits. The admitted
// Kernel actor is trusted only after identity validation and I4 root binding.
func (s Service) run(c context.Context, a identity.ActorContext, op operation.Context, body func(context.Context, tx.Tx, bool) (Result, error)) (Result, error) {
	if e := s.validate(a, op); e != nil {
		return Result{}, e
	}
	var private Result
	outcome, e := s.Runner.Run(c, op, DefaultReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: false}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, nil, func(c context.Context, scope tx.Scope) error {
		private = Result{}
		roots, e := s.PlayerRoots.LockPlayerRootsTx(c, scope.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != a.PlayerID || roots[0].LogicalServerID != a.LogicalServerID {
			return ErrInvalidRead
		}
		root, ok, e := s.Relations.LockRootTx(c, scope.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if ok && (root.Validate() != nil || root.PlayerID != a.PlayerID) {
			return ErrInvalidRead
		}
		value, e := body(c, scope.Tx, ok)
		if e != nil {
			return e
		}
		if value.ObservedAt.IsZero() {
			return ErrInvalidRead
		}
		private = value
		return nil
	})
	if e != nil {
		return Result{}, e
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return Result{}, ErrInvalidRead
	}
	return private, nil
}
func supported(id identity.PlayerID) error { _, e := socialrelation.CanonicalServer(id); return e }

// present obtains one response observation. Empty batches preserve the old
// TxReader contract and use the additive database observer instead.
func (s Service) present(c context.Context, t tx.Tx, ids []identity.PlayerID) (playerpresentation.Batch, error) {
	unique := []identity.PlayerID{}
	seen := map[identity.PlayerID]bool{}
	for _, id := range ids {
		if e := supported(id); e != nil {
			return playerpresentation.Batch{}, e
		}
		if !seen[id] {
			seen[id] = true
			unique = append(unique, id)
		}
	}
	b, e := s.Presentation.ReadManyTx(c, t, unique)
	if e != nil {
		return playerpresentation.Batch{}, e
	}
	if len(unique) == 0 {
		if !b.ObservedAt.IsZero() || len(b.Players) != 0 {
			return playerpresentation.Batch{}, ErrInvalidRead
		}
		b.ObservedAt, e = s.Observer.ObserveTx(c, t)
		if e != nil {
			return playerpresentation.Batch{}, e
		}
	}
	if b.ObservedAt.IsZero() || len(b.Players) != len(unique) {
		return playerpresentation.Batch{}, ErrInvalidRead
	}
	for _, id := range unique {
		v, ok := b.Players[id]
		if !ok || v.Validate(id) != nil {
			return playerpresentation.Batch{}, playerpresentation.ErrMissingPresentation
		}
	}
	return b, nil
}
func (s Service) LoadBase(c context.Context, a identity.ActorContext, op operation.Context) (Result, error) {
	return s.load(c, a, op, 0)
}
func (s Service) LoadList(c context.Context, a identity.ActorContext, k ListKind, op operation.Context) (Result, error) {
	if k < Friend || k > Notice {
		return Result{}, ErrInvalidRead
	}
	return s.load(c, a, op, k)
}
func (s Service) load(c context.Context, a identity.ActorContext, op operation.Context, k ListKind) (Result, error) {
	return s.run(c, a, op, func(c context.Context, t tx.Tx, hasRoot bool) (Result, error) {
		out := emptyResult()
		friends, blocks := []identity.PlayerID{}, []identity.PlayerID{}
		requests := []socialrelation.FriendRequest{}
		notices := []socialinbox.Notice{}
		var e error
		if hasRoot {
			if k == 0 || k == Friend {
				friends, e = s.Relations.ActiveFriendsTx(c, t, a.PlayerID)
				if e != nil {
					return Result{}, e
				}
			}
			if k == 0 || k == Blacklist {
				blocks, e = s.Relations.ActiveBlocksForTx(c, t, a.PlayerID)
				if e != nil {
					return Result{}, e
				}
			}
			if k == 0 || k == Request {
				requests, e = s.Relations.InboundPendingTx(c, t, a.PlayerID)
				if e != nil {
					return Result{}, e
				}
			}
			if k == 0 || k == Notice {
				notices, e = s.Inbox.RelationWindowTx(c, t, a.PlayerID)
				if e != nil {
					return Result{}, e
				}
			}
		}
		ids := append(append([]identity.PlayerID{}, friends...), blocks...)
		for i, req := range requests {
			if req.Validate() != nil || req.TargetPlayerID != a.PlayerID || req.Status != socialrelation.RequestPending {
				return Result{}, ErrInvalidRead
			}
			if i > 0 && (req.RequestedAt.After(requests[i-1].RequestedAt) || req.RequestedAt.Equal(requests[i-1].RequestedAt) && req.RequesterPlayerID <= requests[i-1].RequesterPlayerID) {
				return Result{}, ErrInvalidRead
			}
			ids = append(ids, req.RequesterPlayerID)
		}
		if len(notices) > 50 {
			return Result{}, ErrInvalidRead
		}
		for i, n := range notices {
			if !n.NoticeID.WireSafe() || n.Validate() != nil || socialinbox.ValidateRelationDescriptor(n) != nil || n.RecipientPlayerID != a.PlayerID || !n.Active || !n.RelatedPlayerID.Valid() {
				return Result{}, ErrInvalidRead
			}
			if i > 0 && (n.NoticeTime.After(notices[i-1].NoticeTime) || n.NoticeTime.Equal(notices[i-1].NoticeTime) && n.NoticeID >= notices[i-1].NoticeID) {
				return Result{}, ErrInvalidRead
			}
			ids = append(ids, n.RelatedPlayerID)
		}
		for _, list := range [][]identity.PlayerID{friends, blocks} {
			var prev identity.PlayerID
			for _, id := range list {
				if id == a.PlayerID || id <= prev {
					return Result{}, ErrInvalidRead
				}
				prev = id
			}
		}
		b, e := s.present(c, t, ids)
		if e != nil {
			return Result{}, e
		}
		out.ObservedAt = b.ObservedAt
		for _, id := range friends {
			out.Friends = append(out.Friends, Player{Presentation: b.Players[id]})
		}
		for _, id := range blocks {
			out.Blocks = append(out.Blocks, Player{Presentation: b.Players[id]})
		}
		for _, req := range requests {
			out.Requests = append(out.Requests, Requested{Player: Player{Presentation: b.Players[req.RequesterPlayerID]}, Relation: req})
		}
		for _, n := range notices {
			out.Notices = append(out.Notices, Notified{Player: Player{Presentation: b.Players[n.RelatedPlayerID]}, Notice: n})
		}
		return out, nil
	})
}
func numericPID(raw string) (identity.PlayerID, bool) {
	if raw == "" {
		return 0, false
	}
	for _, v := range []byte(raw) {
		if v < '0' || v > '9' {
			return 0, false
		}
	}
	v, e := strconv.ParseInt(raw, 10, 64)
	return identity.PlayerID(v), e == nil && v > 0
}
func (s Service) states(c context.Context, t tx.Tx, a identity.PlayerID, ids []identity.PlayerID) (map[identity.PlayerID]socialrelation.CandidateState, error) {
	rows, e := s.Relations.CandidateStatesTx(c, t, a, ids)
	if e != nil {
		return nil, e
	}
	if len(rows) != len(ids) {
		return nil, ErrInvalidRead
	}
	want := map[identity.PlayerID]bool{}
	for _, id := range ids {
		if want[id] {
			return nil, ErrInvalidRead
		}
		want[id] = true
	}
	out := map[identity.PlayerID]socialrelation.CandidateState{}
	for _, v := range rows {
		if !want[v.PlayerID] || v.OutgoingPending && !v.Pending {
			return nil, ErrInvalidRead
		}
		delete(want, v.PlayerID)
		out[v.PlayerID] = v
	}
	return out, nil
}
func (s Service) Search(c context.Context, a identity.ActorContext, q SearchQuery, op operation.Context) (Result, error) {
	if e := q.Validate(); e != nil {
		return Result{}, e
	}
	return s.run(c, a, op, func(c context.Context, t tx.Tx, _ bool) (Result, error) {
		ids := []identity.PlayerID{}
		seen := map[identity.PlayerID]bool{}
		if q.Term != "" {
			if q.Mode == Modern {
				if id, ok := numericPID(q.Term); ok {
					p, found, e := s.Directory.ProfileTx(c, t, id)
					if e != nil {
						return Result{}, e
					}
					if found {
						if p.Validate() != nil || p.PlayerID != id || supported(id) != nil {
							return Result{}, ErrInvalidRead
						}
						ids = append(ids, id)
						seen[id] = true
					}
				}
			}
			names, e := s.Directory.ProfilesByExactNameTx(c, t, q.Term, 101)
			if e != nil {
				return Result{}, e
			}
			if len(names) > 100 {
				return Result{}, ErrSearchSaturated
			}
			var prev identity.PlayerID
			for _, p := range names {
				if p.Validate() != nil || p.Name != q.Term || p.PlayerID <= prev || supported(p.PlayerID) != nil {
					return Result{}, ErrInvalidRead
				}
				prev = p.PlayerID
			}
			sort.Slice(names, func(i, j int) bool { return names[i].PlayerID < names[j].PlayerID })
			for _, p := range names {
				if !seen[p.PlayerID] {
					ids = append(ids, p.PlayerID)
					seen[p.PlayerID] = true
				}
			}
		}
		if q.Mode == Legacy {
			if len(ids) == 0 {
				return Result{}, &socialrelation.StockError{Code: 20004}
			}
			if len(ids) != 1 {
				return Result{}, ErrAmbiguousSearch
			}
		}
		overlay, e := s.states(c, t, a.PlayerID, ids)
		if e != nil {
			return Result{}, e
		}
		b, e := s.present(c, t, ids)
		if e != nil {
			return Result{}, e
		}
		out := emptyResult()
		out.ObservedAt = b.ObservedAt
		for _, id := range ids {
			out.Players = append(out.Players, Player{Presentation: b.Players[id], OutgoingPending: overlay[id].OutgoingPending})
		}
		return out, nil
	})
}

// recommendAnchor is bound at the first successful bounds read and retained
// across definite-abort retries, including an initially empty directory.
type recommendAnchor struct {
	bound, empty bool
	pivot        identity.PlayerID
}

func (s Service) Recommend(c context.Context, a identity.ActorContext, op operation.Context) (Result, error) {
	anchor := recommendAnchor{}
	entropy := op.Derive("social-recommend-pivot-v1", 0)
	return s.run(c, a, op, func(c context.Context, t tx.Tx, _ bool) (Result, error) {
		if !anchor.bound {
			min, max, ok, e := s.Directory.PlayerIDBoundsTx(c, t)
			if e != nil {
				return Result{}, e
			}
			if ok {
				if min > max || supported(min) != nil || supported(max) != nil {
					return Result{}, ErrInvalidRead
				}
				span := uint64(max) - uint64(min) + 1
				anchor.pivot = min + identity.PlayerID(binary.BigEndian.Uint64(entropy[:8])%span)
			}
			anchor.empty = !ok
			anchor.bound = true
		}
		out := emptyResult()
		out.Scan.Pivot = int64(anchor.pivot)
		ids := []identity.PlayerID{}
		selected := map[identity.PlayerID]socialrelation.CandidateState{}
		visited := map[identity.PlayerID]bool{}
		if !anchor.empty {
			after := anchor.pivot - 1
			wrapped := false
			done := false
			for !done && len(ids) < 10 && out.Scan.Fetched < 4096 {
				limit := 128
				if remain := 4096 - out.Scan.Fetched; remain < limit {
					limit = remain
				}
				page, e := s.Directory.ProfilesAfterTx(c, t, after, limit)
				if e != nil {
					return Result{}, e
				}
				if len(page) > limit {
					return Result{}, ErrInvalidRead
				}
				out.Scan.Fetched += len(page)
				candidates := []identity.PlayerID{}
				prev := after
				// Validate the complete fetched page before considering its wrap
				// boundary; a malformed provider row cannot hide behind that boundary.
				for _, p := range page {
					if p.Validate() != nil || p.PlayerID <= prev || supported(p.PlayerID) != nil {
						return Result{}, ErrInvalidRead
					}
					prev = p.PlayerID
				}
				for _, p := range page {
					if wrapped && p.PlayerID >= anchor.pivot {
						done = true
						break
					}
					if visited[p.PlayerID] {
						return Result{}, ErrInvalidRead
					}
					visited[p.PlayerID] = true
					candidates = append(candidates, p.PlayerID)
					out.Scan.Evaluated++
				}
				overlay, e := s.states(c, t, a.PlayerID, candidates)
				if e != nil {
					return Result{}, e
				}
				for _, id := range candidates {
					v := overlay[id]
					if id != a.PlayerID && !v.Friend && !v.Blocked && !v.Pending && len(ids) < 10 {
						ids = append(ids, id)
						selected[id] = v
					}
				}
				if len(page) > 0 {
					after = page[len(page)-1].PlayerID
				}
				if len(page) < limit && !done {
					if wrapped {
						done = true
					} else {
						wrapped = true
						out.Scan.Wrapped = true
						after = 0
					}
				}
			}
		}
		b, e := s.present(c, t, ids)
		if e != nil {
			return Result{}, e
		}
		out.ObservedAt = b.ObservedAt
		for _, id := range ids {
			out.Players = append(out.Players, Player{Presentation: b.Players[id], OutgoingPending: selected[id].OutgoingPending})
		}
		return out, nil
	})
}
