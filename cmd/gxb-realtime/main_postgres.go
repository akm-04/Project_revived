//go:build postgres

package main

import (
	"context"
	"errors"
	"log"
	"net"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/channelchatread"
	"gxb.local/backend/v2/internal/adapters/generaldmbindings"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/frienddmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/achievement"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	apparena "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/generaldm"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	appillusion "gxb.local/backend/v2/internal/application/illusion"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/application/roominvite"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/config"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	cfg := config.FromEnv()
	digestSecret := []byte(os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET"))
	bearerSecret := []byte(os.Getenv("GXB_GAMEPLAY_BEARER_SECRET"))
	keyID := os.Getenv("GXB_DERIVATION_KEY_ID")
	host := os.Getenv("GXB_REALTIME_PUBLIC_HOST")
	port, err := strconv.Atoi(os.Getenv("GXB_REALTIME_PUBLIC_PORT"))
	if err != nil || port <= 0 || port > 65535 || host == "" {
		log.Fatal("valid advertised realtime endpoint required")
	}
	if len(cfg.PostgresDSN) == 0 || len(digestSecret) < 16 || len(bearerSecret) < 16 || keyID == "" {
		log.Fatal("I4 PostgreSQL/credential configuration incomplete")
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	pool, err := postgres.Open(ctx, string(cfg.PostgresDSN), postgres.PoolSettings{
		MaxConns: 16, MinConns: 1, MaxConnLifetime: 30 * time.Minute,
		MaxConnIdleTime: 5 * time.Minute, HealthCheckPeriod: 30 * time.Second,
		ApplicationName: "gxb-v2-i4-realtime",
	})
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatal(err)
	}
	ownerGuard, err := postgres.AcquireRealtimeOwner(ctx, pool)
	if err != nil {
		log.Fatalf("realtime single-owner acquisition failed: %v", err)
	}
	defer func() {
		if err := ownerGuard.Close(); err != nil {
			log.Printf("realtime owner guard close: %v", err)
		}
	}()
	presenceStore := presencestore.Store{Queryer: pool}
	realtimeOwnerFence, err := presenceStore.ActivateRealtimeOwnerFence(ctx)
	if err != nil {
		log.Fatalf("realtime presence owner fence allocation failed: %v", err)
	}
	realtimeInstanceID, err := ids.NewUUID()
	if err != nil {
		log.Fatalf("realtime process instance id: %v", err)
	}
	go func() {
		if err := ownerGuard.RunHealthPulses(ctx, postgres.DefaultRealtimeOwnerHealthInterval); err != nil && ctx.Err() == nil {
			log.Printf("realtime owner session lost: %v", err)
			stop()
		}
	}()
	bearerKeys := appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: keyID, Secret: bearerSecret}}
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: keyID, BearerKeys: bearerKeys}
	auth := apprealtime.Service{
		Authority: authority,
		Guilds:    guildprojection.RealtimeMembership{Queryer: pool},
		Endpoints: stockruntime.StaticEndpoints{Endpoint: apprealtime.Endpoint{Host: host, Port: port}},
	}
	runtimePolicy, err := stockruntime.RealtimePolicyFromEnv(os.Getenv)
	if err != nil {
		log.Fatalf("invalid realtime policy: %v", err)
	}
	admission, err := stockruntime.NewAdmissionLimiter(runtimePolicy)
	if err != nil {
		log.Fatalf("invalid realtime admission policy: %v", err)
	}
	tracker := lobby.NewBootTracker()
	evidenceCfg, evidenceEnabled, err := lobby.EvidenceConfigFromEnv(lobby.ProcessRealtime, os.Getenv)
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
	presenceRunner := tx.Runner{DB: pool}
	presenceService := socialpresence.Service{
		Timed: appgeneration.TimedRunner{
			Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}},
			Runner: presenceRunner,
		},
		Store: presenceStore,
	}
	presenceOperations := operation.Factory{Clock: clock.System{}}
	presenceProviders, err := appgeneration.NewReconcileRegistry(socialpresence.Reconciler{
		Runner: presenceRunner, RealtimeOwnerFence: realtimeOwnerFence, Store: presenceStore, Expired: presenceStore,
	})
	if err != nil {
		log.Fatalf("social presence reconciler registry: %v", err)
	}
	presenceReconcile := appgeneration.ReconcileKernel{
		Binder:    appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}},
		Providers: presenceProviders,
	}
	runPresenceReconcile := func(stage string) {
		op, err := presenceOperations.New(policy.Set{})
		if err != nil {
			log.Printf("social presence reconcile %s operation degraded: %v", stage, err)
			return
		}
		results, err := presenceReconcile.Run(ctx, op, appgeneration.MaxReconcileBatch)
		if err != nil {
			log.Printf("social presence reconcile %s degraded: %v", stage, err)
			return
		}
		for _, result := range results {
			if result.Settled > 0 {
				log.Printf("social presence reconcile %s provider=%s scanned=%d settled=%d noops=%d", stage, result.Provider, result.Scanned, result.Settled, result.Noops)
			}
		}
	}
	runPresenceReconcile("startup")
	go func() {
		ticker := time.NewTicker(runtimePolicy.LivenessInterval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				runPresenceReconcile("periodic")
			}
		}
	}()
	connectionsRegistry := stockruntime.NewConnectionRegistry()
	chatEvents, err := wireRT.NewChannelChatEventRegistry()
	if err != nil {
		return err
	}
	displayRevision, err := (contentstore.Store{}).ActiveRevision(ctx, pool)
	if err != nil {
		return err
	}
	if _, err = (contentstore.Store{}).ReadPlayerDisplayCatalogTx(ctx, pool, displayRevision); err != nil {
		return err
	}
	channelService := channelchat.Service{Runner: presenceRunner, Operations: presenceOperations, Reader: channelchatread.Reader{},
		Owners: channelchat.Owners{Illusion: channelchatread.IllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
			AdventureIllusion: channelchatread.AdventureIllusionRoomReader{Store: sharedroomstore.Store{}, Content: contentstore.Store{}},
			Occult:            channelchatread.OccultRoomReader{Store: sharedroomstore.Store{}}}}
	chatDispatcher, err := stockruntime.NewChannelChatDispatcher(connectionsRegistry, channelService, stockruntime.RealtimePublisher{Registry: chatEvents, Limits: limits.Default()}, stockruntime.DefaultChannelChatPolicy(runtimePolicy.MaxConnections))
	if err != nil {
		return err
	}
	server := stockruntime.RealtimeServer{
		Auth: auth, Limits: limits.Default(), Policy: runtimePolicy, Tracker: tracker,
		Registry: connectionsRegistry, Admission: admission, SessionDispatcher: chatDispatcher,
		Presence: presenceService, PresenceOperations: presenceOperations,
		RealtimeOwnerFence: realtimeOwnerFence, RealtimeInstanceID: realtimeInstanceID,
		OnPresenceError: func(stage string, err error) { log.Printf("social presence %s degraded: %v", stage, err) },
	}

	socialEvents, err := stockruntime.NewGeneralSocialEventRegistry()
	if err != nil {
		log.Fatal(err)
	}
	socialReload := socialreload.Service{Gifts: socialgift.Service{Store: socialgiftstore.Store{}, Content: contentstore.Store{Queryer: pool}, NoticeEvidence: socialinboxstore.Store{}}, Runner: presenceRunner, Relations: socialrelationstore.Store{}, Inbox: socialinboxstore.Store{}, Observer: socialpresentation.TransactionReader{}}
	inviteRevision, e := (contentstore.Store{}).ActiveRevision(ctx, pool)
	if e != nil {
		return e
	}
	inviteBundle, e := guildinvitebundle.Prepare(ctx, pool, presenceRunner, inviteRevision)
	if e != nil {
		return e
	}
	if inviteBundle.Present {
		socialReload.Invites = inviteBundle.Target
	}
	socialHandler := stockruntime.SocialReloadHandler{Service: socialReload, Operations: presenceOperations, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: socialEvents, Limits: limits.Default()}, Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, IsStaleActor: func(err error) bool { return errors.Is(err, i4store.ErrGameplayBearerNotLive) }, OnDeliveryError: func(err error) { log.Printf("social delivery degraded: %v", err) }}
	friendDM := frienddm.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: presenceRunner}, Queryer: pool, Store: frienddmstore.Store{}, Players: i4store.PlayerRootLocker{}, Privacy: socialrelation.FriendDMPrivacyProvider{Store: socialrelationstore.Store{}}, Observer: socialpresentation.TransactionReader{}, Content: contentstore.Store{Queryer: pool}, Owner: presenceStore}
	friendDelivery := stockruntime.FriendDMDelivery{Service: friendDM, Fence: realtimeOwnerFence, Operations: presenceOperations, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: socialEvents, Limits: limits.Default()}, Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, IsStaleActor: func(e error) bool { return errors.Is(e, i4store.ErrGameplayBearerNotLive) }, OnDeliveryError: func(e error) { log.Printf("friend dm write degraded: %v", e) }}
	friendReconcile := &frienddm.Reconciler{Store: frienddmstore.Store{}, Queryer: pool, Deliverer: friendDelivery, OnDeliveryError: func(e error) { log.Printf("friend dm reconcile delivery degraded: %v", e) }}
	generalDM := generaldm.Service{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: presenceRunner}, Queryer: pool, Store: generaldmstore.Store{}, Bindings: generaldmbindings.Reader{}, Privacy: socialrelation.GeneralDMPrivacyProvider{Store: socialrelationstore.Store{}}, Players: i4store.PlayerRootLocker{}, Presentation: socialpresentation.TransactionReader{}, Observer: socialpresentation.TransactionReader{}, Owner: presenceStore}
	generalDelivery := stockruntime.GeneralDMDelivery{Service: generalDM, Fence: realtimeOwnerFence, InstanceID: realtimeInstanceID, Operations: presenceOperations, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: socialEvents, Limits: limits.Default()}, Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}}
	generalReconcile := &generaldm.Reconciler{Store: generaldmstore.Store{}, Queryer: pool, Deliverer: generalDelivery, OnDeliveryError: func(e error) { log.Printf("general dm delivery degraded: %v", e) }}
	achievementEvents, err := stockruntime.NewAchievementNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	achievementRuntime := &achievement.Runtime{Timed: appgeneration.TimedRunner{Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: presenceRunner}, Fresh: pool, Active: contentstore.Store{Queryer: pool}}
	achievementNotices := stockruntime.AchievementNoticeHandler{Service: achievement.Service{Store: achievementstore.Store{}, Content: contentstore.Store{Queryer: pool}, Runtime: achievementRuntime}, Operations: presenceOperations, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: achievementEvents, Limits: limits.Default()}, Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, OnDeliveryError: func(e error) { log.Printf("achievement notice delivery degraded: %v", e) }}
	tournamentEvents, err := stockruntime.NewTournamentNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	tournamentNotices := stockruntime.TournamentNoticeHandler{Service: apparena.TournamentNoticeReader{Store: arenastore.Store{}, Queryer: pool, Time: postgres.AuthoritativeTime{Queryer: pool}}, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: tournamentEvents, Limits: limits.Default()}, Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, OnDeliveryError: func(err error) { log.Printf("tournament notice degraded: %v", err) }}
	friendEvents, err := stockruntime.NewFriendFightNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	friendFightDelivery := tournamentNotices
	friendFightDelivery.Publisher = stockruntime.RealtimePublisher{Registry: friendEvents, Limits: limits.Default()}
	friendNotices := stockruntime.FriendFightNoticeHandler{Service: apparena.FriendFightNoticeReader{Store: arenastore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Queryer: pool, Time: postgres.AuthoritativeTime{Queryer: pool}}, Delivery: friendFightDelivery}
	illusionEvents, err := stockruntime.NewIllusionRoomNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	illusionRooms := stockruntime.IllusionRoomNoticeHandler{Service: stockruntime.IllusionRoomNoticeReader{Store: sharedroomstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Queryer: pool},
		Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: illusionEvents, Limits: limits.Default()}, Authority: authority,
		Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, Delivered: stockruntime.NewRoomNoticeLedger(),
		OnDeliveryError: func(err error) { log.Printf("illusion room notice degraded: %v", err) }}
	occultEvents, err := stockruntime.NewOccultRoomNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	occultRooms := stockruntime.OccultRoomNoticeHandler{Service: appoccult.NoticeReader{Rooms: sharedroomstore.Store{}, Content: contentstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Presence: presenceStore,
		Scores: occultstore.Store{}, Tickets: appi5.Service{Store: i5store.Store{}}, Queryer: pool},
		Delivery: stockruntime.RoomDelivery{Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: occultEvents, Limits: limits.Default()}, Authority: authority,
			Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections, OnDeliveryError: func(err error) { log.Printf("occult room notice degraded: %v", err) }},
		Delivered: stockruntime.NewRoomNoticeLedger(),
		Online:    connectionsRegistry.HasWorldConnection}
	adventureEvents, err := stockruntime.NewAdventureNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	adventureNotices := stockruntime.AdventureNoticeHandler{Service: appadventure.NoticeReader{Store: adventurestore.Store{}, Queryer: pool, Time: postgres.AuthoritativeTime{Queryer: pool}},
		Operations: presenceOperations, Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: adventureEvents, Limits: limits.Default()},
		Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections,
		Delivered: stockruntime.NewAdventureNoticeLedger(), OnDeliveryError: func(err error) { log.Printf("adventure notice degraded: %v", err) }}
	adventureRoomEvents, err := stockruntime.NewAdventureRoomNoticeRegistry()
	if err != nil {
		log.Fatal(err)
	}
	adventureRooms := stockruntime.AdventureRoomNoticeHandler{Service: appadventure.Mode{Fresh: pool, RoomStore: sharedroomstore.Store{}, Directory: i4store.PlayerDirectoryReader{}},
		Delivery: stockruntime.RoomDelivery{Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: adventureRoomEvents, Limits: limits.Default()},
			Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections,
			OnDeliveryError: func(err error) { log.Printf("adventure room notice degraded: %v", err) }},
		Delivered: stockruntime.NewRoomNoticeLedger(), Pushes: stockruntime.NewAdventurePushLedger()}
	guildFightEvents, err := stockruntime.NewGuildFightEventRegistry()
	if err != nil {
		log.Fatal(err)
	}
	guildFightNotices := stockruntime.GuildFightNoticeHandler{Registered: guildcampaignstore.Store{}, Queryer: pool, Registry: connectionsRegistry,
		Publisher: stockruntime.RealtimePublisher{Registry: guildFightEvents, Limits: limits.Default()}, MaxHandles: runtimePolicy.MaxConnections}
	roomInviteNotices := stockruntime.RoomInviteNoticeListHandler{Delivery: stockruntime.RoomDelivery{Registry: connectionsRegistry, Publisher: stockruntime.RealtimePublisher{Registry: socialEvents, Limits: limits.Default()},
		Authority: authority, Time: postgres.AuthoritativeTime{Queryer: pool}, MaxHandles: runtimePolicy.MaxConnections,
		OnDeliveryError: func(err error) { log.Printf("room invite notice list degraded: %v", err) }}}
	wakeups, err := realtimewakeup.NewRegistry(realtimewakeup.Registration{Route: apparena.FriendFightNoticeRoute, Handler: friendNotices}, realtimewakeup.Registration{Route: apparena.TournamentNoticeRoute, Handler: tournamentNotices}, realtimewakeup.Registration{Route: postgres.SocialReloadRoute, Handler: socialHandler}, realtimewakeup.Registration{Route: frienddm.WakeupRoute, Handler: friendReconcile}, realtimewakeup.Registration{Route: generaldm.WakeupRoute, Handler: generalReconcile}, realtimewakeup.Registration{Route: achievement.NoticeRoute, Handler: achievementNotices}, realtimewakeup.Registration{Route: appillusion.RoomNoticeRoute, Handler: illusionRooms}, realtimewakeup.Registration{Route: appoccult.RoomNoticeRoute, Handler: occultRooms}, realtimewakeup.Registration{Route: appadventure.NoticeRoute, Handler: adventureNotices},
		realtimewakeup.Registration{Route: appadventure.RoomNoticeRoute, Handler: adventureRooms},
		realtimewakeup.Registration{Route: roominvite.NoticeListRoute, Handler: roomInviteNotices},
		realtimewakeup.Registration{Route: stockruntime.GuildCampaignNoticeRoute, Handler: guildFightNotices})
	if err != nil {
		log.Fatal(err)
	}
	listenerReady := make(chan struct{})
	var readyOnce sync.Once
	listenerDone := make(chan struct{})
	listenerFailure := make(chan error, 1)
	go func() {
		defer close(listenerDone)
		if err := (postgres.RealtimeWakeupListener{Pool: pool, Registry: wakeups, OnReady: func() { readyOnce.Do(func() { close(listenerReady) }) }}).Run(ctx); err != nil && ctx.Err() == nil {
			log.Printf("social listener fatal: %v", err)
			listenerFailure <- err
			stop()
		}
	}()
	// Routes and successful LISTEN precede initial canonical discovery and TCP
	// admission. Failure before admission still cancels and joins the listener.
	select {
	case <-listenerReady:
	case <-ctx.Done():
		<-listenerDone
		return ctx.Err()
	case <-time.After(2 * time.Second):
		stop()
		<-listenerDone
		return errors.New("realtime wakeup listener readiness timeout")
	}
	if err := generalReconcile.InitialReconcile(ctx); err != nil {
		stop()
		<-listenerDone
		return err
	}
	if err := friendReconcile.InitialReconcile(ctx); err != nil {
		stop()
		<-listenerDone
		return err
	}
	reconcileDone := make(chan struct{})
	reconcileFailure := make(chan error, 1)
	go func() {
		defer close(reconcileDone)
		if e := friendReconcile.Run(ctx); e != nil && ctx.Err() == nil {
			log.Printf("friend dm canonical reconcile fatal: %v", e)
			reconcileFailure <- e
			stop()
		}
	}()
	generalDone := make(chan struct{})
	generalFailure := make(chan error, 1)
	go func() {
		defer close(generalDone)
		if e := generalReconcile.Run(ctx); e != nil && ctx.Err() == nil {
			generalFailure <- e
			stop()
		}
	}()
	ln, err := net.Listen("tcp", cfg.RealtimeAddr)
	if err != nil {
		stop()
		<-listenerDone
		<-reconcileDone
		<-generalDone
		return err
	}
	defer ln.Close()
	go func() { <-ctx.Done(); _ = ln.Close() }()
	log.Printf("gxb-realtime I4 listening on %s", cfg.RealtimeAddr)
	listenerSlots := make(chan struct{}, runtimePolicy.MaxConnections)
	var connections sync.WaitGroup
	defer func() {
		stop()
		connectionsRegistry.CloseAll()
		connections.Wait()
		<-listenerDone
		<-reconcileDone
		<-generalDone
	}()
	for {
		conn, err := ln.Accept()
		if err != nil {
			if ctx.Err() != nil || errors.Is(err, net.ErrClosed) {
				select {
				case failure := <-listenerFailure:
					return failure
				case failure := <-reconcileFailure:
					return failure
				case failure := <-generalFailure:
					return failure
				default:
					return nil
				}
			}
			log.Printf("realtime accept: %v", err)
			continue
		}
		select {
		case listenerSlots <- struct{}{}:
		default:
			_ = conn.Close()
			continue
		}
		connections.Add(1)
		go func(c net.Conn) {
			stopSocket := context.AfterFunc(ctx, func() { _ = c.Close() })
			defer stopSocket()
			defer connections.Done()
			defer func() { <-listenerSlots }()
			defer c.Close()
			if err := server.ServeConn(ctx, c); err != nil && ctx.Err() == nil {
				log.Printf("realtime connection closed: %v", err)
			}
		}(conn)
	}
}
