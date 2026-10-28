package stockruntime

import (
	"context"
	"encoding/json"
	application "gxb.local/backend/v2/internal/application/memoir"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"math"
	"testing"
)

type memoirProbe struct {
	MemoirPort
	results int
	report  application.MonsterResult
}

func (probe *memoirProbe) MonsterResult(_ context.Context, _ identity.ActorContext, result application.MonsterResult, _ operation.Context) (map[string]any, error) {
	probe.results++
	probe.report = result
	return map[string]any{}, nil
}
func TestMemoirStockMapReportBoundary(t *testing.T) {
	actor := actorForHTTP(t)
	probe := &memoirProbe{}
	dispatcher := MemoirDispatcher{Authority: httpAuthority{actor}, Service: probe}
	status := func(identifier int64) map[string]any {
		return map[string]any{"hero_id": identifier, "hp": json.Number("1.25"), "mp": 300, "is_reborn": 0}
	}
	valid := func() map[string]any {
		return map[string]any{"grid_pos": 4, "formation": "7|8", "is_win": 0, "round": 1, "heroes_status": map[string]any{"7": status(7), "8": status(8)}, "enemies_status": map[string]any{"9001": status(-1)}}
	}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 2310, valid()))
	if response.HTTPStatus != 200 || probe.results != 1 || probe.report.Report.Allies[0].Player != int64(actor.PlayerID) || probe.report.Report.Enemies[0].Player != 0 || probe.report.Report.Allies[0].HP != 1.25 {
		t.Fatal(response, probe)
	}
	for _, change := range []func(map[string]any){
		func(fields map[string]any) { fields["formation"] = "7|0" },
		func(fields map[string]any) { fields["formation"] = "7|7" },
		func(fields map[string]any) { fields["formation"] = 7 },
		func(fields map[string]any) { fields["round"] = 5 },
		func(fields map[string]any) { fields["is_win"] = true },
		func(fields map[string]any) { fields["pet_id"] = -1 },
		func(fields map[string]any) { fields["heroes_status"] = map[string]any{"07": status(7)} },
		func(fields map[string]any) { fields["heroes_status"] = map[string]any{"7": status(8)} },
		func(fields map[string]any) {
			row := status(7)
			row["hp"] = math.Inf(1)
			fields["heroes_status"] = map[string]any{"7": row}
		},
		func(fields map[string]any) {
			row := status(7)
			row["player_id"] = 99
			fields["heroes_status"] = map[string]any{"7": row}
		},
		func(fields map[string]any) { fields["awards"] = []any{} },
	} {
		fields := valid()
		change(fields)
		if response := dispatcher.Dispatch(context.Background(), heroReq(t, 2310, fields)); response.HTTPStatus != 400 {
			t.Fatal(fields, response)
		}
	}
	if probe.results != 1 {
		t.Fatal("invalid report reached owner", probe.results)
	}
}
func TestMemoirOpenGridBoundary(t *testing.T) {
	for _, raw := range []any{nil, "1|2", []any{1, 1}, []any{55}, []any{1.5}, map[string]any{"1": true}} {
		if _, valid := memoirOpened(raw); valid {
			t.Fatal(raw)
		}
	}
	for _, raw := range []any{[]any{}, map[string]any{}, []any{1, 2, 54}} {
		if _, valid := memoirOpened(raw); !valid {
			t.Fatal(raw)
		}
	}
}
