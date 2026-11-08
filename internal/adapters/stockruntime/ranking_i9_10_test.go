package stockruntime

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type boardSnapshotFixture struct{ boards map[string]d.BoardSnapshot }

func (f boardSnapshotFixture) ReadBoard(_ context.Context, board d.Board, _ identity.ActorContext, _ operation.Context) (d.BoardSnapshot, error) {
	snapshot, ok := f.boards[board.Policy]
	if !ok {
		return d.BoardSnapshot{}, d.ErrSnapshot
	}
	return snapshot, nil
}

type petCampaignRankFixture struct {
	subtype int64
	body    map[string]any
}

func (f *petCampaignRankFixture) RankList(_ context.Context, _ identity.ActorContext, subtype int64, _ operation.Context) (map[string]any, error) {
	f.subtype = subtype
	return f.body, nil
}

func boardSnapshotForTest(t *testing.T, board d.Board, at time.Time, revision string) d.BoardSnapshot {
	t.Helper()
	root, e := d.NewBoardRoot(board, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	opID, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	inputs := []d.BoardInput{}
	for player, value := range map[int64]int64{100001: 2, 100002: 9} {
		inputs = append(inputs, d.BoardInput{
			Metric:  d.BoardMetric{Player: identity.PlayerID(player), Owner: board.SourceOwner, Policy: board.SourcePolicy, Semantics: board.SourceSemantics, Revision: revision, PopulationDigest: strings.Repeat("b", 64), FieldID: board.FieldID, Value: value, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
			Display: d.BoardPresentation{Player: identity.PlayerID(player), Name: "Ranker", Level: 10, AvatarID: 110001001},
		})
	}
	_, snapshot, e := d.BuildBoardSnapshot(root, at, revision, opID, inputs)
	if e != nil {
		t.Fatal(e)
	}
	return snapshot
}

func TestRankingMID301ServesStarAndAwakenCountBoards(t *testing.T) {
	at := time.Date(2026, 11, 8, 4, 0, 0, 0, time.UTC)
	revision := strings.Repeat("a", 64)
	for _, board := range []d.Board{d.StarCountBoard, d.AwakenCountBoard, d.TopForceBoard} {
		snapshot := boardSnapshotForTest(t, board, at, revision)
		dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: boardSnapshotFixture{boards: map[string]d.BoardSnapshot{board.Policy: snapshot}}}
		request := env(301, nil, time.Now().UTC())
		request.Envelope.Params["rank_types"] = []any{board.SubType}
		response := dispatcher.Dispatch(context.Background(), request)
		if response.HTTPStatus != 200 || response.Body["error_code"] != int64(0) {
			t.Fatal(response)
		}
		list, ok := response.Body["rank_list"].([]map[string]any)
		if !ok || len(list) != 1 || list[0]["rank_type"] != board.SubType {
			t.Fatalf("rank list %v", response.Body)
		}
		info, _ := list[0]["rank_info"].(map[string]any)
		rows, _ := info["rank_info"].([]map[string]any)
		if len(rows) != 2 || rows[0]["player_id"] != int64(100002) || rows[0]["info_val"] != int64(9) || rows[0]["rank"] != int64(1) {
			t.Fatalf("subtype %d rows %v", board.SubType, info)
		}
		mine, _ := info["my_rank"].(map[string]any)
		if mine == nil || mine["rank"] != int64(2) || mine["score"] != int64(2) {
			t.Fatalf("subtype %d my rank %v", board.SubType, mine)
		}
	}
}

func TestRankingMID301RoutesSkyTowerEliteToCampaignOwner(t *testing.T) {
	body := map[string]any{"rank_list": []map[string]any{{"rank_type": int64(23), "rank_info": map[string]any{"my_rank": map[string]any{"rank": int64(2), "my_floor": int64(4)}, "rank_info": []map[string]any{{"player_id": int64(100002), "max_floor": int64(7), "rank": int64(1)}}}}}}
	petCampaign := &petCampaignRankFixture{body: body}
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}, PetCampaign: petCampaign}
	request := env(301, nil, time.Now().UTC())
	request.Envelope.Params["rank_types"] = []any{int64(23)}
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 || petCampaign.subtype != int64(23) {
		t.Fatal(response, petCampaign.subtype)
	}
	list, ok := response.Body["rank_list"].([]map[string]any)
	if !ok || len(list) != 1 || list[0]["rank_type"] != int64(23) {
		t.Fatalf("rank list %v", response.Body)
	}
	info, _ := list[0]["rank_info"].(map[string]any)
	mine, _ := info["my_rank"].(map[string]any)
	if mine == nil || mine["my_floor"] != int64(4) {
		t.Fatalf("elite self entry %v", info)
	}
}
