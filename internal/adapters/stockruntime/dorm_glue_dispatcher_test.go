package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type glueCommandFake struct {
	err   error
	calls int
}

func (fake *glueCommandFake) Command(_ context.Context, _ identity.ActorContext, command app.Command, _ operation.Context) (app.Result, error) {
	fake.calls++
	if command.Family != app.BuyGlue {
		return app.Result{}, errors.New("wrong command")
	}
	return app.Result{Body: map[string]any{"buy_glue_times": int64(1), "economy_": map[string]any{"glue": int64(150), "crystal": int64(950)}}}, fake.err
}
func (*glueCommandFake) Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected read")
}
func (*glueCommandFake) SocialRead(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64, int64, int64) (map[string]any, error) {
	return nil, errors.New("unexpected social read")
}
func TestDormGlueDispatcherUsesStockEmptyRequestAndRejectsUnsafeSuccess(t *testing.T) {
	fake := &glueCommandFake{}
	dispatcher := DormDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake}
	request := env(1845, nil, time.Now().UTC())
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 || fake.calls != 1 || response.Body["buy_glue_times"] != int64(1) {
		t.Fatal(response, fake.calls)
	}
	request.Envelope.Params["price"] = 1
	response = dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 400 || fake.calls != 1 {
		t.Fatal("client price accepted", response, fake.calls)
	}
	delete(request.Envelope.Params, "price")
	for _, cell := range []struct {
		err    error
		status int
		code   int64
	}{{app.ErrRejected, 409, unprovenRefusalCode}, {app.ErrUnavailable, 503, serverBusyCode}} {
		fake.err = cell.err
		response = dispatcher.Dispatch(context.Background(), request)
		if response.HTTPStatus != cell.status || response.Body["buy_glue_times"] != nil || response.Body["economy_"] != nil {
			t.Fatal(response, cell)
		}
		if response.Body["error_code"] != cell.code {
			t.Fatalf("stock refusal body %v", response.Body)
		}
		if cell.status == 409 && (len(response.Body) != 2 || response.Body["error_msg"] != "") {
			t.Fatalf("conflict refusal body must be error_code and empty error_msg: %v", response.Body)
		}
	}
}
