//go:build postgres

package playerdisplay_test

import (
	"context"
	"math"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/statinputs"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// realStatIllusionService is the production mode composition (canonicalIllusion)
// with the real public-stats owner instead of the force-floor fake.
func realStatIllusionService(t *testing.T, p *pg.Pool, clock gen.TimeAuthority, privileges i5.PrivilegeSnapshotProvider, guilds il.Guilds) il.Mode {
	t.Helper()
	mode := illusionService(t, p, clock, privileges, guilds)
	mode.Stats = combatService(t, p).Inputs.Stats
	return mode
}

func illusionRoomDispatch(t *testing.T, mode il.Mode, actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.IllusionRoomDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: mode}
	request := unpinnedRequest(mid, actor, time.Now().UTC(), params)
	return dispatcher.Dispatch(context.Background(), request)
}

// independentIllusionBest15 recomputes the room's force outside the command.
func independentIllusionBest15(t *testing.T, p *pg.Pool, mode il.Mode, player identity.PlayerID, at time.Time) int64 {
	t.Helper()
	revision := installed(t, p)
	opContext := opPinned(revision)
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: transaction, Operation: opContext, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	detail := map[string]any{}
	if err = mode.Heroes.OverlayMID1(ctx, transaction, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		t.Fatal(err)
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	total := int64(0)
	for key := range rows {
		partnerID, err := strconv.ParseInt(key, 10, 64)
		if err != nil {
			t.Fatal(err)
		}
		result, err := mode.Stats.HeroTx(ctx, scope, character.HeroRef{PlayerID: player, PartnerID: partnerID}, publicstats.View{Kind: publicstats.Self, Viewer: player})
		if err != nil {
			t.Fatal(err)
		}
		total += int64(math.Round(result.Stats.Force))
	}
	return total
}

func roomSeats(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	var count int64
	if err := p.QueryRow(ctx, `SELECT COUNT(*) FROM shared_room_seats WHERE player_id=$1 AND family='illusion' AND slot=1`, int64(player)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

// TestI9_10Retest10IllusionRoomFlow drives 1349/1352/1350/1360 through the real
// dispatcher with the HTTP edge's unpinned operation: create carries the best-15
// force, a second player joins by room id and both see each other, and the
// friend invite lands in the recipient's polled notice list.
func TestI9_10Retest10IllusionRoomFlow(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	mode := realStatIllusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002, 10001003)
	mate, _ := illusionTeamOwner(t, p, server, 10001004)
	guildFixture(t, p, owner, mate)

	created := illusionRoomDispatch(t, mode, owner, 1349, map[string]any{})
	if created.HTTPStatus != 200 {
		t.Fatalf("1349 status %d body %#v cause %v", created.HTTPStatus, created.Body, created.Cause)
	}
	roomID, _ := created.Body["room_id"].(int64)
	if roomID <= 0 {
		t.Fatalf("room id %#v", created.Body)
	}
	if created.Body["master_id"] != int64(owner.PlayerID) {
		t.Fatalf("owner not seated %#v", created.Body)
	}
	masterInfo, _ := created.Body["master_id_info"].(map[string]any)
	ownerForce := independentIllusionBest15(t, p, mode, owner.PlayerID, clock.at)
	if ownerForce <= 0 || masterInfo["force"] != ownerForce {
		t.Fatalf("master force %v, independent %d", masterInfo["force"], ownerForce)
	}

	entered := illusionRoomDispatch(t, mode, mate, 1352, map[string]any{"room_id": roomID})
	if entered.HTTPStatus != 200 {
		t.Fatalf("1352 status %d body %#v cause %v", entered.HTTPStatus, entered.Body, entered.Cause)
	}
	if entered.Body["master_id"] != int64(owner.PlayerID) || entered.Body["mate_1"] != int64(mate.PlayerID) {
		t.Fatalf("seats %#v", entered.Body)
	}
	enteredMaster, _ := entered.Body["master_id_info"].(map[string]any)
	enteredMate, _ := entered.Body["mate_1_info"].(map[string]any)
	mateForce := independentIllusionBest15(t, p, mode, mate.PlayerID, clock.at)
	if enteredMaster["force"] != ownerForce || enteredMate["force"] != mateForce || mateForce <= 0 {
		t.Fatalf("forces master=%v want %d mate=%v want %d", enteredMaster["force"], ownerForce, enteredMate["force"], mateForce)
	}

	ownerView := illusionRoomDispatch(t, mode, owner, 1350, map[string]any{})
	if ownerView.HTTPStatus != 200 || ownerView.Body["master_id"] != int64(owner.PlayerID) || ownerView.Body["mate_1"] != int64(mate.PlayerID) {
		t.Fatalf("1350 after join %d %#v", ownerView.HTTPStatus, ownerView.Body)
	}

	invited := illusionRoomDispatch(t, mode, owner, 1360, map[string]any{"p_id": int64(mate.PlayerID)})
	if invited.HTTPStatus != 200 {
		t.Fatalf("1360 status %d body %#v cause %v", invited.HTTPStatus, invited.Body, invited.Cause)
	}
	row, found := noticeOfType(socialNoticePage(t, p, mate), socialinbox.RoomInviteIllusionNoticeType)
	if !found || row.RoomID == nil || *row.RoomID != roomID || row.Player.PlayerID != int64(owner.PlayerID) {
		t.Fatalf("invite notice %+v found=%v", row, found)
	}
}

type failingFirstStats struct {
	inner  il.Stats
	failed bool
}

func (s *failingFirstStats) HeroTx(c context.Context, scope ca.CoherentReadScope, ref character.HeroRef, view publicstats.View) (publicstats.Result, error) {
	if !s.failed {
		s.failed = true
		return publicstats.Result{}, statinputs.ErrUnqualified
	}
	return s.inner.HeroTx(c, scope, ref, view)
}

// TestI9_10Retest10IllusionFailedCreateLeavesNoRoom forces the create payload
// step to fail and proves the open transaction rolled back, so the retry works.
func TestI9_10Retest10IllusionFailedCreateLeavesNoRoom(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	mode := realStatIllusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002)
	mode.Stats = &failingFirstStats{inner: mode.Stats}

	failed := illusionRoomDispatch(t, mode, owner, 1349, map[string]any{})
	if failed.HTTPStatus != 503 {
		t.Fatalf("forced create status %d body %#v cause %v", failed.HTTPStatus, failed.Body, failed.Cause)
	}
	if seats := roomSeats(t, p, owner.PlayerID); seats != 0 {
		t.Fatalf("failed create left %d seats", seats)
	}

	retried := illusionRoomDispatch(t, mode, owner, 1349, map[string]any{})
	if retried.HTTPStatus != 200 {
		t.Fatalf("retry status %d body %#v cause %v", retried.HTTPStatus, retried.Body, retried.Cause)
	}
	if seats := roomSeats(t, p, owner.PlayerID); seats != 1 {
		t.Fatalf("retry seated %d", seats)
	}
	masterInfo, _ := retried.Body["master_id_info"].(map[string]any)
	if masterInfo["force"] != independentIllusionBest15(t, p, mode, owner.PlayerID, clock.at) {
		t.Fatalf("retry force %v", masterInfo["force"])
	}
}
