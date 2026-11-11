package petcampaign

import "testing"

func TestRankListBodyHidesUnrankedSelfEntry(t *testing.T) {
	body := petcampaignRankListBody(normalRankSubtype, 0, 7, nil)
	list := body["rank_list"].([]map[string]any)
	info := list[0]["rank_info"].(map[string]any)
	entry, ok := info["my_rank"].(map[string]any)
	if !ok || len(entry) != 0 {
		t.Fatalf("unranked my_rank = %#v, want empty table", info["my_rank"])
	}

	body = petcampaignRankListBody(normalRankSubtype, 4, 7, nil)
	list = body["rank_list"].([]map[string]any)
	info = list[0]["rank_info"].(map[string]any)
	entry, ok = info["my_rank"].(map[string]any)
	if !ok || entry["rank"] != int64(4) || entry["my_floor"] != int64(7) {
		t.Fatalf("ranked my_rank = %#v", info["my_rank"])
	}
}
