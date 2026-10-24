// Package leaguestore exclusively persists ChampionsLeague facts. Every
// gameplay writer holds the global competition row (mode lock rank604).
package leaguestore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/championsleague"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
)

type Store struct{}

func read(c context.Context, q tx.Queryer, sql string, dst any, args ...any) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var raw *string
	e := q.QueryRow(c, sql, args...).Scan(&raw)
	if errors.Is(e, kernelstore.ErrNoRows) || e == nil && raw == nil {
		return false, nil
	}
	if e != nil {
		return false, e
	}
	dec := json.NewDecoder(strings.NewReader(*raw))
	dec.UseNumber()
	return true, dec.Decode(dst)
}
func enc(v any) (string, error) { b, e := json.Marshal(v); return string(b), e }
func one(t tx.CommandTag, e error) error {
	if e != nil {
		return e
	}
	if t.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}
func (Store) RootTx(c context.Context, q tx.Queryer, lock bool) (d.Root, bool, error) {
	sql := `SELECT payload::text FROM league_competitions WHERE competition_id='GLOBAL'`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r d.Root
	ok, e := read(c, q, sql, &r)
	if ok && e == nil {
		e = r.Validate()
	}
	return r, ok, e
}
func (Store) PutRootTx(c context.Context, t tx.Tx, r d.Root, old int64) error {
	if t == nil || r.Validate() != nil || r.Version != old+1 {
		return d.ErrConflict
	}
	raw, e := enc(r)
	if e != nil {
		return e
	}
	if old == 0 {
		return one(t.Exec(c, `INSERT INTO league_competitions(competition_id,content_revision,state_version,payload)VALUES('GLOBAL',$1,1,$2::jsonb) ON CONFLICT DO NOTHING`, r.Revision, raw))
	}
	return one(t.Exec(c, `UPDATE league_competitions SET content_revision=$2,state_version=$3,payload=$4::jsonb WHERE competition_id='GLOBAL' AND state_version=$1`, old, r.Revision, r.Version, raw))
}
func (Store) PlayersTx(c context.Context, q tx.Queryer, lock bool) ([]d.Player, error) {
	sql := `SELECT COALESCE(jsonb_agg(payload ORDER BY player_id),'[]'::jsonb)::text FROM league_players`
	if lock {
		sql = `SELECT COALESCE(jsonb_agg(payload ORDER BY player_id),'[]'::jsonb)::text FROM(SELECT player_id,payload FROM league_players ORDER BY player_id FOR UPDATE)x`
	}
	out := []d.Player{}
	_, e := read(c, q, sql, &out)
	if e == nil {
		for _, p := range out {
			if e = p.Validate(); e != nil {
				break
			}
		}
	}
	return out, e
}
func (Store) PutPlayerTx(c context.Context, t tx.Tx, p d.Player, old int64) error {
	if t == nil || p.Validate() != nil || p.Version != old+1 {
		return d.ErrConflict
	}
	raw, e := enc(p)
	if e != nil {
		return e
	}
	if old == 0 {
		return one(t.Exec(c, `INSERT INTO league_players(player_id,logical_server_id,state_version,payload)VALUES($1,$2,1,$3::jsonb) ON CONFLICT DO NOTHING`, int64(p.ID), int64(p.Server), raw))
	}
	return one(t.Exec(c, `UPDATE league_players SET state_version=$3,payload=$4::jsonb WHERE player_id=$1 AND logical_server_id=$5 AND state_version=$2`, int64(p.ID), old, p.Version, raw, int64(p.Server)))
}

const matchObject = `(payload||jsonb_build_object('WireID',wire_id))::text`

func (Store) MatchTx(c context.Context, q tx.Queryer, id ids.UUID) (d.Match, bool, error) {
	var m d.Match
	ok, e := read(c, q, `SELECT `+matchObject+` FROM league_matches WHERE match_id=$1`, &m, id.String())
	if ok && e == nil {
		e = m.Validate()
	}
	return m, ok, e
}
func (Store) IntentTx(c context.Context, q tx.Queryer, pid identity.PlayerID, intent int64) (d.Match, bool, error) {
	var m d.Match
	ok, e := read(c, q, `SELECT `+matchObject+` FROM league_matches WHERE attacker=$1 AND intent=$2`, &m, int64(pid), intent)
	if ok && e == nil {
		e = m.Validate()
	}
	return m, ok, e
}
func (Store) PutMatchTx(c context.Context, t tx.Tx, m d.Match, old int64) (d.Match, error) {
	if t == nil || m.Validate() != nil || m.Version != old+1 {
		return m, d.ErrConflict
	}
	raw, e := enc(m)
	if e != nil {
		return m, e
	}
	if old == 0 {
		e = t.QueryRow(c, `INSERT INTO league_matches(match_id,attacker,defender,intent,attempt_id,state_version,payload)VALUES($1,$2,$3,$4,$5,1,$6::jsonb) RETURNING wire_id`, m.ID.String(), int64(m.Attacker), int64(m.Defender), m.Intent, m.Attempt.String(), raw).Scan(&m.WireID)
		return m, e
	}
	return m, one(t.Exec(c, `UPDATE league_matches SET state_version=$3,payload=$4::jsonb WHERE match_id=$1 AND state_version=$2`, m.ID.String(), old, m.Version, raw))
}
func (Store) OpenTx(c context.Context, q tx.Queryer, limit int) ([]d.Match, error) {
	out := []d.Match{}
	_, e := read(c, q, `SELECT COALESCE(jsonb_agg(v ORDER BY wire_id),'[]'::jsonb)::text FROM(SELECT payload||jsonb_build_object('WireID',wire_id) v,wire_id FROM league_matches WHERE payload->>'Status'='FIGHTING' ORDER BY wire_id LIMIT $1)x`, &out, limit)
	return out, e
}
func (Store) RecordsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]d.Match, error) {
	out := []d.Match{}
	_, e := read(c, q, `SELECT COALESCE(jsonb_agg(v ORDER BY wire_id DESC),'[]'::jsonb)::text FROM(SELECT payload||jsonb_build_object('WireID',wire_id) v,wire_id FROM league_matches WHERE(attacker=$1 OR defender=$1) AND payload->>'Status'='SETTLED' ORDER BY wire_id DESC LIMIT $2)x`, &out, int64(pid), d.RecordsMax)
	return out, e
}
func (Store) SettlementTx(c context.Context, q tx.Queryer, kind string, n int64) (d.Settlement, bool, error) {
	var s d.Settlement
	ok, e := read(c, q, `SELECT payload::text FROM league_settlements WHERE kind=$1 AND number=$2`, &s, kind, n)
	return s, ok, e
}
func (Store) PutSettlementTx(c context.Context, t tx.Tx, s d.Settlement) error {
	raw, e := enc(s)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO league_settlements(kind,number,content_revision,payload)VALUES($1,$2,$3,$4::jsonb)`, s.Kind, s.Number, s.Revision, raw))
}
func (Store) OriginsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]app.OriginAward, error) {
	out := []app.OriginAward{}
	_, e := read(c, q, `SELECT COALESCE(jsonb_agg(payload ORDER BY origin_key),'[]'::jsonb)::text FROM league_cosmetic_origins WHERE player_id=$1`, &out, int64(pid))
	return out, e
}
func (Store) PutOriginTx(c context.Context, t tx.Tx, award app.OriginAward) error {
	o := award.Origin
	if o.Validate() != nil {
		return d.ErrConflict
	}
	raw, e := enc(award)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO league_cosmetic_origins(player_id,origin_key,family,catalog_id,content_revision,payload)VALUES($1,$2,$3,$4,$5,$6::jsonb) ON CONFLICT DO NOTHING`, int64(o.PlayerID), o.Key, o.Family, o.CatalogID, o.Revision, raw)
	if e != nil {
		return e
	}
	if tag.RowsAffected() == 1 {
		return nil
	}
	var same bool
	e = t.QueryRow(c, `SELECT payload=$3::jsonb FROM league_cosmetic_origins WHERE player_id=$1 AND origin_key=$2`, int64(o.PlayerID), o.Key, raw).Scan(&same)
	if e != nil {
		return e
	}
	if !same {
		return d.ErrConflict
	}
	return nil
}
