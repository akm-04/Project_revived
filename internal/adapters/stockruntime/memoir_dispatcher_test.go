package stockruntime

import (
	"context"
	"encoding/json"
	"fmt"
	application "gxb.local/backend/v2/internal/application/memoir"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/operation"
	"math"
	"strings"
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

type memoirRefusalProbe struct {
	MemoirPort
	err error
}

func (probe memoirRefusalProbe) PlayerFight(context.Context, identity.ActorContext, application.PlayerFight, operation.Context) (map[string]any, error) {
	return nil, probe.err
}

func TestMemoirPlayerFightRefusalsAreCodedConflicts(t *testing.T) {
	actor := actorForHTTP(t)
	for _, test := range []struct {
		name string
		err  error
		code int64
	}{
		{"expired", fmt.Errorf("%w: window ended", domain.ErrReportExpired), domain.ReportExpiredCode},
		{"unavailable", fmt.Errorf("%w: resolver failed", domain.ErrFightUnavailable), domain.FightUnavailableCode},
		{"refused", fmt.Errorf("%w: exit is closed", domain.ErrRefused), 1},
	} {
		t.Run(test.name, func(t *testing.T) {
			dispatcher := MemoirDispatcher{Authority: httpAuthority{actor}, Service: memoirRefusalProbe{err: test.err}}
			response := dispatcher.Dispatch(context.Background(), heroReq(t, 2311, map[string]any{"grid_pos": 4, "formation": "7", "pet_id": 0}))
			if response.HTTPStatus != 409 || response.Body["error_code"] != test.code || response.Cause == nil {
				t.Fatalf("response=%+v", response)
			}
		})
	}
}

type memoirBranchProbe struct {
	MemoirPort
	saveCause  error
	floorCause error
}

func (probe memoirBranchProbe) SaveMap(context.Context, identity.ActorContext, int, []int, operation.Context) (map[string]any, error) {
	return nil, probe.saveCause
}
func (probe memoirBranchProbe) NextFloor(context.Context, identity.ActorContext, int, operation.Context) (map[string]any, error) {
	return nil, probe.floorCause
}

// The journal cause column is what selects the 2306/2308 refusal branch; the
// coded body alone cannot tell them apart.
func TestMemoirSaveMapAndNextFloorKeepTheBranchCause(t *testing.T) {
	actor := actorForHTTP(t)
	saveCause := fmt.Errorf("%w: position 54 is not reachable from 12", domain.ErrRefused)
	floorCause := fmt.Errorf("%w: exit at 54 is closed (guardian_won=false)", domain.ErrRefused)
	dispatcher := MemoirDispatcher{Authority: httpAuthority{actor}, Service: memoirBranchProbe{saveCause: saveCause, floorCause: floorCause}}
	saved := dispatcher.Dispatch(context.Background(), heroReq(t, 2306, map[string]any{"now_pos": 54, "open_grids": []any{}}))
	if saved.HTTPStatus != 409 || saved.Body["error_code"] != int64(1) || !strings.Contains(fmt.Sprint(saved.Cause), "position 54 is not reachable from 12") {
		t.Fatalf("save response=%+v", saved)
	}
	floor := dispatcher.Dispatch(context.Background(), heroReq(t, 2308, map[string]any{"grid_pos": 54}))
	if floor.HTTPStatus != 409 || floor.Body["error_code"] != int64(1) || !strings.Contains(fmt.Sprint(floor.Cause), "exit at 54 is closed") {
		t.Fatalf("floor response=%+v", floor)
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
