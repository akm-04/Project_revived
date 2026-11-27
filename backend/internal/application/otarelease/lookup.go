package otarelease

import (
	"context"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReleaseStatusStore answers the exact-version read with the row's lane and
// state; a REPLACED row is never reported (OA-10).
type ReleaseStatusStore interface {
	ReleaseStatusTx(context.Context, tx.Queryer, string) (bool, string, string, error)
}

// ReleaseExistence is the ota.release read reply. Lane and State are set only
// when the number exists.
type ReleaseExistence struct {
	Version string `json:"version"`
	Exists  bool   `json:"exists"`
	Lane    string `json:"lane,omitempty"`
	State   string `json:"state,omitempty"`
}

// ReleaseLookup is the ota.release read: whether a number exists in any state,
// so a WITHDRAWN or SUPERSEDED release is refused before any build work
// (L4f fix 2), with the lane and state that the rollback reuse rule needs.
type ReleaseLookup struct {
	Store ReleaseStatusStore
}

func (lookup ReleaseLookup) Exists(ctx context.Context, versionText string) (ReleaseExistence, error) {
	version, err := domain.ParseVersion(versionText)
	if err != nil {
		return ReleaseExistence{}, operator.Refuse(operator.CodeReadInvalid, err.Error(), nil)
	}
	if lookup.Store == nil {
		return ReleaseExistence{}, ErrUnavailable
	}
	found, lane, state, err := lookup.Store.ReleaseStatusTx(ctx, nil, version.String())
	if err != nil {
		return ReleaseExistence{}, err
	}
	reply := ReleaseExistence{Version: version.String(), Exists: found}
	if found {
		reply.Lane = lane
		reply.State = state
	}
	return reply, nil
}
