//go:build postgres

package postgres

import (
	"context"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"time"
)

const SocialReloadRoute = "social.reload.v1"

// SocialWakeupEmitter runs only after the caller reports definite completion.
// The entire batch has one finite budget; delivery failure never repeats state.
type SocialWakeupEmitter struct {
	Pool    *Pool
	OnError func(error)
}

func (s SocialWakeupEmitter) Emit(ctx context.Context, refs []sr.ReloadReference) {
	if len(refs) == 0 {
		return
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	workers := 8
	if len(refs) < workers {
		workers = len(refs)
	}
	jobs := make(chan sr.ReloadReference)
	var wg sync.WaitGroup
	report := func(e error) {
		if e != nil && s.OnError != nil {
			s.OnError(e)
		}
	}
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for r := range jobs {
				raw, e := r.Encode()
				if e != nil {
					report(e)
					continue
				}
				if s.Pool == nil || s.Pool.raw == nil {
					report(sr.ErrInvalidState)
					continue
				}
				e = EmitRealtimeWakeup(ctx, socialWakeupExecer{s.Pool}, wake.Envelope{Version: 1, Route: SocialReloadRoute, Ref: raw})
				report(e)
			}
		}()
	}
send:
	for _, r := range refs {
		select {
		case jobs <- r:
		case <-ctx.Done():
			report(ctx.Err())
			break send
		}
	}
	close(jobs)
	wg.Wait()
}

// Autocommit is deliberate: the gameplay transaction has already completed.
// Reuse the sealed wakeup mechanism without borrowing its listener/owner session.
type socialWakeupExecer struct{ p *Pool }

func (s socialWakeupExecer) Exec(ctx context.Context, q string, args ...any) (tx.CommandTag, error) {
	tag, e := s.p.raw.Exec(ctx, q, args...)
	return tag, normalize(e)
}
