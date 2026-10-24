package achievement

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// NoticeRoute is the C4F_ACHIEVEMENT_NOTICE_V1 realtime wakeup route; its
// reference is the decimal player id.
const NoticeRoute = "achievement.notice.v1"

// NoticeParams is one notice 17 body for Achievement.handleNewAchievementNotice.
type NoticeParams struct {
	Entry
	PointLevel, TotalPoints, Rank int64
}

// TakeNotices marks every pending tier delivered and returns the current state
// of each noticed achievement once. Delivery is at most once: a failed push
// never re-sends, and never revokes a tier. Hidden rows stay silent because the
// client drops them from its list (private policy).
func (s Service) TakeNotices(c context.Context, p identity.PlayerID, parent operation.Context) ([]NoticeParams, error) {
	if s.Runtime == nil || s.Runtime.Timed.Runner.DB == nil || s.Runtime.Timed.Binder.Time == nil || s.Runtime.Fresh == nil || s.Runtime.Active == nil || s.Store == nil || s.Content == nil || !p.Valid() {
		return nil, d.ErrUnavailable
	}
	op, rev, e := s.child(c, parent, "notice")
	if e != nil {
		return nil, e
	}
	var out []NoticeParams
	_, _, e = s.Runtime.Timed.Run(c, op, Profile(), tx.Options{Isolation: tx.Serializable}, retry(), unresolved{}, func(c context.Context, sc gen.TimedScope) error {
		out = nil
		pending, e := s.Store.PendingNoticesTx(c, sc.Tx, p)
		if e != nil || len(pending) == 0 {
			return e
		}
		catalog, e := s.Content.AchievementCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		view, e := s.viewTx(c, sc.Tx, catalog, p)
		if e != nil {
			return e
		}
		hidden := map[int64]bool{}
		for _, row := range catalog.Rows {
			hidden[row.ID] = row.Hidden == 1
		}
		entries := map[int64]Entry{}
		for _, entry := range view.Entries {
			entries[entry.AchievementID] = entry
		}
		seen := map[int64]bool{}
		for _, n := range pending {
			entry, known := entries[n.AchievementID]
			if !known || hidden[n.AchievementID] || seen[n.AchievementID] {
				continue
			}
			seen[n.AchievementID] = true
			out = append(out, NoticeParams{Entry: entry, PointLevel: view.PointLevel, TotalPoints: view.TotalPoints, Rank: view.Rank})
		}
		return s.Store.MarkNoticesDeliveredTx(c, sc.Tx, p, sc.Operation.DecisionAt())
	})
	return out, e
}
