package guildstore

import (
	"context"

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
