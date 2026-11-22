package otarelease

import (
	"context"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReleaseExistsStore answers the exact-version existence read.
type ReleaseExistsStore interface {
	ReleaseExistsTx(context.Context, tx.Queryer, string) (bool, error)
}

// ReleaseExistence is the ota.release read reply.
type ReleaseExistence struct {
	Version string `json:"version"`
	Exists  bool   `json:"exists"`
}

// ReleaseLookup is the ota.release read: whether a number exists in any state,
// so a WITHDRAWN or SUPERSEDED release is refused before any build work
// (L4f fix 2).
type ReleaseLookup struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      ReleaseExistsStore
}

func (lookup ReleaseLookup) Exists(ctx context.Context, versionText string) (ReleaseExistence, error) {
	version, err := domain.ParseVersion(versionText)
	if err != nil {
		return ReleaseExistence{}, operator.Refuse(operator.CodeReadInvalid, err.Error(), nil)
	}
	if lookup.Store == nil || lookup.Runner.DB == nil {
		return ReleaseExistence{}, ErrUnavailable
	}
	current, err := lookup.Operations.New(policy.Set{})
	if err != nil {
		return ReleaseExistence{}, err
	}
	var exists bool
	_, err = lookup.Runner.Run(ctx, current, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		found, readErr := lookup.Store.ReleaseExistsTx(ctx, scope.Tx, version.String())
		if readErr == nil {
			exists = found
		}
		return readErr
	})
	if err != nil {
		return ReleaseExistence{}, err
	}
	return ReleaseExistence{Version: version.String(), Exists: exists}, nil
}
