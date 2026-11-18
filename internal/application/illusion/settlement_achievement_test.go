package illusion

import (
	"context"
	"strings"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type settleStore struct {
	Store
	ranks []d.Result
}

func (s settleStore) ReadRankTx(context.Context, tx.Queryer, int64, int64, int64) ([]d.Result, error) {
	return s.ranks, nil
}

type settleGuilds struct{ Guilds }

func (settleGuilds) GuildSummaries(context.Context, identity.LogicalServerID) ([]GuildSummary, error) {
	return nil, nil
}

type fantasyCall struct {
	player        identity.PlayerID
	campaign, day int64
	rank, hurt    int64
	revision      string
}

type settleAchievements struct{ calls []fantasyCall }

func (s *settleAchievements) ObserveFantasyTx(_ context.Context, _ tx.Tx, revision string, player identity.PlayerID, campaign, day, rank, hurt int64, _ time.Time) error {
	s.calls = append(s.calls, fantasyCall{player: player, campaign: campaign, day: day, rank: rank, hurt: hurt, revision: revision})
	return nil
}

func TestSettleAttachesTheFrozenBoardPositionAndHurt(t *testing.T) {
	ranks := []d.Result{
		{PlayerID: 11, Hurt: 900, CostTime: 3, Killed: true},
		{PlayerID: 12, Hurt: 5000000, CostTime: 4},
		{PlayerID: 21, Hurt: 4999999, CostTime: 5},
	}
	achievements := &settleAchievements{}
	mode := Mode{Store: settleStore{ranks: ranks}, Guilds: settleGuilds{}, Achievements: achievements}
	at := time.Unix(1700000000, 0).UTC()
	refs, err := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)})
	if err != nil {
		t.Fatal(err)
	}
	op, err := (operation.Factory{Clock: clock.System{}}).New(refs)
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		t.Fatal(err)
	}
	occurrence := d.NewOccurrence(1, 100001, 5)
	if err = mode.settle(context.Background(), gen.TimedScope{Operation: timed}, occurrence, d.Catalog{}, at); err != nil {
		t.Fatal(err)
	}
	if len(achievements.calls) != len(ranks) {
		t.Fatalf("calls %+v", achievements.calls)
	}
	for index, call := range achievements.calls {
		want := ranks[index]
		if call.player != identity.PlayerID(want.PlayerID) || call.rank != int64(index+1) || call.hurt != want.Hurt || call.campaign != occurrence.CampaignID || call.day != occurrence.OpenDay || call.revision != strings.Repeat("a", 64) {
			t.Fatalf("call %d = %+v, rank row %+v", index, call, want)
		}
	}
}

// An achievement failure must fail the settlement transaction, which retries.
type failingAchievements struct{}

func (failingAchievements) ObserveFantasyTx(context.Context, tx.Tx, string, identity.PlayerID, int64, int64, int64, int64, time.Time) error {
	return d.ErrUnavailable
}

func TestSettleFailsWhenTheAchievementFactCannotBeWritten(t *testing.T) {
	mode := Mode{Store: settleStore{ranks: []d.Result{{PlayerID: 11, Hurt: 1}}}, Guilds: settleGuilds{}, Achievements: failingAchievements{}}
	at := time.Unix(1700000000, 0).UTC()
	refs, _ := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)})
	op, _ := (operation.Factory{Clock: clock.System{}}).New(refs)
	timed, _ := gen.NewTimedOperation(op, at)
	if err := mode.settle(context.Background(), gen.TimedScope{Operation: timed}, d.NewOccurrence(1, 100001, 5), d.Catalog{}, at); err == nil {
		t.Fatal("the settlement must fail so it retries")
	}
}
