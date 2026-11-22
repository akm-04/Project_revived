//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/changes"
)

// TestI9_12VoyageMissionAdvancesOnVoyageTrialNative proves mission 10030 (task_req
// 125, "Finish any mission in Voyage 3 times") moves once per Voyage trial win,
// from both the battle settlement and the trial sweep, through the production
// objective fact port and the materializer the production composition uses.
func TestI9_12VoyageMissionAdvancesOnVoyageTrialNative(t *testing.T) {
	p := pool(t)
	s := campaignMode(t, p)
	at := prophecyDay(time.Now())
	s.Timed.Binder.Time = trialSweepClock{at: at}
	s.Facts = i5.ObjectiveFacts{Owner: missionOwner(p), Open: i5store.Store{Queryer: p}}

	a, revision := trialSweepActor(t, p, s, at)
	if got := missionProgress(t, p, a.PlayerID, 10030); got != 1 {
		t.Fatalf("Voyage mission after one trial clear = %d, want 1", got)
	}
	lines := []grant.Line{{Kind: grant.StackItem, ItemID: 50001013, Amount: 5}}
	if _, err := compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_12_MISSION_DAILY", lines, opPinned(revision)); err != nil {
		t.Fatal(err)
	}
	tracked, _ := changes.Track(ctx)
	if _, err := s.Sweep(tracked, a, app.Sweep{CampaignID: 16001, Type: 16, Count: 1, Kind: 1}, op()); err != nil {
		t.Fatal("trial sweep", err)
	}
	if got := missionProgress(t, p, a.PlayerID, 10030); got != 2 {
		t.Fatalf("Voyage mission after a swept Voyage trial = %d, want 2", got)
	}
}
