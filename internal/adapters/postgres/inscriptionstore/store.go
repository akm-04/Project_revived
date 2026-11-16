package inscriptionstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	inscription "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{ Queryer tx.Queryer }
type Root = inscription.Root

func scan(row tx.Row) (Root, error) {
	var r Root
	var p int64
	var raw string
	var version int16
	e := row.Scan(&p, &r.Version, &r.Revision, &raw, &version, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	e = payload.Decode("player_inscription_roots", version, []byte(raw), &r.Facts)
	if e != nil || !r.Player.Valid() || r.Version < 1 || len(r.Revision) != 64 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return r, inscription.ErrUnqualified
	}
	return r, nil
}

const cols = `player_id,state_version,creation_revision,facts::text,payload_version,created_at,updated_at`

func (Store) ReadRootTx(c context.Context, q tx.Queryer, p identity.PlayerID) (Root, error) {
	return scan(q.QueryRow(c, `SELECT `+cols+` FROM player_inscription_roots WHERE player_id=$1`, int64(p)))
}
func (Store) LockRootTx(c context.Context, t tx.Tx, p identity.PlayerID) (Root, error) {
	return scan(t.QueryRow(c, `SELECT `+cols+` FROM player_inscription_roots WHERE player_id=$1 FOR UPDATE`, int64(p)))
}
func (Store) SaveRootTx(c context.Context, t tx.Tx, r Root, old int64) error {
	if r.Version != old+1 {
		return inscription.ErrUnqualified
	}
	raw, version, e := payload.Encode(r.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_inscription_roots SET facts=$2::jsonb,payload_version=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`, int64(r.Player), string(raw), version, r.Version, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("inscription: stale root write")
	}
	return nil
}
func (Store) EnsureRootTx(c context.Context, t tx.Tx, p identity.PlayerID, rev string, at time.Time) error {
	if !p.Valid() || len(rev) != 64 || at.IsZero() {
		return inscription.ErrUnqualified
	}
	raw, version, e := payload.Encode(inscription.Seed())
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO player_inscription_roots(player_id,state_version,creation_revision,facts,payload_version,created_at,updated_at)VALUES($1,1,$2,$3::jsonb,$4,$5,$5)ON CONFLICT(player_id)DO NOTHING`, int64(p), rev, string(raw), version, at)
	return e
}

func scanHero(row tx.Row) (inscription.HeroRoot, error) {
	var r inscription.HeroRoot
	var p int64
	var raw string
	var version int16
	e := row.Scan(&p, &r.PartnerID, &r.Version, &raw, &version, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	if e = payload.Decode("player_inscription_heroes", version, []byte(raw), &r.Facts); e != nil {
		return r, e
	}
	if !r.Player.Valid() || r.PartnerID <= 0 || r.Version < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return r, inscription.ErrUnqualified
	}
	return r, nil
}

const heroCols = `player_id,partner_id,state_version,facts::text,payload_version,created_at,updated_at`

func (Store) ReadHeroTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64) (inscription.HeroRoot, error) {
	return scanHero(q.QueryRow(c, `SELECT `+heroCols+` FROM player_inscription_heroes WHERE player_id=$1 AND partner_id=$2`, int64(p), id))
}

// ListHeroesTx returns every Hero facet of one player in one owner read.
func (Store) ListHeroesTx(c context.Context, q tx.Queryer, p identity.PlayerID) ([]inscription.HeroRoot, error) {
	if q == nil || !p.Valid() {
		return nil, inscription.ErrUnqualified
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY partner_id),'[]'::jsonb)::text FROM player_inscription_heroes t WHERE player_id=$1`, int64(p)).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []struct {
		PlayerID       int64           `json:"player_id"`
		PartnerID      int64           `json:"partner_id"`
		StateVersion   int64           `json:"state_version"`
		Facts          json.RawMessage `json:"facts"`
		PayloadVersion int16           `json:"payload_version"`
		CreatedAt      time.Time       `json:"created_at"`
		UpdatedAt      time.Time       `json:"updated_at"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]inscription.HeroRoot, 0, len(rows))
	for _, row := range rows {
		var r inscription.HeroRoot
		r.Player, r.PartnerID, r.Version = identity.PlayerID(row.PlayerID), row.PartnerID, row.StateVersion
		r.CreatedAt, r.UpdatedAt = row.CreatedAt, row.UpdatedAt
		if e := payload.Decode("player_inscription_heroes", row.PayloadVersion, row.Facts, &r.Facts); e != nil {
			return nil, e
		}
		if !r.Player.Valid() || r.PartnerID <= 0 || r.Version < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
			return nil, inscription.ErrUnqualified
		}
		out = append(out, r)
	}
	return out, nil
}
func (Store) LockHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (inscription.HeroRoot, error) {
	return scanHero(t.QueryRow(c, `SELECT `+heroCols+` FROM player_inscription_heroes WHERE player_id=$1 AND partner_id=$2 FOR UPDATE`, int64(p), id))
}
func (Store) SaveHeroTx(c context.Context, t tx.Tx, r inscription.HeroRoot, old int64) error {
	if r.Version != old+1 {
		return inscription.ErrUnqualified
	}
	raw, version, e := payload.Encode(r.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_inscription_heroes SET facts=$3::jsonb,payload_version=$4,state_version=$5,updated_at=$6 WHERE player_id=$1 AND partner_id=$2 AND state_version=$7`, int64(r.Player), r.PartnerID, string(raw), version, r.Version, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("inscription: stale Hero write")
	}
	return nil
}
func (Store) EnsureHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64, at time.Time) error {
	if !p.Valid() || id <= 0 || at.IsZero() {
		return inscription.ErrUnqualified
	}
	raw, version, e := payload.Encode(inscription.SeedHero())
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO player_inscription_heroes(player_id,partner_id,state_version,facts,payload_version,created_at,updated_at)VALUES($1,$2,1,$3::jsonb,$4,$5,$5)ON CONFLICT(player_id,partner_id)DO NOTHING`, int64(p), id, string(raw), version, at)
	return e
}

func (Store) InitFreshHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, at time.Time) error {
	if ref.Validate() != nil || at.IsZero() {
		return inscription.ErrUnqualified
	}
	raw, version, e := payload.Encode(inscription.SeedHero())
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_inscription_heroes(player_id,partner_id,state_version,facts,payload_version,created_at,updated_at)VALUES($1,$2,1,$3::jsonb,$4,$5,$5)`, int64(ref.PlayerID), ref.PartnerID, string(raw), version, at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("inscription: fresh facet absent")
	}
	return nil
}
