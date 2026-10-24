package guildprojection

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RealtimeMembership is a read-only adapter from canonical I6C GuildMembership
// truth to the I7A/realtime authorization seam. Canonical Guild SQL remains in
// guildstore; this adapter only translates the owner-owned read to the typed
// realtime application port.
type RealtimeMembership struct{ Queryer tx.Queryer }

func (r RealtimeMembership) CurrentGuildBinding(ctx context.Context, actor identity.ActorContext) (apprealtime.GuildBinding, bool, error) {
	binding, ok, err := (guildstore.Store{Queryer: r.Queryer}).CurrentRealtimeBinding(ctx, actor)
	if err != nil || !ok {
		return apprealtime.GuildBinding{}, ok, err
	}
	out := apprealtime.GuildBinding{GuildID: binding.GuildID, JoinEventID: binding.JoinEventID}
	if !out.Valid() {
		return apprealtime.GuildBinding{}, false, errors.New("invalid canonical realtime guild binding")
	}
	return out, true, nil
}

var _ apprealtime.GuildMembershipPort = RealtimeMembership{}
