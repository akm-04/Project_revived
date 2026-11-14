package stockruntime

import (
	"context"
	"strings"
	"testing"
	"time"

	appranking "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type comfortBoardFixture struct{ read appranking.BoardRead }

func (f comfortBoardFixture) ReadBoard(_ context.Context, board d.Board, _ identity.ActorContext, _ operation.Context) (appranking.BoardRead, error) {
	if board.Policy != d.DormComfortPolicy {
		return appranking.BoardRead{}, d.ErrSnapshot
	}
	return f.read, nil
}

func TestRankingMID301Subtype34ServesDormComfortShape(t *testing.T) {
	at := time.Date(2026, 11, 7, 4, 0, 0, 0, time.UTC)
	revision := strings.Repeat("a", 64)
	opID, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	root, e := d.NewBoardRoot(d.DormComfortBoard, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	entries := []d.BoardEntry{}
	for player, value := range map[int64]int64{100001: 17, 100002: 5} {
		entries = append(entries, d.BoardEntry{
			Metric:     d.BoardMetric{Player: identity.PlayerID(player), Owner: d.DormComfortBoard.SourceOwner, Policy: d.DormComfortBoard.SourcePolicy, Semantics: d.DormComfortBoard.SourceSemantics, Revision: revision, PopulationDigest: strings.Repeat("b", 64), FieldID: d.DormComfortBoard.FieldID, Value: value, SourceVersion: 1, PopulationVersion: 1, ObservedAt: at},
			Display:    d.BoardPresentation{Player: identity.PlayerID(player), Name: "Ranker", Level: 10, AvatarID: 110001001},
			ScoreSince: at,
		})
	}
	_, snapshot, e := d.FreezeBoardSnapshot(root, at, revision, opID, entries)
	if e != nil {
		t.Fatal(e)
	}
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: comfortBoardFixture{read: boardReadFromSnapshot(snapshot, 100001)}}
	request := env(301, nil, time.Now().UTC())
	request.Envelope.Params["rank_types"] = []any{int64(34)}
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 || response.Body["error_code"] != int64(0) {
		t.Fatal(response)
	}
	list, ok := response.Body["rank_list"].([]map[string]any)
	if !ok || len(list) != 1 || list[0]["rank_type"] != int64(34) {
		t.Fatalf("rank list %v", response.Body)
	}
	info, _ := list[0]["rank_info"].(map[string]any)
	rows, _ := info["rank_info"].([]map[string]any)
	if len(rows) != 2 || rows[0]["comfort"] != int64(17) || rows[0]["player_id"] != int64(100001) || rows[0]["rank"] != int64(1) {
		t.Fatalf("comfort rows %v", info)
	}
	mine, _ := info["my_rank"].(map[string]any)
	if mine == nil || mine["rank"] != int64(1) || mine["score"] != int64(17) {
		t.Fatalf("my rank %v", mine)
	}
}
