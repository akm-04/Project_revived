package stockruntime

import (
	"context"
	"errors"
	"reflect"
	"testing"

	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type dormSaveFake struct {
	command    app.Command
	commandErr error
	commandOut map[string]any
}

func (fake *dormSaveFake) Command(_ context.Context, _ identity.ActorContext, command app.Command, _ operation.Context) (app.Result, error) {
	fake.command = command
	return app.Result{Body: fake.commandOut}, fake.commandErr
}

func (*dormSaveFake) Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected read")
}

func (*dormSaveFake) SocialRead(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected social read")
}

func TestDormSaveWrongKeyStaysMalformed(t *testing.T) {
	fake := &dormSaveFake{commandErr: app.ErrRejected, commandOut: map[string]any{"wrong_key": "50031013#999#1#0"}}
	dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
	response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2515, map[string]any{
		"house_id":         int64(1),
		"furniture_record": []any{map[string]any{}, map[string]any{}, map[string]any{}},
	}))
	if response.HTTPStatus != 400 || response.Body["wrong_key"] != "50031013#999#1#0" {
		t.Fatal(response)
	}
}

func TestDormSaveFlattensStockPanelRecord(t *testing.T) {
	fake := &dormSaveFake{commandOut: map[string]any{}}
	dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
	response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2515, map[string]any{
		"house_id": int64(7),
		"furniture_record": []any{
			map[string]any{"50031013#1#1#0": "50031014#1#1#0", "50031014#1#1#0": ""},
			map[string]any{},
			map[string]any{},
		},
	}))
	if response.HTTPStatus != 200 {
		t.Fatal(response)
	}
	want := map[string]string{"50031013#1#1#0": "50031014#1#1#0", "50031014#1#1#0": ""}
	if fake.command.Family != app.Save || fake.command.HouseID != 7 || !reflect.DeepEqual(fake.command.Furniture, want) {
		t.Fatal(fake.command)
	}
}

func TestDormSaveRejectsNonStockPanelRecord(t *testing.T) {
	for _, record := range []any{
		map[string]any{"1": map[string]any{}},
		[]any{map[string]any{}},
		[]any{map[string]any{}, nil, map[string]any{}},
		[]any{map[string]any{"a#1#1#0": ""}, map[string]any{"a#1#1#0": ""}, map[string]any{}},
	} {
		fake := &dormSaveFake{commandOut: map[string]any{}}
		dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
		response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2515, map[string]any{
			"house_id":         int64(7),
			"furniture_record": record,
		}))
		if response.HTTPStatus != 400 || fake.command.Family != "" {
			t.Fatalf("record %v was not rejected before the service: %v %+v", record, response, fake.command)
		}
	}
}
