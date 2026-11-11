package stockruntime

import (
	"context"
	"errors"
	"testing"

	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type dormSaveFake struct {
	commandErr error
	commandOut map[string]any
}

func (fake dormSaveFake) Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error) {
	return app.Result{Body: fake.commandOut}, fake.commandErr
}

func (dormSaveFake) Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected read")
}

func (dormSaveFake) SocialRead(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected social read")
}

func TestDormSaveWrongKeyStaysMalformed(t *testing.T) {
	fake := dormSaveFake{commandErr: app.ErrRejected, commandOut: map[string]any{"wrong_key": "50031013#999#1#0"}}
	dispatcher := DormDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fake}
	response := dispatcher.Dispatch(context.Background(), socialEnv(t, 2515, map[string]any{"house_id": int64(1), "furniture_record": map[string]any{}}))
	if response.HTTPStatus != 400 || response.Body["wrong_key"] != "50031013#999#1#0" {
		t.Fatal(response)
	}
}
