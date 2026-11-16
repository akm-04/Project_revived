package stockruntime

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type countingBookRead struct {
	mu      sync.Mutex
	calls   map[identity.PlayerID]int
	started chan struct{}
	release chan struct{}
	once    sync.Once
}

func (s *countingBookRead) Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error) {
	return app.Result{}, app.ErrUnavailable
}

func (s *countingBookRead) Read(_ context.Context, actor identity.ActorContext, _ uint16, _ operation.Context) (map[string]any, error) {
	s.mu.Lock()
	s.calls[actor.PlayerID]++
	s.mu.Unlock()
	s.once.Do(func() { close(s.started) })
	<-s.release
	return map[string]any{"building_list": map[string]any{}}, nil
}

func (s *countingBookRead) count(player identity.PlayerID) int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.calls[player]
}

type tokenAuthority map[string]identity.ActorContext

func (a tokenAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	return a[token], nil
}

func TestBookCoalescedReadSharesOnePlayerFlight(t *testing.T) {
	actor := actorForHTTP(t)
	service := &countingBookRead{calls: map[identity.PlayerID]int{}, started: make(chan struct{}), release: make(chan struct{})}
	dispatcher := BookDispatcher{Authority: httpAuthority{actor}, Service: NewCoalescedBookRead(service)}
	request := heroReq(t, 1056, nil)

	const readers = 20
	entered := make(chan struct{}, readers)
	var wait sync.WaitGroup
	for i := 0; i < readers; i++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			entered <- struct{}{}
			if got := dispatcher.Dispatch(context.Background(), request); got.HTTPStatus != 200 {
				t.Errorf("concurrent read status=%d", got.HTTPStatus)
			}
		}()
	}
	for i := 0; i < readers; i++ {
		<-entered
	}
	<-service.started
	time.Sleep(50 * time.Millisecond)
	close(service.release)
	wait.Wait()

	if got := service.count(actor.PlayerID); got != 1 {
		t.Fatalf("one player ran the service %d times, want 1", got)
	}
}

type sharedBodyBookRead struct {
	mu      sync.Mutex
	calls   int
	started chan struct{}
	release chan struct{}
	once    sync.Once
	body    map[string]any
}

func (s *sharedBodyBookRead) Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error) {
	return app.Result{}, app.ErrUnavailable
}

func (s *sharedBodyBookRead) Read(ctx context.Context, _ identity.ActorContext, _ uint16, _ operation.Context) (map[string]any, error) {
	s.mu.Lock()
	s.calls++
	s.mu.Unlock()
	s.once.Do(func() { close(s.started) })
	select {
	case <-s.release:
		return s.body, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func TestBookCoalescedReadReturnsIndependentBodies(t *testing.T) {
	actor := actorForHTTP(t)
	service := &sharedBodyBookRead{
		started: make(chan struct{}),
		release: make(chan struct{}),
		body:    map[string]any{"building_list": map[string]any{"desk_info": map[string]any{"is_making": int64(0)}}},
	}
	port := NewCoalescedBookRead(service)

	const readers = 20
	bodies := make([]map[string]any, readers)
	errs := make([]error, readers)
	var wait sync.WaitGroup
	for i := 0; i < readers; i++ {
		wait.Add(1)
		go func(i int) {
			defer wait.Done()
			bodies[i], errs[i] = port.Read(context.Background(), actor, 1056, operation.Context{})
		}(i)
	}
	<-service.started
	time.Sleep(50 * time.Millisecond)
	close(service.release)
	wait.Wait()

	for i, body := range bodies {
		if errs[i] != nil {
			t.Fatalf("reader %d error=%v", i, errs[i])
		}
		body["caller"] = i
		nested, ok := body["building_list"].(map[string]any)
		if !ok {
			t.Fatalf("reader %d body=%#v", i, body)
		}
		nested["caller"] = i
	}
	for i, body := range bodies {
		if body["caller"] != i {
			t.Fatalf("reader %d saw caller=%#v", i, body["caller"])
		}
		if nested := body["building_list"].(map[string]any); nested["caller"] != i {
			t.Fatalf("reader %d saw nested caller=%#v", i, nested["caller"])
		}
	}
}

func TestBookCoalescedReadSurvivesLeaderCancellation(t *testing.T) {
	actor := actorForHTTP(t)
	service := &sharedBodyBookRead{
		started: make(chan struct{}),
		release: make(chan struct{}),
		body:    map[string]any{"building_list": map[string]any{}},
	}
	port := NewCoalescedBookRead(service)
	leaderContext, cancelLeader := context.WithCancel(context.Background())
	leaderDone := make(chan error, 1)
	go func() {
		_, err := port.Read(leaderContext, actor, 1056, operation.Context{})
		leaderDone <- err
	}()
	<-service.started
	const followers = 4
	followerDone := make(chan error, followers)
	for i := 0; i < followers; i++ {
		go func() {
			_, err := port.Read(context.Background(), actor, 1056, operation.Context{})
			followerDone <- err
		}()
	}
	time.Sleep(50 * time.Millisecond)
	cancelLeader()
	close(service.release)

	if err := <-leaderDone; !errors.Is(err, context.Canceled) {
		t.Fatalf("leader error=%v, want context.Canceled", err)
	}
	for i := 0; i < followers; i++ {
		if err := <-followerDone; err != nil {
			t.Fatalf("follower %d error=%v", i, err)
		}
	}
}

func TestBookCoalescedReadSeparatesPlayers(t *testing.T) {
	first := actorForHTTP(t)
	second := first
	second.PlayerID = first.PlayerID + 1
	service := &countingBookRead{calls: map[identity.PlayerID]int{}, started: make(chan struct{}), release: make(chan struct{})}
	dispatcher := BookDispatcher{Authority: tokenAuthority{"first": first, "second": second}, Service: NewCoalescedBookRead(service)}
	firstRequest := heroReq(t, 1056, nil)
	firstRequest.Envelope.Claims.Token = "first"
	secondRequest := heroReq(t, 1056, nil)
	secondRequest.Envelope.Claims.Token = "second"

	var wait sync.WaitGroup
	for _, request := range []httpedge.DispatchRequest{firstRequest, secondRequest} {
		wait.Add(1)
		go func(request httpedge.DispatchRequest) {
			defer wait.Done()
			if got := dispatcher.Dispatch(context.Background(), request); got.HTTPStatus != 200 {
				t.Errorf("read status=%d", got.HTTPStatus)
			}
		}(request)
	}
	<-service.started
	time.Sleep(50 * time.Millisecond)
	close(service.release)
	wait.Wait()

	if service.count(first.PlayerID) != 1 || service.count(second.PlayerID) != 1 {
		t.Fatalf("distinct players shared a flight: %v", service.calls)
	}
}

// A-075: the flight fences only its leader's context, so a caller with another
// context or liveness version of the same player must not join it.
func TestBookCoalescedReadSeparatesActorContexts(t *testing.T) {
	leader := actorForHTTP(t)
	stale := leader
	stale.ContextLivenessVersion++
	service := &countingBookRead{calls: map[identity.PlayerID]int{}, started: make(chan struct{}), release: make(chan struct{})}
	port := NewCoalescedBookRead(service)

	var wait sync.WaitGroup
	wait.Add(2)
	go func() {
		defer wait.Done()
		_, _ = port.Read(context.Background(), leader, 1056, operation.Context{})
	}()
	<-service.started
	go func() {
		defer wait.Done()
		_, _ = port.Read(context.Background(), stale, 1056, operation.Context{})
	}()
	time.Sleep(50 * time.Millisecond)
	close(service.release)
	wait.Wait()

	if got := service.count(leader.PlayerID); got != 2 {
		t.Fatalf("service reads=%d, want 2: a second actor context joined the first one's fenced flight", got)
	}
}
