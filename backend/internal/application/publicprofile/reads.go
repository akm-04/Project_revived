package publicprofile

import (
	"context"
	"encoding/hex"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"time"
)

type Snapshot struct {
	Root            Root
	Present         bool
	ContentRevision string
	ObservedAt      time.Time
}

// Options are the existing Runner witness. Caller supplies one bound revision/read instant.
func (s RootService) ReadSnapshotTx(c context.Context, scope tx.Scope, pid identity.PlayerID, revision string, at time.Time) (Snapshot, error) {
	b, e := hex.DecodeString(revision)
	if scope.Tx == nil || scope.Operation.ID.IsZero() || scope.Operation.StartedAt.IsZero() || scope.Attempt <= 0 || !pid.Valid() || at.IsZero() || e != nil || len(b) != 32 || revision != strings.ToLower(revision) || (scope.Options.Isolation != tx.RepeatableRead && scope.Options.Isolation != tx.Serializable) || s.Store == nil {
		return Snapshot{}, ErrInvalidState
	}
	r, ok, e := s.Store.ReadRootTx(c, scope.Tx, pid)
	if e != nil {
		return Snapshot{}, e
	}
	if ok && (r.Validate() != nil || r.PlayerID != pid) {
		return Snapshot{}, ErrInvalidState
	}
	if !ok {
		r = Root{PlayerID: pid, Preferences: profile.Defaults()}
	}
	return Snapshot{Root: r.Clone(), Present: ok, ContentRevision: revision, ObservedAt: at.UTC()}, nil
}
