//go:build postgres

package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/activitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/characterasset"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	appsavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	appdir "gxb.local/backend/v2/internal/application/directorysync"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildview"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/config"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
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

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	pool, err := postgres.Open(ctx, string(cfg.PostgresDSN), postgres.PoolSettings{
		MaxConns: 16, MinConns: 1, MaxConnLifetime: 30 * time.Minute,
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
	runner := tx.Runner{DB: pool, Admission: tx.NewSemaphore(64), Hooks: observability.TxHooks{Metrics: txMetrics}}
	// Deployment must apply migrations first. Gate all HTTP traffic on content readiness.
	contentCtx, contentCancel := context.WithTimeout(ctx, 3*registry.DefaultWriteProfile().OperationTimeout)
	active, contentErr := registry.Initialize(contentCtx, registry.Service{
		Runner: runner, Repo: contentstore.Store{}, Fresh: pool, Providers: registry.DefaultProviderSet(),
	}, operation.Factory{Clock: clock.System{}})
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
	activityProviders, err := appactivity.NewRegistry(nil, activityContentCapabilities)
	if err != nil {
		log.Fatalf("I6B Activity provider registry: %v", err)
	}
	activityDirectory := appactivity.Directory{Registry: activityProviders}
	activityRuntime := appactivity.Runtime{Directory: activityDirectory, Time: postgres.AuthoritativeTime{Queryer: pool}}
	receipts := kernelstore.Store{}
	bearerKeys := appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: keyID, Secret: bearerSecret}}
	i5db := i5store.Store{Queryer: pool}
	contentDB := contentstore.Store{Queryer: pool}
	i5svc := appi5.Service{Runner: runner, Store: i5db, Content: contentDB, Privileges: appi5.BaselinePrivilegeProvider{}, Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: i5db, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, RedeemSecret: redeemSecret}
	maxHeroColorPolicy := appi5.PreservationMaxHeroColorProvider{}
	heroDB := characterstore.Store{Queryer: pool}
	savedPresetSvc := appsavedpreset.MutationService{Runner: runner, Store: heroDB, Fencer: i5db, References: appsavedpreset.ReferenceOwners{Heroes: heroDB, Pets: heroDB}, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}}
	heroEconomy := appi5.HeroProgressionDebiter{Store: i5db, Content: contentDB}
	heroMaterialCosts := appi5.MaterialCostDebiter{Store: i5db, Content: contentDB}
	heroEquipmentResources := appi5.HeroEquipmentResourceDebiter{Store: i5db, Content: contentDB}
	heroEconomyProjection := appi5.ScalarProjector{Runner: runner, Store: i5db}
	i5CrossOwner := appi5.CrossOwner{Store: i5db}
	practiceSvc := apppractice.Service{
		Runner: runner, Store: heroDB, Content: contentDB, Privileges: appi5.BaselinePrivilegeProvider{}, ReconcileQueryer: pool,
		Deps: apppractice.ServiceDeps{
			Fencer: i5db, HeroOwner: heroDB, PetOwner: heroDB, Level: i5CrossOwner, LevelAndScalar: i5CrossOwner,
			TicketDebit: appi5.LevelAndStackDebiter{Store: i5db, Content: contentDB}, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool},
		},
	}
	// CA2-3 mechanics are constructed against owner-shaped ports, but Capacity
	// remains nil and I5.PartnerEntities/MID59/MID305 remain unregistered in
	// production until the original Hero capacity policy is recovered.
	heroSvc := apphero.Service{Runner: runner, Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}, Store: heroDB, Fencer: i5db, Content: contentDB, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, ProgressionStore: heroDB, Progression: contentDB, Economy: heroEconomy, Backpack: i5db, AcquisitionStore: heroDB, Acquisition: contentDB, MaterialCosts: heroMaterialCosts, PlayerLevel: i5CrossOwner, Capacity: nil, Equipment: contentDB, EquipmentResources: heroEquipmentResources, Fumo: contentDB, Promotion: contentDB, PromotionResources: i5svc, StrictRestoration: i5svc, MaxHeroColorPolicy: maxHeroColorPolicy, RestorationModifier: characterasset.IdentityRestorationModifier{}, RosterProjection: contentDB, AppearanceStore: heroDB, Appearance: contentDB, AppearanceMutationStore: heroDB, AppearanceMutationContent: contentDB, LIVEMutationStore: heroDB}
	petAcquisitionDebit := appi5.PetAcquisitionDebiter{Store: i5db, Content: contentDB}
	petExpDebit := appi5.PetExpDebiter{Store: i5db, Content: contentDB}
	petTimed := appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}
	petSvc := apppet.Service{Runner: runner, Timed: petTimed, Store: heroDB, Fencer: i5db, Content: contentDB, Progression: contentDB, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: pool}, Acquisition: petAcquisitionDebit, MaterialCosts: heroMaterialCosts, Scalar: i5CrossOwner, PetExp: petExpDebit, Equipment: contentDB, EquipmentResources: heroEquipmentResources, Promotion: contentDB, PromotionResources: i5svc, StrictRestoration: i5svc, RestorationModifier: characterasset.IdentityRestorationModifier{}, AppearanceStore: heroDB, Appearance: contentDB}
	petEconomyProjection := appi5.ScalarProjector{Runner: runner, Store: i5db}
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
	}
	guildView := guildview.Service{Store: guildDB, Directory: i4store.PlayerDirectoryReader{Queryer: pool}}
	bootstrap := i4store.BootstrapService{
		Runner: runner, Receipts: receipts, ReceiptReader: kernelstore.Reader{Queryer: pool},
		DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: keyID, BearerKeys: bearerKeys,
		BootstrapProfileVersion: "i4-wave-s-v1",
		PersistenceContributors: []appboot.CharacterBootstrapPersistenceContributor{i5store.PlayerCoreBootstrapContributor{}, i5store.EconomyOwnerBootstrapContributor{Content: contentstore.Store{Queryer: pool}, Privileges: appi5.BaselinePrivilegeProvider{}}, characterstore.BootstrapContributor{}, characterstore.PetBootstrapContributor{}, characterstore.SavedPresetBootstrapContributor{}, characterstore.PracticeBootstrapContributor{}},
		LoginReconcilers:        []appboot.CharacterLoginReconciler{appi5.PetStarterLoginReconciler{Store: i5db, Content: contentDB}},
		OperationBinder:         contentstore.Store{},
		DetailContributors:      []appboot.MID1DetailContributor{i5store.BootstrapProjection{Content: contentstore.Store{Queryer: pool}, Privileges: appi5.BaselinePrivilegeProvider{}, MaxHeroColor: maxHeroColorPolicy}, activitystore.BootstrapProjection{Directory: activityDirectory}, guildprojection.BootstrapProjection{}, characterstore.HeroBootstrapProjection{Content: contentDB}, characterstore.PetBootstrapProjection{Content: contentDB}, characterstore.SavedPresetBootstrapProjection{}},
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
	for _, mid := range []uint16{2, 7, 2864, 20480} {
		mustRegister(mid, prelogin)
	}
	boot := stockruntime.BootstrapDispatcher{Bootstrap: bootstrap, Tracker: tracker, ClientLogURL: cfg.ClientLogURL}
	mustRegister(18, boot)
	mustRegister(1, boot)
	mustRegister(192, stockruntime.DiscoveryDispatcher{Realtime: realtime, Tracker: tracker})
	lobbyD := stockruntime.LobbyDispatcher{Authority: authority, Tracker: tracker}
	for _, mid := range []uint16{56, 1056, 176, 1302, 1344, 2754, 2784, 8193} {
		mustRegister(mid, lobbyD)
	}
	practiceD := stockruntime.PracticeDispatcher{Authority: authority, Service: practiceSvc, Tracker: tracker}
	for _, mid := range []uint16{124, 125, 126, 127, 128, 129, 130, 131, 132, 133} {
		mustRegister(mid, practiceD)
	}
	activityD := stockruntime.ActivityDispatcher{Authority: authority, Service: activityRuntime}
	for _, mid := range []uint16{229, 234} {
		mustRegister(mid, activityD)
	}
	savedPresetD := stockruntime.SavedPresetDispatcher{Authority: authority, Service: savedPresetSvc}
	mustRegister(1793, savedPresetD)
	heroD := stockruntime.HeroDispatcher{Authority: authority, Service: heroSvc, Appearance: heroSvc, LIVE: heroSvc, Economy: heroEconomyProjection}
	for _, mid := range []uint16{49, 51, 52, 54, 55, 57, 58, 60, 61, 62, 63, 67, 68, 69, 89, 304, 2979} {
		mustRegister(mid, heroD)
	}
	petD := stockruntime.PetDispatcher{Authority: authority, Service: petSvc, Economy: petEconomyProjection}
	for _, mid := range []uint16{134, 780, 781, 782, 783, 785, 786, 787, 789, 790, 791, 792} {
		mustRegister(mid, petD)
	}
	guildD := stockruntime.GuildDispatcher{Authority: authority, Core: guildSvc, View: guildView}
	for _, mid := range []uint16{576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 589, 598, 599, 612, 2563, 2564, 2565} {
		mustRegister(mid, guildD)
	}
	i5d := stockruntime.I5Dispatcher{Authority: authority, Service: i5svc}
	for _, mid := range []uint16{26, 81, 161, 230, 368, 369, 370, 2736} {
		mustRegister(mid, i5d)
	}
	admission, err := httpedge.NewAdmission(256)
	if err != nil {
		log.Fatal(err)
	}
	h := httpedge.Handler{
		Limits: limits.Default(), Admission: admission,
		Operations: operation.Factory{Clock: clock.System{}}, Router: router,
	}
	srv := &http.Server{Addr: cfg.HTTPAddr, Handler: h, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: limits.StockMultipartHTTPTimeout + 5*time.Second, WriteTimeout: limits.StockMultipartHTTPTimeout + 5*time.Second, IdleTimeout: 60 * time.Second}
	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = srv.Shutdown(shutdownCtx)
	}()
	log.Printf("gxb-api I6C candidate listening on %s; advertised realtime=%s:%d", cfg.HTTPAddr, host, port)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}
