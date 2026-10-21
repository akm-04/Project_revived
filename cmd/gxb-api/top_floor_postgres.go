//go:build postgres

package main

import (
	"context"
	"log"
	"os"
	"path/filepath"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatkeys"
	"gxb.local/backend/v2/internal/adapters/combatworker"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	appachievement "gxb.local/backend/v2/internal/application/achievement"
	apparena "gxb.local/backend/v2/internal/application/arena"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appleague "gxb.local/backend/v2/internal/application/championsleague"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appelement "gxb.local/backend/v2/internal/application/elementequipment"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appevolution "gxb.local/backend/v2/internal/application/heroevolution"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	apponeonone "gxb.local/backend/v2/internal/application/oneonone"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/publicstats"
	appspirit "gxb.local/backend/v2/internal/application/spirit"
	apptopfloor "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type topFloorOwners struct {
	library     applibrary.Service
	dorm        appdorm.Service
	book        appbook.Service
	course      appcourse.Service
	inscription appinscription.Service
	element     appelement.Service
	spirit      appspirit.Service
	evolution   appevolution.Service
}

// roster is the MID1 Heroes composer shared by Combat and public profile records.
func (o topFloorOwners) roster(content contentstore.Store) characterstore.HeroBootstrapProjection {
	return characterstore.HeroBootstrapProjection{Content: content, Library: o.library, Dorm: o.dorm, Book: o.book, Course: o.course, Inscription: o.inscription, Element: o.element, Spirit: o.spirit, Evolution: o.evolution}
}

// canonicalCombat is the first production Combat composition. It stays
// unavailable (false) until an entropy key ring is configured.
func canonicalCombat(p *postgres.Pool, r tx.Runner, content contentstore.Store, o topFloorOwners) (combat.Service, bool, error) {
	spec := os.Getenv("GXB_COMBAT_ENTROPY_KEYS")
	if spec == "" {
		return combat.Service{}, false, nil
	}
	keys, err := combatkeys.Parse(spec, os.Getenv("GXB_COMBAT_ENTROPY_KEY_CURRENT"))
	if err != nil {
		return combat.Service{}, false, err
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		return combat.Service{}, false, err
	}
	binary := os.Getenv("GXB_COMBAT_WORKER_BINARY")
	if binary == "" {
		self, err := os.Executable()
		if err != nil {
			return combat.Service{}, false, err
		}
		binary = filepath.Join(filepath.Dir(self), "gxb-combat-worker")
	}
	stats := canonicalPublicStats(p, content, o)
	conquer := appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: characterstore.Store{Queryer: p}, Kinds: content, Players: i4store.PlayerRootLocker{}}
	limits := combatworker.Limits{Binary: binary, Deadline: 120 * time.Second, AddressSpace: 4 << 30, CPUSeconds: 180, OpenFiles: 64, MaxOutputBytes: 16 << 20, ExpectedCorpus: corpus.ID()}
	// I8_WORKER_ADMISSION_V1 (private policy): a warm worker peaks near 2.7 GiB,
	// so three live workers bound memory; a busy pool refuses after five seconds.
	worker := combatworker.New(limits, 3, 5*time.Second)
	return combat.Service{Rules: corpus, Keys: keys, Worker: worker, Store: combatstore.Store{}, Content: content, Runner: r, Fresh: p,
		Inputs: combat.Inputs{Heroes: o.roster(content), Pets: characterstore.PetBootstrapProjection{Content: content}, Stats: stats, Awakening: stats.Awakening, Collection: o.library, Conquer: conquer, Stacks: i5store.Store{Queryer: p}}}, true, nil
}

func canonicalPublicStats(p *postgres.Pool, content contentstore.Store, o topFloorOwners) publicstats.Service {
	heroes := characterstore.Store{Queryer: p}
	awakening := apphero.RawAwakeningObservationReader{Heroes: characterstore.Store{}, Births: characterstore.RawAwakeningStore{}}
	conquer := appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: heroes, Kinds: content, Players: i4store.PlayerRootLocker{}}
	owned := &ca.OwnedCompositeBuilder{
		HeroBase: apphero.BaseObservationReader{Store: heroes, Content: content}, PetBase: apppet.BaseObservationReader{Store: heroes},
		HeroEquipment: apphero.CA8EquipmentObservationAdapter{Reader: apphero.EquipmentStateReader{Store: heroes, Content: content}}, PetEquipment: apppet.CA8EquipmentObservationAdapter{Reader: apppet.EquipmentStateReader{Store: heroes, Content: content}},
		HeroPractice: apphero.CA8PracticeObservationAdapter{Reader: apphero.PracticeContributionReader{Store: heroes, Content: content}}, PetPractice: apppet.CA8PracticeObservationAdapter{Reader: apppet.PracticeContributionReader{Store: heroes, Content: content}},
		HeroAppearance: apphero.CA8AppearanceObservationAdapter{Reader: apphero.AppearanceContributionReader{Store: heroes, Content: content}}, PetAppearance: apppet.CA8AppearanceObservationAdapter{Reader: apppet.AppearanceContributionReader{Store: heroes, Content: content}},
	}
	return publicstats.Service{Owned: owned, Pets: heroes, Content: content, Skills: apphero.RawSkillObservationReader{Store: heroes, Content: content}, Awakening: awakening,
		Library: o.library, Dorm: o.dorm, Book: o.book, Courses: o.course, Inscription: o.inscription, Element: o.element, Spirit: o.spirit, Evolution: o.evolution, Conquer: conquer}
}

func canonicalOneOnOne(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, privileges commerceprivilege.Provider, fight combat.Service, o topFloorOwners) apponeonone.Service {
	return apponeonone.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: oneononestore.Store{}, Content: content,
		Fence: i5db, Privileges: privileges, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: content}, Mail: appi5.SettlementMail{Store: i5db},
		Achievements: appachievement.Service{Store: achievementstore.Store{}, Content: content, Population: o.library}, Combat: fight,
		Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Entitlements: i5db, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func canonicalArena(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, i5svc appi5.Service, fight combat.Service, o topFloorOwners) apparena.Service {
	return apparena.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: arenastore.Store{}, Content: content,
		Fence: i5db, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: content}, Grants: i5svc, Values: i5db, Mail: appi5.SettlementMail{Store: i5db},
		Achievements: appachievement.Service{Store: achievementstore.Store{}, Content: content, Population: o.library}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Servers: i4store.ServerNames{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// canonicalConquer is the Conquer School mode (client-attested; no Combat attempt).
func canonicalConquer(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, i5svc appi5.Service, privileges commerceprivilege.Provider, fight combat.Service) appconquer.Mode {
	facts := appconquer.Service{Owner: conquerstore.Store{}, Content: content, Heroes: characterstore.Store{Queryer: p}, Kinds: content, Players: i4store.PlayerRootLocker{}}
	return appconquer.Mode{Facts: facts, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: conquerstore.Store{}, Content: content,
		Fence: i5db, Functions: i5db, Privileges: privileges, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: content}, Grants: i5svc, Mail: appi5.SettlementMail{Store: i5db},
		Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Projection: i4store.DirectoryLevelProjection{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func canonicalTopFloor(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, privileges commerceprivilege.Provider, fight combat.Service, o topFloorOwners) apptopfloor.Service {
	return apptopfloor.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: topfloorstore.Store{}, Content: content,
		Fence: i5db, Functions: i5db, Privileges: privileges, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: content}, Mail: appi5.SettlementMail{Store: i5db},
		Achievements: appachievement.Service{Store: achievementstore.Store{}, Content: content, Population: o.library}, Combat: fight,
		Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// runReconcile runs one mode's owed settlements and abandoned matches every 30 s (in-process reconcile provider).
func runReconcile(ctx context.Context, p *postgres.Pool, provider appgeneration.ReconcileProvider) {
	operations := operation.Factory{Clock: clock.System{}}
	binder := appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
		op, err := operations.New(policy.Set{})
		if err == nil {
			var timed appgeneration.TimedOperation
			if timed, err = binder.Bind(ctx, op); err == nil {
				_, err = provider.Reconcile(ctx, timed, 50)
			}
		}
		if err != nil && ctx.Err() == nil {
			log.Printf("%s reconcile: %v", provider.Name(), err)
		}
	}
}

// canonicalLeague reuses the full qualified owned Combat roster/stats pipeline.
func canonicalLeague(p *postgres.Pool, r tx.Runner, content contentstore.Store, i5db i5store.Store, i5svc appi5.Service, fight combat.Service, o topFloorOwners, display playerdisplay.Service) appleague.Service {
	return appleague.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: leaguestore.Store{}, Content: content, Fence: i5db, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Progression: i5db, Combat: fight, Grants: i5svc, Mail: appi5.SettlementMail{Store: i5db}, Achievements: appachievement.Service{Store: achievementstore.Store{}, Content: content, Population: o.library}, Players: i4store.PlayerRootLocker{}, Recipient: display, Entitlements: i5db, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
