package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// GuildJoinSeedFixture gives the driven guildless player two active guilds on
// its own logical server so the stock Join window (LOAD_ALL_TEAMS 576) has a
// source-shaped list. It is declared prior state, not gameplay-origin proof.
func GuildJoinSeedFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-guild-join-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player, server int64
	if err := pool.QueryRow(requestContext, `SELECT p.player_id,p.logical_server_id FROM players p JOIN accounts a ON a.account_id=p.account_id WHERE a.account_id=$1`, accountID).Scan(&player, &server); err != nil {
		return fmt.Errorf("guild join fixture needs the driven player: %w", err)
	}
	var member bool
	if err := pool.QueryRow(requestContext, `SELECT EXISTS(SELECT 1 FROM guild_memberships WHERE player_id=$1)`, player).Scan(&member); err != nil {
		return err
	}
	if member {
		return fmt.Errorf("guild join fixture needs a guildless player")
	}
	rows, err := pool.Raw().Query(requestContext, `SELECT p.player_id FROM players p
		JOIN player_directory_profiles d ON d.player_id=p.player_id
		LEFT JOIN guild_memberships m ON m.player_id=p.player_id
		WHERE p.logical_server_id=$1 AND p.player_id<>$2 AND m.player_id IS NULL ORDER BY p.player_id LIMIT 2`, server, player)
	if err != nil {
		return err
	}
	leaders := []int64{}
	for rows.Next() {
		var leader int64
		if err := rows.Scan(&leader); err != nil {
			rows.Close()
			return err
		}
		leaders = append(leaders, leader)
	}
	rows.Close()
	if len(leaders) < 2 {
		return fmt.Errorf("guild join fixture needs two guildless leader candidates, found %d", len(leaders))
	}
	for index, leader := range leaders {
		var guildID int64
		if err := pool.QueryRow(requestContext, `INSERT INTO guilds(guild_id,logical_server_id,name,icon,icon_frame,des,apply_type,min_allow_level,vitality,policy_revision,state_version,created_at,updated_at)
			SELECT $1::bigint*1000000+n,$1,$2,20010001,0,'',0,1,0,'vc-guild-join-fixture',1,now(),now()
			FROM (SELECT COALESCE(MAX(guild_id%1000000),0)+1 AS n FROM guilds WHERE logical_server_id=$1) next RETURNING guild_id`, server, fmt.Sprintf("vcjoin%d", index+1)).Scan(&guildID); err != nil {
			return err
		}
		if _, err := pool.Raw().Exec(requestContext, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,1,now(),1,1,now())`, leader, guildID); err != nil {
			return err
		}
	}
	return nil
}
