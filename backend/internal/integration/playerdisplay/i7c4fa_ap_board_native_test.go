//go:build postgres

package playerdisplay_test

import (
	"errors"
	"math"
	"reflect"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	projection "gxb.local/backend/v2/internal/projection/ranking"
)

func TestI7C4FAAchievementPointBoardSumsForceAndTitlesOnlyFirst(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a, _, _ := combatOwner(t, p, server)
	b, _, _ := combatOwner(t, p, server)
	c := rankingActor(t, p, server, true)
	second := collectionResources(t, p, b, rev, 10001002)
	if _, e := ownerSummoner(p).SummonNormal(ctx, b, second.Template.TableID, second.Template.FragmentItemID, second.FragmentCount, op()); e != nil {
		t.Fatal(e)
	}
	s := rankingService(p, p)
	metrics := privateMetricProvider(p)
	metrics.Force = rawBirthStats(p)
	s.Metrics = metrics

	expected := int64(0)
	if e := statRead(t, p, rev, func(sc ca.CoherentReadScope) error {
		for _, partner := range []int64{1, 2} {
			v, e := rawBirthStats(p).HeroTx(ctx, sc, character.HeroRef{PlayerID: b.PlayerID, PartnerID: partner}, publicstats.View{Kind: publicstats.Self, Viewer: b.PlayerID})
			if e != nil {
				return e
			}
			expected += int64(math.Round(v.Stats.Force))
		}
		return nil
	}); e != nil || expected <= 0 {
		t.Fatal(expected, e)
	}

	o := op()
	board, e := s.ReadBoard(ctx, d.AchievementPointBoard, a, o)
	if e != nil {
		t.Fatal(e)
	}
	order := []identity.PlayerID{}
	for _, v := range board.Entries {
		order = append(order, v.Metric.Player)
	}
	if !reflect.DeepEqual(order, []identity.PlayerID{b.PlayerID, a.PlayerID, c.PlayerID}) || board.Entries[0].Metric.Value != expected || board.Entries[0].Metric.FieldID != 1007 || board.Entries[2].Metric.Value != 0 {
		t.Fatal(board.Entries)
	}
	var winner, title int64
	if e = p.QueryRow(ctx, `SELECT player_id,title_id FROM ranking_girls_awards WHERE logical_server_id=$1 AND policy_id=$2`, int64(server), d.AchievementPointPolicy).Scan(&winner, &title); e != nil || winner != int64(b.PlayerID) || title != 100001 {
		t.Fatal("AP title must go to rank 1 only", winner, title, e)
	}
	if rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal("AP settled more than one title")
	}
	replay, e := s.ReadBoard(ctx, d.AchievementPointBoard, a, o)
	if e != nil || !reflect.DeepEqual(board, replay) {
		t.Fatal("AP snapshot receipt changed", e)
	}
	if _, e = s.RefreshBoard(ctx, d.GirlsBoard, a, o); e == nil {
		t.Fatal("one operation crossed into the Girls board")
	}

	wire, e := projection.BoardList(board, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	list := wire["rank_list"].([]map[string]any)[0]
	mine := list["rank_info"].(map[string]any)["my_rank"].(map[string]any)
	first := list["rank_info"].(map[string]any)["rank_info"].([]map[string]any)[0]
	_, scored := first["score"]
	if list["rank_type"] != int64(8) || mine["rank"] != int64(2) || first["info_val"] != board.Entries[0].Metric.Value || scored {
		t.Fatal(wire)
	}

	request := func(pid identity.PlayerID) display.CatalogOriginRequest {
		return display.CatalogOriginRequest{PlayerID: pid, Family: "title", CatalogID: 100001, Revision: rev, ObservedAt: time.Now().UTC()}
	}
	won, e := s.ReadCatalogDisplayOriginsTx(ctx, p, request(b.PlayerID))
	if e != nil || !won.Qualified || !won.CompleteHistory || len(won.Origins) != 1 || won.Origins[0].CatalogID != 100001 {
		t.Fatal(won, e)
	}
	lost, e := s.ReadCatalogDisplayOriginsTx(ctx, p, request(a.PlayerID))
	if e != nil || !lost.Qualified || !lost.CompleteHistory || len(lost.Origins) != 0 {
		t.Fatal(lost, e)
	}
	ds := service(p, p)
	ds.CatalogExternal = s
	if selected, e := ds.Execute(ctx, b, display.Command{Kind: "title", ID: 100001}, op()); e != nil || selected.Wire["title_info"] == nil {
		t.Fatal(selected, e)
	}
	if _, e = ds.Execute(ctx, a, display.Command{Kind: "title", ID: 100001}, op()); !errors.Is(e, display.ErrRequest) {
		t.Fatal("AP runner-up selected the No.1 title", e)
	}
}
