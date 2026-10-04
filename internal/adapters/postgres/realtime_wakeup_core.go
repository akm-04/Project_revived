package postgres

import (
	"context"
	"errors"
	"time"

	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RealtimeWakeupChannel is a V2 mechanism namespace, not recovered gameplay
// truth. No production route is activated by I7A-2 merely because this channel
// and listener foundation exist.
const RealtimeWakeupChannel = "gxb1_realtime_wakeup_v1"

const DefaultRealtimeWakeupRetryDelay = 250 * time.Millisecond

// EmitRealtimeWakeup emits only a bounded reference envelope. Passing the
// caller-owned transaction Execer preserves PostgreSQL's commit-coupled NOTIFY
// behavior when a future owner emits after its canonical state mutation.
func EmitRealtimeWakeup(ctx context.Context, exec tx.Execer, e appwakeup.Envelope) error {
	if exec == nil {
		return errors.New("nil realtime wakeup execer")
	}
	payload, err := e.Encode()
	if err != nil {
		return err
	}
	_, err = exec.Exec(ctx, `SELECT pg_notify($1,$2)`, RealtimeWakeupChannel, string(payload))
	return err
}

type wakeupSession interface {
	Listen(context.Context) error
	Wait(context.Context) (string, error)
	Close()
}

type wakeupFactory interface {
	Acquire(context.Context) (wakeupSession, error)
}

func runRealtimeWakeupListener(ctx context.Context, factory wakeupFactory, registry appwakeup.Registry, retryDelay time.Duration) error {
	if factory == nil || retryDelay < 0 {
		return errors.New("invalid realtime wakeup listener configuration")
	}
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		session, err := factory.Acquire(ctx)
		if err == nil {
			retry, runErr := consumeRealtimeWakeups(ctx, session, registry)
			session.Close()
			if !retry {
				return runErr
			}
			err = runErr
		}
		if err := ctx.Err(); err != nil {
			return err
		}
		if retryDelay == 0 {
			continue
		}
		t := time.NewTimer(retryDelay)
		select {
		case <-ctx.Done():
			if !t.Stop() {
				<-t.C
			}
			return ctx.Err()
		case <-t.C:
		}
	}
}

// consumeRealtimeWakeups returns retry=true only for connection/listener loss.
// Malformed/unknown route input fails closed to the caller rather than being
// silently discarded as if canonical delivery had succeeded.
func consumeRealtimeWakeups(ctx context.Context, session wakeupSession, registry appwakeup.Registry) (bool, error) {
	if session == nil {
		return true, errors.New("nil realtime wakeup session")
	}
	if err := session.Listen(ctx); err != nil {
		return true, err
	}
	for {
		payload, err := session.Wait(ctx)
		if err != nil {
			return true, err
		}
		e, err := appwakeup.Decode([]byte(payload))
		if err != nil {
			return false, err
		}
		if err := registry.Dispatch(ctx, e); err != nil {
			return false, err
		}
	}
}
