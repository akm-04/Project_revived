package achievementstore

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/achievement"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

// ReadStreaksTx returns every streak and owned-state row of one player.
func (s Store) ReadStreaksTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]d.Streak, error) {
	if q == nil || !pid.Valid() {
		return nil, d.ErrUnavailable
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(achievement_id ORDER BY achievement_id),'[]'::jsonb)::text FROM achievement_streaks WHERE player_id=$1`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	var achievementIDs []int64
	if e := json.Unmarshal([]byte(raw), &achievementIDs); e != nil {
		return nil, e
	}
	out := []d.Streak{}
	for _, id := range achievementIDs {
		streak, _, e := s.ReadStreakTx(c, q, pid, id, false)
		if e != nil {
			return nil, e
		}
		out = append(out, streak)
	}
	return out, nil
}

func (Store) ReadClaimsTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (map[int64]bool, error) {
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(level_id),'[]'::jsonb)::text FROM achievement_award_claims WHERE player_id=$1`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	var levels []int64
	out := map[int64]bool{}
	if e := json.Unmarshal([]byte(raw), &levels); e != nil {
		return nil, e
	}
	for _, l := range levels {
		out[l] = true
	}
	return out, nil
}

func (Store) PutClaimTx(c context.Context, t tx.Tx, pid identity.PlayerID, level int64, revision string, operation ids.UUID, total int64, at time.Time) error {
	tag, e := t.Exec(c, `INSERT INTO achievement_award_claims(player_id,level_id,content_revision,operation_id,total_points,claimed_at)VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`, int64(pid), level, revision, operation.String(), total, at.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// PutNoticesTx records notice intents once per earned tier. The wakeup is a
// transactional NOTIFY, so it reaches the realtime route only on commit.
func (Store) PutNoticesTx(c context.Context, t tx.Tx, notices []app.Notice) error {
	woken := map[identity.PlayerID]bool{}
	for _, n := range notices {
		tag, e := t.Exec(c, `INSERT INTO achievement_notices(player_id,achievement_id,tier,complete_time)VALUES($1,$2,$3,$4) ON CONFLICT DO NOTHING`, int64(n.Player), n.AchievementID, n.Tier, n.CompleteTime.UTC())
		if e != nil {
			return e
		}
		if tag.RowsAffected() == 0 || woken[n.Player] {
			continue
		}
		woken[n.Player] = true
		if e = postgres.EmitRealtimeWakeup(c, t, wake.Envelope{Version: wake.EnvelopeVersion, Route: app.NoticeRoute, Ref: strconv.FormatInt(int64(n.Player), 10)}); e != nil {
			return e
		}
	}
	return nil
}

func (Store) PendingNoticesTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]app.Notice, error) {
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('Player',player_id,'AchievementID',achievement_id,'Tier',tier,'CompleteTime',complete_time) ORDER BY notice_id),'[]'::jsonb)::text FROM achievement_notices WHERE player_id=$1 AND delivered_at IS NULL`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	out := []app.Notice{}
	return out, json.Unmarshal([]byte(raw), &out)
}

func (Store) MarkNoticesDeliveredTx(c context.Context, t tx.Tx, pid identity.PlayerID, at time.Time) error {
	_, e := t.Exec(c, `UPDATE achievement_notices SET delivered_at=$2 WHERE player_id=$1 AND delivered_at IS NULL`, int64(pid), at.UTC())
	return e
}

// C4F_LIVE_TROPHY_RANK_V1 orders tracked players on one server by more points,
// then equal points reached earlier, then lower id; players without points are unranked.
const trophyTotalsSQL = `WITH points(achievement_id,tier,points) AS (SELECT * FROM unnest($2::bigint[],$3::int[],$4::bigint[])),
earned AS (
 SELECT r.player_id,100014::bigint AS achievement_id,t.ordinality::int AS tier,(t.value#>>'{}')::timestamptz AS at FROM achievement_roots r CROSS JOIN LATERAL jsonb_array_elements(r.complete_times) WITH ORDINALITY t WHERE r.player_id/100000=$1 AND jsonb_typeof(t.value)='string'
 UNION ALL
 SELECT s.player_id,s.achievement_id,t.ordinality::int,(t.value#>>'{}')::timestamptz FROM achievement_streaks s CROSS JOIN LATERAL jsonb_array_elements(s.complete_times) WITH ORDINALITY t WHERE s.player_id/100000=$1 AND jsonb_typeof(t.value)='string'),
totals AS (SELECT e.player_id,sum(p.points) AS total,max(e.at) AS reached FROM earned e JOIN points p USING(achievement_id,tier) GROUP BY e.player_id)
`

const trophyRankSQL = trophyTotalsSQL + `,me AS (SELECT total,reached FROM totals WHERE player_id=$5)
SELECT COALESCE((SELECT 1+(SELECT count(*) FROM totals o WHERE o.total>me.total OR o.total=me.total AND (o.reached<me.reached OR o.reached=me.reached AND o.player_id<$5)) FROM me),0)`

const trophyTopSQL = trophyTotalsSQL + `SELECT COALESCE(jsonb_agg(jsonb_build_object('Player',player_id,'Points',total) ORDER BY total DESC,reached,player_id),'[]'::jsonb)::text FROM (SELECT * FROM totals ORDER BY total DESC,reached,player_id LIMIT $5) top`

func trophyPoints(catalog d.Catalog) ([]int64, []int32, []int64) {
	var achievementIDs, points []int64
	var tiers []int32
	for _, row := range catalog.Rows {
		for i, value := range row.Points {
			achievementIDs, tiers, points = append(achievementIDs, row.ID), append(tiers, int32(i+1)), append(points, value)
		}
	}
	return achievementIDs, tiers, points
}

// shortcut: aggregates the server's tier rows per read, add a points projection if 1302 load latency grows.
func (Store) TrophyRankTx(c context.Context, q tx.Queryer, pid identity.PlayerID, catalog d.Catalog) (int64, error) {
	achievementIDs, tiers, points := trophyPoints(catalog)
	var rank int64
	e := q.QueryRow(c, trophyRankSQL, int64(pid)/100000, achievementIDs, tiers, points, int64(pid)).Scan(&rank)
	return rank, e
}

func (Store) TrophyTopTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, catalog d.Catalog, limit int) ([]d.TrophyStanding, error) {
	achievementIDs, tiers, points := trophyPoints(catalog)
	var raw string
	if e := q.QueryRow(c, trophyTopSQL, int64(server), achievementIDs, tiers, points, limit).Scan(&raw); e != nil {
		return nil, e
	}
	out := []d.TrophyStanding{}
	return out, json.Unmarshal([]byte(raw), &out)
}
