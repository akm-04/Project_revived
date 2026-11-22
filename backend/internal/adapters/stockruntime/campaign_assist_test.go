package stockruntime

import "testing"

func TestCampaignResultCarriesAssistPartner(t *testing.T) {
	params := map[string]any{"campaign_id": int64(100007), "campaign_type": int64(1), "star": int64(3), "formation": "1|2", "assist_partner": int64(10001053)}
	request, ok := campaignResult(params)
	if !ok || request.AssistPartner != 10001053 {
		t.Fatalf("assist partner %+v %v", request, ok)
	}
	delete(params, "assist_partner")
	request, ok = campaignResult(params)
	if !ok || request.AssistPartner != 0 {
		t.Fatalf("absent assist partner %+v %v", request, ok)
	}
	params["assist_partner"] = int64(-1)
	if _, ok = campaignResult(params); ok {
		t.Fatal("negative assist partner")
	}
}
