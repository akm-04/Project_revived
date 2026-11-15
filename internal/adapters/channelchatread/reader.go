// Package channelchatread composes owner-owned canonical reads without foreign SQL.
package channelchatread

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// shareableRoom is the owner-side card gate: the room exists on the sender's
// logical server, is still open with a free seat, and the sender occupies one.
func shareableRoom(room sharedroom.Room, a apprealtime.Admission) bool {
	if room.Status != sharedroom.StatusOpen || room.LogicalServerID != a.Domain.Actor.LogicalServerID || len(room.Members()) >= int(room.Capacity) {
		return false
	}
	for _, member := range room.Members() {
		if member == a.Domain.Actor.PlayerID {
			return true
		}
	}
	return false
}

type Reader struct{}

func (r Reader) ReadTx(ctx context.Context, t tx.Tx, a apprealtime.Admission, prepare bool) (playerpresentation.Minimal, error) {
	v, e := r.ObserveTx(ctx, t, a, prepare)
	return v.Sender, e
}

// AuthorizeRecipientsTx keeps the per-delivery checks of ObserveTx but takes one
// now() and one batch liveness read for the entire recipient set. Guild rooms
// also take one batch read of the current I6C JOIN incarnations.
func (Reader) AuthorizeRecipientsTx(ctx context.Context, t tx.Tx, admissions []apprealtime.Admission) ([]bool, error) {
	authorized := make([]bool, len(admissions))
	if t == nil {
		return nil, errors.New("invalid channel recipient read transaction")
	}
	if len(admissions) == 0 {
		return authorized, nil
	}
	actors := make([]identity.ActorContext, len(admissions))
	guildActors := make([]identity.ActorContext, 0, len(admissions))
	for i, a := range admissions {
		actors[i] = a.Domain.Actor
		if a.Domain.Role == domainrt.Guild {
			guildActors = append(guildActors, a.Domain.Actor)
		}
	}
	now, err := (postgres.AuthoritativeTime{Queryer: t}).Now(ctx)
	if err != nil {
		return nil, err
	}
	live, err := (i4store.RealtimeAuthority{Queryer: t}).ValidateActors(ctx, actors, now)
	if err != nil {
		return nil, err
	}
	var bindings map[int64]apprealtime.GuildBinding
	if len(guildActors) > 0 {
		bindings, err = (guildprojection.RealtimeMembership{Queryer: t}).CurrentGuildBindings(ctx, guildActors)
		if err != nil {
			return nil, err
		}
	}
	for i, a := range admissions {
		if !live[i] {
			continue
		}
		guildID := int64(0)
		if a.Domain.Role == domainrt.Guild {
			binding, ok := bindings[int64(a.Domain.Actor.PlayerID)]
			if !ok || a.GuildBinding == nil || !a.GuildBinding.Valid() || binding != *a.GuildBinding {
				continue
			}
			guildID = binding.GuildID
		}
		if _, err := domainrt.AuthorizeRoom(a.Domain.Actor, a.Domain.Role, a.Domain.RoomID, guildID); err != nil {
			continue
		}
		authorized[i] = true
	}
	return authorized, nil
}
func (Reader) ObserveTx(ctx context.Context, t tx.Tx, a apprealtime.Admission, prepare bool) (channelchat.Observation, error) {
	if t == nil || !a.Domain.Role.Valid() || a.Domain.RoomID <= 0 {
		return channelchat.Observation{}, errors.New("invalid channel read admission")
	}
	actor := a.Domain.Actor
	// This is a fresh response/authorization observation, not a gameplay decision epoch.
	now, err := (postgres.AuthoritativeTime{Queryer: t}).Now(ctx)
	if err != nil {
		return channelchat.Observation{}, err
	}
	authority := apprealtime.Service{Authority: i4store.RealtimeAuthority{Queryer: t}, Guilds: guildprojection.RealtimeMembership{Queryer: t}}
	if err := authority.ValidateAdmission(ctx, a, now); err != nil {
		return channelchat.Observation{}, err
	}
	guildID := int64(0)
	if a.GuildBinding != nil {
		guildID = a.GuildBinding.GuildID
	}
	if _, err := domainrt.AuthorizeRoom(actor, a.Domain.Role, a.Domain.RoomID, guildID); err != nil {
		return channelchat.Observation{}, err
	}
	if !prepare {
		return channelchat.Observation{At: now}, nil
	}
	rev, err := (contentstore.Store{}).ActiveRevision(ctx, t)
	if err != nil {
		return channelchat.Observation{}, err
	}
	value, ok, err := (publicpresentation.Reader{Queryer: t, Revision: rev, ObservedAt: now}).Minimal(ctx, actor.PlayerID)
	if err != nil {
		return channelchat.Observation{}, err
	}
	if !ok || value.PlayerID != actor.PlayerID {
		return channelchat.Observation{}, playerpresentation.ErrMissingPresentation
	}
	return channelchat.Observation{Sender: value, At: now}, nil
}

var _ channelchat.Reader = Reader{}
