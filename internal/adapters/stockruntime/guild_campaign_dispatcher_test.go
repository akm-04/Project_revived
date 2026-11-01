package stockruntime

import (
	"net/http"
	"testing"

	app "gxb.local/backend/v2/internal/application/guildcampaign"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
)

func TestI9_9CSettleRefusalsAre409AndLateIs30021(t *testing.T) {
	late := campaignSettleFailure(app.ErrLate)
	if late.HTTPStatus != http.StatusConflict || late.Body["error_code"] != int64(30021) {
		t.Fatalf("late %+v", late)
	}
	refused := campaignSettleFailure(d.ErrRefused)
	if refused.HTTPStatus != http.StatusConflict || refused.Body["error_code"] != int64(1) {
		t.Fatalf("refused %+v", refused)
	}
	if unavailable := campaignSettleFailure(app.ErrUnavailable); unavailable.HTTPStatus != http.StatusServiceUnavailable {
		t.Fatalf("unavailable %+v", unavailable)
	}
}

func TestI9_9CNoticeRefRoundTrips(t *testing.T) {
	ref := GuildCampaignNoticeRef(11, 7, 700028, 123)
	guild, chapter, copy, player, err := decodeGuildCampaignNoticeRef(ref)
	if err != nil || guild != 11 || chapter != 7 || copy != 700028 || int64(player) != 123 {
		t.Fatalf("ref %q %+v %v", ref, []int64{guild, chapter, copy, int64(player)}, err)
	}
}
