//go:build postgres

package playerdisplay_test

import (
	"context"
	"sync"
	"testing"

	app "gxb.local/backend/v2/internal/application/guildcampaign"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// A-059: MID 603 decides membership inside its REPEATABLE READ READ ONLY
// snapshot. A leave and another member's progress commit before the snapshot
// opens, so the departed member receives the coherent post-leave empty Lists.
func TestC13BMembershipSharesGuildCampaignReadSnapshotNative(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.copyID(t)
	f.mutateCopy(t, chapterID, copyID, func(copy *d.Copy, waves map[int64][]app.EnemyRow) {
		copy.CurrentIndex = 3
		copy.Percent = 2.0 / 3
		killWaves(waves, 1, 2)
	})
	gate := newCampaignBeginGate(f.pool)
	reader := f.mode
	reader.Runner = tx.Runner{DB: gate}
	core := f.core(t)
	var lists app.Lists
	err := runReadUnderWrite(t, gate,
		func(c context.Context) error {
			if _, err := core.Leave(c, f.second, op()); err != nil {
				return err
			}
			f.fight(t, f.third, chapterID, copyID, f.thirdHero, 4000, 3, 0, f.at)
			return nil
		},
		func(c context.Context) error {
			var readErr error
			lists, readErr = reader.GuildMap(c, f.second, f.op())
			return readErr
		})
	if err != nil {
		t.Fatalf("603 read: %v", err)
	}
	if len(lists.Chapters) != 0 || len(lists.Copies) != 0 {
		t.Fatalf("departed member received post-departure campaign state: %+v", lists)
	}
	var progress float64
	if err := f.pool.QueryRow(ctx, `SELECT percent FROM guild_campaign_chapters WHERE guild_id=$1 AND chapter_id=$2`,
		int64(f.guild), chapterID).Scan(&progress); err != nil {
		t.Fatal(err)
	}
	if progress <= 0 {
		t.Fatalf("concurrent member's progress did not commit: %v", progress)
	}
}

// campaignBeginGate holds a read-only transaction before it begins, so a writer
// can commit a leave and a progress update after the old membership read.
type campaignBeginGate struct {
	inner       tx.Beginner
	firstScan   chan struct{}
	release     chan struct{}
	once        sync.Once
	releaseOnce sync.Once
}

func newCampaignBeginGate(inner tx.Beginner) *campaignBeginGate {
	return &campaignBeginGate{inner: inner, firstScan: make(chan struct{}), release: make(chan struct{})}
}

func (g *campaignBeginGate) Begin(c context.Context, options tx.Options) (tx.Tx, error) {
	if !options.ReadOnly {
		return g.inner.Begin(c, options)
	}
	g.once.Do(func() { close(g.firstScan) })
	<-g.release
	return g.inner.Begin(c, options)
}

func (g *campaignBeginGate) unblock() {
	g.releaseOnce.Do(func() { close(g.release) })
}

func (g *campaignBeginGate) scanned() <-chan struct{} { return g.firstScan }
