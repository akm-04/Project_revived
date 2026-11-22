//go:build postgres

package stockruntime

import (
	"context"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// A-205 S30: an awarded mission row wakes the notice-20 projection, which
// pushes the AWARDED row and the hero's raised favor to the owner's live
// session.
func TestI9_12S30MissionNoticePushesAwarded(t *testing.T) {
	dsn := os.Getenv("GXB_I7B6A_DSN")
	if dsn == "" {
		t.Skip("GXB_I7B6A_DSN with a migrated disposable database is required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	pool, err := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	actor := seedPartnerLogPlayers(t, c, pool, 1)[0]
	partner := seedPartnerLogHero(t, c, pool, actor.PlayerID)
	setMissionNoticeFavor(t, c, pool, actor.PlayerID, partner, 118)

	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	actorPipe := dialPartnerLogSession(t, registry, actor, 1)

	events, err := NewLibraryMissionNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := LibraryMissionNoticeHandler{
		Service:    applibrary.MissionNoticeReader{Queryer: pool, Library: librarystore.Store{}},
		Registry:   registry,
		Publisher:  RealtimePublisher{Registry: events, Limits: limits.Default()},
		Authority:  deliveryAuthority{},
		Time:       postgres.AuthoritativeTime{Queryer: pool},
		MaxHandles: 10,
	}
	wakeups, err := realtimewakeup.NewRegistry(realtimewakeup.Registration{Route: applibrary.MissionNoticeRoute, Handler: handler})
	if err != nil {
		t.Fatal(err)
	}
	listenContext, stop := context.WithCancel(c)
	defer stop()
	ready := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		done <- (postgres.RealtimeWakeupListener{Pool: pool, Registry: wakeups, OnReady: func() { close(ready) }}).Run(listenContext)
	}()
	select {
	case <-ready:
	case <-time.After(10 * time.Second):
		t.Fatal("realtime wakeup listener did not become ready")
	}
	defer func() {
		stop()
		<-done
	}()

	insertAwardedMission(t, c, pool, actor.PlayerID, partner, 1002)
	actorPipe.expectMissionNotice(t, partner, 1002, 118)
}

func setMissionNoticeFavor(t *testing.T, c context.Context, pool *postgres.Pool, player identity.PlayerID, partner, favor int64) {
	t.Helper()
	transaction, err := pool.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(c)
	facts, err := (librarystore.Store{}).LockHeroTx(c, transaction, character.HeroRef{PlayerID: player, PartnerID: partner})
	if err != nil {
		t.Fatal(err)
	}
	old := facts.StateVersion
	facts.Favor = favor
	facts.StateVersion++
	facts.UpdatedAt = time.Now().UTC()
	if err = (librarystore.Store{}).SaveHeroTx(c, transaction, facts, old); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(c); err != nil {
		t.Fatal(err)
	}
}

func insertAwardedMission(t *testing.T, c context.Context, pool *postgres.Pool, player identity.PlayerID, partner, missionID int64) {
	t.Helper()
	transaction, err := pool.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(c)
	row := library.MissionFact{PlayerID: player, PartnerID: partner, MissionID: missionID, Process: 1, MissionState: library.MissionAwarded, UpdatedAt: time.Now().UTC()}
	if err = (librarystore.Store{}).SaveMissionTx(c, transaction, row); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(c); err != nil {
		t.Fatal(err)
	}
}

func (p *noticePipe) expectMissionNotice(t *testing.T, partner, missionID, favor int64) {
	t.Helper()
	select {
	case frame := <-p.frames:
		if frame.MID != mids.MIDPlayerNotice {
			t.Fatalf("notice MID %d", frame.MID)
		}
		if reason := decodedMissionNotice(frame.Params, partner, missionID, favor); reason != "" {
			t.Fatalf("notice 20 %s: %+v", reason, frame.Params)
		}
	case err := <-p.errors:
		t.Fatalf("notice read %v", err)
	case <-time.After(3 * time.Second):
		t.Fatal("no partner mission notice delivered")
	}
}

func decodedMissionNotice(value any, partner, missionID, favor int64) string {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return "payload is not an AMF3 object"
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return "notice envelope"
	}
	noticeType, ok := decodedNumber(fields["notice_type"])
	params, paramsOK := fields["params"].(*amf3.Object)
	if !ok || noticeType != LibraryMissionNoticeType || !paramsOK || params == nil {
		return "notice type or params"
	}
	body, err := params.StrictMap()
	if err != nil || len(body) != 3 {
		return "params shape"
	}
	gotPartner, ok := decodedNumber(body["partner_id"])
	if !ok || gotPartner != partner {
		return "partner id"
	}
	gotFavor, ok := decodedNumber(body["favor"])
	if !ok || gotFavor != favor {
		return "favor"
	}
	info, ok := body["mission_info"].(*amf3.Object)
	if !ok || info == nil {
		return "mission_info shape"
	}
	mission, err := info.StrictMap()
	if err != nil || len(mission) != 3 {
		return "mission_info map"
	}
	gotMission, ok := decodedNumber(mission["mission_id"])
	if !ok || gotMission != missionID {
		return "mission id"
	}
	gotState, ok := decodedNumber(mission["mission_state"])
	if !ok || gotState != library.MissionAwarded {
		return "mission state"
	}
	if _, ok := decodedNumber(mission["process"]); !ok {
		return "mission process"
	}
	return ""
}
