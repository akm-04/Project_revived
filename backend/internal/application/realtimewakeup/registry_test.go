package realtimewakeup

import (
	"context"
	"errors"
	"strings"
	"testing"
)

func TestEnvelopeIsBoundedVersionedAndReferenceOnly(t *testing.T) {
	e := Envelope{Version: EnvelopeVersion, Route: "social.friend", Ref: "player:100001"}
	b, err := e.Encode()
	if err != nil {
		t.Fatal(err)
	}
	got, err := Decode(b)
	if err != nil || got != e {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	for _, raw := range [][]byte{
		[]byte(`{"v":2,"route":"social.friend","ref":"x"}`),
		[]byte(`{"v":1,"route":"social.friend","ref":"x","value":99}`),
		[]byte(`{"v":1,"route":"social friend","ref":"x"}`),
		[]byte(`{"v":1,"route":"social.friend","ref":""}`),
		[]byte(strings.Repeat("x", MaxEnvelopeBytes+1)),
	} {
		if _, err := Decode(raw); !errors.Is(err, ErrInvalidEnvelope) {
			t.Fatalf("raw=%q err=%v", raw, err)
		}
	}
}

func TestRegistryStartsEmptyAndRoutesOnlyExactCanonicalReloadHandler(t *testing.T) {
	empty, err := NewRegistry()
	if err != nil {
		t.Fatal(err)
	}
	e := Envelope{Version: 1, Route: "social.friend", Ref: "p:7"}
	if err := empty.Dispatch(context.Background(), e); !errors.Is(err, ErrUnknownRoute) {
		t.Fatalf("empty registry err=%v", err)
	}
	var got string
	r, err := NewRegistry(Registration{Route: "social.friend", Handler: RouteHandlerFunc(func(_ context.Context, ref string) error {
		got = ref
		return nil
	})})
	if err != nil {
		t.Fatal(err)
	}
	if err := r.Dispatch(context.Background(), e); err != nil {
		t.Fatal(err)
	}
	if got != "p:7" {
		t.Fatalf("ref=%q", got)
	}
	if _, err := NewRegistry(
		Registration{Route: "social.friend", Handler: RouteHandlerFunc(func(context.Context, string) error { return nil })},
		Registration{Route: "social.friend", Handler: RouteHandlerFunc(func(context.Context, string) error { return nil })},
	); !errors.Is(err, ErrDuplicateRoute) {
		t.Fatalf("duplicate route err=%v", err)
	}
}

type nilRouteHandler struct{}

func (*nilRouteHandler) ReloadAndDeliver(context.Context, string) error { return nil }

func TestRegistryRejectsTypedNilHandler(t *testing.T) {
	var h *nilRouteHandler
	if _, err := NewRegistry(Registration{Route: "social.friend", Handler: h}); !errors.Is(err, ErrInvalidRoute) {
		t.Fatalf("typed nil handler err=%v", err)
	}
	if _, err := NewRegistry(Registration{Route: "social.friend", Handler: RouteHandlerFunc(nil)}); !errors.Is(err, ErrInvalidRoute) {
		t.Fatalf("nil function handler err=%v", err)
	}
}
