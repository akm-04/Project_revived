package stockruntime

import (
	"context"
	"encoding/json"
	application "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type taskWireFixture struct {
	TopFloorTaskPort
	defense domain.TaskModeDefense
	command application.TaskStartCommand
}

func (fixture *taskWireFixture) LoadTask(context.Context, identity.ActorContext, operation.Context, bool) (application.TaskArenaView, error) {
	return application.TaskArenaView{ArenaView: application.ArenaView{Player: domain.Player{Defense: []int64{3, 4}, TicketsLeft: 5}, Enemies: []domain.Display{topFloorRobot}}, Rotation: domain.TaskModeRotation{Mode: 3}, Leader: 3}, nil
}
func (fixture *taskWireFixture) SaveTaskDefense(_ context.Context, _ identity.ActorContext, defense domain.TaskModeDefense, _ operation.Context) error {
	fixture.defense = defense
	return nil
}
func (fixture *taskWireFixture) StartTask(_ context.Context, _ identity.ActorContext, command application.TaskStartCommand, _ operation.Context) (application.FightView, error) {
	fixture.command = command
	return application.FightView{Report: []byte(`{"star":1}`), Win: true, Enemy: topFloorRobot}, nil
}
func (*taskWireFixture) TaskSchedule(context.Context) ([]domain.TaskModeRotation, error) {
	return []domain.TaskModeRotation{{Mode: 3, StartsAt: time.Unix(100, 0), EndsAt: time.Unix(200, 0)}, {Mode: 4, StartsAt: time.Unix(200, 0), EndsAt: time.Unix(300, 0)}}, nil
}
func TestI97ATaskWireAndValidation(t *testing.T) {
	fixture := &taskWireFixture{}
	dispatcher := TopFloorTaskDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fixture}
	call := func(mid uint16, parameters map[string]any) map[string]any {
		t.Helper()
		result := dispatcher.Dispatch(context.Background(), heroReq(t, mid, parameters))
		if result.HTTPStatus != 200 {
			t.Fatal(mid, result)
		}
		return result.Body
	}
	load := call(282, map[string]any{})
	if load["defense_3"] != "3|4" || load["mode"] != int64(3) || load["leader"] != int64(3) {
		t.Fatal(load)
	}
	number := func(value string) json.Number { return json.Number(value) }
	call(284, map[string]any{"heroIDs": []any{number("3")}, "leader_id": number("3")})
	if fixture.defense.Leader != 3 || len(fixture.defense.Heroes) != 1 {
		t.Fatal(fixture.defense)
	}
	battle := call(286, map[string]any{"formation": "3|4", "enemy_id": number("7"), "leader_id": number("3"), "campaign_type": number("57")})
	if fixture.command.Leader != 3 || len(fixture.command.Formation) != 2 || battle["award_crystal"] != int64(0) {
		t.Fatal(fixture.command, battle)
	}
	for _, parameters := range []map[string]any{{"formation": "3|x", "enemy_id": number("7")}, {"formation": "3", "enemy_id": number("7"), "campaign_type": number("3")}, {"formation": "3", "enemy_id": number("7"), "leader_id": number("-1")}} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 286, parameters))
		if result.HTTPStatus != 400 {
			t.Fatal("invalid accepted", result)
		}
	}
	schedule := dispatcher.Dispatch(context.Background(), heroReq(t, 300, map[string]any{}))
	rows, ok := schedule.JSON.([]map[string]any)
	if schedule.HTTPStatus != 200 || !ok || len(rows) != 2 || rows[0]["start_time"] != int64(100) {
		t.Fatal("schedule must be a bare nonempty array", schedule)
	}
}

type taskRankingFixture struct{}

func (taskRankingFixture) RankList(context.Context, identity.ActorContext) (application.RankList, error) {
	return application.RankList{}, nil
}
func (taskRankingFixture) TaskRankList(context.Context, identity.ActorContext) (application.RankList, error) {
	return application.RankList{Rows: []domain.Display{topFloorRobot}, MyRank: 8}, nil
}

type unusedBoardRankingFixture struct{ BoardRankingReads }

func TestRankingAcceptsStockClientFieldsAndRefusesForgedOnes(t *testing.T) {
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}, TopFloor: taskRankingFixture{}}
	stock := heroReq(t, 301, map[string]any{"rank_types": []any{json.Number("2")}, "v_": "1.631.0", "app_v": "1.631.0", "platform": int64(3)})
	if result := dispatcher.Dispatch(context.Background(), stock); result.HTTPStatus != 200 {
		t.Fatal(result)
	}
	forged := heroReq(t, 301, map[string]any{"rank_types": []any{json.Number("2")}, "player_id": int64(1)})
	if result := dispatcher.Dispatch(context.Background(), forged); result.HTTPStatus != 400 {
		t.Fatal(result)
	}
}

func TestI97ATaskRankingSubtype(t *testing.T) {
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}, TopFloor: taskRankingFixture{}}
	result := dispatcher.Dispatch(context.Background(), heroReq(t, 301, map[string]any{"rank_types": []any{json.Number("2")}}))
	if result.HTTPStatus != 200 {
		t.Fatal(result)
	}
	entries := result.Body["rank_list"].([]map[string]any)
	if len(entries) != 1 || entries[0]["rank_type"] != int64(2) {
		t.Fatal("special list leaked normal subtype", entries)
	}
}

func TestI97ATaskRefusalDoesNotInvokeStockSuccessCallback(t *testing.T) {
	result := failTopFloorTask(domain.ErrRefused)
	if result.HTTPStatus == 200 {
		t.Fatal("stock client ignores error_code before success callback", result)
	}
}
