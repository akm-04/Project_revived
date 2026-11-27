//go:build postgres

package main

import (
	"context"
	"encoding/json"
	"time"

	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	appevents "gxb.local/backend/v2/internal/application/events"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// campaignDropHooks decodes the events owner's drop hook (I11A_EVENTS_V1
// ruling 9-10, EA-8) into Campaign's own port shape.
type campaignDropHooks struct{ Events appevents.Service }

func (hooks campaignDropHooks) DropHooksTx(ctx context.Context, q tx.Queryer, server int64, at time.Time) ([]appcampaign.DropHook, error) {
	raw, err := hooks.Events.ActiveModifiers(ctx, q, server, at, domainevents.HookCampaignDropMultiplier)
	if err != nil {
		return nil, err
	}
	decoded := make([]appcampaign.DropHook, 0, len(raw))
	for _, payload := range raw {
		var hook domainevents.Hook
		if err := json.Unmarshal(payload, &hook); err != nil {
			return nil, err
		}
		decoded = append(decoded, appcampaign.DropHook{Scope: hook.Scope, ItemKinds: hook.ItemKinds, Multiplier: hook.Multiplier})
	}
	return decoded, nil
}
