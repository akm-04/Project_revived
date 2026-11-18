//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	appadventure "gxb.local/backend/v2/internal/application/adventure"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
)

// resolutionBarrier holds the resolver open after START commits, so a native
// can leave and re-seat the room exactly between START and RESULT.
type resolutionBarrier struct {
	inner   cb.Worker
	entered chan struct{}
	release chan struct{}
}

func (b *resolutionBarrier) Resolve(c context.Context, snapshot []byte, snapshotHash string, root [32]byte) (cb.WorkerOutput, error) {
	select {
	case b.entered <- struct{}{}:
	default:
	}
	<-b.release
	return b.inner.Resolve(c, snapshot, snapshotHash, root)
}

// TestA133AdventureCoopResultSettlesFrozenRosterNative proves RESULT settles,
// mails and reports every member frozen at START after one member leaves and a
// replacement joins while the attempt resolves.
func TestA133AdventureCoopResultSettlesFrozenRosterNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := adventureOwner(t, p, server, 100, 10001001, 10001002)
	b, bPicks := adventureOwner(t, p, server, 100, 10001003, 10001004)
	c, cPicks := adventureOwner(t, p, server, 100, 10001005, 10001006)
	replacement, _ := adventureOwner(t, p, server, 100, 10001007, 10001008)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	fight := combatService(t, p)
	barrier := &resolutionBarrier{inner: fight.Worker, entered: make(chan struct{}, 1), release: make(chan struct{})}
	fight.Worker = barrier
	mode := adventureTestModeWithFight(t, p, clock, adventureOpponents{}, fight)
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at

	for _, player := range []identity.PlayerID{a.PlayerID, b.PlayerID, c.PlayerID, replacement.PlayerID} {
		putAdventureOccurrence(t, p, player, d.EventIllusion, d.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), fmt.Sprintf("a133-coop-%d", player))
	}
	created, err := mode.CreateCoop(ctx, a, opContext)
	if err != nil {
		t.Fatal("create coop", err)
	}
	coopID := adventureRoomIDFrom(created)
	if _, err = mode.EnterCoop(ctx, b, coopID, opContext); err != nil {
		t.Fatal("b join", err)
	}
	if _, err = mode.EnterCoop(ctx, c, coopID, opContext); err != nil {
		t.Fatal("c join", err)
	}
	if _, err = mode.EnterTeamFight(ctx, a, opContext); err != nil {
		t.Fatal("enter team fight", err)
	}
	selectTeam := func(actor identity.ActorContext, picks []int64) {
		for position, hero := range picks {
			if _, err := mode.SelectCoop(ctx, actor, appadventure.PickRequest{PartnerID: hero, Position: int64(position + 1)}, opContext); err != nil {
				t.Fatal("select", err)
			}
		}
		if _, err := mode.PrepareCoop(ctx, actor, opContext); err != nil {
			t.Fatal("prepare", err)
		}
	}
	selectTeam(a, aPicks)
	selectTeam(b, bPicks)
	selectTeam(c, cPicks)

	done := make(chan error, 1)
	go func() {
		_, startErr := mode.StartCoop(ctx, a, opContext)
		done <- startErr
	}()
	select {
	case <-barrier.entered:
	case <-time.After(60 * time.Second):
		close(barrier.release)
		t.Fatal("the resolver never started")
	}
	if _, err = mode.ExitCoop(ctx, b, opContext); err != nil {
		close(barrier.release)
		t.Fatal("b leave", err)
	}
	if _, err = mode.EnterCoop(ctx, replacement, coopID, opContext); err != nil {
		close(barrier.release)
		t.Fatal("replacement join", err)
	}
	close(barrier.release)
	if err = <-done; err != nil {
		t.Fatalf("RESULT: %v", err)
	}

	var raw string
	if err = p.QueryRow(ctx, `SELECT payload::text FROM shared_rooms WHERE room_id=$1`, coopID).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	state, err := d.LoadRoomState([]byte(raw))
	if err != nil || state.ReportID == "" {
		t.Fatalf("coop state %+v %v", state, err)
	}
	for _, frozen := range []identity.PlayerID{a.PlayerID, b.PlayerID, c.PlayerID} {
		if got := scalar(t, p, `SELECT count(*) FROM combat_member_settlements WHERE attempt_id=$1 AND member_player_id=$2`, state.ReportID, int64(frozen)); got != 1 {
			t.Fatalf("frozen member %d settlements=%d, want 1", frozen, got)
		}
		if got := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ADVENTURE_ILLUSION' AND source_key=$1 AND recipient_player_id=$2`, state.ReportID, int64(frozen)); got != 1 {
			t.Fatalf("frozen member %d mails=%d, want 1", frozen, got)
		}
	}
	if got := scalar(t, p, `SELECT count(*) FROM combat_member_settlements WHERE attempt_id=$1 AND member_player_id=$2`, state.ReportID, int64(replacement.PlayerID)); got != 0 {
		t.Fatalf("replacement settlements=%d, want 0", got)
	}
	if got := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ADVENTURE_ILLUSION' AND source_key=$1 AND recipient_player_id=$2`, state.ReportID, int64(replacement.PlayerID)); got != 0 {
		t.Fatalf("replacement mails=%d, want 0", got)
	}
	if got := scalar(t, p, `SELECT count(*) FROM adventure_reports WHERE report_id=$1 AND array_length(member_ids,1)=3 AND member_ids @> ARRAY[$2,$3,$4]::bigint[]`, state.ReportID, int64(a.PlayerID), int64(b.PlayerID), int64(c.PlayerID)); got != 1 {
		t.Fatalf("report member rows=%d, want the frozen roster", got)
	}
	if _, err = mode.GetReport(ctx, b, state.ReportID, opContext); err != nil {
		t.Fatalf("the departed member read the report: %v", err)
	}
	if _, err = mode.GetReport(ctx, replacement, state.ReportID, opContext); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("the replacement read the report: %v", err)
	}
	if got := scalar(t, p, `SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND stage='SEATED'`, coopID); got != 3 {
		t.Fatalf("live seats=%d, want 3", got)
	}
	for _, live := range []identity.PlayerID{a.PlayerID, c.PlayerID, replacement.PlayerID} {
		if got := scalar(t, p, `SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=$2 AND stage='SEATED'`, coopID, int64(live)); got != 1 {
			t.Fatalf("live member %d seats=%d, want 1", live, got)
		}
	}
	if got := scalar(t, p, `SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=$2 AND stage='LEFT'`, coopID, int64(b.PlayerID)); got != 1 {
		t.Fatalf("the departed member is not marked LEFT: %d", got)
	}
}
