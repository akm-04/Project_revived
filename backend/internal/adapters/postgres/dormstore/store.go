package dormstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{ Queryer tx.Queryer }

func one(tag tx.CommandTag, what string) error {
	if tag.RowsAffected() != 1 {
		return errors.New("dorm: stale " + what)
	}
	return nil
}
func scanRoot(row tx.Row) (dorm.Root, error) {
	var r dorm.Root
	var p int64
	e := row.Scan(&p, &r.NextHouseID, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	return r, r.Validate()
}

const rootColumns = `player_id,next_house_id,state_version,created_at,updated_at`

func (Store) ReadRootTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (dorm.Root, error) {
	return scanRoot(q.QueryRow(ctx, `SELECT `+rootColumns+` FROM player_dorm_roots WHERE player_id=$1`, int64(pid)))
}
func (Store) LockRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (dorm.Root, error) {
	return scanRoot(t.QueryRow(ctx, `SELECT `+rootColumns+` FROM player_dorm_roots WHERE player_id=$1 FOR UPDATE`, int64(pid)))
}
func (Store) SaveRootTx(ctx context.Context, t tx.Tx, r dorm.Root, old int64) error {
	if r.Validate() != nil || r.StateVersion != old+1 {
		return dorm.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `UPDATE player_dorm_roots SET next_house_id=$2,state_version=$3,updated_at=$4 WHERE player_id=$1 AND state_version=$5`, int64(r.Player), r.NextHouseID, r.StateVersion, r.UpdatedAt, old)
	if e != nil {
		return e
	}
	return one(tag, "root")
}

const roomColumns = `player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record::text,pending_expansion::text,payload_version,last_enter_at,created_at,updated_at`

func scanRoom(row tx.Row) (dorm.Room, error) {
	var r dorm.Room
	var p int64
	var layout string
	var pending *string
	var version int16
	var last *time.Time
	e := row.Scan(&p, &r.ID, &r.TableID, &r.MainType, &r.CreationRevision, &r.Floor, &r.Position, &r.Comfort, &r.ExpansionLevel, &r.StateVersion, &layout, &pending, &version, &last, &r.CreatedAt, &r.UpdatedAt)
	if e != nil {
		return r, e
	}
	r.Player = identity.PlayerID(p)
	if e = payload.Decode("player_dorm_rooms", version, []byte(layout), &r.Layout); e != nil {
		return r, e
	}
	if pending != nil {
		var x dorm.Expansion
		if e = payload.Decode("player_dorm_rooms", version, []byte(*pending), &x); e != nil {
			return r, e
		}
		r.Pending = &x
	}
	if last != nil {
		r.LastEnterAt = last.UTC()
	}
	return r, r.Validate()
}
func (s Store) ReadRoomTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (dorm.Room, error) {
	r, e := scanRoom(q.QueryRow(ctx, `SELECT `+roomColumns+` FROM player_dorm_rooms WHERE player_id=$1 AND house_id=$2`, int64(pid), id))
	if e != nil {
		return r, e
	}
	var ids string
	if e = q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(partner_id ORDER BY partner_id),'[]'::jsonb)::text FROM player_dorm_heroes WHERE player_id=$1 AND house_id=$2`, int64(pid), id).Scan(&ids); e != nil {
		return r, e
	}
	e = json.Unmarshal([]byte(ids), &r.Residents)
	return r, e
}
func (s Store) ListRoomsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (map[int64]dorm.Room, error) {
	var raw string
	if e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(house_id ORDER BY house_id),'[]'::jsonb)::text FROM player_dorm_rooms WHERE player_id=$1`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	var ids []int64
	if e := json.Unmarshal([]byte(raw), &ids); e != nil {
		return nil, e
	}
	out := map[int64]dorm.Room{}
	for _, id := range ids {
		r, e := s.ReadRoomTx(ctx, q, pid, id)
		if e != nil {
			return nil, e
		}
		out[id] = r
	}
	return out, nil
}
func roomJSON(r dorm.Room) (string, any, int16, error) {
	if r.Validate() != nil {
		return "", nil, 0, dorm.ErrInvalidFacts
	}
	layout, version, e := payload.Encode(r.Layout)
	if e != nil {
		return "", nil, 0, e
	}
	var pending any
	if r.Pending != nil {
		x, _, e := payload.Encode(r.Pending)
		if e != nil {
			return "", nil, 0, e
		}
		pending = string(x)
	}
	return string(layout), pending, version, nil
}
func nullableTime(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t.UTC()
}
func (Store) InsertRoomTx(ctx context.Context, t tx.Tx, r dorm.Room) error {
	layout, pending, version, e := roomJSON(r)
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,pending_expansion,payload_version,last_enter_at,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12::jsonb,$13,$14,$15,$16)`, int64(r.Player), r.ID, r.TableID, r.MainType, r.CreationRevision, r.Floor, r.Position, r.Comfort, r.ExpansionLevel, r.StateVersion, layout, pending, version, nullableTime(r.LastEnterAt), r.CreatedAt, r.UpdatedAt)
	if e != nil {
		return e
	}
	return one(tag, "room insert")
}
func (Store) SaveRoomTx(ctx context.Context, t tx.Tx, r dorm.Room, old int64) error {
	layout, pending, version, e := roomJSON(r)
	if e != nil {
		return e
	}
	if r.StateVersion != old+1 {
		return dorm.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `UPDATE player_dorm_rooms SET comfort=$3,expansion_level=$4,state_version=$5,furniture_record=$6::jsonb,pending_expansion=$7::jsonb,payload_version=$8,last_enter_at=$9,updated_at=$10 WHERE player_id=$1 AND house_id=$2 AND state_version=$11`, int64(r.Player), r.ID, r.Comfort, r.ExpansionLevel, r.StateVersion, layout, pending, version, nullableTime(r.LastEnterAt), r.UpdatedAt, old)
	if e != nil {
		return e
	}
	return one(tag, "room update")
}

const heroColumns = `player_id,partner_id,house_id,state_version,equipment::text,payload_version,lounge_anchor,lounge_fraction,updated_at`

func scanHero(row tx.Row) (dorm.HeroFacts, error) {
	var f dorm.HeroFacts
	var p int64
	var house *int64
	var version int16
	var anchor *time.Time
	var raw string
	e := row.Scan(&p, &f.PartnerID, &house, &f.StateVersion, &raw, &version, &anchor, &f.LoungeFraction, &f.UpdatedAt)
	if e != nil {
		return f, e
	}
	f.Player = identity.PlayerID(p)
	if house != nil {
		f.HouseID = *house
	}
	if anchor != nil {
		f.LoungeAnchor = anchor.UTC()
	}
	var flags []int64
	if e = payload.Decode("player_dorm_heroes", version, []byte(raw), &flags); e != nil {
		return f, e
	}
	if len(flags) != 5 {
		return f, dorm.ErrInvalidFacts
	}
	copy(f.Equipment[:], flags)
	return f, f.Validate()
}
func (Store) ReadHeroTx(ctx context.Context, q tx.Queryer, ref character.HeroRef) (dorm.HeroFacts, error) {
	if ref.Validate() != nil {
		return dorm.HeroFacts{}, dorm.ErrInvalidFacts
	}
	return scanHero(q.QueryRow(ctx, `SELECT `+heroColumns+` FROM player_dorm_heroes WHERE player_id=$1 AND partner_id=$2`, int64(ref.PlayerID), ref.PartnerID))
}
func (Store) SaveHeroTx(ctx context.Context, t tx.Tx, f dorm.HeroFacts, old int64) error {
	if f.Validate() != nil || f.StateVersion != old+1 {
		return dorm.ErrInvalidFacts
	}
	raw, version, e := payload.Encode(f.Equipment)
	if e != nil {
		return e
	}
	var house any
	if f.HouseID > 0 {
		house = f.HouseID
	}
	tag, e := t.Exec(ctx, `UPDATE player_dorm_heroes SET house_id=$3,state_version=$4,equipment=$5::jsonb,payload_version=$6,lounge_anchor=$7,lounge_fraction=$8,updated_at=$9 WHERE player_id=$1 AND partner_id=$2 AND state_version=$10`, int64(f.Player), f.PartnerID, house, f.StateVersion, string(raw), version, nullableTime(f.LoungeAnchor), f.LoungeFraction, f.UpdatedAt, old)
	if e != nil {
		return e
	}
	return one(tag, "Hero facet")
}

// Controlled backfill and unpublished fresh creation only. ON CONFLICT never
// overwrites canonical imported/working facts; normal reads never call these.
func (s Store) EnsureRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, revision string, now time.Time) error {
	if !pid.Valid() || !dorm.ValidRevision(revision) || now.IsZero() {
		return dorm.ErrInvalidFacts
	}
	if _, e := t.Exec(ctx, `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at)VALUES($1,2,1,$2,$2)ON CONFLICT(player_id)DO NOTHING`, int64(pid), now.UTC()); e != nil {
		return e
	}
	layout, version, e := payload.Encode(map[string]string{})
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,payload_version,created_at,updated_at)VALUES($1,1,1000001,1,$2,1,1,0,0,1,$3::jsonb,$4,$5,$5)ON CONFLICT(player_id,house_id)DO NOTHING`, int64(pid), revision, string(layout), version, now.UTC())
	return e
}
func (Store) InitFreshHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, now time.Time) error {
	if ref.Validate() != nil || now.IsZero() {
		return dorm.ErrInvalidFacts
	}
	equipment, version, e := payload.Encode([5]int64{})
	if e != nil {
		return e
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_dorm_heroes(player_id,partner_id,house_id,state_version,equipment,payload_version,lounge_anchor,lounge_fraction,created_at,updated_at)VALUES($1,$2,NULL,1,$3::jsonb,$4,NULL,0,$5,$5)`, int64(ref.PlayerID), ref.PartnerID, string(equipment), version, now.UTC())
	if e != nil {
		return e
	}
	return one(tag, "fresh Hero facet")
}
func (Store) EnsureHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, now time.Time) error {
	if ref.Validate() != nil || now.IsZero() {
		return dorm.ErrInvalidFacts
	}
	equipment, version, e := payload.Encode([5]int64{})
	if e != nil {
		return e
	}
	_, e = t.Exec(ctx, `INSERT INTO player_dorm_heroes(player_id,partner_id,house_id,state_version,equipment,payload_version,lounge_anchor,lounge_fraction,created_at,updated_at)VALUES($1,$2,NULL,1,$3::jsonb,$4,NULL,0,$5,$5)ON CONFLICT(player_id,partner_id)DO NOTHING`, int64(ref.PlayerID), ref.PartnerID, string(equipment), version, now.UTC())
	return e
}
