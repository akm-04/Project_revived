package occult

import "testing"

// TestGeneratedCatalogHasOneFinalPerChapterAndMode pins the source
// creats_campaign.special_reward law: exactly one final node per chapter and
// campaign type, 10013/10026 for chapter 1.
func TestGeneratedCatalogHasOneFinalPerChapterAndMode(t *testing.T) {
	catalog := generatedCatalog(t)
	finals := map[[2]int64]int64{}
	for _, campaign := range catalog.Campaigns {
		if campaign.Final() {
			finals[[2]int64{campaign.ChapterID, campaign.CampaignType}] = campaign.ID
		}
	}
	want := map[[2]int64]int64{
		{1, MultiCampaignType}: 10013, {1, SingleCampaignType}: 10026,
		{2, MultiCampaignType}: 20009, {2, SingleCampaignType}: 20018,
		{3, MultiCampaignType}: 30009, {3, SingleCampaignType}: 30018,
		{4, MultiCampaignType}: 40008, {4, SingleCampaignType}: 40016,
		{5, MultiCampaignType}: 50010, {5, SingleCampaignType}: 50020,
		{6, MultiCampaignType}: 60010, {6, SingleCampaignType}: 60020,
	}
	for pair, id := range want {
		if finals[pair] != id {
			t.Fatalf("chapter %d mode %d final %d, want %d", pair[0], pair[1], finals[pair], id)
		}
	}
	if len(finals) != 12 {
		t.Fatalf("final census %v", finals)
	}
}

func TestCatalogValidateRefusesFinalCensusDrift(t *testing.T) {
	for name, mutate := range map[string]func(*Catalog){
		"missing": func(catalog *Catalog) {
			for index := range catalog.Campaigns {
				if catalog.Campaigns[index].ID == 10013 {
					catalog.Campaigns[index].SpecialReward = 0
				}
			}
		},
		"duplicate": func(catalog *Catalog) {
			for index := range catalog.Campaigns {
				if catalog.Campaigns[index].ID == 10002 {
					catalog.Campaigns[index].SpecialReward = 230001001
				}
			}
		},
	} {
		catalog := generatedCatalog(t)
		mutate(&catalog)
		if err := catalog.Validate(); err == nil {
			t.Fatalf("%s final census was accepted", name)
		}
	}
}

// TestChapterOneClearsOnlyWhenItsFinalFalls is A-181: the chapter 1 final rows
// keep back edges, so the old "no unlock edges" predicate could never clear.
func TestChapterOneClearsOnlyWhenItsFinalFalls(t *testing.T) {
	catalog := generatedCatalog(t)
	run := NewRun(1, MultiCampaignType)
	if err := run.BindRoom(catalog); err != nil {
		t.Fatal(err)
	}
	if run.ChapterCleared(catalog) {
		t.Fatal("a fresh room is cleared")
	}
	for _, campaign := range catalog.RoomCampaigns(1, MultiCampaignType) {
		if campaign.ID == 10013 {
			continue
		}
		for index := range run.Stages[key(campaign.ID)] {
			run.Stages[key(campaign.ID)][index].HP = 0
		}
	}
	if run.ChapterCleared(catalog) {
		t.Fatal("the chapter cleared without its final")
	}
	for index := range run.Stages[key(10013)] {
		run.Stages[key(10013)][index].HP = 0
	}
	if !run.ChapterCleared(catalog) {
		t.Fatal("chapter 1 did not clear when 10013 fell")
	}
}
