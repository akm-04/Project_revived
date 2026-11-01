package guildstore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func playerInt64s(players []identity.PlayerID) []int64 {
	out := make([]int64, 0, len(players))
	for _, player := range players {
		out = append(out, int64(player))
	}
	return out
}

// FoldActivityTx marks the players' credited activity folded and returns the
// amount moved. Rank 723; the caller already holds the guild and membership locks.
func (Store) FoldActivityTx(ctx context.Context, t tx.Tx, players []identity.PlayerID) (int64, error) {
	var credited int64
	err := t.QueryRow(ctx, `WITH locked AS (
		SELECT player_id,game_day,LEAST($2,amount)-folded_amount AS credited FROM player_guild_activity_days
		WHERE player_id=ANY($1) AND folded_amount<LEAST($2,amount) ORDER BY player_id,game_day FOR UPDATE
	), moved AS (
		UPDATE player_guild_activity_days d SET folded_amount=d.folded_amount+l.credited FROM locked l
		WHERE d.player_id=l.player_id AND d.game_day=l.game_day RETURNING l.credited
	) SELECT COALESCE(SUM(credited),0)::bigint FROM moved`, playerInt64s(players), guild.ActivityDailyCap).Scan(&credited)
	return credited, err
}

// FoldActivityAwardsTx marks the guild's unfolded awards folded and returns the amount. Rank 723.
func (Store) FoldActivityAwardsTx(ctx context.Context, t tx.Tx, id guild.ID) (int64, error) {
	var credited int64
	err := t.QueryRow(ctx, `WITH moved AS (
		UPDATE guild_activity_awards SET folded=true WHERE guild_id=$1 AND NOT folded RETURNING amount
	) SELECT COALESCE(SUM(amount),0)::bigint FROM moved`, int64(id)).Scan(&credited)
	return credited, err
}

// MarkActivityFoldedTx marks everything the joiner earned before joining as spent,
// so it credits nothing to the new guild (I9_GUILD_ACTIVITY_V1 C6).
func (Store) MarkActivityFoldedTx(ctx context.Context, t tx.Tx, player identity.PlayerID) error {
	_, err := t.Exec(ctx, `UPDATE player_guild_activity_days SET folded_amount=LEAST($2,amount)
		WHERE player_id=$1 AND folded_amount<LEAST($2,amount)`, int64(player), guild.ActivityDailyCap)
	return err
}

// ForfeitActivityLifetimeTx applies the leaving rule to the player's lifetime contribution.
func (Store) ForfeitActivityLifetimeTx(ctx context.Context, t tx.Tx, player identity.PlayerID) error {
	var lifetime int64
	err := t.QueryRow(ctx, `SELECT COALESCE((SELECT SUM(LEAST($2,amount)) FROM player_guild_activity_days WHERE player_id=$1),0)::bigint
		-COALESCE((SELECT forfeited FROM player_guild_activity_totals WHERE player_id=$1),0)`, int64(player), guild.ActivityDailyCap).Scan(&lifetime)
	if err != nil {
		return err
	}
	lost := lifetime - guild.LifetimeAfterLeaving(lifetime)
	if lost <= 0 {
		return nil
	}
	_, err = t.Exec(ctx, `INSERT INTO player_guild_activity_totals(player_id,forfeited) VALUES($1,$2)
		ON CONFLICT(player_id) DO UPDATE SET forfeited=player_guild_activity_totals.forfeited+excluded.forfeited`, int64(player), lost)
	return err
}

// ReadUnfoldedActivity sums what the guild's current members and awards have
// credited but no fold has moved yet.
func (s Store) ReadUnfoldedActivity(ctx context.Context, id guild.ID) (int64, error) {
	var unfolded int64
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE((SELECT SUM(LEAST($2,d.amount)-d.folded_amount) FROM player_guild_activity_days d
		JOIN guild_memberships m ON m.player_id=d.player_id WHERE m.guild_id=$1 AND d.folded_amount<LEAST($2,d.amount)),0)::bigint
		+COALESCE((SELECT SUM(amount) FROM guild_activity_awards WHERE guild_id=$1 AND NOT folded),0)::bigint`, int64(id), guild.ActivityDailyCap).Scan(&unfolded)
	return unfolded, err
}

// CreditActivityAwardTx credits a guild's community band inside the caller's
// transaction. It takes no guild lock and source_key makes it once only
// (I9_GUILD_ACTIVITY_V1 C9).
func (Store) CreditActivityAwardTx(ctx context.Context, t tx.Tx, guildID int64, sourceKey string, amount int64) error {
	if t == nil || guildID <= 0 || sourceKey == "" || amount <= 0 {
		return errors.New("invalid guild activity award")
	}
	_, err := t.Exec(ctx, `INSERT INTO guild_activity_awards(guild_id,source_key,amount) VALUES($1,$2,$3)
		ON CONFLICT(guild_id,source_key) DO NOTHING`, guildID, sourceKey, amount)
	return err
}

// ReadPlayerActivity reads the activity a member's own rows give (C3, C10).
// Lifetime subtracts the forfeited total the leaving rule wrote (C7).
func (s Store) ReadPlayerActivity(ctx context.Context, player identity.PlayerID, day int64) (guild.PlayerActivity, error) {
	var out guild.PlayerActivity
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(SUM(LEAST($3,amount)) FILTER (WHERE game_day=$2),0)::bigint,
		GREATEST(COALESCE(SUM(LEAST($3,amount)),0)-COALESCE((SELECT forfeited FROM player_guild_activity_totals WHERE player_id=$1),0),0)::bigint,
		COALESCE(SUM(LEAST($3,amount)) FILTER (WHERE game_day BETWEEN $2-6 AND $2),0)::bigint
		FROM player_guild_activity_days WHERE player_id=$1`, int64(player), day, guild.ActivityDailyCap).Scan(&out.Today, &out.Lifetime, &out.SevenDay)
	return out, err
}

// ReadSevenDayActivity reads the roster seven_huoyue for a bounded member list.
func (s Store) ReadSevenDayActivity(ctx context.Context, players []identity.PlayerID, day int64) (map[identity.PlayerID]int64, error) {
	out := make(map[identity.PlayerID]int64, len(players))
	if len(players) == 0 {
		return out, nil
	}
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'total',total)),'[]'::jsonb)::text FROM (
		SELECT player_id AS player,COALESCE(SUM(LEAST($3,amount)),0)::bigint AS total FROM player_guild_activity_days
		WHERE player_id=ANY($1) AND game_day BETWEEN $2-6 AND $2 GROUP BY player_id) rows`, playerInt64s(players), day, guild.ActivityDailyCap).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		Player int64 `json:"player"`
		Total  int64 `json:"total"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	for _, row := range rows {
		out[identity.PlayerID(row.Player)] = row.Total
	}
	return out, nil
}

// ReadGuildThreeDayActivity reads a guild's 3-day active points (C12).
func (s Store) ReadGuildThreeDayActivity(ctx context.Context, id guild.ID, day int64) (int64, error) {
	var total int64
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(SUM(LEAST($3,d.amount)),0)::bigint FROM player_guild_activity_days d
		JOIN guild_memberships m ON m.player_id=d.player_id
		WHERE m.guild_id=$1 AND d.game_day BETWEEN $2-2 AND $2`, int64(id), day, guild.ActivityDailyCap).Scan(&total)
	return total, err
}

// ListActivityBoard returns at most limit guilds of one logical server ordered
// by 3-day active points (C12). The list is bounded by the caller's limit.
func (s Store) ListActivityBoard(ctx context.Context, server identity.LogicalServerID, day, limit int64) ([]guild.ActivityBoardRow, error) {
	var raw string
	err := s.Queryer.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'id',guild_id,'name',name,'icon',icon,'des',des,'min',min_allow_level,'members',members,'three_day',three_day) ORDER BY three_day DESC,guild_id ASC),'[]'::jsonb)::text
		FROM (SELECT g.guild_id,g.name,g.icon,g.des,g.min_allow_level,
		(SELECT COUNT(*) FROM guild_memberships m2 WHERE m2.guild_id=g.guild_id)::bigint AS members,
		COALESCE(SUM(LEAST($4,d.amount)),0)::bigint AS three_day
		FROM guilds g
		LEFT JOIN guild_memberships m ON m.guild_id=g.guild_id
		LEFT JOIN player_guild_activity_days d ON d.player_id=m.player_id AND d.game_day BETWEEN $2-2 AND $2
		WHERE g.logical_server_id=$1 AND g.retired_at IS NULL
		GROUP BY g.guild_id,g.name,g.icon,g.des,g.min_allow_level
		ORDER BY three_day DESC,g.guild_id ASC LIMIT $3) board`, int32(server), day, limit, guild.ActivityDailyCap).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		ID      int64  `json:"id"`
		Name    string `json:"name"`
		Icon    int64  `json:"icon"`
		Des     string `json:"des"`
		Min     int64  `json:"min"`
		Members int64  `json:"members"`
		Three   int64  `json:"three_day"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]guild.ActivityBoardRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, guild.ActivityBoardRow{GuildID: row.ID, Name: row.Name, Icon: row.Icon, Description: row.Des, MinAllowLevel: row.Min, MemberNum: row.Members, ThreeDay: row.Three})
	}
	return out, nil
}
