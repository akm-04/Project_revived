package guildcampaignpolicy

import (
	"testing"

	"gxb.local/backend/v2/internal/content/guildcampaigncatalog"
)

func TestBuiltinPolicyLoads(t *testing.T) {
	builtin, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	if builtin.Revision == "" || builtin.Policy.AttemptsPerChapterDay != 2 || builtin.Policy.ApplicationsPerDay != 4 {
		t.Fatalf("policy=%+v revision=%q", builtin.Policy, builtin.Revision)
	}
	if !builtin.Policy.InRestWindow(builtin.Policy.RestSecondsOfDay[0]) || builtin.Policy.InRestWindow(builtin.Policy.RestSecondsOfDay[1]) {
		t.Fatal("rest window is half-open")
	}
	if !builtin.Policy.NoticeMail.Enabled || builtin.Policy.NoticeMail.OpenTitle == "" {
		t.Fatal("notice mail missing")
	}
	if len(builtin.Policy.ChapterVersions) != 0 {
		t.Fatalf("shipped chapter versions %v, want empty", builtin.Policy.ChapterVersions)
	}
}

func TestChapterVersionsValidation(t *testing.T) {
	builtin, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := guildcampaigncatalog.LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	chapterIDs := make([]int64, 0, len(catalog.Catalog.Chapters))
	for _, chapter := range catalog.Catalog.Chapters {
		chapterIDs = append(chapterIDs, chapter.ChapterID)
	}

	p := builtin.Policy
	p.ChapterVersions = map[int64]int64{7: 3}
	if err := p.Validate(); err == nil {
		t.Fatal("chapter version 3 accepted")
	}
	p.ChapterVersions = map[int64]int64{99: 1}
	if err := p.Validate(); err != nil {
		t.Fatalf("valid version refused: %v", err)
	}
	if err := p.ValidateChapterVersions(chapterIDs); err == nil {
		t.Fatal("unknown chapter 99 accepted")
	}
	p.ChapterVersions = map[int64]int64{7: 2}
	if err := p.ValidateChapterVersions(chapterIDs); err != nil {
		t.Fatalf("catalog chapter 7 refused: %v", err)
	}
}
