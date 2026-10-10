package publicationstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func (Store) InstallTx(c context.Context, t tx.Tx, s pub.Set, digest string) error {
	tag, e := t.Exec(c, `INSERT INTO publication_sets(set_id,family,server_id,starts_at,ends_at,input_digest) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(set_id) DO NOTHING`, s.ID.String(), s.Family, s.ServerID, s.StartsAt, s.EndsAt, digest)
	if e != nil {
		return e
	}
	var stored string
	if e = t.QueryRow(c, `SELECT input_digest FROM publication_sets WHERE set_id=$1`, s.ID.String()).Scan(&stored); e != nil {
		return e
	}
	if stored != digest {
		return pub.ErrRevisionConflict
	}
	if tag.RowsAffected() == 0 {
		return nil
	}
	for pos, item := range s.Items {
		b, e := json.Marshal(item)
		if e != nil {
			return e
		}
		var wire any
		if item.Board != nil {
			wire = item.Board.ID
		}
		if _, e = t.Exec(c, `INSERT INTO publication_items(set_id,position,board_wire_id,payload) VALUES($1,$2,$3,$4::jsonb)`, s.ID.String(), pos, wire, string(b)); e != nil {
			return e
		}
	}
	return nil
}
func (Store) SelectTx(c context.Context, q tx.Queryer, family string, server identity.LogicalServerID, at time.Time) (pub.Set, bool, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT COALESCE((SELECT jsonb_build_object('id',s.set_id,'family',s.family,'server_id',s.server_id,'starts_at',s.starts_at,'ends_at',s.ends_at,'items',COALESCE((SELECT jsonb_agg(i.payload ORDER BY i.position) FROM publication_items i WHERE i.set_id=s.set_id),'[]'::jsonb)) FROM publication_sets s WHERE s.family=$1 AND s.server_id IN(0,$2) AND s.starts_at<=$3 ORDER BY (s.server_id<>0) DESC,s.starts_at DESC,s.install_sequence DESC LIMIT 1),'null'::jsonb)`, family, int32(server), at).Scan(&raw)
	if e != nil {
		return pub.Set{}, false, e
	}
	if string(raw) == "null" {
		return pub.Set{}, false, nil
	}
	var s pub.Set
	if e = json.Unmarshal(raw, &s); e != nil {
		return pub.Set{}, false, e
	}
	if e = s.Validate(); e != nil {
		return pub.Set{}, false, e
	}
	visible := (s.EndsAt == nil || at.Before(*s.EndsAt)) && len(s.Items) > 0
	return s, visible, nil
}
func (Store) MarkerTx(c context.Context, q tx.Queryer, p identity.PlayerID, s ids.UUID) (bool, error) {
	var found bool
	e := q.QueryRow(c, `SELECT EXISTS(SELECT 1 FROM publication_picture_reads WHERE player_id=$1 AND set_id=$2)`, int64(p), s.String()).Scan(&found)
	return found, e
}
func (Store) LockMarkerTx(c context.Context, t tx.Tx, p identity.PlayerID, s ids.UUID) error {
	// Root315 already held by the application. The scalar subquery permits absence without manufacturing a marker.
	var at *time.Time
	return t.QueryRow(c, `SELECT (SELECT read_at FROM publication_picture_reads WHERE player_id=$1 AND set_id=$2 FOR UPDATE)`, int64(p), s.String()).Scan(&at)
}
func (Store) MarkTx(c context.Context, t tx.Tx, p identity.PlayerID, s ids.UUID, at time.Time) error {
	_, e := t.Exec(c, `INSERT INTO publication_picture_reads(player_id,set_id,read_at) VALUES($1,$2,$3) ON CONFLICT(player_id,set_id) DO NOTHING`, int64(p), s.String(), at)
	return e
}
func (Store) CheckSchema(c context.Context, q tx.Queryer) error {
	var ok bool
	e := q.QueryRow(c, `SELECT to_regclass('publication_sets') IS NOT NULL AND to_regclass('publication_items') IS NOT NULL AND to_regclass('publication_picture_reads') IS NOT NULL`).Scan(&ok)
	if e != nil {
		return e
	}
	if !ok {
		return errors.New("PUBLICATION_V1 schema unavailable")
	}
	return nil
}
