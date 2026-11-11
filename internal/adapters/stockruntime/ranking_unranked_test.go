package stockruntime

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/oneonone"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
)

type arenaRankFixture struct{ list arena.RankList }

func (f arenaRankFixture) RankList(context.Context, identity.ActorContext) (arena.RankList, error) {
	return f.list, nil
}

type oneOnOneRankFixture struct{ list oneonone.RankList }

func (f oneOnOneRankFixture) RankList(context.Context, identity.ActorContext, bool) (oneonone.RankList, error) {
	return f.list, nil
}

type topFloorRankFixture struct{ list topfloor.RankList }

func (f topFloorRankFixture) RankList(context.Context, identity.ActorContext) (topfloor.RankList, error) {
	return f.list, nil
}

type trophyRankFixture struct{ board achievement.TrophyBoard }

func (f trophyRankFixture) TrophyBoard(context.Context, identity.ActorContext) (achievement.TrophyBoard, error) {
	return f.board, nil
}

func dispatchBookRank(t *testing.T, dispatcher RankingDispatcher, subtype int64) any {
	t.Helper()
	request := env(301, nil, time.Now().UTC())
	request.Envelope.Params["rank_types"] = []any{subtype}
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 {
		t.Fatalf("subtype %d status %d body %v", subtype, response.HTTPStatus, response.Body)
	}
	list, ok := response.Body["rank_list"].([]map[string]any)
	if !ok || len(list) != 1 {
		t.Fatalf("subtype %d rank_list %v", subtype, response.Body)
	}
	info, _ := list[0]["rank_info"].(map[string]any)
	return info["my_rank"]
}

func TestRankingMID301UnrankedViewerGetsEmptySelfEntry(t *testing.T) {
	unranked := []struct {
		name       string
		subtype    int64
		dispatcher RankingDispatcher
	}{
		{"arena", 6, RankingDispatcher{Arena: arenaRankFixture{}}},
		{"oneonone-global", 3, RankingDispatcher{OneOnOne: oneOnOneRankFixture{}}},
		{"oneonone-server", 4, RankingDispatcher{OneOnOne: oneOnOneRankFixture{}}},
		{"topfloor", 1, RankingDispatcher{TopFloor: topFloorRankFixture{}}},
		{"trophy", 15, RankingDispatcher{Trophy: trophyRankFixture{}}},
	}
	for _, test := range unranked {
		dispatcher := test.dispatcher
		dispatcher.Authority = httpAuthority{actorForHTTP(t)}
		dispatcher.Service = unusedBoardRankingFixture{}
		mine := dispatchBookRank(t, dispatcher, test.subtype)
		entry, ok := mine.(map[string]any)
		if !ok || len(entry) != 0 {
			t.Fatalf("%s: unranked my_rank = %#v, want empty table", test.name, mine)
		}
	}
}

func TestRankingMID301ServesViewerBelowDormWindow(t *testing.T) {
	at := time.Date(2026, 11, 8, 4, 0, 0, 0, time.UTC)
	revision := strings.Repeat("a", 64)
	opID, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	root, e := d.NewBoardRoot(d.DormComfortBoard, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	inputs := []d.BoardInput{}
	for index := int64(0); index < 101; index++ {
		player := int64(200001) + index
		inputs = append(inputs, d.BoardInput{
			Metric:  d.BoardMetric{Player: identity.PlayerID(player), Owner: d.DormComfortBoard.SourceOwner, Policy: d.DormComfortBoard.SourcePolicy, Semantics: d.DormComfortBoard.SourceSemantics, Revision: revision, PopulationDigest: strings.Repeat("b", 64), FieldID: d.DormComfortBoard.FieldID, Value: 1000 - index, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
			Display: d.BoardPresentation{Player: identity.PlayerID(player), Name: "Ranker", Level: 10, AvatarID: 110001001},
		})
	}
	_, snapshot, e := d.BuildBoardSnapshot(root, at, revision, opID, inputs)
	if e != nil {
		t.Fatal(e)
	}
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: comfortBoardFixture{snapshot: snapshot}}
	mine := dispatchBookRank(t, dispatcher, 34)
	entry, ok := mine.(map[string]any)
	if !ok || len(entry) != 0 {
		t.Fatalf("viewer outside the window got my_rank %#v, want empty table", mine)
	}
}
