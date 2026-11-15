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
	return r.CurrentGuildBindingTx(ctx, r.Queryer, actor)
}

func (r RealtimeMembership) CurrentGuildBindingTx(ctx context.Context, q tx.Queryer, actor identity.ActorContext) (apprealtime.GuildBinding, bool, error) {
	binding, ok, err := (guildstore.Store{Queryer: q}).CurrentRealtimeBinding(ctx, actor)
	if err != nil || !ok {
		return apprealtime.GuildBinding{}, ok, err
	}
	out := apprealtime.GuildBinding{GuildID: binding.GuildID, JoinEventID: binding.JoinEventID}
	if !out.Valid() {
		return apprealtime.GuildBinding{}, false, errors.New("invalid canonical realtime guild binding")
	}
	return out, true, nil
}

// CurrentGuildBindings translates the same canonical incarnation for a whole
// recipient set in one owner read.
func (r RealtimeMembership) CurrentGuildBindings(ctx context.Context, actors []identity.ActorContext) (map[int64]apprealtime.GuildBinding, error) {
	bindings, err := (guildstore.Store{Queryer: r.Queryer}).CurrentRealtimeBindings(ctx, actors)
	if err != nil {
		return nil, err
	}
	out := make(map[int64]apprealtime.GuildBinding, len(bindings))
	for playerID, binding := range bindings {
		out[int64(playerID)] = apprealtime.GuildBinding{GuildID: binding.GuildID, JoinEventID: binding.JoinEventID}
	}
	return out, nil
}

var _ apprealtime.GuildMembershipPort = RealtimeMembership{}
