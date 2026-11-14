//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/projection/ranking"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func readOfSnapshot(snapshot d.BoardSnapshot, viewer identity.PlayerID) app.BoardRead {
	board, _ := d.BoardOf(snapshot.Policy)
	read := app.BoardRead{Board: board, Server: snapshot.Server, Displays: map[identity.PlayerID]d.BoardPresentation{}}
	for i, entry := range snapshot.Entries {
		p := entry.Display
		read.Displays[p.Player] = p
		read.Rows = append(read.Rows, d.ScoreRow{Policy: snapshot.Policy, Server: snapshot.Server, Player: entry.Metric.Player, Score: entry.Metric.Value, ScoreSince: entry.ScoreSince, Revision: entry.Metric.Revision, Metric: entry.Metric, UpdatedAt: entry.Metric.ObservedAt})
		if entry.Metric.Player == viewer {
			read.MyRank, read.MyScore = int64(i+1), entry.Metric.Value
		}
	}
	return read
}

func boardWire(t *testing.T, read app.BoardRead) map[string]any {
	t.Helper()
	rows, e := ranking.BoardRows(read.Rows, read.Displays, read.Board.RowValue)
	if e != nil {
		t.Fatal(e)
	}
	mine := map[string]any{}
	if read.MyRank > 0 {
		mine = map[string]any{"rank": read.MyRank, "score": read.MyScore}
	}
	return ranking.BoardList(read.Board.SubType, rows, mine)
}

type bearerAuthority map[string]identity.ActorContext

func (a bearerAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	actor, ok := a[token]
	if !ok {
		return identity.ActorContext{}, d.ErrSnapshot
	}
	return actor, nil
}

func r7Dispatch(t *testing.T, dispatcher stockruntime.RankingDispatcher, actor identity.ActorContext) map[string]any {
	t.Helper()
	token := string(actor.AccountUID)
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 301, Operation: op(), ReceivedAt: time.Now().UTC(), Params: map[string]any{"rank_types": []any{int64(34)}}, Claims: wire.CredentialClaims{Token: token, Region: int64(actor.LogicalServerID)}}}
	response := dispatcher.Dispatch(ctx, request)
	if response.HTTPStatus != 200 || response.Body["error_code"] != int64(0) {
		t.Fatalf("MID301 status=%d body=%v", response.HTTPStatus, response.Body)
	}
	list, ok := response.Body["rank_list"].([]map[string]any)
	if !ok || len(list) != 1 || list[0]["rank_type"] != int64(34) {
		t.Fatalf("rank list %v", response.Body)
	}
	return list[0]["rank_info"].(map[string]any)
}

func TestR7MID301ServesStoredRowsAndViewerRankOutsideThePage(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := rankingServer(t, p)
	first := rankingActor(t, p, server, true)
	second := rankingActor(t, p, server, true)
	viewer := rankingActor(t, p, server, true)
	comfortRooms(t, p, first.PlayerID, revision, map[int64]int64{1: 30})
	comfortRooms(t, p, second.PlayerID, revision, map[int64]int64{1: 20})
	service := rankingService(p, p)
	service.Comfort = dormstore.Store{Queryer: p}
	service.ListSize = 2
	dispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(first.AccountUID): first, string(second.AccountUID): second, string(viewer.AccountUID): viewer}, Service: service}

	r7Dispatch(t, dispatcher, first)
	r7Dispatch(t, dispatcher, second)
	noFact := r7Dispatch(t, dispatcher, viewer)
	if len(noFact["my_rank"].(map[string]any)) != 0 {
		t.Fatalf("viewer without a fact got a rank: %v", noFact)
	}
	if rows := noFact["rank_info"].([]map[string]any); len(rows) != 2 || rows[0]["player_id"] != int64(first.PlayerID) || rows[0]["comfort"] != int64(30) || rows[1]["player_id"] != int64(second.PlayerID) {
		t.Fatalf("published page %v", rows)
	}

	comfortRooms(t, p, viewer.PlayerID, revision, map[int64]int64{1: 10})
	outside := r7Dispatch(t, dispatcher, viewer)
	mine := outside["my_rank"].(map[string]any)
	if mine["rank"] != int64(3) || mine["score"] != int64(10) {
		t.Fatalf("viewer outside the page: %v", mine)
	}
	if rows := outside["rank_info"].([]map[string]any); len(rows) != 2 {
		t.Fatalf("page grew past the limit: %v", rows)
	}

	comfortRooms(t, p, viewer.PlayerID, revision, map[int64]int64{1: 50})
	raised := r7Dispatch(t, dispatcher, viewer)
	if mine := raised["my_rank"].(map[string]any); mine["rank"] != int64(1) || mine["score"] != int64(50) {
		t.Fatalf("viewer score change not visible: %v", mine)
	}
	if rows := raised["rank_info"].([]map[string]any); rows[0]["player_id"] != int64(viewer.PlayerID) || rows[0]["comfort"] != int64(50) {
		t.Fatalf("page did not reflect the score change: %v", rows)
	}
}

func TestR7MID301ViewerAtRank101AndEmptyBoard(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := rankingServer(t, p)
	r7BulkPlayers(t, p, server, 100)
	for i := int64(1); i <= 100; i++ {
		comfortRooms(t, p, identity.PlayerID(int64(server)*100000+i), revision, map[int64]int64{1: 1000 - i})
	}
	viewer := rankingActor(t, p, server, true)
	comfortRooms(t, p, viewer.PlayerID, revision, map[int64]int64{1: 1})
	service := r7JobService(p)
	if e := service.BackfillScoresServer(ctx, op(), server, r7ServerPlayers(t, p, server)); e != nil {
		t.Fatal(e)
	}
	dispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(viewer.AccountUID): viewer}, Service: service}
	info := r7Dispatch(t, dispatcher, viewer)
	mine := info["my_rank"].(map[string]any)
	if mine["rank"] != int64(101) || mine["score"] != int64(1) {
		t.Fatalf("viewer at rank 101: %v", mine)
	}
	if rows := info["rank_info"].([]map[string]any); len(rows) != 100 {
		t.Fatalf("page past the published 100: %d", len(rows))
	}

	emptyServer := rankingServer(t, p)
	emptyViewer := rankingActor(t, p, emptyServer, true)
	emptyService := r7JobService(p)
	emptyDispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(emptyViewer.AccountUID): emptyViewer}, Service: emptyService}
	empty := r7Dispatch(t, emptyDispatcher, emptyViewer)
	if len(empty["my_rank"].(map[string]any)) != 0 {
		t.Fatalf("empty board gave a rank: %v", empty["my_rank"])
	}
	if rows := empty["rank_info"].([]map[string]any); len(rows) != 0 {
		t.Fatalf("empty board published rows: %v", rows)
	}
}
