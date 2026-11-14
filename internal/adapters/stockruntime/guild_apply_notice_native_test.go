//go:build postgres

package stockruntime

import (
	"context"
	"fmt"
	"net"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type noticePipe struct {
	frames chan rt.Frame
	errors chan error
}

func startNoticePipe(client net.Conn) *noticePipe {
	out := &noticePipe{frames: make(chan rt.Frame, 8), errors: make(chan error, 1)}
	go func() {
		decoder, err := rt.NewStreamDecoder(limits.Default())
		if err != nil {
			out.errors <- err
			return
		}
		buffer := make([]byte, 4096)
		for {
			count, err := client.Read(buffer)
			if err != nil {
				out.errors <- err
				return
			}
			values, err := decoder.Feed(buffer[:count])
			if err != nil {
				out.errors <- err
				return
			}
			for _, value := range values {
				out.frames <- value
			}
		}
	}()
	return out
}

func (p *noticePipe) expectApplyNotice(t *testing.T, what string) {
	t.Helper()
	select {
	case frame := <-p.frames:
		if frame.MID != mids.MIDPlayerNotice {
			t.Fatalf("%s: MID=%d", what, frame.MID)
		}
		if reason := decodedApplyNotice(frame.Params); reason != "" {
			t.Fatalf("%s: frame=%+v reason=%s", what, frame.Params, reason)
		}
	case err := <-p.errors:
		t.Fatalf("%s: read error: %v", what, err)
	case <-time.After(3 * time.Second):
		t.Fatalf("%s: no notice delivered", what)
	}
}

// decodedApplyNotice checks the client-side decoded frame. The AMF3 encoder
// writes numbers as doubles, so the decoded notice type is a float64.
func decodedNumber(value any) (int64, bool) {
	switch number := value.(type) {
	case float64:
		return int64(number), number == float64(int64(number))
	case int32:
		return int64(number), true
	case int64:
		return number, true
	default:
		return 0, false
	}
}

func decodedApplyNotice(value any) string {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return fmt.Sprintf("object=%T", value)
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return fmt.Sprintf("fields=%v err=%v", fields, err)
	}
	noticeType, ok := decodedNumber(fields["notice_type"])
	params, paramsOk := fields["params"].(*amf3.Object)
	if !ok || noticeType != GuildApplyNoticeType || !paramsOk || params == nil {
		return fmt.Sprintf("notice_type=%T(%v) params=%T", fields["notice_type"], fields["notice_type"], fields["params"])
	}
	body, err := params.StrictMap()
	if err != nil || len(body) != 0 {
		return fmt.Sprintf("body=%v err=%v", body, err)
	}
	return ""
}

func (p *noticePipe) silent(t *testing.T, what string) {
	t.Helper()
	select {
	case frame := <-p.frames:
		t.Fatalf("%s: unexpected notice %+v", what, frame)
	case err := <-p.errors:
		t.Fatalf("%s: read error: %v", what, err)
	case <-time.After(300 * time.Millisecond):
	}
}

func applyNoticeOps(t *testing.T, refs policy.Set) operation.Context {
	t.Helper()
	op, err := (operation.Factory{Clock: clock.System{}}).New(refs)
	if err != nil {
		t.Fatal(err)
	}
	return op
}

const applyNoticeServer identity.LogicalServerID = 4

func seedApplyNoticePlayers(t *testing.T, c context.Context, p *postgres.Pool) []identity.ActorContext {
	t.Helper()
	fixture, err := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer fixture.Rollback(c)
	var first int64
	// A-035: raw players have no I5 display basis, so their guild must stay off
	// server 1, whose MID 576 list other packages read on the same database.
	if err = fixture.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+6,state_version=state_version+1 WHERE logical_server_id=$1 AND next_player_id+6<=max_player_id RETURNING next_player_id-6`, int64(applyNoticeServer)).Scan(&first); err != nil {
		t.Fatal(err)
	}
	at := time.Now().UTC().Add(-time.Second)
	actors := make([]identity.ActorContext, 6)
	for i := range actors {
		player := identity.PlayerID(first + int64(i))
		accountID, _ := ids.NewUUID()
		sessionID, _ := ids.NewUUID()
		contextID, _ := ids.NewUUID()
		for _, statement := range []struct {
			sql  string
			args []any
		}{
			{`INSERT INTO accounts(account_id,status,created_at,account_uid)VALUES($1::uuid,'ACTIVE',$2,$3)`, []any{accountID.String(), at, accountID.String()}},
			{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2::uuid,$3,$4,'guild-apply-notice-fixture')`, []any{int64(player), accountID.String(), int64(applyNoticeServer), at}},
			{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,80,0,1,$2)`, []any{int64(player), at}},
			{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,$2)`, []any{int64(player), at}},
			{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',10000,1,$2)`, []any{int64(player), at}},
			{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1::uuid,$2::uuid,'guild-apply-notice-fixture',$3,$3)`, []any{sessionID.String(), accountID.String(), at}},
			{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,1,$6)`, []any{contextID.String(), sessionID.String(), accountID.String(), int64(applyNoticeServer), int64(player), at}},
		} {
			if _, err = fixture.Exec(c, statement.sql, statement.args...); err != nil {
				t.Fatal(err)
			}
		}
		account, _ := identity.AccountIDFrom(accountID)
		session, _ := identity.SessionIDFrom(sessionID)
		context, _ := identity.ContextIDFrom(contextID)
		actors[i] = identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID(accountID.String()), SessionID: session, ContextID: context, LogicalServerID: applyNoticeServer, PlayerID: player, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	}
	if err = fixture.Commit(c); err != nil {
		t.Fatal(err)
	}
	return actors
}

func applyNoticeGuildService(t *testing.T, p *postgres.Pool) guildcore.Service {
	t.Helper()
	artifact, err := guildpolicy.LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	binding, err := guildpolicybridge.FromBuiltin(artifact)
	if err != nil {
		t.Fatal(err)
	}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	return guildcore.Service{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Store:       guildstore.Store{Queryer: p},
		Fencer:      i5store.Store{},
		PlayerRoots: i4store.PlayerRootLocker{},
		Level:       i5, Scalar: i5, LevelAndScalar: i5,
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p},
		Policy: binding, Notices: postgres.GuildApplyNoticeEmitter{},
	}
}

func TestGuildApplyNoticeReachesOnlyOnlineOfficers(t *testing.T) {
	dsn := os.Getenv("GXB_GUILD_NOTICE_DSN")
	if dsn == "" {
		t.Skip("GXB_GUILD_NOTICE_DSN with a migrated disposable database is required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	pool, err := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	actors := seedApplyNoticePlayers(t, c, pool)
	leader, deputy, member, firstApplicant, secondApplicant, directJoiner := actors[0], actors[1], actors[2], actors[3], actors[4], actors[5]
	core := applyNoticeGuildService(t, pool)
	refs := policy.Set{}

	icon := core.Policy.Policy.GuildIcons[0]
	created, err := core.Create(c, leader, guildcore.CreateRequest{Name: fmt.Sprintf("J%d", leader.PlayerID), Icon: icon}, applyNoticeOps(t, refs))
	if err != nil {
		t.Fatal(err)
	}
	gid := guild.ID(created.GuildID)

	// Membership setup runs before the listener starts, so its notices vanish.
	if _, err = core.ApplyOrJoin(c, deputy, gid, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err = core.AcceptApplication(c, leader, deputy.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err = core.SetRole(c, leader, guildcore.RoleRequest{MemberID: deputy.PlayerID, Role: guild.Deputy}, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err = core.ApplyOrJoin(c, member, gid, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if _, err = core.AcceptApplication(c, leader, member.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}

	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	pipes := map[identity.PlayerID]*noticePipe{}
	for index, actor := range actors {
		writer, _, client := newRegistryPipeWriter(t)
		defer client.Close()
		if _, err = registry.Replace(registryAdmission(t, fmt.Sprintf("44444444-4444-4444-8444-%012d", index+1), actor.PlayerID, domainrt.World, 1), writer); err != nil {
			t.Fatal(err)
		}
		pipes[actor.PlayerID] = startNoticePipe(client)
	}

	events, err := NewGuildApplyNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := GuildApplyNoticeHandler{Members: guildstore.Store{Queryer: pool},
		Delivery: RoomDelivery{Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()},
			Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10}}
	wakeups, err := realtimewakeup.NewRegistry(realtimewakeup.Registration{Route: guildcore.ApplyNoticeRoute, Handler: handler})
	if err != nil {
		t.Fatal(err)
	}
	listenerContext, stopListener := context.WithCancel(c)
	defer stopListener()
	ready := make(chan struct{})
	listenerDone := make(chan error, 1)
	go func() {
		listenerDone <- (postgres.RealtimeWakeupListener{Pool: pool, Registry: wakeups, OnReady: func() { close(ready) }}).Run(listenerContext)
	}()
	select {
	case <-ready:
	case <-time.After(10 * time.Second):
		t.Fatal("realtime wakeup listener did not become ready")
	}
	defer func() {
		stopListener()
		<-listenerDone
	}()

	// An application files notice 7 for the online leader and deputy only.
	if result, err := core.ApplyOrJoin(c, firstApplicant, gid, applyNoticeOps(t, refs)); err != nil || !result.Applied {
		t.Fatalf("apply result=%+v err=%v", result, err)
	}
	pipes[leader.PlayerID].expectApplyNotice(t, "apply leader")
	pipes[deputy.PlayerID].expectApplyNotice(t, "apply deputy")
	pipes[member.PlayerID].silent(t, "apply plain member")
	pipes[firstApplicant.PlayerID].silent(t, "apply applicant")

	// A replayed receipt must not file a second notice.
	replayedApply, err := core.ApplyOrJoin(c, firstApplicant, gid, applyNoticeOps(t, refs))
	if err != nil || !replayedApply.Replayed {
		t.Fatalf("replayed apply result=%+v err=%v", replayedApply, err)
	}
	pipes[leader.PlayerID].silent(t, "replayed apply leader")
	pipes[deputy.PlayerID].silent(t, "replayed apply deputy")

	// The accepting officer's own windows reload; a replay does not notify again.
	if _, err = core.AcceptApplication(c, leader, firstApplicant.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	pipes[leader.PlayerID].expectApplyNotice(t, "accept leader")
	if replayedAccept, err := core.AcceptApplication(c, leader, firstApplicant.PlayerID, applyNoticeOps(t, refs)); err != nil || !replayedAccept.Replayed {
		t.Fatalf("replayed accept result=%+v err=%v", replayedAccept, err)
	}
	pipes[leader.PlayerID].silent(t, "replayed accept leader")

	// The refusing officer is notified; a replay is silent.
	if _, err = core.ApplyOrJoin(c, secondApplicant, gid, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	pipes[leader.PlayerID].expectApplyNotice(t, "second apply leader")
	pipes[deputy.PlayerID].expectApplyNotice(t, "second apply deputy")
	if replayedSecondApply, err := core.ApplyOrJoin(c, secondApplicant, gid, applyNoticeOps(t, refs)); err != nil || !replayedSecondApply.Replayed {
		t.Fatalf("replayed second apply result=%+v err=%v", replayedSecondApply, err)
	}
	pipes[leader.PlayerID].silent(t, "replayed second apply leader")
	pipes[deputy.PlayerID].silent(t, "replayed second apply deputy")

	if _, err = core.RefuseApplication(c, deputy, secondApplicant.PlayerID, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	pipes[deputy.PlayerID].expectApplyNotice(t, "refuse deputy")
	if replayedRefuse, err := core.RefuseApplication(c, deputy, secondApplicant.PlayerID, applyNoticeOps(t, refs)); err != nil || !replayedRefuse.Replayed {
		t.Fatalf("replayed refuse result=%+v err=%v", replayedRefuse, err)
	}
	pipes[deputy.PlayerID].silent(t, "replayed refuse deputy")

	// A direct join is not an application, so nobody receives notice 7.
	if _, err = core.UpdateSettings(c, leader, guildcore.SettingsRequest{Name: fmt.Sprintf("J%d", leader.PlayerID), Icon: icon, MinAllowLevel: core.Policy.Policy.JoinLevelMin, ApplyType: guild.ApplyImmediate}, applyNoticeOps(t, refs)); err != nil {
		t.Fatal(err)
	}
	if joined, err := core.ApplyOrJoin(c, directJoiner, gid, applyNoticeOps(t, refs)); err != nil || !joined.Joined {
		t.Fatalf("direct join result=%+v err=%v", joined, err)
	}
	pipes[leader.PlayerID].silent(t, "direct join leader")
	pipes[deputy.PlayerID].silent(t, "direct join deputy")
	pipes[directJoiner.PlayerID].silent(t, "direct join joiner")

	pipes[member.PlayerID].silent(t, "final plain member")
}
