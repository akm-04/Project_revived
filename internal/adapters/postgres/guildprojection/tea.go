package guildprojection

import (
	"context"
	"errors"
	"time"

	guildwire "gxb.local/backend/v2/internal/adapters/guildwire"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/guildtea"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TeaProjection overlays the Guild-owned MID1 MID 1808 self_wish_info, which the
// client reads through SelfGuild:teaTalkInitRed (I9_GUILD_ACTIVITY_V1 C13).
type TeaProjection struct{}

func (TeaProjection) Name() string     { return "i9-9a.guild-tea" }
func (TeaProjection) Claims() []string { return []string{"1808"} }

func (TeaProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() {
		return errors.New("guild tea bootstrap: invalid projection input")
	}
	service := guildtea.Service{Store: guildstore.Store{}}
	state, ok, err := service.MID1(ctx, q, actor.PlayerID, modes.Day(observedAt))
	if err != nil {
		return err
	}
	if ok {
		detail["1808"] = guildwire.Tea(state)
	}
	return nil
}

var _ appboot.MID1DetailContributor = TeaProjection{}
