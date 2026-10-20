//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appachievement "gxb.local/backend/v2/internal/application/achievement"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type achievementOwners struct {
	books        appbook.Service
	courses      appcourse.Service
	inscriptions appinscription.Service
	dorm         appdorm.Service
}

// I7C-4 full stage A: the full-catalog Achievement runtime and its observers.
func canonicalAchievements(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, i5svc appi5.Service, population appachievement.Population, owners achievementOwners) appachievement.Service {
	counts := appachievement.OwnerCounts{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: content}, Kinds: content, Books: owners.books, Conquer: appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: characterstore.Store{Queryer: p}, Kinds: content, Players: i4store.PlayerRootLocker{}}, Courses: owners.courses, Inscriptions: owners.inscriptions, Dorm: owners.dorm}
	runtime := &appachievement.Runtime{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Active: content, Counts: counts, Fence: i5db, Grants: i5svc, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	return appachievement.Service{Store: achievementstore.Store{}, Content: content, Population: population, Runtime: runtime}
}

func observing(authority rt.GameplayAuthorityPort, achievements appachievement.Service, family string, next httpedge.Dispatcher) httpedge.Dispatcher {
	return stockruntime.AchievementObserving{Next: next, Authority: authority, Observer: achievements, Families: appachievement.Families[family]}
}
