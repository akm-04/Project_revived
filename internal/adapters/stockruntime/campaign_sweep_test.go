package stockruntime

import (
	"gxb.local/backend/v2/internal/foundation/receipt"
	"net/http"
	"testing"
)

func TestCampaignSweepStockParams(t *testing.T) {
	p := map[string]any{"campaign_id": 100001, "campaign_type": 1, "sweep_num": 10, "sweep_type": 2, "itemComposeID": 50001001, "needItemComposeNum": 1}
	if _, ok := campaignSweep(p); !ok {
		t.Fatal("stock compose params refused")
	}
	for key, value := range map[string]any{"sweep_num": 11, "sweep_type": 3, "campaign_type": 24, "formation": "1|0|0|0|0"} {
		q := map[string]any{}
		for k, v := range p {
			q[k] = v
		}
		q[key] = value
		if _, ok := campaignSweep(q); ok {
			t.Fatal("forged request accepted", key)
		}
	}
}

func TestCampaignPurchaseConflictIsClientError(t *testing.T) {
	response := failCampaign(&receipt.ConflictError{})
	if response.HTTPStatus != http.StatusBadRequest {
		t.Fatal(response)
	}
}
