package guildcampaignstore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReadChapterTx reads one chapter without a lock; the open/reset guild lock
// serialises it against a reset.
func (Store) ReadChapterTx(ctx context.Context, q tx.Queryer, guildID, chapterID int64) (d.Chapter, bool, error) {
	chapter := d.Chapter{GuildID: guildID, ChapterID: chapterID}
	err := q.QueryRow(ctx, `SELECT run,is_win,percent,start_time,end_time FROM guild_campaign_chapters WHERE guild_id=$1 AND chapter_id=$2`, guildID, chapterID).
		Scan(&chapter.Run, &chapter.Win, &chapter.Percent, &chapter.StartTime, &chapter.EndTime)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Chapter{}, false, nil
	}
	return chapter, err == nil, err
}

func (Store) ReadCopyTx(ctx context.Context, q tx.Queryer, guildID, chapterID, copyID int64) (d.Copy, bool, error) {
	return readCopy(ctx, q, guildID, chapterID, copyID, false)
}

func (Store) LockCopyTx(ctx context.Context, t tx.Tx, guildID, chapterID, copyID int64) (d.Copy, bool, error) {
	return readCopy(ctx, t, guildID, chapterID, copyID, true)
}

func readCopy(ctx context.Context, q tx.Queryer, guildID, chapterID, copyID int64, lock bool) (d.Copy, bool, error) {
	query := `SELECT run,waves::text,current_index,is_win,percent,COALESCE(holder_id,0),holder_stage,last_fight_time,start_fight_time,COALESCE(attempt_generation,''),COALESCE(settled_by,0),settled_index,COALESCE(settled_body::text,'')
		FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$3`
	if lock {
		query += ` FOR UPDATE`
	}
	var waves, settledBody string
	copy := d.Copy{GuildID: guildID, ChapterID: chapterID, CopyID: copyID}
	err := q.QueryRow(ctx, query, guildID, chapterID, copyID).
		Scan(&copy.Run, &waves, &copy.CurrentIndex, &copy.Win, &copy.Percent, &copy.HolderID, &copy.HolderStage, &copy.LastFightTime, &copy.StartFightTime, &copy.AttemptGeneration, &copy.SettledBy, &copy.SettledIndex, &settledBody)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Copy{}, false, nil
	}
	copy.Waves, copy.SettledBody = []byte(waves), []byte(settledBody)
	return copy, err == nil, err
}

func (Store) SaveCopyTx(ctx context.Context, t tx.Tx, copy d.Copy) error {
	_, err := t.Exec(ctx, `UPDATE guild_campaign_copies SET waves=$4::jsonb,current_index=$5,is_win=$6,percent=$7,
		holder_id=NULLIF($8,0),holder_stage=$9,last_fight_time=$10,start_fight_time=$11,attempt_generation=$12,
		settled_by=NULLIF($13,0),settled_index=$14,settled_body=NULLIF($15,'')::jsonb
		WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$3`,
		copy.GuildID, copy.ChapterID, copy.CopyID, string(copy.Waves), copy.CurrentIndex, copy.Win, copy.Percent,
		copy.HolderID, copy.HolderStage, copy.LastFightTime, copy.StartFightTime, copy.AttemptGeneration, copy.SettledBy, copy.SettledIndex, string(copy.SettledBody))
	return err
}

func (Store) ListCopiesTx(ctx context.Context, q tx.Queryer, guildID, chapterID int64) ([]app.CopyRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'copy_id',copy_id,'current_index',current_index,'is_win',is_win,'percent',percent,
		'holder_id',COALESCE(holder_id,0),'stage',holder_stage,
		'last_fight',COALESCE(EXTRACT(EPOCH FROM last_fight_time)::bigint,0),
		'start_fight',COALESCE(EXTRACT(EPOCH FROM start_fight_time)::bigint,0)) ORDER BY copy_id),'[]'::jsonb)::text
		FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2`, guildID, chapterID).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		CopyID       int64   `json:"copy_id"`
		CurrentIndex int64   `json:"current_index"`
		IsWin        bool    `json:"is_win"`
		Percent      float64 `json:"percent"`
		HolderID     int64   `json:"holder_id"`
		Stage        int64   `json:"stage"`
		LastFight    int64   `json:"last_fight"`
		StartFight   int64   `json:"start_fight"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.CopyRow, 0, len(rows))
	for _, row := range rows {
		copied := app.CopyRow{CopyID: row.CopyID, CurrentIndex: row.CurrentIndex, Win: row.IsWin, Percent: row.Percent, HolderID: row.HolderID, Stage: row.Stage}
		if row.LastFight > 0 {
			at := time.Unix(row.LastFight, 0).UTC()
			copied.LastFight = &at
		}
		if row.StartFight > 0 {
			at := time.Unix(row.StartFight, 0).UTC()
			copied.StartFight = &at
		}
		out = append(out, copied)
	}
	return out, nil
}

func (Store) IsRegisteredTx(ctx context.Context, q tx.Queryer, guildID, chapterID int64, player identity.PlayerID) (bool, error) {
	var found bool
	err := q.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM guild_campaign_registrations WHERE guild_id=$1 AND chapter_id=$2 AND player_id=$3)`,
		guildID, chapterID, int64(player)).Scan(&found)
	return found, err
}

func (Store) MemberClearsTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, chapterID, day int64) (int64, error) {
	var clears int64
	err := q.QueryRow(ctx, `SELECT clears FROM guild_campaign_member_days WHERE player_id=$1 AND chapter_id=$2 AND game_day=$3`,
		int64(player), chapterID, day).Scan(&clears)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, nil
	}
	return clears, err
}

// LockMemberDayTx takes the member's chapter day row at rank 605, creating it
// and dropping the member's older days for that chapter.
func (Store) LockMemberDayTx(ctx context.Context, t tx.Tx, player identity.PlayerID, chapterID, day int64) (int64, error) {
	if _, err := t.Exec(ctx, `DELETE FROM guild_campaign_member_days WHERE player_id=$1 AND chapter_id=$2 AND game_day<$3`, int64(player), chapterID, day); err != nil {
		return 0, err
	}
	if _, err := t.Exec(ctx, `INSERT INTO guild_campaign_member_days(player_id,chapter_id,game_day,clears) VALUES($1,$2,$3,0) ON CONFLICT DO NOTHING`, int64(player), chapterID, day); err != nil {
		return 0, err
	}
	var clears int64
	err := t.QueryRow(ctx, `SELECT clears FROM guild_campaign_member_days WHERE player_id=$1 AND chapter_id=$2 AND game_day=$3 FOR UPDATE`, int64(player), chapterID, day).Scan(&clears)
	return clears, err
}

func (Store) BumpMemberClearsTx(ctx context.Context, t tx.Tx, player identity.PlayerID, chapterID, day int64) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_member_days(player_id,chapter_id,game_day,clears) VALUES($1,$2,$3,1)
		ON CONFLICT(player_id,chapter_id,game_day) DO UPDATE SET clears=guild_campaign_member_days.clears+1`, int64(player), chapterID, day)
	return err
}

func (Store) SaveChapterProgressTx(ctx context.Context, t tx.Tx, guildID, chapterID, run int64, percent float64, win bool, end *time.Time) error {
	_, err := t.Exec(ctx, `UPDATE guild_campaign_chapters SET percent=$4,is_win=$5,end_time=$6 WHERE guild_id=$1 AND chapter_id=$2 AND run=$3`,
		guildID, chapterID, run, percent, win, end)
	return err
}

func (Store) UpsertDamageTx(ctx context.Context, t tx.Tx, guildID, chapterID, run, player, damage int64, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_damage(guild_id,chapter_id,run,player_id,best_damage,hit_at) VALUES($1,$2,$3,$4,$5,$6)
		ON CONFLICT(guild_id,chapter_id,run,player_id) DO UPDATE SET
		hit_at=CASE WHEN EXCLUDED.best_damage>guild_campaign_damage.best_damage THEN EXCLUDED.hit_at ELSE guild_campaign_damage.hit_at END,
		best_damage=GREATEST(guild_campaign_damage.best_damage,EXCLUDED.best_damage)`,
		guildID, chapterID, run, player, damage, at)
	return err
}

func (Store) ListDamageTx(ctx context.Context, q tx.Queryer, guildID, chapterID, run int64, limit int) ([]app.DamageRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'damage',best_damage,'hit',EXTRACT(EPOCH FROM hit_at)::bigint) ORDER BY best_damage DESC,hit_at ASC),'[]'::jsonb)::text
		FROM (SELECT player_id,best_damage,hit_at FROM guild_campaign_damage WHERE guild_id=$1 AND chapter_id=$2 AND run=$3 ORDER BY best_damage DESC,hit_at ASC LIMIT $4) ranked`, guildID, chapterID, run, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		Damage   int64 `json:"damage"`
		Hit      int64 `json:"hit"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.DamageRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.DamageRow{PlayerID: row.PlayerID, Damage: row.Damage, HitAt: time.Unix(row.Hit, 0).UTC()})
	}
	return out, nil
}

func (Store) UpsertServerRecordTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, copyID, player, guildID, damage int64, partners []byte, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_server_records(logical_server_id,copy_id,player_id,guild_id,damage,partners,hit_at) VALUES($1,$2,$3,$4,$5,$6::jsonb,$7)
		ON CONFLICT(logical_server_id,copy_id,player_id) DO UPDATE SET damage=GREATEST(guild_campaign_server_records.damage,EXCLUDED.damage),
		partners=EXCLUDED.partners,guild_id=EXCLUDED.guild_id,hit_at=EXCLUDED.hit_at WHERE EXCLUDED.damage>guild_campaign_server_records.damage`,
		int64(server), copyID, player, guildID, damage, string(partners), at)
	return err
}

// TopServerDamageTx is the copy's all-server record before this fight's upsert.
func (Store) TopServerDamageTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, copyID int64) (int64, error) {
	var damage int64
	err := q.QueryRow(ctx, `SELECT COALESCE(MAX(damage),0) FROM guild_campaign_server_records WHERE logical_server_id=$1 AND copy_id=$2`, int64(server), copyID).Scan(&damage)
	return damage, err
}

func (Store) ListServerRecordsTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, copyID int64, limit int) ([]app.ServerRecord, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'guild_id',guild_id,'damage',damage,'partners',partners,'hit',EXTRACT(EPOCH FROM hit_at)::bigint) ORDER BY damage DESC,hit_at ASC),'[]'::jsonb)::text
		FROM (SELECT player_id,guild_id,damage,partners,hit_at FROM guild_campaign_server_records WHERE logical_server_id=$1 AND copy_id=$2 ORDER BY damage DESC,hit_at ASC LIMIT $3) ranked`, int64(server), copyID, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID int64           `json:"player_id"`
		GuildID  int64           `json:"guild_id"`
		Damage   int64           `json:"damage"`
		Partners json.RawMessage `json:"partners"`
		Hit      int64           `json:"hit"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.ServerRecord, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.ServerRecord{PlayerID: row.PlayerID, GuildID: row.GuildID, Damage: row.Damage, Partners: row.Partners, HitAt: time.Unix(row.Hit, 0).UTC()})
	}
	return out, nil
}

func (Store) ServerKillTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, copyID, player, guildID int64, at time.Time, elapsed int64) (app.ServerKill, bool, error) {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_server_kills(logical_server_id,copy_id,first_player_id,first_guild_id,first_at,fastest_guild_id,fastest_seconds)
		VALUES($1,$2,$3,$4,$5,$4,$6) ON CONFLICT(logical_server_id,copy_id) DO UPDATE SET
		fastest_guild_id=CASE WHEN EXCLUDED.fastest_seconds<guild_campaign_server_kills.fastest_seconds THEN EXCLUDED.fastest_guild_id ELSE guild_campaign_server_kills.fastest_guild_id END,
		fastest_seconds=LEAST(guild_campaign_server_kills.fastest_seconds,EXCLUDED.fastest_seconds)`,
		int64(server), copyID, player, guildID, at, elapsed)
	if err != nil {
		return app.ServerKill{}, false, err
	}
	return Store{}.ServerKillReadTx(ctx, t, server, copyID)
}

func (Store) ServerKillReadTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, copyID int64) (app.ServerKill, bool, error) {
	var out app.ServerKill
	err := q.QueryRow(ctx, `SELECT first_player_id,first_guild_id,first_at,fastest_guild_id,fastest_seconds FROM guild_campaign_server_kills WHERE logical_server_id=$1 AND copy_id=$2`,
		int64(server), copyID).Scan(&out.FirstPlayerID, &out.FirstGuildID, &out.FirstAt, &out.FastestGuild, &out.FastestSecond)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return app.ServerKill{}, false, nil
	}
	return out, err == nil, err
}

func (Store) ListGuildLogTx(ctx context.Context, q tx.Queryer, guildID int64, cutoff time.Time, limit int) ([]app.GuildLogRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('type',log_type,'player_id',player_id,'chapter_id',chapter_id,'at',EXTRACT(EPOCH FROM at)::bigint) ORDER BY at DESC),'[]'::jsonb)::text
		FROM (SELECT log_type,player_id,chapter_id,at FROM guild_campaign_log WHERE guild_id=$1 AND at>=$2 ORDER BY at DESC LIMIT $3) recent`, guildID, cutoff, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		Type      int64 `json:"type"`
		PlayerID  int64 `json:"player_id"`
		ChapterID int64 `json:"chapter_id"`
		At        int64 `json:"at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.GuildLogRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.GuildLogRow{Type: row.Type, PlayerID: row.PlayerID, ChapterID: row.ChapterID, At: time.Unix(row.At, 0).UTC()})
	}
	return out, nil
}

func (Store) InsertAwardsTx(ctx context.Context, t tx.Tx, guildID, chapterID, run int64, seeds []app.AwardSeed) error {
	for _, seed := range seeds {
		if _, err := t.Exec(ctx, `INSERT INTO guild_campaign_awards(guild_id,chapter_id,run,award_id,remaining,expires_at,next_slot)
			VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(guild_id,chapter_id,run,award_id) DO NOTHING`,
			guildID, chapterID, run, seed.AwardID, seed.Remaining, seed.ExpiresAt, seed.NextSlot); err != nil {
			return err
		}
	}
	return nil
}

func (Store) ListAwardsTx(ctx context.Context, q tx.Queryer, guildID, chapterID, run int64) ([]app.AwardRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('award_id',award_id,'remaining',remaining,'expires',EXTRACT(EPOCH FROM expires_at)::bigint,'next',EXTRACT(EPOCH FROM next_slot)::bigint) ORDER BY award_id),'[]'::jsonb)::text
		FROM guild_campaign_awards WHERE guild_id=$1 AND chapter_id=$2 AND run=$3`, guildID, chapterID, run).Scan(&raw)
	if err != nil {
		return nil, err
	}
	return decodeAwards(raw, guildID, chapterID, run)
}

func (Store) ListDueAwardsTx(ctx context.Context, q tx.Queryer, at time.Time, limit int) ([]app.AwardRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('guild_id',guild_id,'chapter_id',chapter_id,'run',run,'award_id',award_id,'remaining',remaining,'expires',EXTRACT(EPOCH FROM expires_at)::bigint,'next',EXTRACT(EPOCH FROM next_slot)::bigint) ORDER BY next_slot),'[]'::jsonb)::text
		FROM (SELECT guild_id,chapter_id,run,award_id,remaining,expires_at,next_slot FROM guild_campaign_awards WHERE remaining>0 AND next_slot<=$1 AND expires_at>$1 ORDER BY next_slot LIMIT $2) due`, at, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		GuildID   int64 `json:"guild_id"`
		ChapterID int64 `json:"chapter_id"`
		Run       int64 `json:"run"`
		AwardID   int64 `json:"award_id"`
		Remaining int64 `json:"remaining"`
		Expires   int64 `json:"expires"`
		Next      int64 `json:"next"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.AwardRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.AwardRow{GuildID: row.GuildID, ChapterID: row.ChapterID, Run: row.Run, AwardID: row.AwardID, Remaining: row.Remaining,
			ExpiresAt: time.Unix(row.Expires, 0).UTC(), NextSlot: time.Unix(row.Next, 0).UTC()})
	}
	return out, nil
}

func (Store) LockAwardTx(ctx context.Context, t tx.Tx, key app.AwardRow) (app.AwardRow, bool, error) {
	row := app.AwardRow{GuildID: key.GuildID, ChapterID: key.ChapterID, Run: key.Run, AwardID: key.AwardID}
	err := t.QueryRow(ctx, `SELECT remaining,expires_at,next_slot FROM guild_campaign_awards
		WHERE guild_id=$1 AND chapter_id=$2 AND run=$3 AND award_id=$4 FOR UPDATE`,
		key.GuildID, key.ChapterID, key.Run, key.AwardID).Scan(&row.Remaining, &row.ExpiresAt, &row.NextSlot)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return app.AwardRow{}, false, nil
	}
	return row, err == nil, err
}

func (Store) SaveAwardTx(ctx context.Context, t tx.Tx, row app.AwardRow) error {
	_, err := t.Exec(ctx, `UPDATE guild_campaign_awards SET remaining=$5,next_slot=$6
		WHERE guild_id=$1 AND chapter_id=$2 AND run=$3 AND award_id=$4`,
		row.GuildID, row.ChapterID, row.Run, row.AwardID, row.Remaining, row.NextSlot)
	return err
}

func (Store) ApplicationTx(ctx context.Context, q tx.Queryer, guildID, chapterID, run int64, player identity.PlayerID) (app.ApplicationRow, bool, error) {
	row := app.ApplicationRow{PlayerID: int64(player)}
	err := q.QueryRow(ctx, `SELECT award_id,applied_at FROM guild_campaign_applications WHERE guild_id=$1 AND chapter_id=$2 AND run=$3 AND player_id=$4`,
		guildID, chapterID, run, int64(player)).Scan(&row.AwardID, &row.AppliedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return app.ApplicationRow{}, false, nil
	}
	return row, err == nil, err
}

func (Store) ApplicationsByAwardTx(ctx context.Context, q tx.Queryer, guildID, chapterID, run int64) ([]app.ApplicationRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'award_id',award_id,'applied',EXTRACT(EPOCH FROM applied_at)::bigint) ORDER BY applied_at,player_id),'[]'::jsonb)::text
		FROM guild_campaign_applications WHERE guild_id=$1 AND chapter_id=$2 AND run=$3`, guildID, chapterID, run).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		AwardID  int64 `json:"award_id"`
		Applied  int64 `json:"applied"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.ApplicationRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.ApplicationRow{PlayerID: row.PlayerID, AwardID: row.AwardID, AppliedAt: time.Unix(row.Applied, 0).UTC()})
	}
	return out, nil
}

func (Store) ApplyTx(ctx context.Context, t tx.Tx, guildID, chapterID, run int64, player identity.PlayerID, awardID int64, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_applications(guild_id,chapter_id,run,player_id,award_id,applied_at) VALUES($1,$2,$3,$4,$5,$6)
		ON CONFLICT(guild_id,chapter_id,run,player_id) DO UPDATE SET award_id=EXCLUDED.award_id,applied_at=EXCLUDED.applied_at`,
		guildID, chapterID, run, int64(player), awardID, at)
	return err
}

func (Store) ApplicationCountTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, day int64) (int64, error) {
	var count int64
	err := q.QueryRow(ctx, `SELECT applications FROM guild_campaign_application_days WHERE player_id=$1 AND game_day=$2`, int64(player), day).Scan(&count)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, nil
	}
	return count, err
}

func (Store) BumpApplicationCountTx(ctx context.Context, t tx.Tx, player identity.PlayerID, day int64) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_application_days(player_id,game_day,applications) VALUES($1,$2,1)
		ON CONFLICT(player_id,game_day) DO UPDATE SET applications=guild_campaign_application_days.applications+1`, int64(player), day)
	return err
}

func (Store) InsertDistributionTx(ctx context.Context, t tx.Tx, guildID int64, player identity.PlayerID, itemID int64, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_distributions(guild_id,player_id,item_id,distributed_at) VALUES($1,$2,$3,$4)`,
		guildID, int64(player), itemID, at)
	return err
}

func (Store) ListDistributionsTx(ctx context.Context, q tx.Queryer, guildID int64, limit int) ([]app.DistributionRow, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'item_id',item_id,'at',EXTRACT(EPOCH FROM distributed_at)::bigint) ORDER BY distributed_at DESC),'[]'::jsonb)::text
		FROM (SELECT player_id,item_id,distributed_at FROM guild_campaign_distributions WHERE guild_id=$1 ORDER BY distributed_at DESC LIMIT $2) recent`, guildID, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		ItemID   int64 `json:"item_id"`
		At       int64 `json:"at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.DistributionRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.DistributionRow{PlayerID: row.PlayerID, ItemID: row.ItemID, Distributed: time.Unix(row.At, 0).UTC()})
	}
	return out, nil
}

func decodeAwards(raw string, guildID, chapterID, run int64) ([]app.AwardRow, error) {
	var rows []struct {
		AwardID   int64 `json:"award_id"`
		Remaining int64 `json:"remaining"`
		Expires   int64 `json:"expires"`
		Next      int64 `json:"next"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]app.AwardRow, 0, len(rows))
	for _, row := range rows {
		out = append(out, app.AwardRow{GuildID: guildID, ChapterID: chapterID, Run: run, AwardID: row.AwardID, Remaining: row.Remaining,
			ExpiresAt: time.Unix(row.Expires, 0).UTC(), NextSlot: time.Unix(row.Next, 0).UTC()})
	}
	return out, nil
}

// CopyChallengeTimesTx is the 612 member row's copy_challenge_times: the
// member's cleared Guild Campaign stages today, across chapters.
func (Store) CopyChallengeTimesTx(ctx context.Context, q tx.Queryer, players []identity.PlayerID, day int64) (map[identity.PlayerID]int64, error) {
	out := map[identity.PlayerID]int64{}
	if len(players) == 0 {
		return out, nil
	}
	ids := make([]int64, 0, len(players))
	for _, player := range players {
		ids = append(ids, int64(player))
	}
	raw, err := json.Marshal(ids)
	if err != nil {
		return nil, err
	}
	var body string
	if err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(player_id,total),'{}')::text FROM (
		SELECT player_id,SUM(clears)::bigint AS total FROM guild_campaign_member_days
		WHERE game_day=$1 AND player_id IN (SELECT jsonb_array_elements_text($2::jsonb)::bigint) GROUP BY player_id) sums`, day, string(raw)).Scan(&body); err != nil {
		return nil, err
	}
	var rows map[string]int64
	if err := json.Unmarshal([]byte(body), &rows); err != nil {
		return nil, err
	}
	for key, value := range rows {
		id, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			return nil, err
		}
		out[identity.PlayerID(id)] = value
	}
	return out, nil
}
