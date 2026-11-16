package stockruntime

import (
	"context"
	"fmt"

	app "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"

	"golang.org/x/sync/singleflight"
)

// coalescedBookRead collapses concurrent hydration reads of one player and MID
// into one service call. Nothing is cached after the in-flight call completes.
type coalescedBookRead struct {
	Service BookPort
	flights singleflight.Group
}

func NewCoalescedBookRead(service BookPort) BookPort {
	return &coalescedBookRead{Service: service}
}

func (c *coalescedBookRead) Command(ctx context.Context, actor identity.ActorContext, command app.Command, op operation.Context) (app.Result, error) {
	return c.Service.Command(ctx, actor, command, op)
}

func (c *coalescedBookRead) Read(ctx context.Context, actor identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	key := fmt.Sprintf("%d:%d", int64(actor.PlayerID), mid)
	value, err, _ := c.flights.Do(key, func() (any, error) {
		return c.Service.Read(ctx, actor, mid, op)
	})
	if err != nil {
		return nil, err
	}
	body, ok := value.(map[string]any)
	if !ok {
		return nil, app.ErrUnavailable
	}
	return body, nil
}
