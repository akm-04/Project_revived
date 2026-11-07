package librarystore

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ListHeroLogsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) ([]library.HeroLogFact, error) {
	if !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	return listFacts[library.HeroLogFact](ctx, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id,log_id),'[]'::jsonb)::text FROM player_library_hero_logs t WHERE player_id=$1`, int64(pid))
}

// RecordHeroLogTx is the cross-owner journal port used by the Character owner
// for star, promotion and awakening milestones.
func (s Store) RecordHeroLogTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, partnerID, logID int64, at time.Time) error {
	_, e := s.InsertHeroLogTx(ctx, t, library.HeroLogFact{PlayerID: pid, PartnerID: partnerID, LogID: logID, OccurredAt: at})
	return e
}

// InsertHeroLogTx records one milestone once. It reports whether this call
// inserted the row so the event owner can decide its reply.
func (Store) InsertHeroLogTx(ctx context.Context, t tx.Tx, f library.HeroLogFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_hero_logs(player_id,partner_id,log_id,occurred_at)VALUES($1,$2,$3,$4)ON CONFLICT(player_id,partner_id,log_id)DO NOTHING`, int64(f.PlayerID), f.PartnerID, f.LogID, f.OccurredAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}
