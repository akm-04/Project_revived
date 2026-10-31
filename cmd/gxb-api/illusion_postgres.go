//go:build postgres

package main

import (
	"context"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/illusion"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalIllusion(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, owner appi5.Service, privileges appi5.PrivilegeSnapshotProvider, fight combat.Service, guilds guildstore.Store, rooms appsharedroom.Service) illusion.Mode {
	return illusion.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: illusionstore.Store{}, Content: content,
		Fence: values, Players: i4store.PlayerRootLocker{}, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes,
		Pets: fight.Inputs.Pets, Stats: fight.Inputs.Stats, Rooms: rooms, RoomStore: sharedroomstore.Store{},
		Combat: fight, Privileges: privileges, Costs: appi5.MaterialCostDebiter{Store: values, Content: content},
		Facts: appi5.ObjectiveFacts{Owner: owner, Open: values, Observer: appadventure.Observer{Store: adventurestore.Store{}, Wake: adventureWakeup{}}}, Guilds: illusionGuilds{Store: guilds}, Mail: appi5.SettlementMail{Store: values},
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

type illusionGuilds struct{ Store guildstore.Store }

func (g illusionGuilds) GuildSummaries(ctx context.Context, server identity.LogicalServerID) ([]illusion.GuildSummary, error) {
	records, err := g.Store.ListGuilds(ctx, server, 200)
	if err != nil {
		return nil, err
	}
	out := make([]illusion.GuildSummary, 0, len(records))
	for _, record := range records {
		memberships, err := g.Store.ListMemberships(ctx, record.ID)
		if err != nil {
			return nil, err
		}
		members := make([]identity.PlayerID, 0, len(memberships))
		for _, membership := range memberships {
			members = append(members, membership.PlayerID)
		}
		out = append(out, illusion.GuildSummary{ID: int64(record.ID), Name: record.Name, Icon: record.Icon, Description: record.Description, MinAllowLevel: record.MinAllowLevel, Members: members})
	}
	return out, nil
}
