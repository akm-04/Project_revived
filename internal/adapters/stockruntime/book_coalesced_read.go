package stockruntime

import (
	"context"
	"fmt"
	"slices"

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

func (c *coalescedBookRead) OwnsComposeItem(ctx context.Context, itemID int64, op operation.Context) (bool, error) {
	return c.Service.OwnsComposeItem(ctx, itemID, op)
}

func (c *coalescedBookRead) Read(ctx context.Context, actor identity.ActorContext, mid uint16, op operation.Context) (map[string]any, error) {
	// The flight fences only its leader, so callers share it only with the same fence inputs.
	key := fmt.Sprintf("%d:%d:%s:%s:%d:%d:%d", int64(actor.PlayerID), mid, actor.ContextID.UUID(), actor.SessionID.UUID(),
		actor.ContextGeneration, actor.ContextLivenessVersion, actor.SessionLivenessVersion)
	value, flightErr, _ := c.flights.Do(key, func() (any, error) {
		return c.Service.Read(context.WithoutCancel(ctx), actor, mid, op)
	})
	if ownErr := ctx.Err(); ownErr != nil {
		return nil, ownErr
	}
	if flightErr != nil {
		return nil, flightErr
	}
	body, ok := value.(map[string]any)
	if !ok {
		return nil, app.ErrUnavailable
	}
	cloned, ok := cloneBookReply(body).(map[string]any)
	if !ok {
		return nil, app.ErrUnavailable
	}
	return cloned, nil
}

// cloneBookReply gives each caller an owned container graph, because the stock
// reply decorator writes economy and mission fields into the returned body.
func cloneBookReply(value any) any {
	switch typed := value.(type) {
	case map[string]any:
		cloned := make(map[string]any, len(typed))
		for key, item := range typed {
			cloned[key] = cloneBookReply(item)
		}
		return cloned
	case map[string]int64:
		cloned := make(map[string]int64, len(typed))
		for key, item := range typed {
			cloned[key] = item
		}
		return cloned
	case []any:
		cloned := make([]any, len(typed))
		for index, item := range typed {
			cloned[index] = cloneBookReply(item)
		}
		return cloned
	case []int64:
		return slices.Clone(typed)
	default:
		return value
	}
}
