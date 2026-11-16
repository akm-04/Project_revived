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
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func read[T any](c context.Context, q tx.Queryer, table, sql string, dst *T, args ...any) (bool, error) {
	if q == nil {
		return false, d.ErrUnavailable
	}
	var raw *string
	var version int16
	e := q.QueryRow(c, sql, args...).Scan(&raw, &version)
	if errors.Is(e, kernelstore.ErrNoRows) || e == nil && raw == nil {
		return false, nil
	}
	if e != nil {
		return false, e
	}
	return true, payload.Decode(table, version, []byte(*raw), dst)
}

func readAggregate[T any](c context.Context, q tx.Queryer, sql string, dst *T, args ...any) (bool, error) {
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
	return true, json.Unmarshal([]byte(*raw), dst)
}

// versionedPayload carries one aggregated payload row with its version.
type versionedPayload struct {
	Payload json.RawMessage `json:"payload"`
	Version int16           `json:"version"`
}

func decodePayloads[T any](table string, rows []versionedPayload) ([]T, error) {
	out := make([]T, 0, len(rows))
	for _, row := range rows {
		var value T
		if e := payload.Decode(table, row.Version, row.Payload, &value); e != nil {
			return nil, e
		}
		out = append(out, value)
	}
	return out, nil
}
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
	sql := `SELECT payload::text,payload_version FROM league_competitions WHERE competition_id='GLOBAL'`
	if lock {
		sql += ` FOR UPDATE`
	}
	var r d.Root
	ok, e := read(c, q, "league_competitions", sql, &r)
	if ok && e == nil {
		e = r.Validate()
	}
	return r, ok, e
}
func (Store) PutRootTx(c context.Context, t tx.Tx, r d.Root, old int64) error {
	if t == nil || r.Validate() != nil || r.Version != old+1 {
		return d.ErrConflict
	}
	raw, version, e := payload.Encode(r)
	if e != nil {
		return e
	}
	if old == 0 {
		return one(t.Exec(c, `INSERT INTO league_competitions(competition_id,content_revision,state_version,payload,payload_version)VALUES('GLOBAL',$1,1,$2::jsonb,$3) ON CONFLICT DO NOTHING`, r.Revision, string(raw), version))
	}
	return one(t.Exec(c, `UPDATE league_competitions SET content_revision=$2,state_version=$3,payload=$4::jsonb,payload_version=$5 WHERE competition_id='GLOBAL' AND state_version=$1`, old, r.Revision, r.Version, string(raw), version))
}
func (Store) PlayersTx(c context.Context, q tx.Queryer, lock bool) ([]d.Player, error) {
	sql := `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',payload,'version',payload_version) ORDER BY player_id),'[]'::jsonb)::text FROM league_players`
	if lock {
		sql = `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',payload,'version',payload_version) ORDER BY player_id),'[]'::jsonb)::text FROM(SELECT player_id,payload,payload_version FROM league_players ORDER BY player_id FOR UPDATE)x`
	}
	var rows []versionedPayload
	if _, e := readAggregate(c, q, sql, &rows); e != nil {
		return nil, e
	}
	out, e := decodePayloads[d.Player]("league_players", rows)
	if e != nil {
		return nil, e
	}
	for _, p := range out {
		if e = p.Validate(); e != nil {
			return nil, e
		}
	}
	return out, nil
}
func (Store) PutPlayerTx(c context.Context, t tx.Tx, p d.Player, old int64) error {
	if t == nil || p.Validate() != nil || p.Version != old+1 {
		return d.ErrConflict
	}
	raw, version, e := payload.Encode(p)
	if e != nil {
		return e
	}
	if old == 0 {
		return one(t.Exec(c, `INSERT INTO league_players(player_id,logical_server_id,state_version,payload,payload_version)VALUES($1,$2,1,$3::jsonb,$4) ON CONFLICT DO NOTHING`, int64(p.ID), int64(p.Server), string(raw), version))
	}
	return one(t.Exec(c, `UPDATE league_players SET state_version=$3,payload=$4::jsonb,payload_version=$6 WHERE player_id=$1 AND logical_server_id=$5 AND state_version=$2`, int64(p.ID), old, p.Version, string(raw), int64(p.Server), version))
}

const matchObject = `(payload||jsonb_build_object('WireID',wire_id))::text`

func (Store) MatchTx(c context.Context, q tx.Queryer, id ids.UUID) (d.Match, bool, error) {
	var m d.Match
	ok, e := read(c, q, "league_matches", `SELECT `+matchObject+`,payload_version FROM league_matches WHERE match_id=$1`, &m, id.String())
	if ok && e == nil {
		e = m.Validate()
	}
	return m, ok, e
}
func (Store) IntentTx(c context.Context, q tx.Queryer, pid identity.PlayerID, intent int64) (d.Match, bool, error) {
	var m d.Match
	ok, e := read(c, q, "league_matches", `SELECT `+matchObject+`,payload_version FROM league_matches WHERE attacker=$1 AND intent=$2`, &m, int64(pid), intent)
	if ok && e == nil {
		e = m.Validate()
	}
	return m, ok, e
}
func (Store) PutMatchTx(c context.Context, t tx.Tx, m d.Match, old int64) (d.Match, error) {
	if t == nil || m.Validate() != nil || m.Version != old+1 {
		return m, d.ErrConflict
	}
	raw, version, e := payload.Encode(m)
	if e != nil {
		return m, e
	}
	if old == 0 {
		e = t.QueryRow(c, `INSERT INTO league_matches(match_id,attacker,defender,intent,attempt_id,state_version,payload,payload_version)VALUES($1,$2,$3,$4,$5,1,$6::jsonb,$7) RETURNING wire_id`, m.ID.String(), int64(m.Attacker), int64(m.Defender), m.Intent, m.Attempt.String(), string(raw), version).Scan(&m.WireID)
		return m, e
	}
	return m, one(t.Exec(c, `UPDATE league_matches SET state_version=$3,payload=$4::jsonb,payload_version=$5 WHERE match_id=$1 AND state_version=$2`, m.ID.String(), old, m.Version, string(raw), version))
}
func (Store) OpenTx(c context.Context, q tx.Queryer, limit int) ([]d.Match, error) {
	var rows []versionedPayload
	if _, e := readAggregate(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',v,'version',payload_version) ORDER BY wire_id),'[]'::jsonb)::text FROM(SELECT payload||jsonb_build_object('WireID',wire_id) v,wire_id,payload_version FROM league_matches WHERE payload->>'Status'='FIGHTING' ORDER BY wire_id LIMIT $1)x`, &rows, limit); e != nil {
		return nil, e
	}
	return decodePayloads[d.Match]("league_matches", rows)
}
func (Store) RecordsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]d.Match, error) {
	var rows []versionedPayload
	if _, e := readAggregate(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',v,'version',payload_version) ORDER BY wire_id DESC),'[]'::jsonb)::text FROM(SELECT payload||jsonb_build_object('WireID',wire_id) v,wire_id,payload_version FROM league_matches WHERE(attacker=$1 OR defender=$1) AND payload->>'Status'='SETTLED' ORDER BY wire_id DESC LIMIT $2)x`, &rows, int64(pid), d.RecordsMax); e != nil {
		return nil, e
	}
	return decodePayloads[d.Match]("league_matches", rows)
}
func (Store) SettlementTx(c context.Context, q tx.Queryer, kind string, n int64) (d.Settlement, bool, error) {
	var s d.Settlement
	ok, e := read(c, q, "league_settlements", `SELECT payload::text,payload_version FROM league_settlements WHERE kind=$1 AND number=$2`, &s, kind, n)
	return s, ok, e
}
func (Store) PutSettlementTx(c context.Context, t tx.Tx, s d.Settlement) error {
	raw, version, e := payload.Encode(s)
	if e != nil {
		return e
	}
	return one(t.Exec(c, `INSERT INTO league_settlements(kind,number,content_revision,payload,payload_version)VALUES($1,$2,$3,$4::jsonb,$5)`, s.Kind, s.Number, s.Revision, string(raw), version))
}
func (Store) OriginsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]app.OriginAward, error) {
	var rows []versionedPayload
	if _, e := readAggregate(c, q, `SELECT COALESCE(jsonb_agg(jsonb_build_object('payload',payload,'version',payload_version) ORDER BY origin_key),'[]'::jsonb)::text FROM league_cosmetic_origins WHERE player_id=$1`, &rows, int64(pid)); e != nil {
		return nil, e
	}
	return decodePayloads[app.OriginAward]("league_cosmetic_origins", rows)
}
func (Store) PutOriginTx(c context.Context, t tx.Tx, award app.OriginAward) error {
	o := award.Origin
	if o.Validate() != nil {
		return d.ErrConflict
	}
	raw, version, e := payload.Encode(award)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO league_cosmetic_origins(player_id,origin_key,family,catalog_id,content_revision,payload,payload_version)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7) ON CONFLICT DO NOTHING`, int64(o.PlayerID), o.Key, o.Family, o.CatalogID, o.Revision, string(raw), version)
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
