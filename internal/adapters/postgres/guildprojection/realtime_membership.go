package guildprojection

import (
	"context"

	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/application/guildview"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RealtimeMembership is a read-only adapter from canonical I6C GuildMembership
// truth to the I7A/realtime authorization seam. It does not publish, mutate
// rooms, or own socket lifecycle.
type RealtimeMembership struct{ Queryer tx.Queryer }

func (r RealtimeMembership) GuildRoom(ctx context.Context, actor identity.ActorContext) (int64, bool, error) {
	return (guildview.Service{Store: guildstore.Store{Queryer: r.Queryer}}).GuildRoom(ctx, actor)
}

var _ apprealtime.GuildMembershipPort = RealtimeMembership{}
