//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"

	appguild "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MID 603 (guild map) keeps one snapshot while another transaction commits a
// copy row of the same guild.
func TestC13BReadOnlyGuildCampaignSnapshotNative(t *testing.T) {
	fixture := newCampaignFixture(t)
	fixture.seedActivity(t, 40)
	if _, err := fixture.mode.Open(ctx, fixture.leader, 7, fixture.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := fixture.copyID(t)
	var before float64
	if err := fixture.pool.QueryRow(ctx, `SELECT percent FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$3`,
		int64(fixture.guild), chapterID, copyID).Scan(&before); err != nil {
		t.Fatal(err)
	}
	gate := newSnapshotGate(fixture.pool)
	fixture.mode.Runner = tx.Runner{DB: gate}
	var lists appguild.Lists
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			return commitConcurrentWrite(t, fixture.pool, `UPDATE guild_campaign_copies SET percent=0.42 WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$3`,
				int64(fixture.guild), chapterID, copyID)
		},
		func(c context.Context) error {
			var readErr error
			lists, readErr = fixture.mode.GuildMap(c, fixture.leader, fixture.op())
			return readErr
		})
	if err != nil {
		t.Fatalf("603 read: %v", err)
	}
	if len(lists.Chapters) == 0 {
		t.Fatal("603 chapter_list empty")
	}
	found := false
	for _, copy := range lists.Copies {
		if copy.CopyID != copyID {
			continue
		}
		found = true
		if copy.Percent != before {
			t.Fatalf("603 saw a row committed during the request: percent %v, snapshot %v", copy.Percent, before)
		}
	}
	if !found {
		t.Fatalf("603 copy_list lost copy %d", copyID)
	}
	var latest float64
	if err := fixture.pool.QueryRow(ctx, `SELECT percent FROM guild_campaign_copies WHERE guild_id=$1 AND chapter_id=$2 AND copy_id=$3`,
		int64(fixture.guild), chapterID, copyID).Scan(&latest); err != nil {
		t.Fatal(err)
	}
	if latest != 0.42 {
		t.Fatalf("concurrent write did not commit: %v", latest)
	}
}
