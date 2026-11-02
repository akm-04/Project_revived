package stockruntime

import "testing"

func TestCloudCampaignWireSeparatesPetAndGirlIdentities(t *testing.T) {
	p := map[string]any{"campaign_id": int64(40001), "campaign_type": int64(40), "formation": "", "pet_formation": "7|9"}
	r, ok := campaignFight(p)
	if !ok || len(r.Formation) != 0 || len(r.PetFormation) != 2 {
		t.Fatal(r, ok)
	}
	p["campaign_type"] = int64(14)
	if _, ok = campaignFight(p); ok {
		t.Fatal("pet formation on Girl trial")
	}
	p = map[string]any{"campaign_id": int64(40001), "campaign_type": int64(40), "star": int64(3)}
	if _, ok = campaignResult(p); !ok {
		t.Fatal("stock Cloud omitted formation")
	}
	p["formation"] = "7"
	if _, ok = campaignResult(p); ok {
		t.Fatal("unexpected Girl echo")
	}
}
