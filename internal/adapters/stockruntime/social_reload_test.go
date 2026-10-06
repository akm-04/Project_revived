package stockruntime

import (
	"context"
	"errors"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreload"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"sync"
	"testing"
	"time"
)

type reloadQuery struct {
	intent socialreload.Intent
	ok     bool
	err    error
}

func (q reloadQuery) Reload(context.Context, sr.ReloadReference, operation.Context) (socialreload.Intent, bool, error) {
	return q.intent, q.ok, q.err
}

type deliveryClock struct{}

func (deliveryClock) Now(context.Context) (time.Time, error) { return time.Now(), nil }

type deliveryAuthority struct{ bad bool }

func (a deliveryAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	if a.bad {
		return errors.New("stale")
	}
	return nil
}
func TestSocialPayloadStrictAndZeroPresence(t *testing.T) {
	obj := func(props ...amf3.Property) *amf3.Object { return &amf3.Object{Properties: props} }
	good := obj(amf3.Property{Name: "player_id", Value: 0.0}, amf3.Property{Name: "friend_req", Value: 1.0})
	if e := ValidateSocialReload(good); e != nil {
		t.Fatal(e)
	}
	for _, bad := range []any{nil, obj(amf3.Property{Name: "friend_req", Value: 1}), obj(amf3.Property{Name: "player_id", Value: 1}, amf3.Property{Name: "friend_req", Value: 1}), obj(amf3.Property{Name: "player_id", Value: 0}, amf3.Property{Name: "blacklist", Value: 1}), obj(amf3.Property{Name: "player_id", Value: 0}, amf3.Property{Name: "friend_req", Value: 1}, amf3.Property{Name: "friend_notice", Value: 1}), obj(amf3.Property{Name: "player_id", Value: 0}, amf3.Property{Name: "player_id", Value: 0})} {
		if ValidateSocialReload(bad) == nil {
			t.Fatal(bad)
		}
	}
	reg, e := NewSocialEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	if e := reg.ValidateDirect(mids.MIDForceReload, rt.Guild, good); e == nil {
		t.Fatal("wrong role")
	}
}
func TestSocialWorldFanoutCanonicalReadAndRetirement(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, _ := NewSocialEventRegistry()
	ref := sr.ReloadReference{Recipient: 100001, Actor: 200001, RootVersion: 2, Purpose: sr.ReloadAccept, First: 100001, Second: 200001, Generation: 1}
	raw, _ := ref.Encode()
	handler := SocialReloadHandler{Service: reloadQuery{intent: socialreload.Intent{Recipient: 100001, Purpose: sr.ReloadAccept, ObservedAt: time.Now()}, ok: true}, Operations: operation.Factory{Clock: clock.System{}}, Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10}
	frames := make(chan rt.Frame, 4)
	fail := make(chan error, 2)
	var readers sync.WaitGroup
	for _, cid := range []string{"33333333-3333-4333-8333-333333333333", "55555555-5555-4555-8555-555555555555"} {
		writer, _, client := newRegistryPipeWriter(t)
		defer client.Close()
		_, e := registry.Replace(registryAdmission(t, cid, 100001, domainrt.World, 1), writer)
		if e != nil {
			t.Fatal(e)
		}
		readers.Add(1)
		go func(c net.Conn) {
			defer readers.Done()
			decoder, _ := rt.NewStreamDecoder(limits.Default())
			count := 0
			buf := make([]byte, 4096)
			c.SetReadDeadline(time.Now().Add(3 * time.Second))
			for count < 2 {
				n, e := c.Read(buf)
				if e != nil {
					fail <- e
					return
				}
				out, e := decoder.Feed(buf[:n])
				if e != nil {
					fail <- e
					return
				}
				for _, f := range out {
					frames <- f
					count++
				}
			}
		}(client)
	}
	if e := handler.ReloadAndDeliver(context.Background(), raw); e != nil {
		t.Fatal(e)
	}
	readers.Wait()
	close(fail)
	for e := range fail {
		t.Fatal(e)
	}
	if len(frames) != 4 {
		t.Fatal(len(frames))
	}
	for i := 0; i < 4; i++ {
		f := <-frames
		if f.MID != mids.MIDForceReload || ValidateSocialReload(f.Params) != nil {
			t.Fatal(f)
		}
	}
	handler.Service = reloadQuery{err: errors.New("canonicalreadfailed")}
	if e := handler.ReloadAndDeliver(context.Background(), raw); e == nil {
		t.Fatal("canonical failure hidden")
	}
	handler.Service = reloadQuery{}
	if e := handler.ReloadAndDeliver(context.Background(), raw); e != nil {
		t.Fatal(e)
	}
	registry.CloseAll()
	if len(registry.ByPlayerRole(100001, domainrt.World)) != 0 {
		t.Fatal("shutdown left handles")
	}
}

func TestSocialStaleWorldRetiredGuildUntouchedAndAuthorityFailurePropagates(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, _ := NewSocialEventRegistry()
	ref := sr.ReloadReference{Recipient: 100001, Actor: 200001, RootVersion: 2, Purpose: sr.ReloadRequest, First: 200001, Second: 100001, Generation: 1}
	raw, _ := ref.Encode()
	worldWriter, _, worldClient := newRegistryPipeWriter(t)
	defer worldClient.Close()
	world, e := registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1), worldWriter)
	if e != nil {
		t.Fatal(e)
	}
	h := SocialReloadHandler{Service: reloadQuery{intent: socialreload.Intent{Recipient: 100001, Purpose: sr.ReloadRequest, ObservedAt: time.Now()}, ok: true}, Operations: operation.Factory{Clock: clock.System{}}, Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{bad: true}, Time: deliveryClock{}, MaxHandles: 4}
	if e := h.ReloadAndDeliver(context.Background(), raw); e == nil {
		t.Fatal("nonstale authority error hidden")
	}
	if !registry.IsCurrent(world) {
		t.Fatal("authority transient error retired canonical handle")
	}
	h.IsStaleActor = func(error) bool { return true }
	if e := h.ReloadAndDeliver(context.Background(), raw); e != nil || registry.IsCurrent(world) {
		t.Fatal("staleWORLD notretired", e)
	}
}
func TestSocialSlowWriterBoundedAndReplacementFence(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, _ := NewSocialEventRegistry()
	ref := sr.ReloadReference{Recipient: 100001, Actor: 200001, RootVersion: 2, Purpose: sr.ReloadRequest, First: 200001, Second: 100001, Generation: 1}
	raw, _ := ref.Encode()
	writer, _, client := newRegistryPipeWriter(t)
	defer client.Close()
	old, _ := registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1), writer)
	h := SocialReloadHandler{Service: reloadQuery{intent: socialreload.Intent{Recipient: 100001, Purpose: sr.ReloadRequest, ObservedAt: time.Now()}, ok: true}, Operations: operation.Factory{Clock: clock.System{}}, Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 4}
	c, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	at := time.Now()
	if e := h.ReloadAndDeliver(c, raw); e != nil {
		t.Fatal(e)
	}
	if time.Since(at) > time.Second {
		t.Fatal("slow writer exceededbudget")
	}
	nextWriter, _, nextClient := newRegistryPipeWriter(t)
	defer nextClient.Close()
	next, e := registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 2), nextWriter)
	if e != nil {
		t.Fatal(e)
	}
	if registry.IsCurrent(old) || !registry.IsCurrent(next) {
		t.Fatal("replacement generation notfenced")
	}
}
