//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/herorecommendstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appherorecommend "gxb.local/backend/v2/internal/application/herorecommend"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// canonicalHeroRecommend composes the derived recommendation owner from the six
// mode owners' existing store APIs; no mode store is queried from another owner.
func canonicalHeroRecommend(p *pg.Pool, runner tx.Runner, content contentstore.Store, owners topFloorOwners, stats publicstats.Service) appherorecommend.Service {
	return appherorecommend.Service{
		Timed:     appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner},
		Fresh:     p,
		Store:     herorecommendstore.Store{},
		Sources:   appherorecommend.Sources{TopFloor: topfloorstore.Store{}, OneOnOne: oneononestore.Store{}, Arena: arenastore.Store{}, Fantasy: illusionstore.Store{}, GuildEvent: guildcampaignstore.Store{}, Champion: leaguestore.Store{}},
		Content:   content,
		Directory: i4store.PlayerDirectoryReader{},
		Guilds:    guildstore.Store{},
		Heroes:    owners.roster(content),
		Pets:      characterstore.PetBootstrapProjection{Content: content},
		HeroPower: stats,
		Cohort:    i4store.PlayerRootLocker{},
	}
}
