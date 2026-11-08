//go:build postgres

package playerdisplay_test

import (
	"math"
	"reflect"
	"slices"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	rankingdomain "gxb.local/backend/v2/internal/domain/ranking"
	projection "gxb.local/backend/v2/internal/projection/ranking"
)

// summonHeroes runs the real Character summon command for each table. The
// caller has already birthed the player's bootstrap rows via combatOwner.
func summonHeroes(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, tables ...int64) []int64 {
	t.Helper()
	partners := make([]int64, 0, len(tables))
	for _, table := range tables {
		def := collectionResources(t, p, a, rev, table)
		h, e := ownerSummoner(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if e != nil {
			t.Fatal(table, e)
		}
		partners = append(partners, h.Ref().PartnerID)
	}
	return partners
}

func topFiveForce(t *testing.T, p *pg.Pool, rev string, a identity.ActorContext, partners []int64) (int64, int64) {
	t.Helper()
	forces := make([]int64, 0, len(partners))
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		for _, partner := range partners {
			v, e := rawBirthStats(p).HeroTx(ctx, sc, character.HeroRef{PlayerID: a.PlayerID, PartnerID: partner}, publicstats.View{Kind: publicstats.Self, Viewer: a.PlayerID})
			if e != nil {
				return e
			}
			if v.Stats.Force <= 0 {
				t.Fatalf("hero %d has no force", partner)
			}
			forces = append(forces, int64(math.Round(v.Stats.Force)))
		}
		return nil
	}); e != nil {
		t.Fatal(e)
	}
	slices.Sort(forces)
	all := int64(0)
	for _, force := range forces {
		all += force
	}
	top := int64(0)
	for _, force := range forces[max(0, len(forces)-5):] {
		top += force
	}
	return top, all
}

func TestI9_10ETopFiveForceBoardOrdersAndIsolatesServers(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	other := rankingServer(t, p)
	a, rev, first := combatOwner(t, p, server)
	b, _, _ := combatOwner(t, p, server)
	c, _, cFirst := combatOwner(t, p, other)
	partners := append([]int64{first.PartnerID}, summonHeroes(t, p, a, rev, 10001002, 10001003, 10001004, 10001005, 10001006)...)
	otherPartners := append([]int64{cFirst.PartnerID}, summonHeroes(t, p, c, rev, 10001002, 10001003)...)

	expected, all := topFiveForce(t, p, rev, a, partners)
	if len(partners) != 6 || expected >= all {
		t.Fatal("fixture must prove the sixth hero is dropped", partners, expected, all)
	}
	otherExpected, _ := topFiveForce(t, p, rev, c, otherPartners)
	metrics := privateMetricProvider(p)
	metrics.Force = rawBirthStats(p)
	s := rankingService(p, p)
	s.TopForce = metrics

	board, e := s.ReadBoard(ctx, rankingdomain.TopForceBoard, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(board.Entries) != 2 || board.Server != server {
		t.Fatal(board)
	}
	order := []identity.PlayerID{board.Entries[0].Metric.Player, board.Entries[1].Metric.Player}
	if !reflect.DeepEqual(order, []identity.PlayerID{a.PlayerID, b.PlayerID}) || board.Entries[0].Metric.Value != expected || board.Entries[0].Metric.FieldID != 1012 {
		t.Fatal(board.Entries)
	}
	wire, e := projection.BoardList(board, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	list := wire["rank_list"].([]map[string]any)[0]
	info := list["rank_info"].(map[string]any)
	mine := info["my_rank"].(map[string]any)
	firstRow := info["rank_info"].([]map[string]any)[0]
	if list["rank_type"] != int64(9) || mine["rank"] != int64(1) || mine["score"] != expected || firstRow["info_val"] != expected {
		t.Fatal(wire)
	}

	otherBoard, e := s.ReadBoard(ctx, rankingdomain.TopForceBoard, c, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(otherBoard.Entries) != 1 || otherBoard.Server != other || otherBoard.Entries[0].Metric.Player != c.PlayerID || otherBoard.Entries[0].Metric.Value != otherExpected {
		t.Fatal(otherBoard)
	}
}
