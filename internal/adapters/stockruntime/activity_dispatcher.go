package stockruntime

import (
	"context"
	"net/http"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/activity"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	activityproj "gxb.local/backend/v2/internal/projection/activity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ActivityLevelReader reads the actor's directory level through a caller
// snapshot, so a provider projecting there never opens a second connection.
type ActivityLevelReader interface {
	PlayerLevelTx(context.Context, tx.Queryer, identity.PlayerID) (int64, bool, error)
}

// ActivityDispatcher exposes only the read-only I6B ActivityDirectory surface.
// Gameplay child owners remain responsible for their own mutations and details.
type ActivityDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   appactivity.Runtime
	Reads     tx.Runner
	Levels    ActivityLevelReader
}

func (d ActivityDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority == nil {
		return failureReply(defect(nil))
	}
	if req.Envelope.Claims.Token == "" {
		return failureReply(sessionFailure())
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		return authFailure(err)
	}
	if req.Envelope.Claims.Region != int64(actor.LogicalServerID) {
		return failureReply(refusal(unprovenRefusalCode))
	}

	switch req.Envelope.MID {
	case 229:
		rows, err := d.list(ctx, actor, req.Envelope.Operation)
		if err != nil {
			return failureFromRows(nil, err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.List(rows)}
	case 234:
		id, err := requiredInt64(req.Envelope.Params, "activity_id")
		if err != nil || id <= 0 {
			return failureReply(malformed("invalid_activity_id"))
		}
		row, ok, err := d.lookup(ctx, actor, id, req.Envelope.Operation)
		if err != nil {
			return failureFromRows(nil, err)
		}
		if !ok {
			return failureReply(refusal(unprovenRefusalCode))
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.Row(row)}
	default:
		return failureReply(refusal(unprovenRefusalCode))
	}
}

func (d ActivityDispatcher) list(ctx context.Context, actor identity.ActorContext, op operation.Context) ([]activity.Projection, error) {
	if d.Reads.DB == nil || d.Service.Directory.Registry.Len() == 0 {
		return d.Service.List(ctx, actor)
	}
	at, err := d.Service.Time.Now(ctx)
	if err != nil {
		return nil, err
	}
	var rows []activity.Projection
	_, err = d.Reads.Run(ctx, op, appi5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		var readErr error
		rows, readErr = d.Service.Directory.ListAt(c, actor, at, d.level(scope.Tx))
		return readErr
	})
	return rows, err
}

func (d ActivityDispatcher) lookup(ctx context.Context, actor identity.ActorContext, tableID int64, op operation.Context) (activity.Projection, bool, error) {
	if d.Reads.DB == nil || !d.Service.Directory.Registered(tableID) {
		return d.Service.Lookup(ctx, actor, tableID)
	}
	at, err := d.Service.Time.Now(ctx)
	if err != nil {
		return activity.Projection{}, false, err
	}
	var row activity.Projection
	var found bool
	_, err = d.Reads.Run(ctx, op, appi5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, scope tx.Scope) error {
		var readErr error
		row, found, readErr = d.Service.Directory.LookupAt(c, actor, at, tableID, d.level(scope.Tx))
		return readErr
	})
	return row, found, err
}

func (d ActivityDispatcher) level(q tx.Queryer) appactivity.PlayerLevel {
	if d.Levels == nil {
		return nil
	}
	return func(c context.Context, pid identity.PlayerID) (int64, bool, error) {
		return d.Levels.PlayerLevelTx(c, q, pid)
	}
}
