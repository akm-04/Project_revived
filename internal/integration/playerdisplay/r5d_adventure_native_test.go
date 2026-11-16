//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	da "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R5D-04: the RESULT credits the one shared Combat attempt and records the
// credited damage in the mode's settlement row; a duplicate answers from that
// row instead of changing it.
func TestR5DAdventureDuplicateSettlementNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 100, 10001001, 10001002)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	formation := []int64{picks[0]}
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "r5d-sophia")

	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: formation}, opContext); err != nil {
		t.Fatal("start", err)
	}
	clock.Set(clock.at.Add(time.Minute))
	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: formation}, opContext); err != nil {
		t.Fatal("replayed start", err)
	}
	clock.Set(clock.at.Add(time.Minute))
	replaced := []int64{picks[1]}
	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: replaced}, opContext); err != nil {
		t.Fatal("replacing start", err)
	}
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND actor_player_id=$1 AND state='TERMINAL' AND terminal_kind IN ('SUPERSEDED','ADVENTURE_START_CLOSED')`, int64(a.PlayerID)); closed != 1 {
		t.Fatal("the replaced attempt was not closed", closed)
	}
	if open := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND actor_player_id=$1 AND state<>'TERMINAL'`, int64(a.PlayerID)); open != 1 {
		t.Fatal("replacement attempts", open)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_single_attempts_retired_r5d WHERE player_id=$1`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("START wrote a mode-local attempt row", rows)
	}
	clock.Set(clock.at.Add(time.Minute))
	settled, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: replaced}, opContext)
	if err != nil || settled.Duplicate {
		t.Fatalf("settle %+v %v", settled, err)
	}
	clock.Set(clock.at.Add(time.Minute))
	duplicate, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 900, Formation: replaced}, opContext)
	if err != nil || !duplicate.Duplicate {
		t.Fatalf("duplicate %+v %v", duplicate, err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_attempt_settlements WHERE player_id=$1 AND damage=500`, int64(a.PlayerID)); rows != 1 {
		t.Fatal("settlement rows", rows)
	}
}

// R5D-04: a RESULT credits the occurrence the attempt froze even after the
// player's next occurrence exists; it never reads the current one.
func TestR5DAdventureFrozenOccurrenceNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 100, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	formation := []int64{picks[0]}
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "frozen-a")
	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: formation}, opContext); err != nil {
		t.Fatal("start", err)
	}
	later := clock.at.Add(time.Hour)
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, later, later.Add(2*time.Hour), "frozen-b")

	if _, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: formation}, opContext); err != nil {
		t.Fatal("settle", err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND source_key='frozen-a' AND finished_at IS NOT NULL`, int64(a.PlayerID)); rows != 1 {
		t.Fatal("the frozen occurrence was not finished", rows)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND source_key='frozen-b' AND finished_at IS NOT NULL`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("the current occurrence was finished", rows)
	}
}

type cancellingAdventureSettlementStore struct {
	adventurestore.Store
	cancel context.CancelFunc
}

func (s cancellingAdventureSettlementStore) InsertSettlementTx(c context.Context, t tx.Tx, attemptID ids.UUID, playerID identity.PlayerID, damage int64, settledAt time.Time) error {
	s.cancel()
	return s.Store.InsertSettlementTx(c, t, attemptID, playerID, damage, settledAt)
}

// R5D-04: cancelling the RESULT at the settlement insert rolls back Combat's
// attestation and the credit, leaving the attempt unsettled.
func TestR5DAdventureCancelledResultNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 100, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	formation := []int64{picks[0]}
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "r5d-cancel")
	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: formation}, opContext); err != nil {
		t.Fatal("start", err)
	}

	runContext, cancel := context.WithCancel(ctx)
	mode.Store = cancellingAdventureSettlementStore{Store: adventurestore.Store{}, cancel: cancel}
	if _, err := mode.SettleSingle(runContext, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: formation}, opContext); err == nil {
		t.Fatal("cancelled RESULT committed")
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_attempt_settlements WHERE player_id=$1`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("cancelled RESULT left a settlement", rows)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND source_key='r5d-cancel' AND finished_at IS NOT NULL`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("cancelled RESULT finished the occurrence", rows)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND actor_player_id=$1 AND state='TERMINAL'`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("cancelled RESULT terminalised the attempt", rows)
	}

	mode.Store = adventurestore.Store{}
	settled, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: formation}, opContext)
	if err != nil || settled.Duplicate {
		t.Fatalf("settle after cancellation %+v %v", settled, err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_attempt_settlements WHERE player_id=$1 AND damage=500`, int64(a.PlayerID)); rows != 1 {
		t.Fatal("settlement rows after retry", rows)
	}
}

// R5D-04: a stale mode-local row, open or resolved, with no Combat attempt
// neither settles nor blocks the shared START.
func TestR5DAdventureStaleModeRowNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 100, 10001001)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	formation := []int64{picks[0]}
	putAdventureOccurrence(t, p, a.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "r5d-stale")
	for _, row := range []struct {
		attemptID string
		resolved  bool
		damage    int64
	}{{fmt.Sprintf("placeholder-%d", a.PlayerID), false, 0}, {fmt.Sprintf("stale-resolved-%d", a.PlayerID), true, 999}} {
		exec(t, p, `INSERT INTO adventure_single_attempts_retired_r5d(attempt_id,player_id,event_type,occurred_at,created_at,resolved,damage)
			VALUES($1,$2,$3,$4,$4,$5,$6)`, row.attemptID, int64(a.PlayerID), da.EventIllusion, clock.at.UTC(), row.resolved, row.damage)
	}

	if _, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: formation}, opContext); !errors.Is(err, da.ErrRefused) {
		t.Fatalf("a stale mode row settled: %v", err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_attempt_settlements WHERE player_id=$1`, int64(a.PlayerID)); rows != 0 {
		t.Fatal("a stale mode row produced a settlement", rows)
	}
	if _, err := mode.StartSingle(ctx, a, appadventure.FightRequest{Formation: formation}, opContext); err != nil {
		t.Fatalf("a stale mode row blocked START: %v", err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1`, fmt.Sprintf("player:%d", int64(a.PlayerID))); rows != 1 {
		t.Fatal("the stable locator attempt", rows)
	}
	if _, err := mode.SettleSingle(ctx, a, appadventure.ResultRequest{Star: 0, Damage: 500, Formation: formation}, opContext); err != nil {
		t.Fatal("settle after START", err)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_single_attempts_retired_r5d WHERE player_id=$1`, int64(a.PlayerID)); rows != 2 {
		t.Fatal("the stale rows were read or written", rows)
	}
}
