package arena

import (
	"context"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SeasonPicksTx is the ARENA_HERO_PICKS_V1 read for the hero roster: per base
// (pre-awaken) table id, the ranked attack fights this season in which the girl
// was in the attacking team. The stored season is rolled at the decision
// instant without saving it, so a stale row counts 0 until the next arena write.
func (s Service) SeasonPicksTx(c context.Context, q tx.Queryer, player identity.PlayerID) (map[int64]int64, error) {
	if !s.ready() {
		return nil, d.ErrUnavailable
	}
	revision, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return nil, err
	}
	templates, err := s.Content.ArenaTemplatesTx(c, q, revision)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	p, found, err := s.Store.ReadPlayerTx(c, q, player, false)
	if err != nil {
		return nil, err
	}
	if !found {
		return map[int64]int64{}, nil
	}
	usage, err := s.Store.UsageTx(c, q, player, catalog.Rolled(p, at).Season)
	if err != nil {
		return nil, err
	}
	return seasonPickCounts(usage, templates), nil
}

func seasonPickCounts(usage []d.Usage, templates d.Templates) map[int64]int64 {
	counts := make(map[int64]int64, len(usage))
	for _, row := range usage {
		counts[templates.Base(row.TableID)] += row.Fights
	}
	return counts
}
