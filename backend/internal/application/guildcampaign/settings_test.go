package guildcampaign

import "testing"

func TestSettingsChapterVersionDefaultsToOne(t *testing.T) {
	if got := (Settings{}).ChapterVersion(7); got != 1 {
		t.Fatalf("default chapter version %d, want 1", got)
	}
	settings := Settings{ChapterVersions: map[int64]int64{7: 2}}
	if got := settings.ChapterVersion(7); got != 2 {
		t.Fatalf("mapped chapter version %d, want 2", got)
	}
	if got := settings.ChapterVersion(8); got != 1 {
		t.Fatalf("unmapped chapter version %d, want 1", got)
	}
}
