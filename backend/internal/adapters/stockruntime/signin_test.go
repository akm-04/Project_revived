package stockruntime

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type signWire struct {
	err    error
	called bool
}

func (f *signWire) ReadSignIn(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	f.called = true
	return map[string]any{"awards": []any{}, "month": int64(10)}, f.err
}
func (f *signWire) ClaimSignIn(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	f.called = true
	return map[string]any{"award": map[string]any{"table_id": int64(-1), "item_num": int64(40)}, "sign_times": int64(1), "is_signed": int64(1)}, f.err
}
func TestSignInStockWireAndRefusal(t *testing.T) {
	f := &signWire{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &i5WireFake{}, SignIn: f}
	at := time.Now()
	for _, mid := range []uint16{352, 353} {
		got := d.Dispatch(context.Background(), i5Req(mid, map[string]any{"mid": int64(mid), "token": "stock", "region": int64(1), "v_": "1.631.0", "app_v": "1.631.0", "platform": int64(3)}, at))
		if got.HTTPStatus != 200 || !f.called {
			t.Fatal(mid, got)
		}
		f.called = false
		got = d.Dispatch(context.Background(), i5Req(mid, map[string]any{"award_id": 1}, at))
		if got.HTTPStatus != 400 || f.called {
			t.Fatal("untrusted reward input", got)
		}
	}
	f.err = objective.ErrSignRefused
	got := d.Dispatch(context.Background(), i5Req(353, map[string]any{}, at))
	if got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatal(got)
	}
}
