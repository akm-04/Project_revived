// Package guildcampaignstore is the persistence of I9_GUILD_CAMPAIGN_V1.
package guildcampaignstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

// LockChapterTx takes one chapter at rank 606.
func (Store) LockChapterTx(ctx context.Context, t tx.Tx, guildID, chapterID int64) (d.Chapter, bool, error) {
	chapter := d.Chapter{GuildID: guildID, ChapterID: chapterID}
	err := t.QueryRow(ctx, `SELECT run,is_win,percent,start_time,end_time FROM guild_campaign_chapters WHERE guild_id=$1 AND chapter_id=$2 FOR UPDATE`, guildID, chapterID).
		Scan(&chapter.Run, &chapter.Win, &chapter.Percent, &chapter.StartTime, &chapter.EndTime)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Chapter{}, false, nil
	}
	return chapter, err == nil, err
}

// ChapterWonTx reads whether a guild has won a chapter, without a lock: the guild
// lock of open and reset serialises this against every path that resets it.
func (Store) ChapterWonTx(ctx context.Context, q tx.Queryer, guildID, chapterID int64) (bool, error) {
	var won bool
	err := q.QueryRow(ctx, `SELECT is_win FROM guild_campaign_chapters WHERE guild_id=$1 AND chapter_id=$2`, guildID, chapterID).Scan(&won)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return false, nil
	}
	return won, err
}

// LockGuildChaptersTx takes every open chapter of a guild at rank 606 in chapter
// order, and reports them with their locks held.
func (Store) LockGuildChaptersTx(ctx context.Context, t tx.Tx, guildID int64) ([]int64, error) {
	var raw string
	err := t.QueryRow(ctx, `WITH locked AS (
		SELECT chapter_id FROM guild_campaign_chapters WHERE guild_id=$1 ORDER BY chapter_id FOR UPDATE
	) SELECT COALESCE(jsonb_agg(chapter_id ORDER BY chapter_id),'[]')::text FROM locked`, guildID).Scan(&raw)
	if err != nil {
		return nil, err
	}
	chapters := []int64{}
	return chapters, json.Unmarshal([]byte(raw), &chapters)
}

// LockChapterCopiesTx takes a chapter's copies at rank 607 in copy order.
func (Store) LockChapterCopiesTx(ctx context.Context, t tx.Tx, guildID, chapterID int64) error {
	var count int64
	return t.QueryRow(ctx, `WITH locked AS (
		SELECT copy_id FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2 ORDER BY copy_id FOR UPDATE
	) SELECT count(*) FROM locked`, guildID, chapterID).Scan(&count)
}

// BeginRunTx opens run 1 of a chapter, or moves it to a new run, with fresh
// copies and the given registration list. The caller holds 310, 606 and 607.
func (Store) BeginRunTx(ctx context.Context, t tx.Tx, chapter d.Chapter, copies []d.Copy, registered []identity.PlayerID) error {
	if _, err := t.Exec(ctx, `INSERT INTO guild_campaign_chapters(guild_id,chapter_id,run,is_win,percent,start_time,end_time) VALUES($1,$2,$3,false,0,$4,NULL)
		ON CONFLICT(guild_id,chapter_id) DO UPDATE SET run=excluded.run,is_win=false,percent=0,start_time=excluded.start_time,end_time=NULL`,
		chapter.GuildID, chapter.ChapterID, chapter.Run, chapter.StartTime); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, `DELETE FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2`, chapter.GuildID, chapter.ChapterID); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, `DELETE FROM guild_campaign_registrations WHERE guild_id=$1 AND chapter_id=$2`, chapter.GuildID, chapter.ChapterID); err != nil {
		return err
	}
	for _, stage := range copies {
		if _, err := t.Exec(ctx, `INSERT INTO guild_campaign_copies(guild_id,chapter_id,copy_id,run,waves) VALUES($1,$2,$3,$4,$5)`,
			chapter.GuildID, chapter.ChapterID, stage.CopyID, chapter.Run, string(stage.Waves)); err != nil {
			return err
		}
	}
	for _, player := range registered {
		if _, err := t.Exec(ctx, `INSERT INTO guild_campaign_registrations(guild_id,chapter_id,player_id) VALUES($1,$2,$3)`, chapter.GuildID, chapter.ChapterID, int64(player)); err != nil {
			return err
		}
	}
	return nil
}

// ListRegisteredTx is bounded by the guild member cap of the moment of open or reset.
func (Store) ListRegisteredTx(ctx context.Context, q tx.Queryer, guildID, chapterID int64) ([]identity.PlayerID, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]')::text FROM guild_campaign_registrations WHERE guild_id=$1 AND chapter_id=$2`, guildID, chapterID).Scan(&raw)
	if err != nil {
		return nil, err
	}
	players := []int64{}
	if err := json.Unmarshal([]byte(raw), &players); err != nil {
		return nil, err
	}
	out := make([]identity.PlayerID, 0, len(players))
	for _, player := range players {
		out = append(out, identity.PlayerID(player))
	}
	return out, nil
}

// RemoveMemberTx forfeits a leaver's places. The caller holds the guild's chapter rows.
func (Store) RemoveMemberTx(ctx context.Context, t tx.Tx, guildID int64, player identity.PlayerID) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_campaign_registrations WHERE guild_id=$1 AND player_id=$2`, guildID, int64(player))
	return err
}

// DeleteGuildTx removes a dissolved guild's chapters, with their copies and
// registrations by cascade. The caller holds the guild's chapter rows.
func (Store) DeleteGuildTx(ctx context.Context, t tx.Tx, guildID int64) error {
	_, err := t.Exec(ctx, `DELETE FROM guild_campaign_chapters WHERE guild_id=$1`, guildID)
	return err
}

func (Store) AppendLogTx(ctx context.Context, t tx.Tx, guildID, logType int64, player identity.PlayerID, chapterID int64, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO guild_campaign_log(guild_id,log_type,player_id,chapter_id,at) VALUES($1,$2,$3,$4,$5)`, guildID, logType, int64(player), chapterID, at)
	return err
}
