package stockruntime

import (
	"context"
	"errors"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type socialDormFake struct {
	command     app.Command
	commandErr  error
	readMID     uint16
	readHost    int64
	readHouse   int64
	readStart   int64
	readOffset  int64
	socialCalls int
	commandCall int
}

func (fake *socialDormFake) Command(_ context.Context, _ identity.ActorContext, command app.Command, _ operation.Context) (app.Result, error) {
	fake.commandCall++
	fake.command = command
	if fake.commandErr != nil {
		return app.Result{}, fake.commandErr
	}
	body := map[string]any{"praise_num": int64(2), "is_has_praise": int64(1), "comment_info": map[string]any{"comment_id": int64(9)}, "house_info": map[string]any{"is_hide": int64(1)}}
	return app.Result{Body: body}, nil
}

func (*socialDormFake) Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected read")
}

func (fake *socialDormFake) SocialRead(_ context.Context, _ identity.ActorContext, _ operation.Context, mid uint16, host, house, start, offset int64) (map[string]any, error) {
	fake.socialCalls++
	fake.readMID = mid
	fake.readHost = host
	fake.readHouse = house
	fake.readStart = start
	fake.readOffset = offset
	switch mid {
	case 2519:
		return map[string]any{"house_infos": map[string]any{"house_list": [][]any{{}, {}, {}, {}}, "open_functions": []int64{71}}, "host_info": map[string]any{"player_id": int64(2)}}, nil
	case 2522:
		return map[string]any{"praise_list": []any{}, "total_num": int64(0)}, nil
	default:
		return map[string]any{"best_comments": []any{}, "comment_list": []any{}, "comment_num": int64(0)}, nil
	}
}

func socialEnv(t *testing.T, mid uint16, params map[string]any) httpedge.DispatchRequest {
	t.Helper()
	request := env(mid, nil, time.Now().UTC())
	for key, value := range params {
		request.Envelope.Params[key] = value
	}
	return request
}

func TestDormSocialDispatcherParsesEachStableShape(t *testing.T) {
	fake := &socialDormFake{}
	dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
	for _, tc := range []struct {
		mid    uint16
		params map[string]any
		check  func(t *testing.T)
	}{
		{2518, map[string]any{"house_id": int64(3), "house_name": "name"}, func(t *testing.T) {
			if fake.command.Family != app.ChangeName || fake.command.HouseID != 3 || fake.command.HouseName != "name" {
				t.Fatal(fake.command)
			}
		}},
		{2520, map[string]any{"house_id": int64(3)}, func(t *testing.T) {
			if fake.command.Family != app.HideHouse || fake.command.HouseID != 3 {
				t.Fatal(fake.command)
			}
		}},
		{2521, map[string]any{"host_id": int64(2), "house_id": int64(3)}, func(t *testing.T) {
			if fake.command.Family != app.PraiseHouse || fake.command.HostID != 2 || fake.command.HouseID != 3 {
				t.Fatal(fake.command)
			}
		}},
		{2523, map[string]any{"host_id": int64(2), "house_id": int64(3), "content": "hi"}, func(t *testing.T) {
			if fake.command.Family != app.CommentHouse || fake.command.Content != "hi" {
				t.Fatal(fake.command)
			}
		}},
		{2525, map[string]any{"host_id": int64(2), "house_id": int64(3), "comment_id": int64(9)}, func(t *testing.T) {
			if fake.command.Family != app.PraiseComment || fake.command.CommentID != 9 {
				t.Fatal(fake.command)
			}
		}},
		{2526, map[string]any{"house_id": int64(3), "comment_id": int64(9)}, func(t *testing.T) {
			if fake.command.Family != app.DeleteComment || fake.command.CommentID != 9 {
				t.Fatal(fake.command)
			}
		}},
	} {
		fake.command = app.Command{}
		response := dispatcher.Dispatch(context.Background(), socialEnv(t, tc.mid, tc.params))
		if response.HTTPStatus != 200 {
			t.Fatalf("mid %d status=%d body=%v", tc.mid, response.HTTPStatus, response.Body)
		}
		tc.check(t)
	}

	response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2519, nil))
	if response.HTTPStatus != 200 || fake.readMID != 2519 || response.Body["host_info"] == nil {
		t.Fatal(response, fake)
	}
	response = dispatcher.Dispatch(context.Background(), socialEnv(t, 2522, map[string]any{"house_id": int64(3), "start": int64(0), "offset": int64(20)}))
	if response.HTTPStatus != 200 || fake.readMID != 2522 || fake.readHouse != 3 || fake.readOffset != 20 {
		t.Fatal(response, fake)
	}
	response = dispatcher.Dispatch(context.Background(), socialEnv(t, 2524, map[string]any{"host_id": int64(2), "house_id": int64(3), "start": int64(0), "offset": int64(20), "comment_num": int64(0)}))
	if response.HTTPStatus != 200 || fake.readMID != 2524 || fake.readHost != 2 || fake.readHouse != 3 {
		t.Fatal(response, fake)
	}

	for _, mid := range []uint16{2518, 2520, 2521, 2523, 2525, 2526} {
		response = dispatcher.Dispatch(context.Background(), socialEnv(t, mid, map[string]any{"house_id": int64(3), "unexpected": int64(1)}))
		if response.HTTPStatus != 400 {
			t.Fatalf("mid %d forged param status=%d", mid, response.HTTPStatus)
		}
	}
	response = dispatcher.Dispatch(context.Background(), socialEnv(t, 2527, nil))
	if response.HTTPStatus != 400 {
		t.Fatalf("2527 must stay unregistered: %d", response.HTTPStatus)
	}
}

func TestDormSocialDispatcherMapsEveryDomainRefusalToConflict(t *testing.T) {
	fake := &socialDormFake{commandErr: app.ErrRejected}
	dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
	valid := map[uint16]map[string]any{
		2518: {"house_id": int64(3), "house_name": "name"},
		2520: {"house_id": int64(3)},
		2521: {"host_id": int64(2), "house_id": int64(3)},
		2523: {"host_id": int64(2), "house_id": int64(3), "content": "hi"},
		2525: {"host_id": int64(2), "house_id": int64(3), "comment_id": int64(9)},
		2526: {"house_id": int64(3), "comment_id": int64(9)},
	}
	for _, mid := range []uint16{2518, 2520, 2521, 2523, 2525, 2526} {
		response := dispatcher.Dispatch(context.Background(), socialEnv(t, mid, valid[mid]))
		if response.HTTPStatus != 409 || response.Body["error_code"] != unprovenRefusalCode {
			t.Fatalf("mid %d refusal=%d %v", mid, response.HTTPStatus, response.Body)
		}
	}
	fake.commandErr = app.ErrUnavailable
	response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2521, map[string]any{"host_id": int64(2), "house_id": int64(3)}))
	if response.HTTPStatus != 500 || response.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("bare unavailable sentinel mapped to %d", response.HTTPStatus)
	}
	if got := failSocialDorm(app.ErrStale); got.HTTPStatus != 409 || got.Body["error_code"] != staleConflictCode {
		t.Fatal(got)
	}
}
