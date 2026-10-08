package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
)

type GeneralDMPrivacyProvider struct{ Store Store }

// Caller holds canonical player roots315. Acquire both Social roots360 before
// the directed block363, preserving absent roots without EnsureRoot writes.
func (p GeneralDMPrivacyProvider) ReadGeneralBlockTx(c context.Context, t tx.Tx, sender, recipient identity.PlayerID) (int64, bool, error) {
	if p.Store == nil || t == nil || sender == recipient {
		return 0, false, ErrInvalidState
	}
	ids := []identity.PlayerID{sender, recipient}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	for _, id := range ids {
		r, ok, e := p.Store.LockRootTx(c, t, id)
		if e != nil {
			return 0, false, e
		}
		if ok && (r.Validate() != nil || r.PlayerID != id) {
			return 0, false, ErrInvalidState
		}
	}
	b, ok, e := p.Store.LockBlockTx(c, t, recipient, sender)
	if e != nil || !ok {
		return 0, false, e
	}
	return b.StateVersion, b.Active, nil
}
