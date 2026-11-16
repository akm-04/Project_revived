//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/memoirstore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appachievement "gxb.local/backend/v2/internal/application/achievement"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appguildcampaign "gxb.local/backend/v2/internal/application/guildcampaign"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	appmemoir "gxb.local/backend/v2/internal/application/memoir"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	apppetcampaign "gxb.local/backend/v2/internal/application/petcampaign"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type achievementOwners struct {
	books        appbook.Service
	courses      appcourse.Service
	inscriptions appinscription.Service
	dorm         appdorm.Service
	skins        appachievement.Skins
}

// I7C-4 full stage A: the full-catalog Achievement runtime and its observers.
func canonicalAchievements(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, i5svc appi5.Service, population appachievement.Population, owners achievementOwners, metrics observability.Metrics) appachievement.Service {
	counts := appachievement.OwnerCounts{
		Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: content}, Kinds: content, Books: owners.books,
		Conquer: appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: characterstore.Store{Queryer: p}, Kinds: content, Players: i4store.PlayerRootLocker{}},
		Courses: owners.courses, Inscriptions: owners.inscriptions, Dorm: owners.dorm, Skins: owners.skins,
		GuildCampaign: appguildcampaign.Mode{Service: appguildcampaign.Service{Store: guildcampaignstore.Store{}}},
		PetCampaign:   apppetcampaign.Mode{Store: petcampaignstore.Store{}},
		Campaign:      appcampaign.Mode{Store: campaignstore.Store{}, Content: content},
		SchoolStories: applibrary.Service{Library: librarystore.Store{}},
		Mentor:        appmentor.Service{Store: mentorstore.Store{}, Content: content},
		Memoir:        appmemoir.Mode{Store: memoirstore.Store{}},
		Occult:        appoccult.Mode{Store: occultstore.Store{}, Content: content},
	}
	runtime := &appachievement.Runtime{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Active: content, Counts: counts, Fence: i5db, Grants: i5svc, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Directory: i4store.PlayerDirectoryReader{}, Servers: i4store.ServerNames{}}
	return appachievement.Service{Store: achievementstore.Store{Metrics: metrics}, Content: content, Population: population, Runtime: runtime}
}

func observing(authority rt.GameplayAuthorityPort, achievements appachievement.Service, family string, next httpedge.Dispatcher) httpedge.Dispatcher {
	families, known := appachievement.Families[family]
	if !known {
		panic("achievement: unknown observation family " + family)
	}
	return stockruntime.AchievementObserving{Next: next, Authority: authority, Observer: achievements, Families: families}
}
