//go:build postgres

// gxb-ranking-backfill is the explicit one-shot deploy backfill for every
// registered generic board. It composes the same owner read providers the API
// uses for ranking and writes only stored score rows.
package main

import (
	"context"
	"errors"
	"log"
	"os"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/application/characterasset"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdir "gxb.local/backend/v2/internal/application/directorysync"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appelement "gxb.local/backend/v2/internal/application/elementequipment"
	gen "gxb.local/backend/v2/internal/application/generation"
	appevolution "gxb.local/backend/v2/internal/application/heroevolution"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	apppublicprofile "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/publicstats"
	appranking "gxb.local/backend/v2/internal/application/ranking"
	appspirit "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func main() {
	c, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	if e := run(c); e != nil {
		log.Fatal(e)
	}
}

func run(c context.Context) error {
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		return errors.New("ranking backfill requires GXB_POSTGRES_DSN")
	}
	p, e := pg.Open(c, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		return e
	}
	defer p.Close()
	service := compose(p)
	op, e := operation.Factory{Clock: clock.System{}}.New(policy.Set{})
	if e != nil {
		return e
	}
	roots, e := (i4store.PlayerRootLocker{}).ListPlayerRootsTx(c, p)
	if e != nil {
		return e
	}
	if e = service.BackfillScores(c, op, roots); e != nil {
		return e
	}
	log.Print("ranking score backfill complete")
	return nil
}

func compose(p *pg.Pool) appranking.Service {
	runner := tx.Runner{DB: p, Admission: tx.NewSemaphore(32)}
	contentDB := contentstore.Store{Queryer: p}
	heroDB := characterstore.Store{Queryer: p}
	receipts := kernelstore.Store{}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: contentDB}
	i5db := i5store.Store{Queryer: p, StackUsage: appdorm.FurnitureUsage{Owner: dormstore.Store{}, Content: contentDB}}
	i5svc := appi5.Service{Runner: runner, Store: i5db, Content: contentDB, Privileges: privileges, Functions: appi5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: i5db, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}
	librarySvc := applibrary.Service{Timed: timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Library: librarystore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: contentDB}, Receipts: receipts}
	dormSvc := appdorm.Service{Timed: timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Owner: dormstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db}
	bookSvc := appbook.Service{Timed: timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Owner: bookstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db}
	courseSvc := appcourse.Service{Timed: timed, Reads: runner, Heroes: characterstore.CourseHeroPort{Store: heroDB}, Owner: coursestore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Privileges: privileges}
	inscriptionSvc := appinscription.Service{Timed: timed, Reads: runner, Heroes: characterstore.InscriptionHeroPort{Store: heroDB, Content: contentDB}, Owner: inscriptionstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Eligibility: characterstore.InscriptionHeroPort{Store: heroDB, Content: contentDB}}
	elementSvc := appelement.Service{Timed: timed, Reads: runner, Heroes: characterstore.ElementHeroPort{Store: heroDB}, Owner: elementstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db}
	spiritSvc := appspirit.Service{Timed: timed, Reads: runner, Heroes: characterstore.SpiritHeroPort{Store: heroDB}, Owner: spiritstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db}
	evolutionSvc := appevolution.Service{Timed: timed, Reads: runner, Heroes: characterstore.EvolutionHeroPort{Store: heroDB}, Owner: characterstore.EvolutionStore{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db}
	owned := &characterasset.OwnedCompositeBuilder{
		HeroBase: apphero.BaseObservationReader{Store: heroDB, Content: contentDB}, PetBase: apppet.BaseObservationReader{Store: heroDB},
		HeroEquipment: apphero.CA8EquipmentObservationAdapter{Reader: apphero.EquipmentStateReader{Store: heroDB, Content: contentDB, Awakening: &apphero.AwakeningPositionResolver{Raw: characterstore.RawAwakeningStore{}, Content: contentDB}}}, PetEquipment: apppet.CA8EquipmentObservationAdapter{Reader: apppet.EquipmentStateReader{Store: heroDB, Content: contentDB}},
		HeroPractice: apphero.CA8PracticeObservationAdapter{Reader: apphero.PracticeContributionReader{Store: heroDB, Content: contentDB}}, PetPractice: apppet.CA8PracticeObservationAdapter{Reader: apppet.PracticeContributionReader{Store: heroDB, Content: contentDB}},
		HeroAppearance: apphero.CA8AppearanceObservationAdapter{Reader: apphero.AppearanceContributionReader{Store: heroDB, Content: contentDB}}, PetAppearance: apppet.CA8AppearanceObservationAdapter{Reader: apppet.AppearanceContributionReader{Store: heroDB, Content: contentDB}},
	}
	publicStats := publicstats.Service{Owned: owned, Pets: heroDB, Content: contentDB, Skills: apphero.RawSkillObservationReader{Store: heroDB, Content: contentDB}, Awakening: apphero.RawAwakeningObservationReader{Heroes: heroDB, Births: characterstore.RawAwakeningStore{}}, Library: librarySvc, Dorm: dormSvc, Book: bookSvc, Courses: courseSvc, Inscription: inscriptionSvc, Element: elementSvc, Spirit: spiritSvc, Evolution: evolutionSvc, Conquer: appconquer.Service{Owner: conquerstore.Store{}, Content: contentDB, Heroes: heroDB, Kinds: contentDB, Players: i4store.PlayerRootLocker{}}}
	displayService := playerdisplay.Service{Runner: runner, Fresh: p, Time: pg.AuthoritativeTime{Queryer: p}, Players: i4store.PlayerRootLocker{}, Fence: i5db, Store: i5db, Content: contentDB, Receipts: receipts, Privileges: privileges, CosmeticPrivileges: privileges, Inventory: i5db, Population: characterstore.DisplayReader{Store: heroDB, Content: contentDB}, Characters: characterstore.DisplayReader{Store: heroDB, Content: contentDB}, Values: appi5.DisplayValueOwner{Store: i5db, Content: contentDB, Grant: i5svc}, Directory: appdir.Reconciler{Source: i5db, Sink: i4store.DirectoryLevelProjection{}}, SkinItems: contentDB}
	metrics := apppublicprofile.CanonicalMetricProvider{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: contentDB}, Force: publicStats, Display: displayService, Awakenings: characterstore.RawAwakeningStore{}}
	return appranking.Service{Timed: timed, Fresh: p, Store: rankingstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Content: contentDB, Fence: i5db, Players: i4store.PlayerRootLocker{}, Recipient: displayService, Ledger: i5db, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}, Metrics: metrics, TopForce: metrics, BloodAwaken: metrics, Comfort: dormstore.Store{Queryer: p}, Occult: occultstore.Store{}, Presence: presencestore.Store{}, Login: i4store.PlayerLoginActivity{}}
}
