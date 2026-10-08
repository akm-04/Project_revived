package stockruntime

import (
	"context"
	"gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
	"testing"
	"time"
)

type generalFake struct{ called bool }

func (f *generalFake) Accept(context.Context, int64, int64, string, operation.Context) (generaldm.Intent, error) {
	f.called = true
	return generaldm.Intent{}, nil
}
func TestGeneralDispatcherRequiresExactChannel(t *testing.T) {
	f := &generalFake{}
	d := GeneralDMDispatcher{Service: f}
	r := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 513, Params: map[string]any{"to_player_id": "2", "message": "hello"}, ReceivedAt: time.Now()}}
	if got := d.Dispatch(context.Background(), r); got.HTTPStatus != 401 {
		t.Fatal(got)
	}
	if f.called {
		t.Fatal("unauthenticated call")
	}
}

func (f *generalFake) Wait(context.Context, generaldm.Intent) (generaldm.Intent, error) {
	return generaldm.Intent{}, generaldm.ErrUnavailable
}
