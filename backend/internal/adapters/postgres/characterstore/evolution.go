package characterstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/domain/character"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"time"
)

// EvolutionStore is an intrinsic CharacterHero facet, serialized under existing
// population400/Hero410. It never owns a second Hero or lower-ranked player root.
type EvolutionStore struct{ Store }
type EvolutionHeroPort struct{ Store }

func (s EvolutionHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	h, e := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		e = app.ErrRetired
	}
	return h, e
}
func scanEvolution(row tx.Row) (evo.Facet, error) {
	var f evo.Facet
	var pid int64
	var raw string
	if e := row.Scan(&pid, &f.PartnerID, &f.Version, &f.PolicyID, &raw, &f.CreatedAt, &f.UpdatedAt); e != nil {
		if errors.Is(e, kernelstore.ErrNoRows) {
			return f, app.ErrUnavailable
		}
		return f, e
	}
	f.Player = identity.PlayerID(pid)
	d := json.NewDecoder(bytes.NewBufferString(raw))
	d.DisallowUnknownFields()
	if e := d.Decode(&f.Facts); e != nil {
		return f, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return f, evo.ErrUnqualified
	}
	if !f.Player.Valid() || f.PartnerID <= 0 || f.Version < 1 || f.PolicyID != evo.LifecyclePolicy || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) {
		return f, evo.ErrUnqualified
	}
	return f, nil
}

const evolutionCols = `player_id,partner_id,state_version,policy_id,facts::text,created_at,updated_at`

func (EvolutionStore) ReadHeroTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64) (evo.Facet, error) {
	return scanEvolution(q.QueryRow(c, `SELECT `+evolutionCols+` FROM player_hero_evolution WHERE player_id=$1 AND partner_id=$2`, int64(p), id))
}
func (EvolutionStore) LockHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (evo.Facet, error) {
	return scanEvolution(t.QueryRow(c, `SELECT `+evolutionCols+` FROM player_hero_evolution WHERE player_id=$1 AND partner_id=$2 FOR UPDATE`, int64(p), id))
}
func (EvolutionStore) SaveHeroTx(c context.Context, t tx.Tx, f evo.Facet, old int64) error {
	if old < 1 || f.Version != old+1 || f.Version < 1 || f.PolicyID != evo.LifecyclePolicy || f.Facts.Points == nil || f.Facts.Stage < 1 || f.Facts.Stage > 3 || f.UpdatedAt.Before(f.CreatedAt) {
		return evo.ErrUnqualified
	}
	raw, e := json.Marshal(f.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_hero_evolution SET facts=$3::jsonb,state_version=$4,updated_at=$5 WHERE player_id=$1 AND partner_id=$2 AND state_version=$6 AND policy_id=$7`, int64(f.Player), f.PartnerID, string(raw), f.Version, f.UpdatedAt, old, evo.LifecyclePolicy)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return evo.ErrUnqualified
	}
	return nil
}
func (EvolutionStore) EnsureHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64, at time.Time) error {
	if !p.Valid() || id < 1 || at.IsZero() {
		return evo.ErrUnqualified
	}
	raw, _ := json.Marshal(evo.Seed())
	_, e := t.Exec(c, `INSERT INTO player_hero_evolution(player_id,partner_id,state_version,policy_id,facts,created_at,updated_at)VALUES($1,$2,1,$3,$4::jsonb,$5,$5)ON CONFLICT(player_id,partner_id)DO NOTHING`, int64(p), id, evo.LifecyclePolicy, string(raw), at)
	return e
}
func (EvolutionStore) InitFreshHeroTx(c context.Context, t tx.Tx, ref character.HeroRef, at time.Time) error {
	if ref.Validate() != nil || at.IsZero() {
		return evo.ErrUnqualified
	}
	raw, _ := json.Marshal(evo.Seed())
	tag, e := t.Exec(c, `INSERT INTO player_hero_evolution(player_id,partner_id,state_version,policy_id,facts,created_at,updated_at)VALUES($1,$2,1,$3,$4::jsonb,$5,$5)`, int64(ref.PlayerID), ref.PartnerID, evo.LifecyclePolicy, string(raw), at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return evo.ErrUnqualified
	}
	return nil
}
