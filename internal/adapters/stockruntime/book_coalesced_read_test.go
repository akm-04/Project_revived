package stockruntime

import (
	"context"
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
