package herorecommend

import (
	"context"
	"errors"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Overview returns the 2497 body from the current weekly snapshot.
func (s Service) Overview(ctx context.Context, a identity.ActorContext, o operation.Context) (map[string]any, error) {
	snapshot, err := s.Snapshot(ctx, a, o)
	if err != nil {
		return nil, err
	}
	return map[string]any{"sub_rank_list": snapshot.Overview.SubRankList, "total_rank_list": snapshot.Overview.TotalRankList}, nil
}

// Detail returns the 2498 body, or an empty object when the hero has no record.
func (s Service) Detail(ctx context.Context, a identity.ActorContext, o operation.Context, tableID int64) (map[string]any, error) {
	if tableID <= 0 {
		return nil, d.ErrRefused
	}
	snapshot, err := s.Snapshot(ctx, a, o)
	if err != nil {
		return nil, err
	}
	detail, found := snapshot.Details[strconv.FormatInt(tableID, 10)]
	if !found {
		return map[string]any{}, nil
	}
	forceInfo := map[string]any{"top_player_info": cardBody(detail.TopPlayer, 0), "top_hero_info": detail.TopHero}
	if detail.Formations == nil {
		detail.Formations = map[string]any{}
	}
	body := map[string]any{"recommend_score": detail.Score, "force_info": forceInfo, "recommend_formations": detail.Formations}
	force, owned, err := s.viewerForce(ctx, a, o, tableID)
	if err != nil {
		return nil, err
	}
	if owned {
		forceInfo["my_hero_info"] = map[string]any{"force": force}
		forceInfo["exceed_percent"] = exceedPercent(detail.ForceRows, force)
	}
	return body, nil
}

// ScoresTx is the read-only MID1 detail source for the flat score map. Every
// origin catalogue id is present so no client lookup can be nil; a hero absent
// from the accepted weekly snapshot is 0. It never builds a snapshot.
func (s Service) ScoresTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time) (map[string]int64, error) {
	if q == nil || !server.Valid() || at.IsZero() || s.Content == nil || s.Store == nil {
		return nil, d.ErrUnavailable
	}
	revision, err := s.Content.ActiveRevision(ctx, q)
	if err != nil {
		return nil, err
	}
	origins, err := s.Content.HeroOriginCatalogTx(ctx, q, revision)
	if err != nil {
		return nil, err
	}
	scores := make(map[string]int64, len(origins))
	for _, tableID := range origins {
		scores[strconv.FormatInt(tableID, 10)] = 0
	}
	snapshot, current, err := s.Store.LatestSnapshotTx(ctx, q, server)
	if errors.Is(err, d.ErrUnavailable) {
		current, err = false, nil
	}
	if err != nil {
		return nil, err
	}
	if !current || !servingGeneration(snapshot.Generation, at) {
		return scores, nil
	}
	for _, row := range snapshot.Overview.TotalRankList {
		key := strconv.FormatInt(rowNumber(row, "table_id"), 10)
		if _, known := scores[key]; known {
			scores[key] = rowNumber(row, "recommend_score")
		}
	}
	return scores, nil
}

// servingGeneration mirrors the generation rule ensureSnapshot applies.
func servingGeneration(generation int64, at time.Time) bool {
	return generation == WeekStart(at).Unix() || generation == LegacyWeekStart(at).Unix()
}

// ForceRank returns the 2499 body. An unknown but positive hero id yields an
// empty board with an object my_rank, which the rank window can index safely.
func (s Service) ForceRank(ctx context.Context, a identity.ActorContext, o operation.Context, tableID int64) (map[string]any, error) {
	if tableID <= 0 {
		return nil, d.ErrRefused
	}
	snapshot, err := s.Snapshot(ctx, a, o)
	if err != nil {
		return nil, err
	}
	rows := []d.ForceRow{}
	if detail, found := snapshot.Details[strconv.FormatInt(tableID, 10)]; found {
		rows = detail.ForceRows
	}
	rankList := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		rankList = append(rankList, cardBody(row.Player, row.Force))
	}
	myRank := map[string]any{"rank": int64(0), "force": int64(0)}
	force, owned, err := s.viewerForce(ctx, a, o, tableID)
	if err != nil {
		return nil, err
	}
	if owned {
		rank := int64(1)
		for _, row := range rows {
			if row.Force > force {
				rank++
			}
		}
		myRank = map[string]any{"rank": rank, "force": force}
	}
	return map[string]any{"my_rank": myRank, "rank_list": rankList}, nil
}

func (s Service) viewerForce(ctx context.Context, a identity.ActorContext, o operation.Context, tableID int64) (int64, bool, error) {
	var force int64
	var owned bool
	_, _, err := s.Timed.Run(ctx, o, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(ctx context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		rows, err := s.rosterRows(ctx, sc.Tx, a.PlayerID, at)
		if err != nil {
			return err
		}
		var partnerID int64
		for _, value := range rows {
			row, ok := value.(map[string]any)
			if ok && (rowNumber(row, "table_id") == tableID || recommendationTableID(row) == tableID) {
				partnerID = rowNumber(row, "partner_id")
				break
			}
		}
		if partnerID <= 0 {
			return nil
		}
		revision, err := s.Content.ActiveRevision(ctx, sc.Tx)
		if err != nil {
			return err
		}
		operationContext, err := pinContent(sc.Operation.Operation(), revision)
		if err != nil {
			return err
		}
		scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: operationContext, Attempt: sc.Attempt, Options: sc.Options}, revision, at)
		if err != nil {
			return err
		}
		force, err = s.heroForce(ctx, scope, a.PlayerID, partnerID)
		if err != nil {
			return err
		}
		owned = true
		return nil
	})
	if err != nil {
		return 0, false, err
	}
	return force, owned, nil
}

func exceedPercent(rows []d.ForceRow, force int64) float64 {
	if len(rows) == 0 {
		return 0
	}
	below := 0
	for _, row := range rows {
		if row.Force < force {
			below++
		}
	}
	return float64(below) / float64(len(rows))
}

func cardBody(card d.PlayerCard, force int64) map[string]any {
	body := map[string]any{"player_id": card.PlayerID, "player_name": card.Name, "lev": card.Level, "level": card.Level,
		"conquer_lev": card.ConquerLevel, "conquer_loop_id": card.ConquerLoopID, "avatar_id": card.AvatarID,
		"avatar_frame_id": card.AvatarFrameID, "region": card.Region, "guild_id": card.GuildID, "force": force}
	if card.GuildName != "" {
		body["guild_name"] = card.GuildName
	}
	return body
}
