package contentstore

import (
	"context"
	"encoding/hex"
	"errors"
	"strings"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) BindCharacterBootstrapOperation(ctx context.Context, q tx.Queryer, op operation.Context) (operation.Context, error) {
	if q == nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, errors.New("invalid bootstrap content binding")
	}
	revision, bound := op.Policies.Get("content")
	if !bound {
		var err error
		revision, err = s.ActiveRevision(ctx, q)
		if err != nil {
			return operation.Context{}, err
		}
	}
	decoded, err := hex.DecodeString(revision)
	if err != nil || len(decoded) != 32 || strings.ToLower(revision) != revision {
		return operation.Context{}, errors.New("invalid bootstrap content revision")
	}
	if bound {
		return op, nil // Never reread the active pointer on a retry.
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})
	op.Policies, err = policy.NewSet(refs...)
	return op, err
}

var _ appboot.CharacterBootstrapOperationBinder = Store{}
