// Package channelchatread composes owner-owned canonical reads without foreign SQL.
package channelchatread

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Reader struct{}

func (r Reader) ReadTx(ctx context.Context, t tx.Tx, a apprealtime.Admission, prepare bool) (playerpresentation.Minimal, error) {
	v, e := r.ObserveTx(ctx, t, a, prepare)
	return v.Sender, e
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
	value, ok, err := (playerpresentation.Service{Directory: i4store.PlayerDirectoryReader{Queryer: t}, Types: i5store.Store{Queryer: t}}).Read(ctx, actor.PlayerID)
	if err != nil {
		return channelchat.Observation{}, err
	}
	if !ok || value.PlayerID != actor.PlayerID {
		return channelchat.Observation{}, playerpresentation.ErrMissingPresentation
	}
	return channelchat.Observation{Sender: value, At: now}, nil
}

var _ channelchat.Reader = Reader{}
