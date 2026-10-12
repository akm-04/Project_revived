// Package guildviewread gives existing Guild views one caller snapshot and
// qualified canonical Player presentation. It owns no Guild/Player SQL or facts.
package guildviewread

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/application/guildview"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Reader struct{ Runner tx.Runner }
type presenceAt struct {
	Queryer tx.Queryer
	At      time.Time
}

func (r presenceAt) ReadMany(c context.Context, ids []identity.PlayerID) (map[identity.PlayerID]socialpresence.Observation, error) {
	return (presencestore.Store{Queryer: r.Queryer}).ReadManyAt(c, ids, r.At)
}
func (r Reader) read(c context.Context, a identity.ActorContext, fn func(guildview.Service) error) error {
	if r.Runner.DB == nil {
		return guildview.ErrUnavailable
	}
	policies, e := policy.NewSet()
	if e != nil {
		return e
	}
	o, e := (operation.Factory{Clock: clock.System{}}).New(policies)
	if e != nil {
		return e
	}
	result, e := r.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at, e := (postgres.AuthoritativeTime{Queryer: sc.Tx}).Now(c)
		if e != nil {
			return e
		}
		if e = (i5store.Store{}).FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		rev, e := (contentstore.Store{}).ActiveRevision(c, sc.Tx)
		if e != nil {
			return e
		}
		return fn(guildview.Service{Store: guildstore.Store{Queryer: sc.Tx}, Directory: publicpresentation.Reader{Queryer: sc.Tx, Revision: rev, ObservedAt: at}, Presence: presenceAt{Queryer: sc.Tx, At: at}})
	})
	if e != nil {
		return e
	}
	if result.Outcome != tx.DefiniteCommit {
		return errors.New("Guild presentation snapshot unresolved")
	}
	return nil
}
func (r Reader) Self(c context.Context, a identity.ActorContext) (guildview.SelfGuild, bool, error) {
	var out guildview.SelfGuild
	var ok bool
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, ok, e = v.Self(c, a); return e })
	return out, ok, e
}
func (r Reader) Other(c context.Context, a identity.ActorContext, gid guild.ID) (guildview.SelfGuild, bool, error) {
	var out guildview.SelfGuild
	var ok bool
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, ok, e = v.Other(c, a, gid); return e })
	return out, ok, e
}
func (r Reader) Members(c context.Context, a identity.ActorContext) (guildview.GuildInfo, []guildview.Member, error) {
	var info guildview.GuildInfo
	var out []guildview.Member
	e := r.read(c, a, func(v guildview.Service) error { var e error; info, out, e = v.Members(c, a); return e })
	return info, out, e
}
func (r Reader) Guilds(c context.Context, a identity.ActorContext, limit int) ([]guildview.GuildInfo, error) {
	var out []guildview.GuildInfo
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, e = v.Guilds(c, a, limit); return e })
	return out, e
}
func (r Reader) Applicants(c context.Context, a identity.ActorContext) ([]guildview.Applicant, error) {
	var out []guildview.Applicant
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, e = v.Applicants(c, a); return e })
	return out, e
}
func (r Reader) PlayerApplications(c context.Context, a identity.ActorContext) ([]guildview.GuildInfo, error) {
	var out []guildview.GuildInfo
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, e = v.PlayerApplications(c, a); return e })
	return out, e
}
func (r Reader) GuildForPlayer(c context.Context, a identity.ActorContext, pid identity.PlayerID) (guildview.GuildInfo, bool, error) {
	var out guildview.GuildInfo
	var ok bool
	e := r.read(c, a, func(v guildview.Service) error { var e error; out, ok, e = v.GuildForPlayer(c, a, pid); return e })
	return out, ok, e
}
