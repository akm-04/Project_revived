package stockruntime

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"sync"
	"testing"
	"time"
)

type recordingPresence struct {
	mutex       sync.Mutex
	admittedTTL time.Duration
	renewedTTL  time.Duration
}

func (r *recordingPresence) Admit(_ context.Context, _ operation.Context, _ socialpresence.LeaseRef, ttl time.Duration) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	r.admittedTTL = ttl
	return nil
}

func (r *recordingPresence) Renew(_ context.Context, _ operation.Context, _ socialpresence.LeaseRef, ttl time.Duration) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	r.renewedTTL = ttl
	return nil
}

func (r *recordingPresence) Retire(context.Context, operation.Context, socialpresence.LeaseRef) error {
	return nil
}

// A held HTTP poll keeps the logical socket alive, but it must not shorten the
// presence lease below the stock two-heartbeat budget: general DM admission reads
// presence to find an online recipient, and the stock client only heartbeats
// every 600 s.
func TestHTTPPollPresenceLeaseKeepsStockHeartbeatBudget(t *testing.T) {
	presence := &recordingPresence{}
	server := newRealtimeTestServer(t)
	server.Presence = presence
	server.PresenceOperations = operation.Factory{Clock: clock.System{}}
	server.RealtimeOwnerFence = 1
	instance, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	server.RealtimeInstanceID = instance
	server.Policy.ClientIdleTimeout = 20 * time.Minute
	poll, e := NewHTTPPollServer(t.Context(), server, time.Second, time.Second)
	if e != nil {
		t.Fatal(e)
	}
	defer poll.Close()

	loginSocket(t, poll.Handler(), "alpha", "world", 1)

	presence.mutex.Lock()
	observed := presence.admittedTTL
	presence.mutex.Unlock()
	if observed != server.Policy.ClientIdleTimeout {
		t.Fatalf("presence lease ttl=%s, want the realtime client idle budget %s (poll idle is %s)", observed, server.Policy.ClientIdleTimeout, time.Second)
	}
}
