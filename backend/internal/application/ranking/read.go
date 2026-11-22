package ranking

import (
	"context"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BoardListSizePolicy is the labelled private tunable for the published top
// rows. The value is a server choice, not recovered original behavior.
const BoardListSizePolicy = "R7_PRIVATE_RANK_LIST_SIZE_V1"
const DefaultBoardListSize int64 = 100

// ScoreScope is the writer's board scope: the caller transaction witness plus
// the logical server its rows belong to.
type ScoreScope struct {
	tx.Scope
	Server identity.LogicalServerID
}

// BoardRead is one stored-score board page plus the viewer's own rank.
type BoardRead struct {
	Board    d.Board
	Server   identity.LogicalServerID
	Rows     []d.ScoreRow
	Displays map[identity.PlayerID]d.BoardPresentation
	MyRank   int64
	MyScore  int64
}

func (s Service) readReady() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Fresh != nil && s.Store != nil && s.Directory != nil && s.Metrics != nil && s.Content != nil && s.Fence != nil
}

// RefreshScoresTx rewrites the stored rows of the given players with the same
// metric owners the snapshot path used. A player without an owned fact loses
// the row; score_since follows the domain current-value run rule.
func (s Service) RefreshScoresTx(c context.Context, scope ScoreScope, b d.Board, players []identity.PlayerID, rev string, at time.Time) error {
	return s.refreshScores(c, scope, b, players, nil, rev, at)
}

func (s Service) refreshScores(c context.Context, scope ScoreScope, b d.Board, players []identity.PlayerID, runs map[identity.PlayerID]d.ScoreRun, rev string, at time.Time) error {
	if scope.Tx == nil || !scope.Server.Valid() || scope.Operation.ID.IsZero() || scope.Attempt <= 0 || len(players) == 0 || at.Unix() <= 0 || s.Store == nil || s.Metrics == nil {
		return ErrUnavailable
	}
	if _, e := ca.NewCoherentReadScope(scope.Scope, rev, at); e != nil {
		return e
	}
	seen := map[identity.PlayerID]bool{}
	for _, player := range players {
		if !player.Valid() || seen[player] {
			return ErrConflict
		}
		seen[player] = true
		m, e := s.boardMetric(c, b, scope.Scope, player, rev, at)
		if e != nil {
			return e
		}
		if m.Player == 0 {
			if e = s.Store.DeleteScoreRowTx(c, scope.Tx, b.Policy, player); e != nil {
				return e
			}
			continue
		}
		prev, ok, e := s.Store.ReadScoreRowTx(c, scope.Tx, b.Policy, player)
		if e != nil {
			return e
		}
		var prior *d.ScoreRow
		if ok {
			if prev.Server != scope.Server || prev.Player != player {
				return ErrConflict
			}
			prior = &prev
		} else if run, has := runs[player]; has && run.Score == m.Value && run.Revision == rev && run.Since.Unix() > 0 && !run.Since.After(at) {
			prior = &d.ScoreRow{Score: run.Score, Revision: run.Revision, ScoreSince: run.Since}
		}
		row, e := d.NextScoreRow(prior, m, at)
		if e != nil {
			return e
		}
		row.Server = scope.Server
		if e = s.Store.UpsertScoreRowTx(c, scope.Tx, row); e != nil {
			return e
		}
	}
	return nil
}

// ReadBoard refreshes the viewer's own row in one short transaction, then
// reads the published page without a snapshot, receipt or board-root lock.
func (s Service) ReadBoard(c context.Context, b d.Board, a identity.ActorContext, o operation.Context) (BoardRead, error) {
	var out BoardRead
	if _, known := boardReceipts[b.Policy]; !known || !s.readReady() || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || o.ID.IsZero() || o.StartedAt.IsZero() {
		return out, ErrUnavailable
	}
	bound, rev, e := s.bindRefresh(c, b, o)
	if e != nil {
		return out, e
	}
	_, _, e = s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}, nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		scope := ScoreScope{Scope: tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, Server: a.LogicalServerID}
		return s.RefreshScoresTx(c, scope, b, []identity.PlayerID{a.PlayerID}, rev, at)
	})
	if e != nil {
		return out, e
	}
	limit := s.ListSize
	if limit <= 0 {
		limit = DefaultBoardListSize
	}
	// The board's own limit is an upper cap, never a lower floor.
	if b.Limit > 0 && b.Limit < limit {
		limit = b.Limit
	}
	_, _, e = s.Timed.Run(c, bound, Profile(), tx.Options{Isolation: tx.ReadCommitted, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc gen.TimedScope) error {
		rows, e := s.Store.TopScoreRowsTx(c, sc.Tx, b.Policy, a.LogicalServerID, limit)
		if e != nil {
			return e
		}
		mine, ok, e := s.Store.ReadScoreRowTx(c, sc.Tx, b.Policy, a.PlayerID)
		if e != nil {
			return e
		}
		if ok && (mine.Server != a.LogicalServerID || mine.Player != a.PlayerID) {
			return ErrConflict
		}
		players := make([]identity.PlayerID, 0, len(rows))
		for _, row := range rows {
			players = append(players, row.Player)
		}
		profiles, e := s.Directory.ProfilesTx(c, sc.Tx, players)
		if e != nil {
			return e
		}
		displays := make(map[identity.PlayerID]d.BoardPresentation, len(profiles))
		for id, p := range profiles {
			displays[id] = d.BoardPresentation{Player: p.PlayerID, Name: p.Name, Level: p.Level, AvatarID: p.AvatarID, FrameID: p.AvatarFrameID, ConquerLevel: p.ConquerLevel, ConquerLoopID: p.ConquerLoopID}
		}
		out = BoardRead{Board: b, Server: a.LogicalServerID, Rows: rows, Displays: displays}
		if ok {
			rank, e := s.Store.ScoreRankTx(c, sc.Tx, b.Policy, a.LogicalServerID, mine)
			if e != nil {
				return e
			}
			out.MyRank, out.MyScore = rank+1, mine.Score
		}
		return nil
	})
	if e != nil {
		return BoardRead{}, e
	}
	return out, nil
}
