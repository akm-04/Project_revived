package playerdisplay

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (s Service) Read(c context.Context, a identity.ActorContext, kind string, o operation.Context) (map[string]any, error) {
	if !s.valid(a, o) || (kind != "names" && kind != "titles" && kind != "bubbles") {
		return nil, ErrRequest
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return nil, e
	}
	at, e := s.Time.Now(c)
	if e != nil {
		return nil, e
	}
	var out map[string]any
	res, e := s.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		p, e := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Tx, rev)
		if e != nil {
			return e
		}
		if kind == "names" {
			out = map[string]any{"player_name_list": append([]string{}, p.Names...)}
			return nil
		}
		family, key := "title", "title_list"
		if kind == "bubbles" {
			family, key = "bubble", "bubble_list"
		}
		origins, e := s.origins(c, sc.Tx, a.PlayerID, family, rev, at)
		if e != nil {
			return e
		}
		items := []map[string]any{}
		seen := map[[2]int64]bool{}
		for _, o := range origins {
			original, e := s.Content.ReadPlayerDisplayCatalogTx(c, sc.Tx, o.Revision)
			if e != nil {
				return e
			}
			v, ok := original.Find(family, o.CatalogID)
			if !ok {
				return ErrConflict
			}
			end, e := v.EndTime(o.StartsAt, o.EndTime)
			if e != nil {
				return e
			}
			if !player.EligibleAt(end, at) {
				continue
			}
			id := [2]int64{o.CatalogID, o.UniqueID}
			if seen[id] {
				return ErrConflict
			}
			seen[id] = true
			row := map[string]any{"end_time": end}
			if family == "title" {
				row["title_id"] = o.CatalogID
				row["unique_id"] = o.UniqueID
			} else {
				row["bubble_id"] = o.CatalogID
			}
			items = append(items, row)
		}
		out = map[string]any{key: items}
		return nil
	})
	if e != nil {
		return nil, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return nil, ErrUnresolved
	}
	return out, nil
}

func (s Service) ReadEffectivePlayerDisplayTx(c context.Context, t tx.Queryer, pid identity.PlayerID, rev string, at time.Time) (i5.EffectivePlayerDisplay, error) {
	o, e := s.ObserveTx(c, t, pid, rev, at)
	if e != nil {
		return i5.EffectivePlayerDisplay{}, e
	}
	title := map[string]any{}
	if o.TitleID > 0 {
		title = map[string]any{"title_id": o.TitleID, "unique_id": o.TitleUniqueID, "end_time": o.TitleEndTime}
	}
	return i5.EffectivePlayerDisplay{AvatarID: o.AvatarID, AvatarFrameID: o.FrameID, TitleInfo: title, BubbleInfo: map[string]any{"bubble_id": o.BubbleID, "end_time": o.BubbleEndTime}, ProfileVersion: o.ProfileVersion, ProgressionVersion: o.ProgressionVersion, ContentRevision: rev, ObservedAt: at}, nil
}
