package guildprojection

import (
	"context"
	"errors"
	"time"

	guildproj "gxb.local/backend/v2/internal/adapters/guildwire"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/guildview"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BootstrapProjection overlays only canonical I6C Guild-owned MID1 fields.
// It reuses the caller-owned MID1 transaction/queryer so MID17.guild_id and
// MID612 describe one coherent GuildMembership snapshot.
type BootstrapProjection struct{}

func (BootstrapProjection) Name() string     { return "i6c.guild-membership" }
func (BootstrapProjection) Claims() []string { return []string{"17.guild_id", "612"} }

func (BootstrapProjection) OverlayMID1(ctx context.Context, q tx.Queryer, actor identity.ActorContext, _ bool, observedAt time.Time, detail map[string]any) error {
	if q == nil || detail == nil || observedAt.IsZero() || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() {
		return errors.New("guild bootstrap: invalid projection input")
	}
	mid17, ok := detail["17"].(map[string]any)
	if !ok {
		return errors.New("guild bootstrap: MID17 frozen baseline missing")
	}
	rev, err := (contentstore.Store{}).ActiveRevision(ctx, q)
	if err != nil {
		return err
	}
	view := guildview.Service{
		Store:     guildstore.Store{Queryer: q},
		Directory: publicpresentation.Reader{Queryer: q, Revision: rev, ObservedAt: observedAt},
	}
	self, member, err := view.Self(ctx, actor)
	if err != nil {
		return err
	}
	if !member {
		mid17["guild_id"] = int64(0)
		detail["612"] = guildproj.EmptySelf()
		return nil
	}
	mid17["guild_id"] = self.GuildInfo.GuildID
	detail["612"] = guildproj.Self(self)
	return nil
}

var _ appboot.MID1DetailContributor = BootstrapProjection{}
