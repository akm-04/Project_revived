//go:build postgres

package main

import (
	"context"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildrentalread"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/guildrental"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/content/guildrentalpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// guildRentalRuntime implements the dispatcher port with one owner service and
// its read side.
type guildRentalRuntime struct {
	Service guildrental.Service
	Reads   guildrental.Reader
}

func (g guildRentalRuntime) Place(c context.Context, a identity.ActorContext, kind guild.RentalKind, unit int64, op operation.Context) error {
	return g.Service.Place(c, a, kind, unit, op)
}

func (g guildRentalRuntime) Recall(c context.Context, a identity.ActorContext, kind guild.RentalKind, unit int64, op operation.Context) (int64, int64, error) {
	return g.Service.Recall(c, a, kind, unit, op)
}

func (g guildRentalRuntime) OwnOffers(c context.Context, a identity.ActorContext, kind guild.RentalKind, op operation.Context) ([]guildrental.Row, error) {
	return g.Reads.OwnOffers(c, a, kind, op)
}

func (g guildRentalRuntime) GuildOffers(c context.Context, a identity.ActorContext, kind guild.RentalKind, requested int64, op operation.Context) (guildrental.List, error) {
	return g.Reads.GuildOffers(c, a, kind, requested, op)
}

var _ stockruntime.GuildRentalPort = guildRentalRuntime{}

func rentalPolicyBinding(p guildrentalpolicy.Policy) guildrental.Policy {
	modes := make(map[int64]guildrental.ModeRule)
	for _, mode := range p.Modes {
		rule := guildrental.ModeRule{Enabled: mode.Enabled}
		if mode.StarCap > 0 {
			rule.StarCap = mode.StarCap
		}
		for _, kind := range mode.CampaignTypes {
			modes[kind] = rule
		}
	}
	vip := make(map[int64]guildrental.VIPLimit, len(p.VIPLimits))
	for _, row := range p.VIPLimits {
		vip[row.VIP] = guildrental.VIPLimit{Lend: row.Lend, LevelUp: row.LevelUp}
	}
	return guildrental.Policy{
		Money: guild.RentalMoney{PriceForceDivisor: p.Money.PriceForceDivisor, PriceFloorMana: p.Money.PriceFloorMana,
			HourlyInterestForceDivisor: p.Money.HourlyInterestForceDivisor, RecallMinimumSeconds: p.Money.RecallMinimumSeconds,
			LevelUpCeiling: p.Money.LevelUpCeiling},
		Modes: modes, VIP: vip,
		Departure: guildrental.DepartureMail{Sender: p.Departure.Sender, Title: p.Departure.Title, Body: p.Departure.Body},
	}
}

// rentalStarCaps is the borrow-mode star bound keyed by campaign type (C13).
func rentalStarCaps(p guildrentalpolicy.Policy) map[int64]int64 {
	out := map[int64]int64{}
	for _, mode := range p.Modes {
		if !mode.Enabled || mode.StarCap <= 0 {
			continue
		}
		for _, kind := range mode.CampaignTypes {
			out[kind] = mode.StarCap
		}
	}
	return out
}

func canonicalGuildRental(p *pg.Pool, r tx.Runner, content contentstore.Store, guildDB guildstore.Store, i5db i5store.Store, i5svc i5.Service,
	privileges i5.PrivilegeSnapshotProvider, stats publicstats.Service, costs i5.MaterialCostDebiter, binding guildrental.Policy) (guildrental.Service, guildrental.Reader) {
	now := func(c context.Context, q tx.Queryer) (time.Time, error) {
		return (pg.AuthoritativeTime{Queryer: q}).Now(c)
	}
	service := guildrental.Service{
		Runner: r, Store: guildDB, Units: guildrentalread.Units{Stats: stats, Content: content, Now: now},
		Levels: guildrentalread.Levels{}, Workplace: workplace.Mode{Store: workplacestore.Store{}},
		Privileges: privileges, Values: i5svc, Costs: costs,
		Facts: i5.ObjectiveFacts{Owner: i5svc, Open: i5db}, Mail: i5.SettlementMail{Store: i5db},
		Fence: i5db, Players: i4store.PlayerRootLocker{}, Content: content, Policy: binding,
	}
	reads := guildrental.Reader{Runner: r, Store: guildDB, Characters: guildrentalread.Characters{}, Profiles: guildrentalread.Profiles{},
		Levels: guildrentalread.Levels{}, Mana: guildrentalread.Mana{}, Privileges: privileges, Policy: binding}
	return service, reads
}
