package socialrelation

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"sort"
	"time"
)

type Service struct {
	Timed        gen.TimedRunner
	PlayerRoots  playerroot.TxLocker
	Store        CommandStore
	Inbox        socialinbox.RelationMaterializer
	Presentation playerpresentation.TxReader
}

func DefaultCommandProfile() tx.Profile {
	return tx.Profile{Name: "I7A4B_SOCIAL_RELATION", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) Execute(ctx context.Context, actor identity.ActorContext, command Command, op operation.Context) (Result, error) {
	if s.Store == nil || s.PlayerRoots == nil || s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil {
		return Result{}, ErrInvalidCommand
	}
	server, err := CanonicalServer(actor.PlayerID)
	if err != nil || server != actor.LogicalServerID {
		return Result{}, ErrInvalidCommand
	}
	if actor.AccountID.UUID().IsZero() || !actor.AccountUID.Valid() || actor.SessionID.UUID().IsZero() || actor.ContextID.UUID().IsZero() || actor.ContextGeneration < 1 || actor.SessionLivenessVersion < 1 || actor.ContextLivenessVersion < 1 {
		return Result{}, ErrInvalidCommand
	}
	if err := command.validate(); err != nil {
		return Result{}, err
	}
	switch command.Kind {
	case DenyRequests, AcceptRequest, DeleteFriend, AcceptAllRequests:
		if s.Inbox == nil {
			return Result{}, ErrInvalidCommand
		}
	}
	switch command.Kind {
	case AcceptRequest, AcceptAllRequests, AddBlock:
		if s.Presentation == nil {
			return Result{}, ErrInvalidCommand
		}
	}
	bound, err := bindPolicies(op)
	if err != nil {
		return Result{}, err
	}
	var answer Result
	_, outcome, err := s.Timed.Run(ctx, bound, DefaultCommandProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, nil, func(ctx context.Context, scope gen.TimedScope) error {
		answer = Result{}
		state, err := s.load(ctx, scope.Tx, actor, command, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		p, err := state.plan(command, scope.Operation.DecisionAt())
		if err != nil {
			return err
		}
		if len(p.project) > 0 {
			projections, err := s.Presentation.ReadManyTx(ctx, scope.Tx, p.project)
			if err != nil {
				return err
			}
			if projections.ObservedAt.IsZero() || len(projections.Players) != len(p.project) {
				return playerpresentation.ErrMissingPresentation
			}
			for _, pid := range p.project {
				row, ok := projections.Players[pid]
				if !ok {
					return playerpresentation.ErrMissingPresentation
				}
				if err := row.Validate(pid); err != nil {
					return err
				}
			}
			p.result.Players = projections
		}
		var notices []socialinbox.PreparedRelationNotice
		if len(p.events) > 0 {
			fences := make([]socialinbox.RecipientFence, 0, len(state.roots))
			for _, root := range state.roots {
				fences = append(fences, socialinbox.RecipientFence{PlayerID: root.PlayerID, StateVersion: root.StateVersion})
			}
			notices, err = s.Inbox.PrepareRelationsTx(ctx, scope.Tx, fences, p.events)
			if err != nil {
				return err
			}
		}
		if err := p.preflight(state.roots, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		if err := p.apply(ctx, scope.Tx, s.Store, state.roots, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		if len(notices) > 0 {
			if _, err := s.Inbox.ApplyRelationsTx(ctx, scope.Tx, notices); err != nil {
				return err
			}
		}
		p.result.Reloads, err = p.reloadReferences(state, command)
		if err != nil {
			return err
		}
		p.result.NoOp = !p.changed()
		answer = p.result
		return nil
	})
	if err != nil {
		return Result{}, err
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return Result{}, ErrStateConflict
	}
	return answer, nil
}

type directed struct{ first, second identity.PlayerID }
type maybe[T any] struct {
	value  T
	exists bool
}
type lockSpec struct {
	key  lockkey.Key
	kind uint16
	pair directed
}
type commandState struct {
	actor    identity.PlayerID
	order    []identity.PlayerID
	roots    map[identity.PlayerID]Root
	present  map[identity.PlayerID]bool
	friends  map[directed]maybe[Friendship]
	requests map[directed]maybe[FriendRequest]
	blocks   map[directed]maybe[Block]
	epoch    maybe[RequestEpoch]
	counts   map[identity.PlayerID]int64
}

func pair(a, b identity.PlayerID) directed {
	if a > b {
		a, b = b, a
	}
	return directed{a, b}
}
func (s Service) load(ctx context.Context, t tx.Tx, actor identity.ActorContext, c Command, at time.Time) (commandState, error) {
	st := commandState{actor: actor.PlayerID, roots: map[identity.PlayerID]Root{}, present: map[identity.PlayerID]bool{}, friends: map[directed]maybe[Friendship]{}, requests: map[directed]maybe[FriendRequest]{}, blocks: map[directed]maybe[Block]{}, counts: map[identity.PlayerID]int64{}}
	seen := map[identity.PlayerID]bool{}
	for _, id := range c.Targets {
		if id != st.actor && !seen[id] {
			seen[id] = true
			st.order = append(st.order, id)
		}
	}
	ids := append([]identity.PlayerID{st.actor}, st.order...)
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, pid := range ids {
		server, err := CanonicalServer(pid)
		if err != nil {
			return st, err
		}
		rows, err := s.PlayerRoots.LockPlayerRootsTx(ctx, t, server, []identity.PlayerID{pid})
		if errors.Is(err, playerroot.ErrPlayerRootNotFound) && pid != st.actor {
			switch c.Kind {
			case RequestFriend, AddBlock:
				return st, &StockError{Code: 20004}
			case AcceptRequest:
				return st, ErrNotEligible
			default:
				continue
			}
		}
		if err != nil {
			return st, err
		}
		if len(rows) != 1 || rows[0].PlayerID != pid || rows[0].LogicalServerID != server {
			return st, ErrStateConflict
		}
		if err := rows[0].Validate(); err != nil {
			return st, err
		}
		st.present[pid] = true
	}
	if !st.present[st.actor] {
		return st, ErrStateConflict
	}
	for _, pid := range ids {
		if !st.present[pid] {
			continue
		}
		root, err := s.Store.EnsureRootTx(ctx, t, pid, at)
		if err != nil {
			return st, err
		}
		if root.PlayerID != pid {
			return st, ErrStateConflict
		}
		if err := root.Validate(); err != nil {
			return st, err
		}
		st.roots[pid] = root
	}
	if c.Kind == ClearBlocks {
		ids, err := s.Store.ActiveBlockTargetsTx(ctx, t, st.actor)
		if err != nil {
			return st, err
		}
		st.order = ids
	}
	var specs []lockSpec
	add := func(kind uint16, a, b identity.PlayerID) error {
		var k lockkey.Key
		var err error
		d := directed{a, b}
		switch kind {
		case LockRankFriendship:
			d = pair(a, b)
			k, err = FriendshipLockKey(a, b)
		case LockRankRequest:
			k, err = RequestLockKey(a, b)
		case LockRankBlock:
			k, err = BlockLockKey(a, b)
		case LockRankRequestEpoch:
			k, err = RequestEpochLockKey(a, RequestDayPolicy)
		default:
			return ErrInvalidCommand
		}
		if err != nil {
			return err
		}
		specs = append(specs, lockSpec{key: k, kind: kind, pair: d})
		return nil
	}
	for _, id := range st.order {
		if c.Kind != ClearBlocks && !st.present[id] {
			continue
		}
		switch c.Kind {
		case RequestFriend, AcceptRequest, AcceptAllRequests, DeleteFriend:
			if err := add(LockRankFriendship, st.actor, id); err != nil {
				return st, err
			}
		}
		switch c.Kind {
		case RequestFriend:
			if err := add(LockRankRequest, st.actor, id); err != nil {
				return st, err
			}
			fallthrough
		case DenyRequests, IgnoreRequests, AcceptRequest, AcceptAllRequests:
			if err := add(LockRankRequest, id, st.actor); err != nil {
				return st, err
			}
		}
		switch c.Kind {
		case RequestFriend, AcceptRequest, AcceptAllRequests:
			if err := add(LockRankBlock, id, st.actor); err != nil {
				return st, err
			}
			fallthrough
		case IgnoreRequests, AddBlock, RemoveBlock, ClearBlocks:
			if err := add(LockRankBlock, st.actor, id); err != nil {
				return st, err
			}
		}
	}
	if c.Kind == RequestFriend {
		if err := add(LockRankRequestEpoch, st.actor, 0); err != nil {
			return st, err
		}
	}
	// Sort the accepted key representation, not numeric SQL tuples.
	keys := make([]lockkey.Key, len(specs))
	for i := range specs {
		keys[i] = specs[i].key
	}
	if _, err := lockkey.CanonicalDedup(keys); err != nil {
		return st, err
	}
	sort.Slice(specs, func(i, j int) bool { return lockkey.Compare(specs[i].key, specs[j].key) < 0 })
	for i, x := range specs {
		if i > 0 && lockkey.Compare(specs[i-1].key, x.key) == 0 {
			continue
		}
		a, b := x.pair.first, x.pair.second
		switch x.kind {
		case LockRankFriendship:
			v, ok, err := s.Store.LockFriendshipTx(ctx, t, a, b)
			if err != nil {
				return st, err
			}
			if ok && (v.PlayerLowID != a || v.PlayerHighID != b) {
				return st, ErrStateConflict
			}
			if ok {
				if err := v.Validate(); err != nil {
					return st, err
				}
			}
			st.friends[x.pair] = maybe[Friendship]{v, ok}
		case LockRankRequest:
			v, ok, err := s.Store.LockRequestTx(ctx, t, a, b)
			if err != nil {
				return st, err
			}
			if ok && (v.RequesterPlayerID != a || v.TargetPlayerID != b) {
				return st, ErrStateConflict
			}
			if ok {
				if err := v.Validate(); err != nil {
					return st, err
				}
			}
			st.requests[x.pair] = maybe[FriendRequest]{v, ok}
		case LockRankBlock:
			v, ok, err := s.Store.LockBlockTx(ctx, t, a, b)
			if err != nil {
				return st, err
			}
			if ok && (v.BlockerPlayerID != a || v.BlockedPlayerID != b) {
				return st, ErrStateConflict
			}
			if ok {
				if err := v.Validate(); err != nil {
					return st, err
				}
			}
			st.blocks[x.pair] = maybe[Block]{v, ok}
		case LockRankRequestEpoch:
			v, ok, err := s.Store.LockRequestEpochTx(ctx, t, a, RequestDayPolicy)
			if err != nil {
				return st, err
			}
			if ok && (v.PlayerID != a || v.PolicyID != RequestDayPolicy) {
				return st, ErrStateConflict
			}
			if ok {
				if err := v.Validate(); err != nil {
					return st, err
				}
			}
			st.epoch = maybe[RequestEpoch]{v, ok}
		}
	}
	if c.Kind == RequestFriend || c.Kind == AcceptRequest || c.Kind == AcceptAllRequests {
		for _, pid := range ids {
			if !st.present[pid] {
				continue
			}
			count, err := s.Store.CountActiveFriendsTx(ctx, t, pid)
			if err != nil {
				return st, err
			}
			if count < 0 {
				return st, ErrInvalidState
			}
			st.counts[pid] = count
		}
	}
	return st, nil
}

type writePlan[T any] struct {
	old  *T
	next T
}
type commandPlan struct {
	friends  []writePlan[Friendship]
	requests []writePlan[FriendRequest]
	blocks   []writePlan[Block]
	epoch    *writePlan[RequestEpoch]
	touch    map[identity.PlayerID]bool
	events   []socialinbox.RelationTransition
	project  []identity.PlayerID
	result   Result
	changes  map[identity.PlayerID]Change
}

func (p *commandPlan) changed() bool {
	return len(p.friends)+len(p.requests)+len(p.blocks) > 0 || p.epoch != nil
}
func (p *commandPlan) mark(a, b identity.PlayerID, kind CommandKind) {
	p.touch[a] = true
	p.touch[b] = true
	for _, pid := range []identity.PlayerID{a, b} {
		x := p.changes[pid]
		x.PlayerID = pid
		switch kind {
		case RequestFriend, DenyRequests, IgnoreRequests:
			x.Request = true
		case AcceptRequest, AcceptAllRequests:
			x.Request = true
			x.Friendship = true
		case DeleteFriend:
			x.Friendship = true
		}
		p.changes[pid] = x
	}
}
func (p *commandPlan) notice(e socialinbox.RelationTransition) {
	p.events = append(p.events, e)
	x := p.changes[e.Recipient]
	x.PlayerID = e.Recipient
	x.Notice = true
	p.changes[e.Recipient] = x
}
func (p *commandPlan) block(old maybe[Block], a, b identity.PlayerID, active bool, at time.Time) error {
	if old.exists && old.value.Active == active || !old.exists && !active {
		return nil
	}
	n := Block{BlockerPlayerID: a, BlockedPlayerID: b, Generation: 1, Active: active, ActivatedAt: at, StateVersion: 1, UpdatedAt: at}
	var previous *Block
	if old.exists {
		v := old.value
		previous = &v
		n = v
		n.Active = active
		n.UpdatedAt = at
		var err error
		n.StateVersion, err = increment(v.StateVersion)
		if err != nil {
			return err
		}
		if active {
			n.Generation, err = increment(v.Generation)
			if err != nil {
				return err
			}
			n.ActivatedAt = at
			n.RemovedAt = nil
		} else {
			n.RemovedAt = &at
		}
	}
	p.blocks = append(p.blocks, writePlan[Block]{previous, n})
	p.touch[a] = true
	p.touch[b] = true
	x := p.changes[a]
	x.PlayerID = a
	x.Block = true
	p.changes[a] = x
	return nil
}
func (p *commandPlan) terminal(old FriendRequest, status RequestStatus, at time.Time) error {
	n := old
	n.Status = status
	n.TerminalAt = &at
	n.UpdatedAt = at
	v, err := increment(old.StateVersion)
	if err != nil {
		return err
	}
	n.StateVersion = v
	p.requests = append(p.requests, writePlan[FriendRequest]{&old, n})
	return nil
}
func (p *commandPlan) activate(old maybe[Friendship], a, b identity.PlayerID, at time.Time) error {
	key := pair(a, b)
	n := Friendship{PlayerLowID: key.first, PlayerHighID: key.second, Generation: 1, Active: true, ActivatedAt: at, StateVersion: 1, UpdatedAt: at}
	var previous *Friendship
	if old.exists {
		v := old.value
		if v.Active {
			return ErrStateConflict
		}
		previous = &v
		var err error
		n.Generation, err = increment(v.Generation)
		if err != nil {
			return err
		}
		n.StateVersion, err = increment(v.StateVersion)
		if err != nil {
			return err
		}
	}
	p.friends = append(p.friends, writePlan[Friendship]{previous, n})
	return nil
}
func (st commandState) plan(c Command, at time.Time) (commandPlan, error) {
	p := commandPlan{touch: map[identity.PlayerID]bool{}, changes: map[identity.PlayerID]Change{}, result: Result{Players: playerpresentation.Batch{Players: map[identity.PlayerID]playerpresentation.Projected{}}}}
	a := st.actor
	if len(c.Targets) == 1 && c.Targets[0] == a {
		switch c.Kind {
		case RequestFriend, AddBlock, AcceptRequest:
			return p, ErrNotEligible
		}
	}
	switch c.Kind {
	case RequestFriend:
		b := c.Targets[0]
		f := st.friends[pair(a, b)]
		out := st.requests[directed{a, b}]
		in := st.requests[directed{b, a}]
		if f.exists && f.value.Active {
			return p, &StockError{Code: 20008}
		}
		if out.exists && out.value.Status == RequestPending {
			return p, &StockError{Code: 20009}
		}
		if in.exists && in.value.Status == RequestPending {
			return p, &StockError{Code: 20010}
		}
		if st.blocked(a, b) {
			return p, ErrNotEligible
		}
		if st.counts[a] >= FriendCapacity {
			return p, &StockError{Code: 20012}
		}
		if st.counts[b] >= FriendCapacity {
			return p, &StockError{Code: 20014}
		}
		day, anchor, err := RequestDay(at)
		if err != nil {
			return p, err
		}
		epoch := RequestEpoch{PlayerID: a, PolicyID: RequestDayPolicy, EpochGeneration: day, EpochStartedAt: anchor, SuccessfulNewRequests: 1, StateVersion: 1, UpdatedAt: at}
		var oldEpoch *RequestEpoch
		if st.epoch.exists {
			v := st.epoch.value
			oldEpoch = &v
			if v.EpochGeneration > (math.MaxInt64-28800)/86400 || !v.EpochStartedAt.Equal(time.Unix(v.EpochGeneration*86400-28800, 0).UTC()) || v.SuccessfulNewRequests > RequestQuota {
				return p, ErrStateConflict
			}
			if day < v.EpochGeneration {
				return p, ErrStaleDecisionTime
			}
			if day == v.EpochGeneration {
				if v.SuccessfulNewRequests >= RequestQuota {
					return p, &StockError{Code: 20011}
				}
				epoch.SuccessfulNewRequests = v.SuccessfulNewRequests + 1
			}
			epoch.StateVersion, err = increment(v.StateVersion)
			if err != nil {
				return p, err
			}
		}
		req := FriendRequest{RequesterPlayerID: a, TargetPlayerID: b, Generation: 1, Status: RequestPending, Message: c.Message, RequestedAt: at, StateVersion: 1, UpdatedAt: at}
		var previous *FriendRequest
		if out.exists {
			v := out.value
			previous = &v
			req.Generation, err = increment(v.Generation)
			if err != nil {
				return p, err
			}
			req.StateVersion, err = increment(v.StateVersion)
			if err != nil {
				return p, err
			}
		}
		p.requests = append(p.requests, writePlan[FriendRequest]{previous, req})
		p.epoch = &writePlan[RequestEpoch]{oldEpoch, epoch}
		p.mark(a, b, RequestFriend)
	case DenyRequests, IgnoreRequests:
		for _, b := range st.order {
			r := st.requests[directed{b, a}]
			if !st.present[b] || !r.exists || r.value.Status != RequestPending {
				continue
			}
			status := RequestDenied
			if c.Kind == IgnoreRequests {
				status = RequestIgnored
			}
			if err := p.terminal(r.value, status, at); err != nil {
				return p, err
			}
			p.mark(a, b, c.Kind)
			if c.Kind == DenyRequests {
				p.notice(socialinbox.RelationTransition{Event: socialinbox.DenyRelationRequest, First: b, Second: a, Generation: r.value.Generation, Actor: a, Recipient: b, At: at})
			} else {
				if err := p.block(st.blocks[directed{a, b}], a, b, true, at); err != nil {
					return p, err
				}
			}
		}
	case AcceptRequest, AcceptAllRequests:
		for _, b := range st.order {
			if !st.present[b] {
				continue
			}
			r := st.requests[directed{b, a}]
			f := st.friends[pair(a, b)]
			if c.Kind == AcceptRequest && r.exists && r.value.Status == RequestAccepted && f.exists && f.value.Active {
				p.project = append(p.project, b)
				continue
			}
			if !r.exists || r.value.Status != RequestPending {
				if c.Kind == AcceptRequest {
					return p, ErrNotEligible
				}
				continue
			}
			if f.exists && f.value.Active {
				return p, ErrStateConflict
			}
			if st.blocked(a, b) {
				if c.Kind == AcceptRequest {
					return p, ErrNotEligible
				}
				continue
			}
			if st.counts[a] >= FriendCapacity {
				if c.Kind == AcceptRequest {
					return p, &StockError{Code: 20012}
				}
				continue
			}
			if st.counts[b] >= FriendCapacity {
				if c.Kind == AcceptRequest {
					return p, &StockError{Code: 20014}
				}
				continue
			}
			if err := p.terminal(r.value, RequestAccepted, at); err != nil {
				return p, err
			}
			if err := p.activate(f, a, b, at); err != nil {
				return p, err
			}
			st.counts[a]++
			st.counts[b]++
			p.project = append(p.project, b)
			p.mark(a, b, c.Kind)
			p.notice(socialinbox.RelationTransition{Event: socialinbox.AcceptRelationRequest, First: b, Second: a, Generation: r.value.Generation, Actor: a, Recipient: b, At: at})
		}
	case DeleteFriend:
		for _, b := range st.order {
			if !st.present[b] {
				continue
			}
			f := st.friends[pair(a, b)]
			if !f.exists || !f.value.Active {
				continue
			}
			old := f.value
			n := old
			var err error
			n.StateVersion, err = increment(old.StateVersion)
			if err != nil {
				return p, err
			}
			n.Active = false
			n.EndedAt = &at
			n.UpdatedAt = at
			p.friends = append(p.friends, writePlan[Friendship]{&old, n})
			p.mark(a, b, DeleteFriend)
			p.notice(socialinbox.RelationTransition{Event: socialinbox.DeleteRelationFriendship, First: old.PlayerLowID, Second: old.PlayerHighID, Generation: old.Generation, Actor: a, Recipient: b, At: at})
		}
	case AddBlock:
		b := c.Targets[0]
		if err := p.block(st.blocks[directed{a, b}], a, b, true, at); err != nil {
			return p, err
		}
		p.project = append(p.project, b)
	case RemoveBlock, ClearBlocks:
		for _, b := range st.order {
			if c.Kind != ClearBlocks && !st.present[b] {
				continue
			}
			old := st.blocks[directed{a, b}]
			if c.Kind == ClearBlocks && (!old.exists || !old.value.Active) {
				return p, ErrStateConflict
			}
			if err := p.block(old, a, b, false, at); err != nil {
				return p, err
			}
		}
		if c.Kind == ClearBlocks {
			p.touch = map[identity.PlayerID]bool{}
			if len(p.blocks) > 0 {
				p.touch[a] = true
			}
		}
	}
	ids := make([]identity.PlayerID, 0, len(p.changes))
	for pid := range p.changes {
		ids = append(ids, pid)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, pid := range ids {
		p.result.Changes = append(p.result.Changes, p.changes[pid])
	}
	return p, nil
}
func (st commandState) blocked(a, b identity.PlayerID) bool {
	x, y := st.blocks[directed{a, b}], st.blocks[directed{b, a}]
	return x.exists && x.value.Active || y.exists && y.value.Active
}
func (p commandPlan) preflight(roots map[identity.PlayerID]Root, at time.Time) error {
	check := func(times ...time.Time) error {
		for _, t := range times {
			if !t.IsZero() && at.Before(t) {
				return ErrStaleDecisionTime
			}
		}
		return nil
	}
	optional := func(t *time.Time) time.Time {
		if t == nil {
			return time.Time{}
		}
		return *t
	}
	for pid := range p.touch {
		r, ok := roots[pid]
		if !ok {
			return ErrStateConflict
		}
		if r.StateVersion == math.MaxInt64 {
			return ErrCounterOverflow
		}
		if err := check(r.CreatedAt, r.UpdatedAt); err != nil {
			return err
		}
	}
	for _, w := range p.friends {
		if w.old != nil {
			if err := check(w.old.ActivatedAt, w.old.UpdatedAt, optional(w.old.EndedAt)); err != nil {
				return err
			}
		}
		if err := w.next.Validate(); err != nil {
			return err
		}
	}
	for _, w := range p.requests {
		if w.old != nil {
			if err := check(w.old.RequestedAt, w.old.UpdatedAt, optional(w.old.TerminalAt)); err != nil {
				return err
			}
		}
		if err := w.next.Validate(); err != nil {
			return err
		}
	}
	for _, w := range p.blocks {
		if w.old != nil {
			if err := check(w.old.ActivatedAt, w.old.UpdatedAt, optional(w.old.RemovedAt)); err != nil {
				return err
			}
		}
		if err := w.next.Validate(); err != nil {
			return err
		}
	}
	if p.epoch != nil {
		if p.epoch.old != nil {
			if err := check(p.epoch.old.EpochStartedAt, p.epoch.old.UpdatedAt); err != nil {
				return err
			}
		}
		if err := p.epoch.next.Validate(); err != nil {
			return err
		}
	}
	return nil
}
func (p commandPlan) apply(ctx context.Context, t tx.Tx, store CommandStore, roots map[identity.PlayerID]Root, at time.Time) error {
	ids := make([]identity.PlayerID, 0, len(p.touch))
	for pid := range p.touch {
		ids = append(ids, pid)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, pid := range ids {
		if err := store.TouchRootTx(ctx, t, roots[pid], at); err != nil {
			return err
		}
	}
	for _, w := range p.friends {
		if err := store.PutFriendshipTx(ctx, t, w.old, w.next); err != nil {
			return err
		}
	}
	for _, w := range p.requests {
		if err := store.PutRequestTx(ctx, t, w.old, w.next); err != nil {
			return err
		}
	}
	for _, w := range p.blocks {
		if err := store.PutBlockTx(ctx, t, w.old, w.next); err != nil {
			return err
		}
	}
	if p.epoch != nil {
		if err := store.PutRequestEpochTx(ctx, t, p.epoch.old, p.epoch.next); err != nil {
			return err
		}
	}
	return nil
}
