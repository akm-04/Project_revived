package campaign

import (
	"errors"
	"testing"
)

func TestBonusCumulativeCursorAndChapterEntitlements(t *testing.T) {
	c := loadCatalog(t)
	p := Progress{Nodes: map[int64]NodeState{}}
	if c.Info(p, false).NormalBonusID != 1 || c.Info(p, false).SuperBonusID != 101 {
		t.Fatal("initial cursors")
	}
	if _, _, err := c.ClaimBonus(p, Normal); !errors.Is(err, ErrRefused) {
		t.Fatal(err)
	}
	for _, id := range []int64{100001, 100004, 100007, 100011, 100015, 100018} {
		p.Nodes[id] = NodeState{CampaignID: id, Star: 3}
	}
	next, b, err := c.ClaimBonus(p, Normal)
	if err != nil || b.ID != 1 || next.NormalBonusID != 2 {
		t.Fatal(b, err)
	}
	// Moving the chapter cursor must not erase stars already earned.
	p.Nodes[200002] = NodeState{CampaignID: 200002, Star: 3}
	p.Nodes[100002] = NodeState{CampaignID: 100002, Star: 3}
	if c.TotalStars(p, Normal) != 21 {
		t.Fatal("global star sum")
	}
	event := c.ChapterEvent(p, 1)
	if event["left_times"] != int64(1) {
		t.Fatal(event)
	}
	next, items, err := c.ClaimChapter(p, 1)
	if err != nil || len(items) != 1 || items[0] != [2]int64{50001024, 3} {
		t.Fatal(items, err)
	}
	if p.ChapterClaims[1] != 0 {
		t.Fatal("input mutated")
	}
	if _, _, err = c.ClaimChapter(next, 1); !errors.Is(err, ErrRefused) {
		t.Fatal(err)
	}
	next.Nodes[100024] = NodeState{CampaignID: 100024, Star: 1}
	next, _, err = c.ClaimChapter(next, 1)
	if err != nil || next.ChapterClaims[1] != 2 {
		t.Fatal(err)
	}
	if _, _, err = c.ClaimChapter(next, 7); !errors.Is(err, ErrInvalid) {
		t.Fatal("boss granted as gacha", err)
	}
	p.ChapterClaims = map[int64]int64{1: -1}
	if _, _, err = c.ClaimChapter(p, 1); !errors.Is(err, ErrUnavailable) {
		t.Fatal("corrupt negative claim count", err)
	}
	next.NormalBonusID = 24
	if _, _, err = c.ClaimBonus(next, Normal); !errors.Is(err, ErrRefused) {
		t.Fatal("terminal cursor wrapped", err)
	}
}

func TestHistoricalCatalogRemainsReadableWithoutActivatingMissingGiftPayload(t *testing.T) {
	c := loadCatalog(t)
	c.ChapterGifts = nil
	if err := c.Validate(); err != nil {
		t.Fatal(err)
	}
	p := Progress{Nodes: map[int64]NodeState{100018: {CampaignID: 100018, Star: 3}}}
	if _, _, err := c.ClaimChapter(p, 1); !errors.Is(err, ErrUnavailable) {
		t.Fatal("old content manufactured a gift", err)
	}
}

func TestDisplayedStarsMatchEveryChapterBonus(t *testing.T) {
	c := loadCatalog(t)
	p := Progress{Nodes: map[int64]NodeState{}}
	for _, n := range c.Nodes {
		p.Nodes[n.ID] = NodeState{CampaignID: n.ID, Star: 3}
	}
	for _, kind := range []int64{Normal, Super} {
		if got := c.TotalStars(p, kind); got != 465 {
			t.Fatalf("kind %d: %d", kind, got)
		}
	}
}
