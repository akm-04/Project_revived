package elementstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	elementequipment "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{ Queryer tx.Queryer }
type Root = elementequipment.Root

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
	e = payload.Decode("player_element_roots", version, []byte(raw), &r.Facts)
	if e != nil || !r.Player.Valid() || r.Version < 1 || len(r.Revision) != 64 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return r, elementequipment.ErrUnqualified
	}
	return r, nil
}

const cols = `player_id,state_version,creation_revision,facts::text,payload_version,created_at,updated_at`

func (Store) ReadRootTx(c context.Context, q tx.Queryer, p identity.PlayerID) (Root, error) {
	return scan(q.QueryRow(c, `SELECT `+cols+` FROM player_element_roots WHERE player_id=$1`, int64(p)))
}
func (Store) LockRootTx(c context.Context, t tx.Tx, p identity.PlayerID) (Root, error) {
	return scan(t.QueryRow(c, `SELECT `+cols+` FROM player_element_roots WHERE player_id=$1 FOR UPDATE`, int64(p)))
}
func (Store) SaveRootTx(c context.Context, t tx.Tx, r Root, old int64) error {
	if r.Version != old+1 {
		return elementequipment.ErrUnqualified
	}
	raw, version, e := payload.Encode(r.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_element_roots SET facts=$2::jsonb,payload_version=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`, int64(r.Player), string(raw), version, r.Version, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("elementequipment: stale root write")
	}
	return nil
}
func (Store) EnsureRootTx(c context.Context, t tx.Tx, p identity.PlayerID, rev string, at time.Time) error {
	if !p.Valid() || len(rev) != 64 || at.IsZero() {
		return elementequipment.ErrUnqualified
	}
	raw, version, e := payload.Encode(elementequipment.Seed())
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO player_element_roots(player_id,state_version,creation_revision,facts,payload_version,created_at,updated_at)VALUES($1,1,$2,$3::jsonb,$4,$5,$5)ON CONFLICT(player_id)DO NOTHING`, int64(p), rev, string(raw), version, at)
	return e
}

func scanHero(row tx.Row) (elementequipment.HeroRoot, error) {
	var r elementequipment.HeroRoot
	var p int64
	var raw string
	var version int16
	e := row.Scan(&p, &r.PartnerID, &r.Version, &raw, &version, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	if e = payload.Decode("player_element_heroes", version, []byte(raw), &r.Facts); e != nil {
		return r, e
	}
	if !r.Player.Valid() || r.PartnerID <= 0 || r.Version < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return r, elementequipment.ErrUnqualified
	}
	return r, nil
}

const heroCols = `player_id,partner_id,state_version,facts::text,payload_version,created_at,updated_at`

func (Store) ReadHeroTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64) (elementequipment.HeroRoot, error) {
	return scanHero(q.QueryRow(c, `SELECT `+heroCols+` FROM player_element_heroes WHERE player_id=$1 AND partner_id=$2`, int64(p), id))
}
func (Store) LockHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (elementequipment.HeroRoot, error) {
	return scanHero(t.QueryRow(c, `SELECT `+heroCols+` FROM player_element_heroes WHERE player_id=$1 AND partner_id=$2 FOR UPDATE`, int64(p), id))
}
func (Store) SaveHeroTx(c context.Context, t tx.Tx, r elementequipment.HeroRoot, old int64) error {
	if r.Version != old+1 {
		return elementequipment.ErrUnqualified
	}
	raw, version, e := payload.Encode(r.Facts)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE player_element_heroes SET facts=$3::jsonb,payload_version=$4,state_version=$5,updated_at=$6 WHERE player_id=$1 AND partner_id=$2 AND state_version=$7`, int64(r.Player), r.PartnerID, string(raw), version, r.Version, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("elementequipment: stale Hero write")
	}
	return nil
}
func (Store) EnsureHeroTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64, at time.Time) error {
	if !p.Valid() || id <= 0 || at.IsZero() {
		return elementequipment.ErrUnqualified
	}
	raw, version, e := payload.Encode(elementequipment.SeedHero())
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO player_element_heroes(player_id,partner_id,state_version,facts,payload_version,created_at,updated_at)VALUES($1,$2,1,$3::jsonb,$4,$5,$5)ON CONFLICT(player_id,partner_id)DO NOTHING`, int64(p), id, string(raw), version, at)
	return e
}

func (Store) InitFreshHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, at time.Time) error {
	if ref.Validate() != nil || at.IsZero() {
		return elementequipment.ErrUnqualified
	}
	raw, version, e := payload.Encode(elementequipment.SeedHero())
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_element_heroes(player_id,partner_id,state_version,facts,payload_version,created_at,updated_at)VALUES($1,$2,1,$3::jsonb,$4,$5,$5)`, int64(ref.PlayerID), ref.PartnerID, string(raw), version, at)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("elementequipment: fresh facet absent")
	}
	return nil
}
