package guildinvitetarget

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	ref "gxb.local/backend/v2/internal/application/socialreloadref"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) PrepareInviteReloadTx(c context.Context, q tx.Queryer, r ref.ReloadReference) (ref.InviteObservation, bool, error) {
	var out ref.InviteObservation
	if r.Validate() != nil || !s.valid() || r.Purpose != ref.ReloadInviteMaterialized && r.Purpose != ref.ReloadInviteInvalidated {
		return out, false, gi.ErrEvidence
	}
	v, e := s.Sources.ReadIssueEvidenceTx(c, q, r.SourceID)
	if e != nil {
		return out, false, e
	}
	if v.Tuple.Recipient != r.Recipient {
		return out, false, gi.ErrEvidence
	}
	key, _ := v.Tuple.SourceKey()
	n, ok, e := s.Store.ReadInviteNoticeSourceTx(c, q, r.Recipient, socialinbox.SourceKey{Kind: gi.SourceKind, Key: key})
	if e != nil {
		return out, false, e
	}
	if !ok {
		return out, false, nil
	}
	if socialinbox.MatchInvite(n, v) != nil {
		return out, false, gi.ErrEvidence
	}
	if r.Purpose == ref.ReloadInviteMaterialized {
		p, ok, e := s.ReadInviteTargetProofTx(c, q, r.SourceID)
		if e != nil {
			return out, false, e
		}
		if !ok || p.State != gi.Materialized || p.RootVersion != r.RootVersion || v.Inviter != r.Actor {
			return out, false, nil
		}
	} else {
		m, e := s.Sources.ReadMarkerEvidenceTx(c, q, r.MarkerID)
		if e != nil {
			return out, false, e
		}
		p, ok, e := s.ReadInviteInvalidationProofTx(c, q, r.MarkerID, r.SourceID)
		if e != nil {
			return out, false, e
		}
		if !ok || !p.Consumed || p.RootVersion != r.RootVersion || m.Actor != r.Actor {
			return out, false, nil
		}
		out.Invalidation = true
	}
	out.Snapshot, e = s.Sources.ReadInviteSnapshotTx(c, q, r.SourceID)
	if e != nil {
		return out, false, e
	}
	out.Active = n.Active
	return out, true, nil
}
