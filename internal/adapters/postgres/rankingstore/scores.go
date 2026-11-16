package rankingstore

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const scoreRowColumns = `policy,logical_server_id,player_id,score,score_since,revision,metric::text,updated_at`

// The aggregate path must keep metric a jsonb object so to_jsonb embeds it.
const scoreRowAggregateColumns = `policy,logical_server_id,player_id,score,score_since,revision,metric,updated_at`

func decodeScoreMetric(raw string) (d.BoardMetric, error) {
	var out d.BoardMetric
	dec := json.NewDecoder(bytes.NewReader([]byte(raw)))
	dec.DisallowUnknownFields()
	if e := dec.Decode(&out); e != nil {
		return out, e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return out, d.ErrSnapshot
	}
	return out, nil
}

type scoreRowWire struct {
	Policy     string          `json:"policy"`
	Server     int64           `json:"logical_server_id"`
	Player     int64           `json:"player_id"`
	Score      int64           `json:"score"`
	ScoreSince time.Time       `json:"score_since"`
	Revision   string          `json:"revision"`
	Metric     json.RawMessage `json:"metric"`
	UpdatedAt  time.Time       `json:"updated_at"`
}

func strictScoreRow(w scoreRowWire) (d.ScoreRow, error) {
	r := d.ScoreRow{
		Policy:     w.Policy,
		Server:     identity.LogicalServerID(w.Server),
		Player:     identity.PlayerID(w.Player),
		Score:      w.Score,
		ScoreSince: w.ScoreSince,
		Revision:   w.Revision,
		UpdatedAt:  w.UpdatedAt,
	}
	m, e := decodeScoreMetric(string(w.Metric))
	if e != nil {
		return r, e
	}
	r.Metric = m
	return r, r.Validate()
}

func (Store) UpsertScoreRowTx(c context.Context, t tx.Tx, r d.ScoreRow) error {
	if t == nil || r.Validate() != nil {
		return d.ErrSnapshot
	}
	raw, e := json.Marshal(r.Metric)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO ranking_board_scores(policy,logical_server_id,player_id,score,score_since,revision,metric,updated_at)VALUES($1,$2,$3,$4,$5,$6,$7::jsonb,$8) ON CONFLICT(policy,player_id)DO UPDATE SET logical_server_id=excluded.logical_server_id,score=excluded.score,score_since=excluded.score_since,revision=excluded.revision,metric=excluded.metric,updated_at=excluded.updated_at`, r.Policy, int64(r.Server), int64(r.Player), r.Score, r.ScoreSince, r.Revision, string(raw), r.UpdatedAt)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrSnapshot
	}
	return nil
}

func (Store) DeleteScoreRowTx(c context.Context, t tx.Tx, policy string, player identity.PlayerID) error {
	if t == nil || policy == "" || !player.Valid() {
		return d.ErrSnapshot
	}
	_, e := t.Exec(c, `DELETE FROM ranking_board_scores WHERE policy=$1 AND player_id=$2`, policy, int64(player))
	return e
}

func (Store) ReadScoreRowTx(c context.Context, q tx.Queryer, policy string, player identity.PlayerID) (d.ScoreRow, bool, error) {
	var out d.ScoreRow
	if q == nil || policy == "" || !player.Valid() {
		return out, false, d.ErrSnapshot
	}
	var raw string
	var server, pid int64
	e := q.QueryRow(c, `SELECT `+scoreRowColumns+` FROM ranking_board_scores WHERE policy=$1 AND player_id=$2`, policy, int64(player)).Scan(&out.Policy, &server, &pid, &out.Score, &out.ScoreSince, &out.Revision, &raw, &out.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	out.Server, out.Player = identity.LogicalServerID(server), identity.PlayerID(pid)
	m, e := decodeScoreMetric(raw)
	if e != nil {
		return out, true, e
	}
	out.Metric = m
	return out, true, out.Validate()
}

func readScoreRows(c context.Context, q tx.Queryer, query string, args ...any) ([]d.ScoreRow, error) {
	var raw string
	if e := q.QueryRow(c, query, args...).Scan(&raw); e != nil {
		return nil, e
	}
	var wire []scoreRowWire
	if e := json.Unmarshal([]byte(raw), &wire); e != nil {
		return nil, e
	}
	out := make([]d.ScoreRow, 0, len(wire))
	for _, w := range wire {
		r, e := strictScoreRow(w)
		if e != nil {
			return nil, e
		}
		out = append(out, r)
	}
	return out, nil
}

func (Store) TopScoreRowsTx(c context.Context, q tx.Queryer, policy string, server identity.LogicalServerID, limit int64) ([]d.ScoreRow, error) {
	if q == nil || policy == "" || !server.Valid() || limit < 1 {
		return nil, d.ErrSnapshot
	}
	return readScoreRows(c, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.score DESC,t.score_since,t.player_id),'[]'::jsonb)::text FROM (SELECT `+scoreRowAggregateColumns+` FROM ranking_board_scores WHERE policy=$1 AND logical_server_id=$2 ORDER BY score DESC,score_since,player_id LIMIT $3)t`, policy, int64(server), limit)
}

func (Store) AllScoreRowsTx(c context.Context, q tx.Queryer, policy string, server identity.LogicalServerID) ([]d.ScoreRow, error) {
	if q == nil || policy == "" || !server.Valid() {
		return nil, d.ErrSnapshot
	}
	return readScoreRows(c, q, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.score DESC,t.score_since,t.player_id),'[]'::jsonb)::text FROM (SELECT `+scoreRowAggregateColumns+` FROM ranking_board_scores WHERE policy=$1 AND logical_server_id=$2 ORDER BY score DESC,score_since,player_id)t`, policy, int64(server))
}

// ReadScoreRowUpdatesTx returns the board's stored update times so the refresh
// job can tell which active players are stale.
func (Store) ReadScoreRowUpdatesTx(c context.Context, q tx.Queryer, policy string, server identity.LogicalServerID) (map[identity.PlayerID]time.Time, error) {
	out := map[identity.PlayerID]time.Time{}
	if q == nil || policy == "" || !server.Valid() {
		return out, d.ErrSnapshot
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'updated_at',updated_at)),'[]'::jsonb)::text FROM ranking_board_scores WHERE policy=$1 AND logical_server_id=$2`, policy, int64(server)).Scan(&raw); e != nil {
		return out, e
	}
	var rows []struct {
		Player    int64     `json:"player"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return out, e
	}
	for _, x := range rows {
		id := identity.PlayerID(x.Player)
		if !id.Valid() || x.UpdatedAt.Unix() <= 0 {
			return nil, d.ErrSnapshot
		}
		out[id] = x.UpdatedAt
	}
	return out, nil
}

// ReadBoardRootRunsTx reads the legacy Runs map for backfill seeding. It never
// creates or locks a root.
func (Store) ReadBoardRootRunsTx(c context.Context, q tx.Queryer, b d.Board, server identity.LogicalServerID) (map[identity.PlayerID]d.ScoreRun, error) {
	out := map[identity.PlayerID]d.ScoreRun{}
	if q == nil || !server.Valid() {
		return out, d.ErrSnapshot
	}
	var raw string
	var version int16
	e := q.QueryRow(c, `SELECT payload::text,payload_version FROM ranking_girls_roots WHERE logical_server_id=$1 AND policy_id=$2`, int64(server), b.Policy).Scan(&raw, &version)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, nil
	}
	if e != nil {
		return nil, e
	}
	var root d.BoardRoot
	if e = payload.Decode("ranking_girls_roots", version, []byte(raw), &root); e != nil {
		return nil, e
	}
	if root.Validate() != nil || root.Server != server || root.Policy != b.Policy {
		return nil, d.ErrSnapshot
	}
	return root.Runs, nil
}

func (Store) ScoreRankTx(c context.Context, q tx.Queryer, policy string, server identity.LogicalServerID, row d.ScoreRow) (int64, error) {
	if q == nil || policy == "" || !server.Valid() || !row.Player.Valid() || row.Score < 0 || row.Score > 9007199254740991 || row.ScoreSince.Unix() <= 0 {
		return 0, d.ErrSnapshot
	}
	var rank int64
	e := q.QueryRow(c, `SELECT count(*) FROM ranking_board_scores WHERE policy=$1 AND logical_server_id=$2 AND (score>$3 OR (score=$3 AND (score_since<$4 OR (score_since=$4 AND player_id<$5))))`, policy, int64(server), row.Score, row.ScoreSince, int64(row.Player)).Scan(&rank)
	return rank, e
}
