package stockruntime

import (
	"context"
	"errors"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type fakeCompatPort struct {
	calls       int
	messageType int64
	enabled     bool
	firstTouch  int
	err         error
}

func (p *fakeCompatPort) SetMessagePush(_ context.Context, _ identity.ActorContext, messageType int64, enabled bool, _ operation.Context) error {
	p.calls++
	p.messageType = messageType
	p.enabled = enabled
	return p.err
}

func (p *fakeCompatPort) FirstMainTouch(context.Context, identity.ActorContext, operation.Context) error {
	p.firstTouch++
	return p.err
}

func TestCompatDispatchToggles(t *testing.T) {
	now := time.Unix(500, 0).UTC()
	port := &fakeCompatPort{}
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, port)
	for _, testCase := range []struct {
		mid     uint16
		enabled bool
	}{
		{mid: 1025, enabled: true},
		{mid: 1026, enabled: false},
	} {
		request := env(testCase.mid, nil, now)
		request.Envelope.Params["message_type"] = float64(7)
		response := dispatcher.Dispatch(context.Background(), request)
		if response.HTTPStatus != 200 || len(response.Body) != 0 {
			t.Fatalf("MID %d: %+v", testCase.mid, response)
		}
		replyconformance.Check(t, testCase.mid, response.Body)
		if port.messageType != 7 || port.enabled != testCase.enabled {
			t.Fatalf("MID %d recorded type %d enabled %v", testCase.mid, port.messageType, port.enabled)
		}
	}
}

func TestCompatDispatchFirstTouch(t *testing.T) {
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{})
	response := dispatcher.Dispatch(context.Background(), env(1864, nil, time.Unix(500, 0).UTC()))
	if response.HTTPStatus != 200 || len(response.Body) != 0 {
		t.Fatalf("1864: %+v", response)
	}
	replyconformance.Check(t, 1864, response.Body)
}

func TestCompatDispatchRejectsMalformedParams(t *testing.T) {
	now := time.Unix(500, 0).UTC()
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{})
	cases := []struct {
		name   string
		mid    uint16
		params map[string]any
	}{
		{name: "missing message_type", mid: 1025},
		{name: "non-integer message_type", mid: 1025, params: map[string]any{"message_type": "seven"}},
		{name: "text digits message_type", mid: 1025, params: map[string]any{"message_type": "7"}},
		{name: "fractional message_type", mid: 1025, params: map[string]any{"message_type": 7.5}},
		{name: "extra toggle param", mid: 1026, params: map[string]any{"message_type": float64(7), "enabled": true}},
		{name: "first touch body", mid: 1864, params: map[string]any{"count": float64(1)}},
	}
	for _, testCase := range cases {
		request := env(testCase.mid, nil, now)
		for key, value := range testCase.params {
			request.Envelope.Params[key] = value
		}
		response := dispatcher.Dispatch(context.Background(), request)
		if response.HTTPStatus != 400 || response.Body["error"] != "compat_invalid_parameter" {
			t.Fatalf("%s: %+v", testCase.name, response)
		}
	}
}

func TestCompatDispatchCatalogRefusalIsMalformed(t *testing.T) {
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{err: d.ErrInvalidMessageType})
	request := env(1025, nil, time.Unix(500, 0).UTC())
	request.Envelope.Params["message_type"] = float64(99)
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 400 || response.Body["error"] != "compat_invalid_parameter" {
		t.Fatalf("catalog refusal: %+v", response)
	}
}

func TestCompatDispatchRequiresABearer(t *testing.T) {
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{})
	request := env(1864, nil, time.Unix(500, 0).UTC())
	request.Envelope.Claims.Token = ""
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 401 {
		t.Fatalf("missing bearer: %+v", response)
	}
}

func TestCompatDispatchStaleStateIsAConflict(t *testing.T) {
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{err: d.ErrStaleState})
	request := env(1864, nil, time.Unix(500, 0).UTC())
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(40002) {
		t.Fatalf("stale state: %+v", response)
	}
}

func TestCompatDispatchUnknownTransientFault(t *testing.T) {
	dispatcher := NewCompatDispatcher(httpAuthority{actorForHTTP(t)}, &fakeCompatPort{err: errors.New("boom")})
	request := env(1864, nil, time.Unix(500, 0).UTC())
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 500 {
		t.Fatalf("unknown fault: %+v", response)
	}
}
