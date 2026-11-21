package stockruntime

import (
	"context"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/foundation/changes"
)

func TestHeroPromotionResponseCarriesMissionChanges(t *testing.T) {
	ctx, _ := changes.Track(context.Background())
	rows := []any{map[string]any{"table_id": int64(20001), "count": int64(1)}}
	changes.Missions(ctx, map[string]any{"mainline_mission_": rows})
	body := heroPromotionResponse(ctx, apphero.HeroPromotionResult{})
	got, ok := body["mainline_mission_"].([]any)
	if !ok || len(got) != 1 {
		t.Fatalf("promotion reply lost mission changes: %#v", body)
	}
}
