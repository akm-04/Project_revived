package stockruntime

import (
	"context"
	"log"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// sessionActivityTouchTimeout bounds one coalesced identity-activity write; the
// reply never waits for it.
const sessionActivityTouchTimeout = 5 * time.Second

// sessionActivityCacheLimit bounds the per-process touch memory. Clearing it
// only makes a session eligible again earlier, which the owner's conditional
// write still coalesces.
const sessionActivityCacheLimit = 65536

// SessionActivity keeps the identity session behind an authenticated stock
// request inside the presence window that the operator online read uses. A
// playing client talks over the HTTP API, so its session is touched here; the
// HTTP long poll touches the same row. At most one touch per session per
// interval is forwarded, and the owner's conditional write is the cross-process
// bound, so a polling client never writes on every request.
type SessionActivity struct {
	Touch    ActivityToucher
	Interval time.Duration
	// now is the test clock; nil means time.Now.
	now func() time.Time

	mutex sync.Mutex
	last  map[string]time.Time
}

// Wrap decorates one dispatcher with the shared activity throttle.
func (s *SessionActivity) Wrap(next httpedge.Dispatcher) httpedge.Dispatcher {
	if s == nil || s.Touch == nil {
		return next
	}
	return sessionActivityDispatcher{next: next, activity: s}
}

type sessionActivityDispatcher struct {
	next     httpedge.Dispatcher
	activity *SessionActivity
}

func (d sessionActivityDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	response := d.next.Dispatch(ctx, req)
	d.activity.note(ctx)
	return response
}

func (s *SessionActivity) note(ctx context.Context) {
	actor := observability.ActingActor(ctx)
	if actor.SessionID == "" {
		return
	}
	parsed, err := ids.ParseUUID(actor.SessionID)
	if err != nil {
		return
	}
	sessionID, err := identity.SessionIDFrom(parsed)
	if err != nil {
		return
	}
	if !s.due(actor.SessionID) {
		return
	}
	go func() {
		touchContext, cancel := context.WithTimeout(context.WithoutCancel(ctx), sessionActivityTouchTimeout)
		defer cancel()
		if err := s.Touch.TouchActivity(touchContext, sessionID); err != nil {
			log.Printf("stock HTTP request activity touch failed: %v", err)
		}
	}()
}

func (s *SessionActivity) due(session string) bool {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	now := time.Now
	if s.now != nil {
		now = s.now
	}
	at := now()
	if previous, seen := s.last[session]; seen && at.Sub(previous) < s.Interval {
		return false
	}
	if len(s.last) >= sessionActivityCacheLimit {
		s.last = make(map[string]time.Time)
	}
	if s.last == nil {
		s.last = make(map[string]time.Time)
	}
	s.last[session] = at
	return true
}
