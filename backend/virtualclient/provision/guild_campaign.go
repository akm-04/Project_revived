package provision

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
)

// GuildCampaignFixture seeds the campaign prerequisites the scenario does not
// prove: level 40+ and forty days of personal activity. It is declared prior
// state, not gameplay-origin proof.
func GuildCampaignFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-guild-campaign-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var player int64
	if err := pool.QueryRow(requestContext, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&player); err != nil {
		return fmt.Errorf("guild campaign fixture needs the driven player: %w", err)
	}
	if _, err := pool.Raw().Exec(requestContext, `UPDATE player_progression SET level=GREATEST(level,41),updated_at=clock_timestamp() WHERE player_id=$1`, player); err != nil {
		return err
	}
	if _, err := pool.Raw().Exec(requestContext, `UPDATE player_directory_profiles SET lev=GREATEST(lev,41),updated_at=clock_timestamp() WHERE player_id=$1`, player); err != nil {
		return err
	}
	day := (time.Now().Unix() + 8*3600 - 5*3600) / 86400
	for offset := int64(0); offset < 40; offset++ {
		if _, err := pool.Raw().Exec(requestContext, `INSERT INTO player_guild_activity_days(player_id,game_day,amount)VALUES($1,$2,1000)
			ON CONFLICT(player_id,game_day) DO UPDATE SET amount=GREATEST(player_guild_activity_days.amount,1000)`, player, day-offset); err != nil {
			return err
		}
	}
	return nil
}

// GuildCampaignLastWaveFixture keeps one open copy on its last wave and marks
// every other copy of the chapter won, so one clear wins the chapter without a
// three-wave battle per copy. It changes only the declared campaign prior state.
func GuildCampaignLastWaveFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-guild-campaign-last-wave"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var guildID, chapterID, keep int64
	if err := pool.QueryRow(requestContext, `SELECT m.guild_id FROM players p JOIN guild_memberships m ON m.player_id=p.player_id WHERE p.account_id=$1`, accountID).Scan(&guildID); err != nil {
		return fmt.Errorf("last wave fixture needs a guild: %w", err)
	}
	if err := pool.QueryRow(requestContext, `SELECT c.chapter_id,c.copy_id FROM guild_campaign_chapters ch
		JOIN guild_campaign_copies c ON c.guild_id=ch.guild_id AND c.chapter_id=ch.chapter_id
		WHERE ch.guild_id=$1 AND NOT ch.is_win ORDER BY c.copy_id LIMIT 1`, guildID).Scan(&chapterID, &keep); err != nil {
		return fmt.Errorf("last wave fixture needs an open chapter: %w", err)
	}
	rows, err := pool.Raw().Query(requestContext, `SELECT copy_id,waves::text FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2 ORDER BY copy_id`, guildID, chapterID)
	if err != nil {
		return err
	}
	type copyRow struct {
		copyID int64
		waves  string
	}
	copies := []copyRow{}
	for rows.Next() {
		var row copyRow
		if err := rows.Scan(&row.copyID, &row.waves); err != nil {
			rows.Close()
			return err
		}
		copies = append(copies, row)
	}
	rows.Close()
	for _, copy := range copies {
		var waves map[string][]map[string]any
		if err := json.Unmarshal([]byte(copy.waves), &waves); err != nil {
			return err
		}
		wavesToKill := []string{"1", "2", "3"}
		if copy.copyID == keep {
			wavesToKill = []string{"1", "2"}
		}
		for _, wave := range wavesToKill {
			for _, enemy := range waves[wave] {
				enemy["health"] = 1
				delete(enemy, "hp")
			}
		}
		encoded, err := json.Marshal(waves)
		if err != nil {
			return err
		}
		win := copy.copyID != keep
		currentIndex, percent := 3, 2.0/3
		if win {
			percent = 1
		}
		if _, err := pool.Raw().Exec(requestContext, `UPDATE guild_campaign_copies SET waves=$3::jsonb,current_index=$4,is_win=$5,percent=$6 WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$7`,
			guildID, chapterID, string(encoded), currentIndex, win, percent, copy.copyID); err != nil {
			return err
		}
	}
	return nil
}
