package achievement

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type countsQueryer struct{}

func (countsQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	panic("unexpected database access")
}
func (countsQueryer) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	panic("unexpected database access")
}
func (countsQueryer) Commit(context.Context) error   { return nil }
func (countsQueryer) Rollback(context.Context) error { return nil }

type countsRoster struct {
	rows []ca.RosterMetricRow
	err  error
}

func (r countsRoster) ReadRosterMetricsTx(_ context.Context, _ ca.CoherentReadScope, p identity.PlayerID, family string) (ca.RosterMetricPopulation, error) {
	return ca.RosterMetricPopulation{PlayerID: p, Family: family, Rows: r.rows}, r.err
}

type countsKinds struct{ kinds map[int64]string }

func (k countsKinds) ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error) {
	out := player.DisplayCatalog{}
	for table, kind := range k.kinds {
		out.HeroTemplates = append(out.HeroTemplates, player.DisplayHeroTemplate{TableID: table, Kind: kind})
	}
	return out, nil
}

type guildCampaignFake struct {
	value int64
	err   error
}

func (f guildCampaignFake) BestDamageTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return f.value, f.err
}

type petCampaignFake struct{ value int64 }

func (f petCampaignFake) MaxFloorTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return f.value, nil
}

type campaignFake struct{ value int64 }

func (f campaignFake) NormalStarsTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, error) {
	return f.value, nil
}

type schoolStoryFake struct{ value int64 }

func (f schoolStoryFake) SchoolStoryCountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return f.value, nil
}

type mentorFake struct{ value int64 }

func (f mentorFake) GraduatedCountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return f.value, nil
}

type memoirFake struct{ value int64 }

func (f memoirFake) TenthFloorTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error) {
	return f.value, nil
}

type occultFake struct{ value int64 }

func (f occultFake) ClearedChapterCountTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, error) {
	return f.value, nil
}

func baseCounts() OwnerCounts {
	return OwnerCounts{Roster: countsRoster{}, Kinds: countsKinds{}}
}

func countsScope(t *testing.T) ca.CoherentReadScope {
	t.Helper()
	at := time.Unix(100, 0).UTC()
	revision := strings.Repeat("a", 64)
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if e != nil {
		t.Fatal(e)
	}
	scope, e := ca.NewCoherentReadScope(tx.Scope{Tx: countsQueryer{}, Operation: operation.Context{ID: ids.UUID{1}, StartedAt: at, Policies: refs}, Attempt: 1,
		Options: tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}}, revision, at)
	if e != nil {
		t.Fatal(e)
	}
	return scope
}

func TestOwnerCountsReadsEachOwnerFact(t *testing.T) {
	scope := countsScope(t)
	playerID := identity.PlayerID(100001)
	cases := []struct {
		name   string
		id     int64
		mutate func(*OwnerCounts)
		want   int64
	}{
		{"guild damage in tens of thousands", 100004, func(o *OwnerCounts) { o.GuildCampaign = guildCampaignFake{value: 99999} }, 9},
		{"sky tower floor", 100005, func(o *OwnerCounts) { o.PetCampaign = petCampaignFake{value: 77} }, 77},
		{"normal campaign stars", 100010, func(o *OwnerCounts) { o.Campaign = campaignFake{value: 612} }, 612},
		{"school stories", 100020, func(o *OwnerCounts) { o.SchoolStories = schoolStoryFake{value: 4} }, 4},
		{"graduated students", 100022, func(o *OwnerCounts) { o.Mentor = mentorFake{value: 2} }, 2},
		{"memoir tenth floor", 100024, func(o *OwnerCounts) { o.Memoir = memoirFake{value: 3} }, 3},
		{"occult chapters", 100027, func(o *OwnerCounts) { o.Occult = occultFake{value: 5} }, 5},
		{"titan roster rows", 100031, func(o *OwnerCounts) {
			o.Roster = countsRoster{rows: []ca.RosterMetricRow{{TableID: 20001001, OriginTableID: 20001001}, {TableID: 20001002, OriginTableID: 20001002}, {TableID: 10001001, OriginTableID: 10001001}}}
			o.Kinds = countsKinds{kinds: map[int64]string{20001001: "SUPER", 20001002: "SUPER", 10001001: "NORMAL"}}
		}, 2},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			counts := baseCounts()
			test.mutate(&counts)
			got := counts.OwnedStateCountsTx(context.Background(), scope, playerID, []int64{test.id})
			value, ok := got[test.id]
			if !ok || value != test.want {
				t.Fatalf("id %d = %d (present %v), want %d", test.id, value, ok, test.want)
			}
		})
	}
}

func TestOwnerCountsLeavesUnreadOwnerUnobserved(t *testing.T) {
	scope := countsScope(t)
	counts := baseCounts()
	counts.GuildCampaign = guildCampaignFake{err: errors.New("owner unavailable")}
	got := counts.OwnedStateCountsTx(context.Background(), scope, identity.PlayerID(100001), []int64{100004})
	if _, observed := got[100004]; observed {
		t.Fatalf("an owner read error must leave the id unobserved: %v", got)
	}
}
