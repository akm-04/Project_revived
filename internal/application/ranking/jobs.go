package ranking

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R7_PRIVATE_RANK_REFRESH_PERIOD_V1 and R7_PRIVATE_RANK_LIST_SIZE_V1 are
// private tunables, not recovered original-server constants.
const RankRefreshPeriodPolicy = "R7_PRIVATE_RANK_REFRESH_PERIOD_V1"
const DefaultRankRefreshPeriod = 60 * time.Second

const refreshBatchSize = 50
const maxRefreshBatches = 200
const maxBackfillBatches = 100000

func (s Service) jobsReady() bool {
	return s.readReady()
}

func (s Service) now(c context.Context) (time.Time, error) {
	if s.Timed.Binder.Time == nil {
		return time.Time{}, ErrUnavailable
	}
	at, e := s.Timed.Binder.Time.Now(c)
	if e != nil {
		return time.Time{}, e
	}
	return at.UTC(), nil
}

func (s Service) activeRevision(c context.Context) (string, error) {
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil || rev == "" {
		return "", ErrUnavailable
	}
	return rev, nil
}

func groupPlayersByServer(roots []playerroot.Root) (map[identity.LogicalServerID][]identity.PlayerID, error) {
	out := map[identity.LogicalServerID][]identity.PlayerID{}
	seen := map[identity.PlayerID]bool{}
	for _, root := range roots {
		if root.Validate() != nil || seen[root.PlayerID] {
			return nil, ErrConflict
		}
		seen[root.PlayerID] = true
		out[root.LogicalServerID] = append(out[root.LogicalServerID], root.PlayerID)
	}
	for server := range out {
		sort.Slice(out[server], func(i, j int) bool { return out[server][i] < out[server][j] })
	}
	return out, nil
}

func bindScoreOperation(o operation.Context, b d.Board, rev string) (operation.Context, error) {
	o, e := bind(o, "content", rev)
	if e != nil {
		return o, e
	}
	o, e = bind(o, boardReceipts[b.Policy].metricPin, b.SourcePolicy)
	if e != nil {
		return o, e
	}
	return bind(o, "ranking", b.Policy)
}

func (s Service) runScoreTx(c context.Context, o operation.Context, b d.Board, server identity.LogicalServerID, players []identity.PlayerID, runs map[identity.PlayerID]d.ScoreRun, rev string) error {
	bound, e := bindScoreOperation(o, b, rev)
	if e != nil {
		return e
	}
	o = bound
	_, res, e := s.Timed.Run(c, o, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc gen.TimedScope) error {
		// A-030: each batch takes its own decision time, as the viewer read does;
		// a row a viewer stored after the job began must not fail validation.
		scope := ScoreScope{Scope: tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, Server: server}
		return s.refreshScores(c, scope, b, players, runs, rev, sc.Operation.DecisionAt())
	})
	if e != nil {
		return e
	}
	if res.Outcome != tx.DefiniteCommit {
		return ErrUnavailable
	}
	return nil
}

func (s Service) activityStale(c context.Context, players []identity.PlayerID, updates map[identity.PlayerID]time.Time) ([]identity.PlayerID, error) {
	latest := map[identity.PlayerID]time.Time{}
	merge := func(in map[identity.PlayerID]time.Time) {
		for id, at := range in {
			if at.After(latest[id]) {
				latest[id] = at
			}
		}
	}
	if s.Presence != nil {
		seen, e := s.Presence.LastSeenAtTx(c, s.Fresh, players)
		if e != nil {
			return nil, e
		}
		merge(seen)
	}
	if s.Login != nil {
		logins, e := s.Login.LastLoginAtTx(c, s.Fresh, players)
		if e != nil {
			return nil, e
		}
		merge(logins)
	}
	out := []identity.PlayerID{}
	for _, player := range players {
		activity, active := latest[player]
		if !active {
			continue
		}
		if updated, stored := updates[player]; !stored || activity.After(updated) {
			out = append(out, player)
		}
	}
	return out, nil
}

// RefreshActiveScores refreshes rows whose owner activity is newer than the
// stored row, for every generic board, in bounded player batches. The caller
// supplies the I4 enumeration so this package never scans all players.
func (s Service) RefreshActiveScores(c context.Context, o operation.Context, roots []playerroot.Root) error {
	if !s.jobsReady() || (s.Presence == nil && s.Login == nil) || o.ID.IsZero() || o.StartedAt.IsZero() {
		return ErrUnavailable
	}
	byServer, e := groupPlayersByServer(roots)
	if e != nil {
		return e
	}
	var failed []error
	for server := range byServer {
		failed = append(failed, s.RefreshActiveScoresServer(c, o, server, byServer[server]))
	}
	return errors.Join(failed...)
}

// refreshServer goes on past a failed board or batch, so one player cannot stop
// the rest of the server (A-030); every failure is returned at the end.
func (s Service) refreshServer(c context.Context, o operation.Context, players []identity.PlayerID, server identity.LogicalServerID, rev string) error {
	var failed []error
	for _, board := range d.Boards {
		updates, e := s.Store.ReadScoreRowUpdatesTx(c, s.Fresh, board.Policy, server)
		if e != nil {
			failed = append(failed, fmt.Errorf("ranking refresh %s: %w", board.Name, e))
			continue
		}
		for batch := 0; batch < maxRefreshBatches; batch++ {
			first := batch * refreshBatchSize
			if first >= len(players) {
				break
			}
			last := first + refreshBatchSize
			if last > len(players) {
				last = len(players)
			}
			stale, e := s.activityStale(c, players[first:last], updates)
			if e == nil && len(stale) > 0 {
				e = s.runScoreTx(c, o, board, server, stale, nil, rev)
			}
			if e != nil {
				failed = append(failed, fmt.Errorf("ranking refresh %s: %w", board.Name, e))
			}
		}
	}
	return errors.Join(failed...)
}

// RefreshActiveScoresServer scopes the activity refresh to one logical server.
func (s Service) RefreshActiveScoresServer(c context.Context, o operation.Context, server identity.LogicalServerID, players []identity.PlayerID) error {
	if !s.jobsReady() || (s.Presence == nil && s.Login == nil) || o.ID.IsZero() || o.StartedAt.IsZero() || !server.Valid() {
		return ErrUnavailable
	}
	rev, e := s.activeRevision(c)
	if e != nil {
		return e
	}
	return s.refreshServer(c, o, players, server, rev)
}

// BackfillScores seeds every player of every server for every board. A legacy
// board-root Run keeps its observation time when the score and revision agree.
func (s Service) BackfillScores(c context.Context, o operation.Context, roots []playerroot.Root) error {
	if !s.jobsReady() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return ErrUnavailable
	}
	byServer, e := groupPlayersByServer(roots)
	if e != nil {
		return e
	}
	var failed []error
	for server := range byServer {
		failed = append(failed, s.BackfillScoresServer(c, o, server, byServer[server]))
	}
	return errors.Join(failed...)
}

// BackfillScoresServer scopes the deploy backfill to one logical server.
func (s Service) BackfillScoresServer(c context.Context, o operation.Context, server identity.LogicalServerID, players []identity.PlayerID) error {
	if !s.jobsReady() || o.ID.IsZero() || o.StartedAt.IsZero() || !server.Valid() {
		return ErrUnavailable
	}
	var failed []error
	for _, board := range d.Boards {
		if e := s.BackfillBoardServer(c, o, board, server, players); e != nil {
			failed = append(failed, fmt.Errorf("ranking backfill %s: %w", board.Name, e))
		}
	}
	return errors.Join(failed...)
}

// BackfillBoardServer scopes the deploy backfill to one board of a server.
func (s Service) BackfillBoardServer(c context.Context, o operation.Context, board d.Board, server identity.LogicalServerID, players []identity.PlayerID) error {
	if !s.jobsReady() || o.ID.IsZero() || o.StartedAt.IsZero() || !server.Valid() {
		return ErrUnavailable
	}
	rev, e := s.activeRevision(c)
	if e != nil {
		return e
	}
	runs, e := s.Store.ReadBoardRootRunsTx(c, s.Fresh, board, server)
	if e != nil {
		return e
	}
	var failed []error
	for batch := 0; batch < maxBackfillBatches; batch++ {
		first := batch * refreshBatchSize
		if first >= len(players) {
			break
		}
		last := first + refreshBatchSize
		if last > len(players) {
			last = len(players)
		}
		failed = append(failed, s.runScoreTx(c, o, board, server, players[first:last], runs, rev))
		if last == len(players) {
			break
		}
	}
	return errors.Join(failed...)
}

// SettleBoardBoundaries settles the current week's board once, after
// processing any periods the old read-bound path left pending.
func (s Service) SettleBoardBoundaries(c context.Context, o operation.Context, roots []playerroot.Root) error {
	if !s.jobsReady() || s.Players == nil || s.Recipient == nil || s.Receipts == nil || s.ReceiptRead == nil || o.ID.IsZero() || o.StartedAt.IsZero() {
		return ErrUnavailable
	}
	byServer, e := groupPlayersByServer(roots)
	if e != nil {
		return e
	}
	var failed []error
	for server := range byServer {
		failed = append(failed, s.SettleBoardBoundariesServer(c, o, server))
	}
	return errors.Join(failed...)
}

// SettleBoardBoundariesServer scopes the weekly settlement to one logical server.
func (s Service) SettleBoardBoundariesServer(c context.Context, o operation.Context, server identity.LogicalServerID) error {
	if !s.jobsReady() || s.Players == nil || s.Recipient == nil || s.Receipts == nil || s.ReceiptRead == nil || o.ID.IsZero() || o.StartedAt.IsZero() || !server.Valid() {
		return ErrUnavailable
	}
	var failed []error
	for _, board := range d.Boards {
		if e := s.SettleBoardServer(c, o, board, server); e != nil {
			failed = append(failed, fmt.Errorf("ranking settle %s: %w", board.Name, e))
		}
	}
	return errors.Join(failed...)
}

// SettleBoardServer settles one board's current week for a server.
func (s Service) SettleBoardServer(c context.Context, o operation.Context, b d.Board, server identity.LogicalServerID) error {
	if !s.jobsReady() || s.Players == nil || s.Recipient == nil || s.Receipts == nil || s.ReceiptRead == nil || o.ID.IsZero() || o.StartedAt.IsZero() || !server.Valid() {
		return ErrUnavailable
	}
	now, e := s.now(c)
	if e != nil {
		return e
	}
	week, e := d.BoardWeek(now)
	if e != nil {
		return e
	}
	rev, e := s.activeRevision(c)
	if e != nil {
		return e
	}
	if _, e = s.SettlePendingBoard(c, b, server, o); e != nil {
		return e
	}
	return s.settleCurrentWeek(c, o, b, server, week, rev)
}

func (s Service) settleCurrentWeek(c context.Context, o operation.Context, board d.Board, server identity.LogicalServerID, week time.Time, rev string) error {
	p, ok, e := s.Store.ReadBoardPeriodTx(c, s.Fresh, board, server, week)
	if e != nil {
		return e
	}
	if ok {
		if p.SettledAt != nil {
			return nil
		}
		_, e = s.settleBoardPeriod(c, board, server, p, o)
		return e
	}
	bound, e := bindScoreOperation(o, board, rev)
	if e != nil {
		return e
	}
	freezeOperation, e := ids.NewUUID()
	if e != nil {
		return e
	}
	_, _, e = s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		root, e := s.Store.LockBoardRootTx(c, sc.Tx, board, server, at)
		if e != nil {
			return e
		}
		if observed, e := d.BoardWeek(at); e != nil || !observed.Equal(week) {
			return ErrConflict
		}
		// A concurrent settlement that held the root lock first already froze this week.
		_, frozen, e := s.Store.ReadBoardPeriodTx(c, sc.Tx, board, server, week)
		if e != nil {
			return e
		}
		if frozen {
			return nil
		}
		rows, e := s.Store.AllScoreRowsTx(c, sc.Tx, board.Policy, server)
		if e != nil {
			return e
		}
		players := make([]identity.PlayerID, 0, len(rows))
		for _, row := range rows {
			players = append(players, row.Player)
		}
		if len(players) > 0 {
			scope := ScoreScope{Scope: tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, Server: server}
			if e = s.refreshScores(c, scope, board, players, nil, rev, at); e != nil {
				return e
			}
		}
		rows, e = s.Store.AllScoreRowsTx(c, sc.Tx, board.Policy, server)
		if e != nil {
			return e
		}
		ids := make([]identity.PlayerID, 0, len(rows))
		for _, row := range rows {
			ids = append(ids, row.Player)
		}
		profiles, e := s.Directory.ProfilesTx(c, sc.Tx, ids)
		if e != nil {
			return e
		}
		entries := make([]d.BoardEntry, 0, len(rows))
		for _, row := range rows {
			p, ok := profiles[row.Player]
			if !ok || p.Validate() != nil || p.PlayerID != row.Player {
				return ErrConflict
			}
			entries = append(entries, d.BoardEntry{Metric: row.Metric, Display: d.BoardPresentation{Player: p.PlayerID, Name: p.Name, Level: p.Level, AvatarID: p.AvatarID, FrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID}, ScoreSince: row.ScoreSince})
		}
		next, snapshot, e := d.FreezeBoardSnapshot(root, at, rev, freezeOperation, entries)
		if e != nil {
			return e
		}
		if e = s.Store.InsertBoardSnapshotTx(c, sc.Tx, snapshot); e != nil {
			return e
		}
		if e = s.Store.BindBoardPeriodTx(c, sc.Tx, snapshot); e != nil {
			return e
		}
		return s.Store.SaveBoardRootTx(c, sc.Tx, next, root.StateVersion)
	})
	if e != nil {
		return e
	}
	p, ok, e = s.Store.ReadBoardPeriodTx(c, s.Fresh, board, server, week)
	if e != nil {
		return e
	}
	if !ok {
		return ErrConflict
	}
	if p.SettledAt != nil {
		return nil
	}
	_, e = s.settleBoardPeriod(c, board, server, p, o)
	return e
}
