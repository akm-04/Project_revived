//go:build postgres

package main

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyresetstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	apparena "gxb.local/backend/v2/internal/application/arena"
	appawakeningbattle "gxb.local/backend/v2/internal/application/awakeningbattle"
	appleague "gxb.local/backend/v2/internal/application/championsleague"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/dailyconsume"
	"gxb.local/backend/v2/internal/application/dailyreset"
	apponeonone "gxb.local/backend/v2/internal/application/oneonone"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	apptopfloor "gxb.local/backend/v2/internal/application/topfloor"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/generaldmbindings"
	"gxb.local/backend/v2/internal/adapters/guildcampaigncontent"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/guildviewread"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/activitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/elementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/eventcentrestore"
	"gxb.local/backend/v2/internal/adapters/postgres/frienddmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/gmquestionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/godstrialstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/libraryforumstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/marchstore"
	"gxb.local/backend/v2/internal/adapters/postgres/mentorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicationstore"
	"gxb.local/backend/v2/internal/adapters/postgres/restorestore"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialexchangestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	"gxb.local/backend/v2/internal/adapters/postgres/summonstore"
	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/adapters/postgres/worldbossstore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appachievement "gxb.local/backend/v2/internal/application/achievement"
	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/characterasset"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	appsavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	appconquer "gxb.local/backend/v2/internal/application/conquerschool"
	appcourse "gxb.local/backend/v2/internal/application/course"
	appdir "gxb.local/backend/v2/internal/application/directorysync"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	appelement "gxb.local/backend/v2/internal/application/elementequipment"
	appeventcentre "gxb.local/backend/v2/internal/application/eventcentre"
	"gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/generaldm"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/gmquestion"
	appgodstrial "gxb.local/backend/v2/internal/application/godstrial"
	appguildcampaign "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/guildcore"
	appguildtea "gxb.local/backend/v2/internal/application/guildtea"
	appevolution "gxb.local/backend/v2/internal/application/heroevolution"
	appherorecommend "gxb.local/backend/v2/internal/application/herorecommend"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	appillusion "gxb.local/backend/v2/internal/application/illusion"
	appinscription "gxb.local/backend/v2/internal/application/inscription"
	applibraryforum "gxb.local/backend/v2/internal/application/libraryforum"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	appmarch "gxb.local/backend/v2/internal/application/march"
	appmentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/application/missioninputs"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	apppetcampaign "gxb.local/backend/v2/internal/application/petcampaign"
	apppublication "gxb.local/backend/v2/internal/application/publication"
	apppublicprofile "gxb.local/backend/v2/internal/application/publicprofile"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/roominvite"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/application/socialdismiss"
	"gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/application/socialfriendbase"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	appspirit "gxb.local/backend/v2/internal/application/spirit"
	appsummon "gxb.local/backend/v2/internal/application/summon"
	appworldboss "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/content/guildcampaigncatalog"
	"gxb.local/backend/v2/internal/content/guildcampaignpolicy"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/content/guildrentalpolicy"
	"gxb.local/backend/v2/internal/content/guildteapolicy"
	"gxb.local/backend/v2/internal/content/registry"
	domainspirit "gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/config"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func main() {
	cfg := config.FromEnv()
	digestSecret := []byte(os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET"))
	bearerSecret := []byte(os.Getenv("GXB_GAMEPLAY_BEARER_SECRET"))
	redeemSecret := []byte(os.Getenv("GXB_REDEEM_DIGEST_SECRET"))
	keyID := os.Getenv("GXB_DERIVATION_KEY_ID")
	host := os.Getenv("GXB_REALTIME_PUBLIC_HOST")
	port, err := strconv.Atoi(os.Getenv("GXB_REALTIME_PUBLIC_PORT"))
	if err != nil || port <= 0 || port > 65535 || host == "" {
		log.Fatal("GXB_REALTIME_PUBLIC_HOST and valid GXB_REALTIME_PUBLIC_PORT are required")
	}
	if len(cfg.PostgresDSN) == 0 || len(digestSecret) < 16 || len(bearerSecret) < 16 || len(redeemSecret) < 16 || keyID == "" {
		log.Fatal("I5 PostgreSQL/credential/redeem configuration incomplete")
	}
	if cfg.PublicEngineURL == "" {
		log.Fatal("GXB_PUBLIC_ENGINE_URL is required for stock UpdateScene MID20480 discovery")
	}
	retentionPolicies, err := retentionstore.PoliciesFromEnvironment()
	if err != nil {
		log.Fatal(err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	poolConnections := envPositiveInt("GXB_API_DB_POOL_MAX_CONNS", 16)
	pool, err := postgres.Open(ctx, string(cfg.PostgresDSN), postgres.PoolSettings{
		MaxConns: int32(poolConnections), MinConns: 1, MaxConnLifetime: 30 * time.Minute,
		MaxConnIdleTime: 5 * time.Minute, HealthCheckPeriod: 30 * time.Second,
		ApplicationName: "gxb-v2-i6b-api",
	})
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatal(err)
	}
	if err := (restorestore.Store{}).CheckWritable(ctx, pool); err != nil {
		log.Fatalf("refusing to start: %v", err)
	}
	if short, err := postgres.SerializableLockShortfall(ctx, pool); err != nil || len(short) > 0 {
		log.Printf("WARNING: PostgreSQL SSI lock budget below C1 Tier 0, expect 40001 between unrelated players under load: %v %v", short, err)
	}

	var txMetrics observability.Metrics = observability.NopMetrics{}
	txMetricsCfg, txMetricsEnabled, err := observability.JSONLMetricsConfigFromEnv(os.Getenv)
	if err != nil {
		log.Fatalf("invalid transaction metrics configuration: %v", err)
	}
	if txMetricsEnabled {
		sink, err := observability.NewJSONLMetrics(txMetricsCfg)
		if err != nil {
			log.Fatalf("transaction metrics sink: %v", err)
		}
		txMetrics = sink
		defer func() {
			if err := sink.Close(); err != nil {
				log.Printf("transaction metrics close: %v", err)
			}
		}()
	}
	// Admission equals the pool, so an admitted transaction never waits inside pgx where no deadline or order applies (C1-1).
	transactionAdmission := tx.NewSemaphore(poolConnections)
	runner := tx.Runner{DB: pool, Admission: transactionAdmission, Hooks: observability.TxHooks{Metrics: txMetrics}}
	broadcastEmitter := postgres.BroadcastEmitter{Metrics: txMetrics}
	// Deployment must apply migrations first. Gate all HTTP traffic on content readiness.
	contentCtx, contentCancel := context.WithTimeout(ctx, 3*registry.DefaultWriteProfile().OperationTimeout)
	active, contentErr := (registry.Service{Runner: runner, Repo: contentstore.Store{}, Fresh: pool, Providers: registry.DefaultProviderSet()}).ValidateActiveReadiness(contentCtx)
	contentCancel()
	if contentErr != nil {
		log.Fatalf("content startup failed: %v", contentErr)
	}
	log.Printf("content ready revision=%s activation_version=%d", active.Activation.RevisionID, active.Activation.Version)
	activeManifest, err := registry.DecodeManifestStrict(active.ManifestJSON)
	if err != nil {
		log.Fatalf("decode active content manifest for I6B capability qualification: %v", err)
	}
	activityContentCapabilities, err := appactivity.NewStaticContentCapabilities(activeManifest.EnabledCapabilities)
	if err != nil {
		log.Fatalf("I6B content capability set: %v", err)
	}
	activityProviders, err := appactivity.NewRegistry([]appactivity.Registration{{Name: "worldboss", TableID: 1026, RuntimeCapability: "activity.worldboss", Provider: appworldboss.ActivityProvider{Queryer: pool, Directory: i4store.PlayerDirectoryReader{}}}}, activityContentCapabilities)
	if err != nil {
		log.Fatalf("I6B Activity provider registry: %v", err)
	}
	activityDirectory := appactivity.Directory{Registry: activityProviders}
	activityRuntime := appactivity.Runtime{Directory: activityDirectory, Time: postgres.AuthoritativeTime{Queryer: pool}}
	receipts := kernelstore.Store{}
	bearerKeys := appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: keyID, Secret: bearerSecret}}
	dormBundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		log.Fatalf("Dorm source definition: %v", e)
	}
	i5db := i5store.Store{Queryer: pool, StackUsage: appdorm.FurnitureUsage{Owner: dormstore.Store{}, Content: contentstore.Store{Queryer: pool}}}
	contentDB := contentstore.Store{Queryer: pool}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: contentDB}
	i5svc := appi5.Service{Runner: runner, Store: i5db, Content: contentDB, Privileges: privileges, Functions: appi5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: i5db, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, RedeemSecret: redeemSecret}
	if e := i5svc.ValidateStartup(); e != nil {
		log.Fatalf("I5 startup: %v", e)
	}
	i5svc.CharacterFunctions = characterstore.FunctionPrerequisites{Store: characterstore.Store{Queryer: pool}, Content: contentDB}
	i5svc.ServerLevels = i5db
	i5svc.Awakening = &appi5.AwakeningRuntime{Store: i5db, Content: contentDB, Stacks: i5db, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: contentDB}}
	displayService := playerdisplay.Service{Runner: runner, Fresh: pool, Time: postgres.AuthoritativeTime{Queryer: pool}, Players: i4store.PlayerRootLocker{}, Fence: i5db, Store: i5db, Content: contentDB, Receipts: receipts, Privileges: privileges, CosmeticPrivileges: privileges, Inventory: i5db, Population: characterstore.DisplayReader{Store: characterstore.Store{Queryer: pool}, Content: contentDB}, Characters: characterstore.DisplayReader{Store: characterstore.Store{Queryer: pool}, Content: contentDB}, Values: appi5.DisplayValueOwner{Store: i5db, Content: contentDB, Grant: i5svc}, Directory: appdir.Reconciler{Source: i5db, Sink: i4store.DirectoryLevelProjection{}}, SkinItems: contentDB}

	boardRanking := canonicalBoardRanking(pool, runner, contentDB, displayService, receipts)
	// Title origins route by catalog id; the 1 on 1 origin read needs no Combat.
	leagueOrigins := appleague.Service{Store: leaguestore.Store{}, Content: contentDB, Entitlements: i5db}
	displayRoutes := playerdisplay.CatalogOriginRoutes{{Family: "title", First: 100078, Last: 100080, Owner: leagueOrigins}, {Family: "bubble", First: 10002, Last: 10007, Owner: leagueOrigins}, {Family: "title", First: 100104, Last: 100104, Owner: leagueOrigins}, {Family: "title", First: 100111, Last: 100111, Owner: leagueOrigins}, {Family: "title", First: 100114, Last: 100121, Owner: leagueOrigins}, {Family: "title", First: 100059, Last: 100066, Owner: boardRanking}, {Family: "title", First: 100001, Last: 100001, Owner: boardRanking},
		{First: 100002, Last: 100005, Owner: apponeonone.Service{Store: oneononestore.Store{}, Content: contentDB, Entitlements: i5db}},
		{Family: "frame", First: 120001078, Last: 120001078, Owner: apparena.Service{Store: arenastore.Store{}, Content: contentDB}},
		{Family: "avatar", First: 110006001, Last: 110006001, Owner: apparena.Service{Store: arenastore.Store{}, Content: contentDB}}}

	maxHeroColorPolicy := appi5.CurrentMaxHeroColorProvider{}
	heroDB := characterstore.Store{Queryer: pool}
	campaignWorld := appcampaign.Mode{Daily: dailyconsume.Service{Store: dailyconsumestore.Store{}, Costs: appi5.MaterialCostDebiter{Store: i5db, Content: contentDB}}, Store: campaignstore.Store{}, Content: contentDB, Functions: i5db}
	savedPresetSvc := appsavedpreset.MutationService{Runner: runner, Store: heroDB, Fencer: i5db, References: appsavedpreset.ReferenceOwners{Heroes: heroDB, Pets: heroDB}, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}}
	heroEconomy := appi5.HeroProgressionDebiter{Store: i5db, Content: contentDB}
	heroMaterialCosts := appi5.MaterialCostDebiter{Store: i5db, Content: contentDB}
	heroEquipmentResources := appi5.HeroEquipmentResourceDebiter{Store: i5db, Content: contentDB}
	heroEconomyProjection := appi5.ScalarProjector{Runner: runner, Store: i5db, FloorPolicies: contentDB}
	i5CrossOwner := appi5.CrossOwner{Store: i5db, FloorPolicies: contentDB}
	practiceSvc := apppractice.Service{
		Runner: runner, Store: heroDB, Content: contentDB, Privileges: privileges, ReconcileQueryer: pool,
		Deps: apppractice.ServiceDeps{
			Fencer: i5db, HeroOwner: heroDB, PetOwner: heroDB, Level: i5CrossOwner, LevelAndScalar: i5CrossOwner,
			TicketDebit: appi5.LevelAndStackDebiter{Store: i5db, Content: contentDB}, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool},
		},
	}
	// The current-client private collection policy admits Normal59 against the
	// pinned origin catalog and canonical unique roster. Legacy paid slots/MID64,
	// Vows305 and the I5 Hero materializer remain separately unqualified.

	heroSvc := apphero.Service{CharacterFunctions: i5svc, AwakeningPositions: &apphero.AwakeningPositionResolver{Raw: characterstore.RawAwakeningStore{}, Content: contentDB, Queryer: pool}, Awakening: struct {
		characterstore.Store
		characterstore.RawAwakeningStore
	}{Store: heroDB}, FreshFacets: characterbirth.FreshHeroFacets(), Journals: librarystore.Store{}, Runner: runner, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}, Store: heroDB, Fencer: i5db, Content: contentDB, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, ProgressionStore: heroDB, Progression: contentDB, Economy: heroEconomy, Backpack: i5db, AcquisitionStore: heroDB, Acquisition: contentDB, MaterialCosts: heroMaterialCosts, PlayerLevel: i5CrossOwner, CollectionAdmission: apphero.CatalogCollectionAdmission{Content: contentDB}, Capacity: nil, Equipment: contentDB, EquipmentResources: heroEquipmentResources, Fumo: contentDB, Promotion: contentDB, PromotionResources: i5svc, StrictRestoration: i5svc, MaxHeroColorPolicy: maxHeroColorPolicy, RestorationModifier: characterasset.IdentityRestorationModifier{}, RosterProjection: contentDB, AppearanceStore: heroDB, Appearance: contentDB, AppearanceMutationStore: heroDB, AppearanceMutationContent: contentDB, LIVEMutationStore: heroDB, Metrics: txMetrics}
	petAcquisitionDebit := appi5.PetAcquisitionDebiter{Store: i5db, Content: contentDB}
	petExpDebit := appi5.PetExpDebiter{Store: i5db, Content: contentDB}
	petTimed := appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}
	librarySvc := applibrary.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Library: librarystore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Receipts: receipts, Metrics: txMetrics, Broadcast: broadcastEmitter}
	librarySvc.Achievements = appachievement.Service{Store: achievementstore.Store{Metrics: txMetrics}, Content: contentDB, Population: librarySvc}
	librarySvc.Stacks = i5db
	librarySvc.Skins = heroDB
	forumSvc := applibraryforum.Service{Timed: heroSvc.Timed, Reads: runner, Store: libraryforumstore.Store{}, Players: i4store.PlayerRootLocker{}, Fence: i5db, Receipts: receipts, Directory: i4store.PlayerDirectoryReader{}, Characters: heroDB}
	dormSvc := appdorm.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Owner: dormstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Values: i5db, EXP: heroSvc, Exchange: i5svc, Receipts: receipts, GluePurchases: dormstore.Store{}, GlueValues: i5svc, GluePrivileges: privileges, Social: dormstore.Store{}, Directory: i4store.TransactionDiscoveryReader{}, Moderation: contentDB, Broadcast: broadcastEmitter}
	bookSvc := appbook.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.LibraryHeroPort{Store: heroDB}, Owner: bookstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Values: i5db, Grants: i5svc, Exchange: i5svc, Receipts: receipts}
	eventCentreSvc := appeventcentre.Service{Timed: heroSvc.Timed, Reads: runner, Owner: eventcentrestore.Store{}, Book: bookSvc, Content: contentDB, Pets: characterstore.Store{}, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Grants: i5svc, Receipts: receipts}
	bookSvc.MakeInfo = eventCentreSvc
	courseSvc := appcourse.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.CourseHeroPort{Store: heroDB}, Owner: coursestore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Values: i5db, Grants: i5svc, Exchange: i5svc, Receipts: receipts, Privileges: privileges}
	inscriptionSvc := appinscription.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.InscriptionHeroPort{Store: heroDB, Content: contentDB}, Owner: inscriptionstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Values: i5db, ValuePlans: i5svc, Eligibility: characterstore.InscriptionHeroPort{Store: heroDB, Content: contentDB}, Receipts: receipts}
	elementSvc := appelement.Service{Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.ElementHeroPort{Store: heroDB}, Owner: elementstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Values: i5db, Costs: heroMaterialCosts, Grants: i5svc, Exchange: i5svc, Receipts: receipts}
	spiritSvc := appspirit.Service{Mint: domainspirit.V1PreservationPolicy{}, Milestones: domainspirit.V1PreservationPolicy{}, Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.SpiritHeroPort{Store: heroDB}, Owner: spiritstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Values: i5db, Costs: heroMaterialCosts, Receipts: receipts}
	evolutionSvc := appevolution.Service{Values: i5db, Timed: heroSvc.Timed, Reads: runner, Heroes: characterstore.EvolutionHeroPort{Store: heroDB}, Owner: characterstore.EvolutionStore{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Costs: heroMaterialCosts, Receipts: receipts}
	i5svc.Spirits = spiritSvc
	displayService.CatalogExternal = append(displayRoutes,
		playerdisplay.CatalogOriginRoute{Family: "title", First: 100022, Last: 100023, Owner: playerdisplay.ProgressTitleOrigins{Owner: "Library", TitleType: 5, Content: contentDB, Progress: librarySvc}},
		playerdisplay.CatalogOriginRoute{Family: "title", First: 100024, Last: 100025, Owner: playerdisplay.ProgressTitleOrigins{Owner: "BookSkill", TitleType: 6, Content: contentDB, Progress: bookSvc}},
		playerdisplay.CatalogOriginRoute{Family: "title", First: 100026, Last: 100028, Owner: playerdisplay.ProgressTitleOrigins{Owner: "Dormhouse", TitleType: 7, Content: contentDB, Progress: dormSvc}})

	i5svc.Missions = &appi5.MissionMaterializer{Awakening: i5db, Activity: contentDB, Store: i5db, Catalog: contentDB, Observations: missioninputs.Reader{Spending: i5db, Heroes: heroDB, Progression: i5db, Campaigns: campaignstore.Store{}, Books: bookSvc, Privileges: privileges}}
	i5svc.MissionTime = postgres.AuthoritativeTime{Queryer: pool}
	i5svc.MissionFresh = pool
	i5svc.SignIn = &appi5.SignInRuntime{Store: i5db, Content: contentDB, Heroes: heroSvc, HeroWire: heroproj.StockHero}
	// C17/C18: the Library settling commands emit INTIMACY_IMPROVED through the
	// same objective port as charge/summon, including the Adventure 10002 observer.
	librarySvc.Grants = i5svc
	librarySvc.Facts = appi5.ObjectiveFacts{Owner: i5svc, Open: i5db, Observer: appadventure.Observer{Store: adventurestore.Store{}, Wake: adventureWakeup{}}}
	eventCentreSvc.Facts = appi5.ObjectiveFacts{Owner: i5svc, Open: i5db}
	rosterProjection := &characterstore.HeroBootstrapProjection{AwakeningPositions: heroSvc.AwakeningPositions, Awakening: heroSvc, Content: contentDB, Library: librarySvc, Dorm: dormSvc, Book: bookSvc, Course: courseSvc, Inscription: inscriptionSvc, Element: elementSvc, Spirit: spiritSvc, Evolution: evolutionSvc}
	librarySvc.Roster = rosterProjection
	achievements := canonicalAchievements(pool, runner, contentDB, i5db, i5svc, librarySvc, achievementOwners{books: bookSvc, courses: courseSvc, inscriptions: inscriptionSvc, dorm: dormSvc, skins: displayService}, txMetrics)
	mentorTimed := appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}
	socialRelationDB := socialrelationstore.Store{}
	mentorSvc := appmentor.Service{
		Timed:       mentorTimed,
		Players:     i4store.PlayerRootLocker{},
		Store:       mentorstore.Store{},
		Directory:   i4store.TransactionDiscoveryReader{},
		Cards:       socialpresentation.TransactionReader{Display: displayService},
		Friendships: socialrelation.FriendshipEnsurer{Players: i4store.PlayerRootLocker{}, Store: socialRelationDB},
		Backgrounds: librarystore.Store{},
		Functions:   i5db,
		Grants:      i5svc,
		Content:     contentDB,
		Receipts:    receipts,
	}
	petSvc := apppet.Service{Awakening: heroDB, Runner: runner, Timed: petTimed, Store: heroDB, Fencer: i5db, Content: contentDB, Progression: contentDB, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, Acquisition: petAcquisitionDebit, MaterialCosts: heroMaterialCosts, Scalar: i5CrossOwner, PetExp: petExpDebit, Equipment: contentDB, EquipmentResources: heroEquipmentResources, Promotion: contentDB, PromotionResources: i5svc, StrictRestoration: i5svc, RestorationModifier: characterasset.IdentityRestorationModifier{}, AppearanceStore: heroDB, Appearance: contentDB, AppearanceMutationStore: heroDB}
	heroSvc.AwakeningEquipment, petSvc.AwakeningEquipment = &i5svc, &i5svc
	i5svc.Awakening.Heroes, i5svc.Awakening.Pets = heroSvc, petSvc
	petEconomyProjection := appi5.ScalarProjector{Runner: runner, Store: i5db, FloorPolicies: contentDB}
	guildPolicyArtifact, err := guildpolicy.LoadBuiltin()
	if err != nil {
		log.Fatalf("I6C Guild policy: %v", err)
	}
	guildPolicy, err := guildpolicybridge.FromBuiltin(guildPolicyArtifact)
	if err != nil {
		log.Fatalf("I6C Guild policy binding: %v", err)
	}
	guildDB := guildstore.Store{Queryer: pool}
	guildSvc := guildcore.Service{
		Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner},
		Store: guildDB, Fencer: i5db, PlayerRoots: i4store.PlayerRootLocker{},
		Level: i5CrossOwner, Scalar: i5CrossOwner, LevelAndScalar: i5CrossOwner,
		Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, Policy: guildPolicy,
		Notices: postgres.GuildApplyNoticeEmitter{},
	}
	guildView := guildviewread.Reader{Runner: runner}
	teaPolicy, err := guildteapolicy.LoadBuiltin()
	if err != nil {
		log.Fatalf("I9-9A Guild tea policy: %v", err)
	}
	guildTeaSvc := appguildtea.Service{Runner: runner, Store: guildDB, Directory: i4store.PlayerDirectoryReader{}, Content: contentDB,
		Heroes: heroDB, Inventory: i5db, Values: i5svc, Costs: heroMaterialCosts, Facts: appi5.ObjectiveFacts{Owner: i5svc, Open: i5db},
		Fence: i5db, Players: i4store.PlayerRootLocker{}, Policy: appguildtea.Policy{RequestsPerDay: teaPolicy.Policy.RequestsPerDay, NormalNeed: teaPolicy.Policy.NormalNeed, SXNeed: teaPolicy.Policy.SXNeed, DonorFriendMedalPerScroll: teaPolicy.Policy.DonorFriendMedalPerScroll}}
	vending := appsummon.Mode{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}, Fresh: pool, Store: summonstore.Store{}, Content: contentDB, Fence: i5db,
		Heroes: heroSvc, HeroWire: heroproj.StockHero, Grants: i5svc, Costs: heroMaterialCosts, Facts: appi5.ObjectiveFacts{Owner: i5svc, Open: i5db, Observer: appadventure.Observer{Store: adventurestore.Store{}, Wake: adventureWakeup{}}}, Privileges: privileges, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}, Broadcast: broadcastEmitter}
	charge := commerceprivilege.Charge{
		Timed:       appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner},
		Fresh:       pool,
		Fence:       i5db,
		Facts:       appi5.ObjectiveFacts{Owner: i5svc, Open: i5db, Observer: appadventure.Observer{Store: adventurestore.Store{}, Wake: adventureWakeup{}}},
		Store:       commerceprivilegestore.Store{},
		Content:     contentDB,
		Grants:      i5svc,
		Effects:     appi5.PrivilegeTransitionOwner{Store: i5db, Content: contentDB},
		Directory:   i4store.DirectoryLevelProjection{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: pool},
	}
	heroBootstrap := &characterstore.HeroBootstrapProjection{AwakeningPositions: heroSvc.AwakeningPositions, Awakening: heroSvc, Content: contentDB, Library: librarySvc, Dorm: dormSvc, Book: bookSvc, Course: courseSvc, Inscription: inscriptionSvc, Element: elementSvc, Spirit: spiritSvc, Evolution: evolutionSvc}
	bootstrap := i4store.BootstrapService{
		Runner: runner, Receipts: receipts, ReceiptReader: kernelstore.Reader{Queryer: pool},
		DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: keyID, BearerKeys: bearerKeys,
		BootstrapProfileVersion: "i4-wave-s-v1",
		PersistenceContributors: characterbirth.Contributors(contentstore.Store{Queryer: pool}, privileges, dormBundle.RevisionID()),
		LoginTime:               postgres.AuthoritativeTime{Queryer: pool},
		LoginReconcilers:        []appboot.CharacterLoginReconciler{i4store.PlayerLoginActivity{}, socialrecall.LoginReconciler{Owner: socialrecallstore.Store{}, Players: i4store.PlayerRootLocker{}}, appi5.MailExpiryLoginReconciler{Store: i5db}, appi5.SignInBootstrap{Owner: i5svc}, appi5.MissionBootstrap{Owner: i5svc}, appi5.AwakeningBootstrap{Owner: i5svc}, appi5.PetStarterLoginReconciler{Store: i5db, Content: contentDB}},
		OperationBinder:         contentstore.Store{},
		DetailContributors:      []appboot.MID1DetailContributor{appdorm.GlueBootstrap{Owner: dormstore.Store{}}, appi5.AwakeningBootstrap{Owner: i5svc}, appi5.SignInBootstrap{Owner: i5svc}, appi5.MissionBootstrap{Owner: i5svc}, commerceprivilege.BootstrapProjection{Provider: privileges}, i5store.BootstrapProjection{Display: displayService, Content: contentstore.Store{Queryer: pool}, Privileges: privileges, MaxHeroColor: maxHeroColorPolicy, Spirit: spiritSvc}, activitystore.BootstrapProjection{Directory: activityDirectory}, guildprojection.BootstrapProjection{}, guildprojection.TeaProjection{}, mentorstore.BootstrapProjection{Service: mentorSvc}, heroBootstrap, librarystore.BootstrapProjection{Service: librarySvc}, bookstore.BootstrapProjection{Service: bookSvc, Content: contentDB}, coursestore.BootstrapProjection{Service: courseSvc, Content: contentDB}, characterstore.PetBootstrapProjection{Content: contentDB}, characterstore.SavedPresetBootstrapProjection{}, conquerstore.BootstrapProjection{Content: contentDB}, campaignWorld, vending, appmarch.Mode{Store: marchstore.Store{}, Roster: heroBootstrap}, apppetcampaign.Mode{Store: petcampaignstore.Store{}}, appgodstrial.Mode{Store: godstrialstore.Store{}}, appworldboss.Mode{Store: worldbossstore.Store{}}, appadventure.Mode{Store: adventurestore.Store{}, Content: contentDB, Functions: i5db, Directory: i4store.PlayerDirectoryReader{}}},
		DirectoryReconciler:     appdir.Reconciler{Source: i5db, Sink: i4store.DirectoryLevelProjection{}},
	}
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: keyID, BearerKeys: bearerKeys}
	realtime := apprealtime.Service{
		Authority: authority,
		Guilds:    guildprojection.RealtimeMembership{Queryer: pool},
		Endpoints: stockruntime.StaticEndpoints{Endpoint: apprealtime.Endpoint{Host: host, Port: port}},
	}
	tracker := lobby.NewBootTracker()
	evidenceCfg, evidenceEnabled, err := lobby.EvidenceConfigFromEnv(lobby.ProcessAPI, os.Getenv)
	if err != nil {
		log.Fatalf("invalid Wave-S evidence configuration: %v", err)
	}
	if evidenceEnabled {
		tracker, err = lobby.NewCapturedBootTracker(evidenceCfg)
		if err != nil {
			log.Fatal(err)
		}
		defer func() {
			if err := tracker.Close(); err != nil {
				log.Printf("Wave-S evidence close: %v", err)
			}
		}()
		go func() {
			if err := tracker.RunHealthPulses(ctx, lobby.DefaultEvidenceHealthInterval); err != nil && ctx.Err() == nil {
				log.Printf("Wave-S evidence unhealthy: %v", err)
			}
		}()
	}
	router := httpedge.NewRouter()
	mustRegister := func(mid uint16, d httpedge.Dispatcher) {
		if err := router.Register(mid, d); err != nil {
			log.Fatal(err)
		}
	}
	prelogin := stockruntime.PreloginDispatcher{PublicEngineURL: cfg.PublicEngineURL, Tracker: tracker}
	for _, mid := range []uint16{2, 2864, 20480} {
		mustRegister(mid, prelogin)
	}
	mux := http.NewServeMux()
	clientLogs, journal := startClientLog(ctx, pool, authority, cfg.ClientLogURL, retentionPolicies.RetentionDays, txMetrics, mux, handlerConcurrency("GXB_CLIENT_LOG_MAX_CONCURRENT", 4, poolConnections))
	dailyReset := dailyreset.Service{Markers: dailyresetstore.Store{Queryer: pool}, Counters: dailyreset.ZeroCounters{}}
	boot := stockruntime.BootstrapDispatcher{Bootstrap: bootstrap, Tracker: tracker, LogURLs: clientLogs, DailyReset: dailyReset}
	mustRegister(18, boot)
	mustRegister(1, boot)
	mustRegister(192, stockruntime.DiscoveryDispatcher{Realtime: realtime, Tracker: tracker, Reads: runner})
	// Login, bootstrap and discovery carry their own full state; every gameplay MID registered from here gets the F17 keys
	// and the R6 undelivered-reply guard: one decorator, resolved before the MID handler runs.
	undeliveredMarks := undeliveredstore.Store{Pool: pool.Raw()}
	replayWindow := envDurationWithin("GXB_UNDELIVERED_REPLAY_WINDOW", 10*time.Minute, time.Minute, 30*time.Minute)
	router.Wrap = func(d httpedge.Dispatcher) httpedge.Dispatcher {
		return stockruntime.UndeliveredReplay{Next: stockruntime.Decorated{Next: d, DailyReset: dailyReset}, Authority: authority, Marks: undeliveredMarks, Window: replayWindow, Metrics: txMetrics}
	}
	owners := topFloorOwners{library: librarySvc, dorm: dormSvc, book: bookSvc, course: courseSvc, inscription: inscriptionSvc, element: elementSvc, spirit: spiritSvc, evolution: evolutionSvc}
	publicStats := canonicalPublicStats(pool, contentDB, owners)
	heroRecommend := canonicalHeroRecommend(pool, runner, contentDB, owners, publicStats)
	heroRecommendD := stockruntime.HeroRecommendDispatcher{Authority: authority, Service: heroRecommend}
	for _, mid := range []uint16{2496, 2497, 2498, 2499} {
		mustRegister(mid, heroRecommendD)
	}
	go runReconcileWithInterval(ctx, pool, &appherorecommend.Reconciler{Service: heroRecommend}, envPositiveDuration("GXB_HERO_RECOMMEND_RECONCILE_INTERVAL", defaultReconcileInterval))
	profileMetrics := canonicalProfileMetrics(contentDB, publicStats, displayService, achievements)
	profileRecords := apppublicprofile.RosterRecords{Heroes: owners.roster(contentDB), Pets: characterstore.PetBootstrapProjection{Content: contentDB}, Awakening: publicStats.Awakening, Conquer: appconquer.Service{Owner: conquerstore.Store{}, Content: contentDB, Heroes: characterstore.Store{Queryer: pool}, Kinds: contentDB, Players: i4store.PlayerRootLocker{}}}
	var profileHistory apppublicprofile.HistoryReader
	// The title origin route copied above never reads metrics.
	boardRanking.Metrics = profileMetrics
	boardRanking.TopForce = profileMetrics
	boardRanking.Comfort = dormstore.Store{Queryer: pool}
	boardRanking.Presence = presencestore.Store{}
	boardRanking.Login = i4store.PlayerLoginActivity{}
	startRankingJobs(ctx, pool, boardRanking)
	rentalPolicy, err := guildrentalpolicy.LoadBuiltin()
	if err != nil {
		log.Fatalf("I9-9B Guild rental policy: %v", err)
	}
	rentalBinding := rentalPolicyBinding(rentalPolicy.Policy)
	rentalSvc, rentalReads := canonicalGuildRental(pool, runner, contentDB, guildDB, i5db, i5svc, privileges, publicStats, heroMaterialCosts, rentalBinding)
	guildSvc.Rental = rentalSvc
	fight, fightReady, err := canonicalCombat(pool, runner, contentDB, owners, rentalSvc)
	if err != nil {
		log.Fatalf("I7C-5B Combat composition: %v", err)
	}
	eventCentreSvc.Heroes = characterstore.Store{Queryer: pool}
	eventCentreSvc.Levels = i5db
	eventCentreSvc.Stats = publicStats
	eventCentreSvc.Combat = fight
	rentalRuntime := guildRentalRuntime{Service: rentalSvc, Reads: rentalReads}
	campaignCatalog, err := guildcampaigncatalog.LoadBuiltin()
	if err != nil {
		log.Fatalf("I9-9C Guild Campaign catalog: %v", err)
	}
	campaignPolicy, err := guildcampaignpolicy.LoadBuiltin()
	if err != nil {
		log.Fatalf("I9-9C Guild Campaign policy: %v", err)
	}
	if fightReady {
		campaignMode, _ := canonicalGuildCampaign(pool, runner, contentDB, guildDB, i5db, i5svc, guildcampaigncontent.Catalog{Installed: campaignCatalog.Catalog}, campaignPolicy.Policy, fight)
		campaignMode.Metrics = txMetrics
		guildSvc.Campaign = campaignMode
		campaignD := stockruntime.GuildCampaignDispatcher{Authority: authority, Service: campaignMode}
		for _, mid := range stockruntime.GuildCampaignMIDs {
			if mid == 610 {
				mustRegister(mid, observing(authority, achievements, "GuildCampaign", campaignD))
				continue
			}
			mustRegister(mid, campaignD)
		}
		go runReconcile(ctx, pool, appguildcampaign.Reconciler{Mode: campaignMode})
	}
	ranking := stockruntime.RankingDispatcher{Authority: authority, Service: boardRanking, Trophy: achievements, Guilds: guildView}
	var roomChat stockruntime.RoomChatSender
	if fightReady {
		sharedRooms := appsharedroom.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner},
			Fresh: pool, Store: sharedroomstore.Store{}, Fence: i5db, Players: i4store.PlayerRootLocker{}}
		fight.Inputs.Rooms = stockruntime.NewAdmissionRouter()
		worldBoss := canonicalWorldBoss(pool, runner, contentDB, i5db, i5svc, privileges, fight)
		roomInvites := roominvite.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner},
			Players: i4store.PlayerRootLocker{}, Roots: socialrelation.RootService{Store: socialrelationstore.Store{}}, Store: socialinboxstore.Store{},
			Notices: postgres.RoomInviteNoticeListEmitter{Pool: pool, OnError: func(err error) { log.Printf("room invite notice list degraded: %v", err) }},
			Limiter: roominvite.NewSenderRateLimiter(envPositiveDuration("GXB_ROOM_INVITE_SENDER_INTERVAL", roominvite.DefaultSenderInterval), envPositiveInt("GXB_ROOM_INVITE_SENDER_BURST", roominvite.DefaultSenderBurst))}
		illusion := canonicalIllusion(pool, runner, contentDB, i5db, i5svc, privileges, fight, guildDB, sharedRooms, roomInvites, retentionPolicies.RetentionDays)
		ranking.Illusion = illusion
		roomChat = illusion
		occultMode := canonicalOccult(pool, runner, contentDB, i5db, i5svc, fight, sharedRooms, roomInvites, retentionPolicies.RetentionDays)
		topFloor := canonicalTopFloor(pool, runner, contentDB, i5db, i5svc, privileges, fight, publicStats, owners, broadcastEmitter, displayService)
		memoir := canonicalMemoir(pool, runner, contentDB, i5db, i5svc, heroSvc, fight, topFloor)
		for _, mid := range stockruntime.MemoirMIDs {
			memoirD := stockruntime.MemoirDispatcher{Authority: authority, Service: memoir}
			if mid == 2310 || mid == 2313 {
				mustRegister(mid, observing(authority, achievements, "Memoir", memoirD))
				continue
			}
			mustRegister(mid, memoirD)
		}
		dodgeball := canonicalDodgeball(pool, runner, contentDB, i5db, i5svc, fight, displayService)
		for _, mid := range stockruntime.DodgeballMIDs {
			mustRegister(mid, stockruntime.DodgeballDispatcher{Authority: authority, Service: dodgeball})
		}
		godsTrial := canonicalGodsTrial(pool, runner, contentDB, i5db, i5svc, heroSvc, petSvc, fight, spiritSvc)
		for _, mid := range stockruntime.GodsTrialMIDs {
			mustRegister(mid, stockruntime.GodsTrialDispatcher{Authority: authority, Service: godsTrial})
		}
		petCampaign := canonicalPetCampaign(pool, runner, contentDB, i5db, i5svc, heroSvc, petSvc, fight)
		ranking.PetCampaign = petCampaign
		for _, mid := range stockruntime.PetCampaignMIDs {
			petD := stockruntime.PetCampaignDispatcher{Authority: authority, Service: petCampaign}
			if mid == 820 {
				mustRegister(mid, observing(authority, achievements, "PetCampaign", petD))
				continue
			}
			mustRegister(mid, petD)
		}
		workplace := canonicalWorkplace(pool, runner, contentDB, i5db, i5svc, heroSvc, fight, topFloor, rentalReads, broadcastEmitter)
		for _, mid := range stockruntime.WorkplaceMIDs {
			mustRegister(mid, observing(authority, achievements, "Hero", stockruntime.WorkplaceDispatcher{Authority: authority, Service: workplace}))
		}

		march := canonicalMarch(pool, runner, contentDB, i5db, i5svc, heroSvc, fight, topFloor)
		for _, mid := range stockruntime.MarchMIDs {
			mustRegister(mid, observing(authority, achievements, "Hero", stockruntime.MarchDispatcher{Authority: authority, Service: march}))
		}
		ranking.TopFloor = topFloor
		for _, mid := range stockruntime.TopFloorMIDs {
			mustRegister(mid, stockruntime.TopFloorDispatcher{Authority: authority, Service: topFloor})
		}
		for _, mid := range stockruntime.TopFloorTaskMIDs {
			mustRegister(mid, stockruntime.TopFloorTaskDispatcher{Authority: authority, Service: topFloor})
		}
		go runReconcile(ctx, pool, apptopfloor.Reconciler{Service: topFloor})
		oneOnOne := canonicalOneOnOne(pool, runner, contentDB, i5db, i5svc, privileges, fight, owners)
		ranking.OneOnOne = oneOnOne
		for _, mid := range stockruntime.OneOnOneMIDs {
			mustRegister(mid, stockruntime.OneOnOneDispatcher{Authority: authority, Service: oneOnOne})
		}
		go runReconcile(ctx, pool, apponeonone.Reconciler{Service: oneOnOne})
		arena := canonicalArena(pool, runner, contentDB, i5db, i5svc, fight, owners)
		// ARENA_HERO_PICKS_V1: both MID1 key49 and MID49 roster bodies read Arena's
		// season pick count (ledger DL-b024e8a4).
		rosterProjection.SeasonPicks = arena
		heroBootstrap.SeasonPicks = arena
		ranking.Arena = arena
		for _, mid := range stockruntime.ArenaMIDs {
			mustRegister(mid, stockruntime.ArenaDispatcher{Authority: authority, Service: arena})
		}
		for _, mid := range stockruntime.FriendFightMIDs {
			mustRegister(mid, stockruntime.FriendFightDispatcher{Authority: authority, Service: arena})
		}
		for _, mid := range stockruntime.TournamentMIDs {
			tournament := stockruntime.TournamentDispatcher{Authority: authority, Service: arena}
			if mid == 276 {
				tournament.WorldBoss = worldBoss
			}
			mustRegister(mid, tournament)
		}
		go runReconcile(ctx, pool, apparena.Reconciler{Service: arena})
		profileHistory = apppublicprofile.ModeHistory{TopFloor: topFloor, OneOnOne: oneOnOne, Arena: arena, Heroes: fight.Inputs.Heroes}
		league := canonicalLeague(pool, runner, contentDB, i5db, i5svc, fight, owners, displayService)
		for _, mid := range stockruntime.LeagueMIDs {
			mustRegister(mid, stockruntime.LeagueDispatcher{Authority: authority, Service: league})
		}
		go runReconcile(ctx, pool, appleague.Reconciler{Service: league})
		conquer := canonicalConquer(pool, runner, contentDB, i5db, i5svc, privileges, fight, broadcastEmitter)
		campaign := canonicalCampaign(pool, runner, contentDB, i5db, i5svc, heroSvc, fight)
		campaign.StarCaps = rentalStarCaps(rentalPolicy.Policy)
		blood := appawakeningbattle.Mode{Timed: heroSvc.Timed, Fresh: pool, Content: contentDB, Fence: i5db, Heroes: heroSvc, Missions: i5svc, Combat: fight, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}}
		for _, mid := range []uint16{866, 867} {
			mustRegister(mid, stockruntime.AwakeningBloodDispatcher{Authority: authority, Service: blood})
		}
		campaign.StoryHeroes, campaign.Pets, campaign.MaxColor = heroSvc, petSvc, maxHeroColorPolicy
		campaign.StoryWire = heroproj.StockHero
		for _, mid := range stockruntime.CampaignMIDs {
			campaignD := stockruntime.CampaignDispatcher{Authority: authority, Service: campaign}
			if mid == 114 {
				mustRegister(mid, observing(authority, achievements, "Campaign", campaignD))
				continue
			}
			mustRegister(mid, campaignD)
		}
		for _, mid := range stockruntime.ConquerMIDs {
			mustRegister(mid, observing(authority, achievements, "Conquer", stockruntime.ConquerDispatcher{Authority: authority, Service: conquer}))
		}
		for _, mid := range stockruntime.WorldBossMIDs {
			mustRegister(mid, stockruntime.WorldBossDispatcher{Authority: authority, Service: worldBoss})
		}
		for _, mid := range stockruntime.IllusionMIDs {
			mustRegister(mid, stockruntime.IllusionDispatcher{Authority: authority, Service: illusion})
		}
		adventureMode := canonicalAdventure(pool, runner, contentDB, i5db, i5svc, fight, adventureOpponents{Arena: arena, TopFloor: topFloor}, sharedRooms, heroSvc, heroproj.StockHero, roomInvites, retentionPolicies.RetentionDays)
		// 1362 is shared: Illusion answers its own reports, Adventure the co-op ones.
		for _, mid := range stockruntime.IllusionRoomMIDs {
			mustRegister(mid, stockruntime.IllusionRoomDispatcher{Authority: authority, Service: illusion, ReportFallback: adventureMode})
		}
		for _, mid := range stockruntime.OccultMIDs {
			occultD := stockruntime.OccultDispatcher{Authority: authority, Service: occultMode}
			if mid == 2371 || mid == 2372 || mid == 2374 || mid == 2377 {
				mustRegister(mid, observing(authority, achievements, "Occult", occultD))
				continue
			}
			mustRegister(mid, occultD)
		}
		for _, mid := range stockruntime.AdventureMIDs {
			mustRegister(mid, stockruntime.AdventureDispatcher{Authority: authority, Service: adventureMode})
		}
		go runReconcile(ctx, pool, appsharedroom.Reconciler{Service: sharedRooms, AllServers: true, Routes: map[string]string{appillusion.RoomFamily: appillusion.RoomNoticeRoute, appoccult.RoomFamily: appoccult.RoomNoticeRoute, appadventure.RoomFamily: appadventure.RoomNoticeRoute}})
		go runReconcile(ctx, pool, appillusion.Reconciler{Service: illusion})
		go runReconcile(ctx, pool, appworldboss.Reconciler{Service: worldBoss})
		go runReconcile(ctx, pool, appoccult.Reconciler{Service: occultMode})
		go runReconcile(ctx, pool, appadventure.Reconciler{Service: adventureMode})
	} else {
		log.Print("I7C-5B/5C/5D/5E/5F Top Floor, 1 on 1, Arena, Conquer School and Champions League routes not registered: GXB_COMBAT_ENTROPY_KEYS is unset")
	}
	mustRegister(301, ranking)
	mustRegister(121, stockruntime.OperationLogDispatcher{Authority: authority})
	mustRegister(30, stockruntime.FunctionClickDispatcher{Authority: authority})
	lobbyD := stockruntime.LobbyDispatcher{Authority: authority, Tracker: tracker}
	mustRegister(2754, lobbyD)
	for _, mid := range stockruntime.SummonMIDs {
		mustRegister(mid, stockruntime.SummonDispatcher{Authority: authority, Service: vending})
	}
	for _, mid := range stockruntime.ChargeMIDs {
		mustRegister(mid, stockruntime.ChargeDispatcher{Authority: authority, Service: charge})
	}
	for _, mid := range stockruntime.AchievementMIDs {
		mustRegister(mid, stockruntime.AchievementDispatcher{Authority: authority, Service: achievements})
	}
	socialTimed := appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}
	questionService := gmquestion.Service{Timed: socialTimed, Fence: i5db, Players: i4store.PlayerRootLocker{}, Owner: gmquestionstore.Store{}, Directory: i4store.TransactionDiscoveryReader{}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	questionDispatcher := stockruntime.GMQuestionDispatcher{Authority: authority, Service: questionService}
	mustRegister(4, questionDispatcher)
	mustRegister(5, questionDispatcher)

	publicationDB := publicationstore.Store{}
	if err := publicationDB.CheckSchema(ctx, pool); err != nil {
		log.Fatal(err)
	}
	publicationService := apppublication.Service{Timed: socialTimed, Store: publicationDB, PlayerRoots: i4store.PlayerRootLocker{}, Fence: i5db, Evidence: pool}
	if file := os.Getenv("GXB_PUBLICATION_FILE"); file != "" {
		f, err := os.Open(file)
		if err != nil {
			log.Fatal(err)
		}
		input, err := stockruntime.DecodePublicationInput(f)
		f.Close()
		if err != nil {
			log.Fatal(err)
		}
		op, err := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
		if err != nil {
			log.Fatal(err)
		}
		if err = publicationService.Install(ctx, op, input); err != nil {
			log.Fatal(err)
		}
	}
	publicationDispatcher := stockruntime.PublicationDispatcher{Authority: authority, Service: publicationService, Tracker: tracker}
	for _, mid := range []uint16{7, 1537, 8193, 8194} {
		mustRegister(mid, publicationDispatcher)
	}
	exchangeService := socialexchange.Service{Timed: socialTimed, Fence: i5db, Players: i4store.PlayerRootLocker{}, Content: contentDB, Settings: socialexchangestore.Store{}, Materials: i5svc, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	mustRegister(191, stockruntime.SocialExchangeDispatcher{Authority: authority, Service: exchangeService})
	recallTargets := socialrecallstore.TargetReader{Activity: i4store.PlayerLoginActivity{}, Progression: i5db, Roster: characterstore.RosterMetricReader{Store: heroDB, Content: contentDB}, Privilege: privileges, Relations: socialRelationDB}
	recallService := socialrecall.StartService{Timed: socialTimed, Fence: i5db, Content: contentDB, Starter: socialrecall.Starter{Players: i4store.PlayerRootLocker{}, Owner: socialrecallstore.Store{}, Targets: recallTargets}, Projection: socialrecallstore.DoingProjection{Directory: i4store.TransactionDiscoveryReader{}}, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	mustRegister(193, stockruntime.SocialRecallStartDispatcher{Authority: authority, Service: recallService})
	recallAwarder := socialrecall.Awarder{Players: i4store.PlayerRootLocker{}, Owner: socialrecallstore.Store{}, Content: contentDB, Current: recallTargets, Grants: i5svc}
	recallClaim := socialrecall.ClaimService{Timed: socialTimed, Fence: i5db, Players: i4store.PlayerRootLocker{}, Content: contentDB, Awarder: recallAwarder, Values: i5db, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	mustRegister(194, stockruntime.SocialRecallAwardDispatcher{Authority: authority, Service: recallClaim})
	inviteStore := socialinvitestore.Store{}
	inviteFacts := socialinvitestore.FactsReader{Directory: i4store.TransactionDiscoveryReader{}, Accounts: i4store.PlayerAccounts{}, Progression: i5db, Heroes: characterstore.HeroLevelReader{Store: heroDB}, Privilege: privileges, Servers: i4store.ServerNames{}}
	inviteReader := socialinvitestore.Reader{Owner: inviteStore, Facts: inviteFacts}
	inviteRead := socialinvite.ReadService{Timed: socialTimed, Content: contentDB, Reader: inviteReader}
	inviteBind := socialinvite.BindService{Timed: socialTimed, Fence: i5db, Players: i4store.PlayerRootLocker{}, Owner: inviteStore, Facts: inviteFacts, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	inviteClaim := socialinvite.ClaimService{Timed: socialTimed, Fence: i5db, Players: i4store.PlayerRootLocker{}, Content: contentDB, Owner: inviteStore, Reader: inviteReader, Grants: i5svc, Settings: inviteStore, Receipts: kernelstore.Store{}, ReceiptReader: kernelstore.Reader{Queryer: pool}}
	for _, mid := range []uint16{384, 385, 386} {
		mustRegister(mid, stockruntime.SocialInviteDispatcher{Authority: authority, Read: inviteRead, Bind: inviteBind, Claim: inviteClaim})
	}
	socialInboxDB := socialinboxstore.Store{}
	socialPresentation := socialpresentation.TransactionReader{Display: displayService}
	socialCommands := socialrelation.Service{Timed: socialTimed, PlayerRoots: i4store.PlayerRootLocker{}, Store: socialRelationDB, Inbox: socialinbox.RelationService{Store: socialInboxDB}, Presentation: socialPresentation}
	giftService := socialgift.Service{Timed: socialTimed, Reads: runner, Store: socialgiftstore.Store{}, Content: contentDB, Players: i4store.PlayerRootLocker{}, Relations: socialRelationDB, Privacy: socialrelation.FriendDMPrivacyProvider{Store: socialRelationDB}, Inbox: socialinbox.GiftService{Store: socialInboxDB}, NoticeEvidence: socialInboxDB, Grants: i5svc, Admission: authority, Fence: i5db, Bond: mentorSvc}
	socialReads := socialprojection.Service{Gifts: giftService, NoticePages: socialInboxDB, Runner: runner, PlayerRoots: i4store.PlayerRootLocker{}, Relations: socialRelationDB, Inbox: socialInboxDB, Directory: publicpresentation.DiscoveryReader{}, Presentation: socialPresentation, PresentationAt: socialPresentation, Observer: socialPresentation, Recall: socialrecallstore.RecallProjectionReader{Current: recallTargets}, Content: contentDB, ShowGuildInviteNotices: envBool("GXB_SOCIAL_SHOW_GUILD_INVITES")}
	friendDM := frienddm.Service{Timed: socialTimed, Queryer: pool, Store: frienddmstore.Store{}, Players: i4store.PlayerRootLocker{}, Privacy: socialrelation.FriendDMPrivacyProvider{Store: socialRelationDB}, Observer: socialPresentation, Content: contentDB, Entitlement: appi5.EmoticonEntitlementReader{Store: i5db, Content: contentDB}, Owner: presencestore.Store{Queryer: pool}}
	generalDM := generaldm.Service{Timed: socialTimed, Queryer: pool, Store: generaldmstore.Store{}, Bindings: generaldmbindings.Reader{}, Privacy: socialrelation.GeneralDMPrivacyProvider{Store: socialRelationDB}, Players: i4store.PlayerRootLocker{}, Presentation: socialPresentation, Observer: socialPresentation, Owner: presencestore.Store{Queryer: pool}}
	mustRegister(513, stockruntime.GeneralDMDispatcher{Authority: authority, Service: generalDM, Slots: make(chan struct{}, 16), Emitter: postgres.GeneralDMWakeupEmitter{Pool: pool}})
	friendBase := socialfriendbase.Service{FriendDM: friendDM, Projection: socialReads}
	mustRegister(515, stockruntime.FriendDMDispatcher{Authority: authority, Service: friendDM, RoomChat: roomChat, Emitter: postgres.FriendDMWakeupEmitter{Pool: pool, OnError: func(err error) { log.Printf("friend dm wakeup degraded: %v", err) }}})
	socialDismissal := socialdismiss.Service{Timed: socialTimed, PlayerRoots: i4store.PlayerRootLocker{}, Roots: socialRelationDB, Inbox: socialInboxDB}
	socialDispatcher := stockruntime.SocialDispatcher{Authority: authority, Relations: socialCommands, Projection: friendBase, Dismissal: socialDismissal, Scalar: appi5.ScalarProjector{Runner: runner, Store: i5db, FloorPolicies: contentDB}, Tracker: tracker, Emitter: postgres.SocialWakeupEmitter{Pool: pool, OnError: func(err error) { log.Printf("social wakeup degraded: %v", err) }}}
	giftReload := socialreload.Service{Runner: runner, Relations: socialRelationDB, Inbox: socialInboxDB, Observer: socialPresentation, Gifts: giftService}
	if e := configureGuildInvite(ctx, pool, runner, &guildSvc, &giftService, &socialReads, &giftReload); e != nil {
		log.Fatalf("Guild Invite bundle readiness: %v", e)
	}
	socialReads.Gifts = giftService
	giftReload.Gifts = giftService
	friendBase.Projection = socialReads
	socialDispatcher.Projection = friendBase
	giftGroup, err := stockruntime.PrepareGiftStock(socialDispatcher, giftService, friendBase, giftReload)
	if err != nil {
		log.Fatalf("Gift consumer readiness: %v", err)
	}
	// Startup preserves the content-owner activation pointer. Only a compatible
	// active catalog enables all Gift surfaces together; relation routes remain.
	giftReadinessCtx, giftReadinessCancel := context.WithTimeout(ctx, 2*time.Second)
	enabledGiftDispatcher, giftReadinessErr := giftGroup.Enable(giftReadinessCtx, pool)
	giftReadinessCancel()
	if giftReadinessErr == nil {
		socialDispatcher = enabledGiftDispatcher
	} else {
		// shortcut: this degraded window lists relation rows only, so room and guild
		// invites stay unseen until the content owner activates the gift group.
		legacyReads := socialReads
		legacyReads.Invites = nil
		legacyReads.PresentationAt = nil
		legacyReads.Gifts = nil
		legacyReads.NoticePages = nil
		socialDispatcher.Projection = socialfriendbase.Service{FriendDM: friendDM, Projection: legacyReads}
		log.Printf("Gift stock group inactive; explicit content-owner activation required: %v", giftReadinessErr)
	}
	if err := stockruntime.RegisterSocialRoutes(router, socialDispatcher); err != nil {
		log.Fatalf("social route assembly: %v", err)
	}
	mentorDispatcher := stockruntime.MentorDispatcher{Authority: authority, Service: mentorSvc}
	for _, mid := range []uint16{1856, 1857, 1858, 1859, 1860, 1861, 1862, 1863} {
		if mid == 1862 {
			mustRegister(mid, observing(authority, achievements, "Mentor", mentorDispatcher))
			continue
		}
		mustRegister(mid, mentorDispatcher)
	}
	practiceD := stockruntime.PracticeDispatcher{Authority: authority, Service: practiceSvc, Tracker: tracker}
	for _, mid := range []uint16{124, 125, 126, 127, 128, 129, 130, 131, 132, 133} {
		mustRegister(mid, practiceD)
	}
	activityD := stockruntime.ActivityDispatcher{Authority: authority, Service: activityRuntime, Reads: runner, Levels: i4store.PlayerDirectoryReader{}}
	for _, mid := range []uint16{229, 234} {
		mustRegister(mid, activityD)
	}
	savedPresetD := stockruntime.SavedPresetDispatcher{Authority: authority, Service: savedPresetSvc}
	mustRegister(1793, savedPresetD)
	bookmarkSvc := apphero.BookmarkService{Timed: heroSvc.Timed, Reads: runner, Store: heroDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Receipts: receipts}
	skillSvc := apphero.SkillChoiceService{Timed: heroSvc.Timed, Reads: runner, Store: heroDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Receipts: receipts, Inventory: i5db, Content: contentDB}
	skillLevelSvc := apphero.HeroSkillLevelService{Timed: heroSvc.Timed, Reads: runner, Store: heroDB, Books: bookSvc, Content: contentDB, Players: i4store.PlayerRootLocker{}, Fence: i5db, Receipts: receipts, Resources: i5svc, DiscountBasisPoints: 10000}
	heroD := observing(authority, achievements, "Hero", stockruntime.HeroDispatcher{Roster: librarySvc, Skills: skillSvc, SkillLevels: skillLevelSvc, Bookmark: bookmarkSvc, Authority: authority, Service: heroSvc, Appearance: heroSvc, LIVE: heroSvc, Economy: heroEconomyProjection})
	for _, mid := range []uint16{39, 53, 2144, 3116, 49, 51, 52, 54, 55, 57, 58, 59, 60, 61, 62, 63, 67, 68, 69, 89, 304, 305, 2979} {
		mustRegister(mid, heroD)
	}
	evolutionD := stockruntime.EvolutionDispatcher{Authority: authority, Service: evolutionSvc}
	for _, mid := range []uint16{2608, 2609} {
		mustRegister(mid, evolutionD)
	}
	spiritD := stockruntime.SpiritDispatcher{Authority: authority, Service: spiritSvc}
	for _, mid := range []uint16{3089, 3090, 3091, 3094, 3095, 3112, 3113, 3114, 3115} {
		mustRegister(mid, spiritD)
	}

	elementD := stockruntime.ElementDispatcher{Authority: authority, Service: elementSvc}
	for _, mid := range []uint16{2849, 2850, 2851, 2852, 2853} {
		mustRegister(mid, elementD)
	}
	inscriptionD := stockruntime.InscriptionDispatcher{Authority: authority, Service: inscriptionSvc}
	for mid := uint16(1400); mid <= 1407; mid++ {
		mustRegister(mid, observing(authority, achievements, "Inscription", inscriptionD))
	}
	courseD := stockruntime.CourseDispatcher{Authority: authority, Service: courseSvc}
	for _, mid := range []uint16{2128, 2129, 2130, 2131, 2132, 2133, 2134, 2135, 2136, 2137, 2138, 2139, 2140, 2141, 2142, 2500} {
		mustRegister(mid, observing(authority, achievements, "Course", courseD))
	}
	bookD := stockruntime.BookDispatcher{Authority: authority, Service: stockruntime.NewCoalescedBookRead(bookSvc), Tracker: tracker}
	for _, mid := range []uint16{83, 1056, 1057, 1058, 1059, 1060, 1061, 1077, 1078, 1079, 1080} {
		mustRegister(mid, observing(authority, achievements, "Book", bookD))
	}
	eventCentreD := stockruntime.EventCentreDispatcher{Authority: authority, Service: eventCentreSvc}
	for _, mid := range []uint16{1072, 1073, 1074, 1075, 1076, 1081, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091} {
		mustRegister(mid, eventCentreD)
	}
	dormD := stockruntime.DormDispatcher{Authority: authority, Service: dormSvc}
	for _, mid := range []uint16{1845, 2512, 2513, 2514, 2515, 2516, 2517, 2518, 2519, 2520, 2521, 2522, 2523, 2524, 2525, 2526, 2693, 2694, 2695} {
		mustRegister(mid, observing(authority, achievements, "Dorm", dormD))
	}
	libraryD := stockruntime.LibraryDispatcher{Authority: authority, Service: librarySvc}
	for _, mid := range []uint16{72, 835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 847, 851, 852, 853, 854, 855, 856, 857, 2784, 2785} {
		if mid == 851 {
			mustRegister(mid, observing(authority, achievements, "SchoolStory", libraryD))
			continue
		}
		mustRegister(mid, libraryD)
	}
	forumD := stockruntime.LibraryForumDispatcher{Authority: authority, Service: forumSvc}
	for _, mid := range []uint16{832, 833, 834} {
		mustRegister(mid, forumD)
	}
	petD := observing(authority, achievements, "Pet", stockruntime.PetDispatcher{Authority: authority, Service: petSvc, Economy: petEconomyProjection})
	for _, mid := range []uint16{134, 780, 781, 782, 783, 785, 786, 787, 789, 790, 791, 792, 1893, 1894, 1895} {
		mustRegister(mid, petD)
	}
	guildD := stockruntime.GuildDispatcher{Authority: authority, Core: guildSvc, View: guildView}
	for _, mid := range []uint16{576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 589, 598, 599, 612, 616, 2563, 2564, 2565} {
		mustRegister(mid, guildD)
	}
	teaD := stockruntime.GuildTeaDispatcher{Authority: authority, Service: guildTeaSvc}
	for _, mid := range stockruntime.GuildTeaMIDs {
		mustRegister(mid, teaD)
	}
	mustRegister(stockruntime.GuildWarRedPointMID, stockruntime.GuildWarRedPointDispatcher{Authority: authority})
	rentalD := stockruntime.GuildRentalDispatcher{Authority: authority, Service: rentalRuntime}
	for _, mid := range stockruntime.GuildRentalMIDs {
		mustRegister(mid, rentalD)
	}
	if e := registerGuildBroadcast(ctx, pool, runner, authority, guildDB, i5db, receipts, contentDB, router); e != nil {
		log.Fatalf("Guild broadcast group: %v", e)
	}
	if e := registerProfileFeedback(ctx, pool, runner, authority, receipts, contentDB, router); e != nil {
		log.Fatal(e)
	}
	if e := registerPublicProfile(ctx, pool, runner, authority, receipts, contentDB, profileMetrics, router); e != nil {
		log.Fatalf("PublicProfile startup: %v", e)
	}
	if e := registerPublicProfileReads(ctx, pool, runner, authority, receipts, contentDB, displayService, profileMetrics, profileRecords, profileHistory, router); e != nil {
		log.Fatal(e)
	}
	if e := registerPlayerDisplay(ctx, pool, contentDB, router, stockruntime.PlayerDisplayDispatcher{Authority: authority, Service: displayService}); e != nil {
		log.Fatalf("Player display startup: %v", e)
	}
	i5d := stockruntime.I5Dispatcher{Awakening: i5svc, SignIn: i5svc, Authority: authority, Service: i5svc, Missions: i5svc, SpiritBackpack: stockruntime.SpiritBackpackProjection{Service: spiritSvc}}
	for _, mid := range []uint16{163, 164, 165, 166, 167, 168, 171, 2561, 2737, 2738, 26, 81, 161, 230, 368, 369, 370, 2736, 2865, 2866} {
		mustRegister(mid, i5d)
	}
	for _, mid := range []uint16{160, 169, 170, 352, 353} {
		mustRegister(mid, i5d)
	}
	mediaHandler, err := registerProfileMedia(ctx, pool, runner, authority, receipts, contentDB, router, cfg.ProfileMediaRoot, cfg.ProfileMediaPublicOrigin, handlerConcurrency("GXB_PROFILE_MEDIA_GET_MAX_CONCURRENT", 8, poolConnections))
	if err != nil {
		log.Fatalf("Profile media startup: %v", err)
	}
	// Registered last: a surface MID that already has its owner's dispatcher keeps it.
	for _, mid := range stockruntime.InactiveModeMIDs {
		if _, owned := router.Lookup(mid); !owned {
			mustRegister(mid, stockruntime.InactiveModeDispatcher{Authority: authority})
		}
	}
	admission, err := httpedge.NewAdmission(envPositiveInt("GXB_HTTP_EDGE_MAX_IN_FLIGHT", 1024))
	if err != nil {
		log.Fatal(err)
	}
	// Bodies read at once; each is bounded by limits.Default, so this caps edge memory, not database work (A-047).
	decoding, err := httpedge.NewAdmission(envPositiveInt("GXB_HTTP_EDGE_MAX_DECODING", 1024))
	if err != nil {
		log.Fatal(err)
	}
	h := httpedge.Handler{
		Limits: limits.Default(), Admission: admission, Decoding: decoding,
		Operations: operation.Factory{Clock: clock.System{}}, Router: router, Journal: journal,
		Undelivered: undeliveredMarks, Metrics: txMetrics,
		Conformance: replyconformance.Checker{},
		QueueBudget: time.Duration(envPositiveInt("GXB_HTTP_QUEUE_BUDGET_SECONDS", int(httpedge.DefaultQueueBudget/time.Second))) * time.Second,
		QueueWait:   transactionAdmission,
	}
	mux.Handle("/", h)
	if mediaHandler != nil {
		mux.Handle("/profile-media/", mediaHandler)
	}
	srv := &http.Server{Addr: cfg.HTTPAddr, Handler: mux, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: limits.StockMultipartHTTPTimeout + 5*time.Second, WriteTimeout: limits.StockMultipartHTTPTimeout + 5*time.Second, IdleTimeout: 60 * time.Second}
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = srv.Shutdown(shutdownCtx)
	}()
	log.Printf("gxb-api listening on %s; advertised realtime=%s:%d", cfg.HTTPAddr, host, port)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}
