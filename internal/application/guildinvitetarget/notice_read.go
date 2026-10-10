package guildinvitetarget

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) ReadImmutableInviteNoticeTx(c context.Context, q tx.Queryer, n socialinbox.Notice) (gi.Issue, error) {
	tuple, e := socialinbox.InviteTuple(n)
	if e != nil || !s.valid() {
		return gi.Issue{}, gi.ErrEvidence
	}
	v, e := s.Sources.ReadIssueTupleEvidenceTx(c, q, tuple)
	if e != nil {
		return v, e
	}
	if socialinbox.MatchInvite(n, v) != nil {
		return v, gi.ErrEvidence
	}
	p, ok, e := s.ReadInviteTargetProofTx(c, q, v.Operation.ID)
	if e != nil {
		return v, e
	}
	if !ok || p.State != gi.Materialized || p.NoticeID != int64(n.NoticeID) {
		return v, gi.ErrEvidence
	}
	return v, nil
}
func (s Service) ReadCurrentInviteNoticeTx(c context.Context, q tx.Queryer, n socialinbox.Notice) (gi.Snapshot, error) {
	v, e := s.ReadImmutableInviteNoticeTx(c, q, n)
	if e != nil {
		return gi.Snapshot{}, e
	}
	return s.Sources.ReadInviteSnapshotTx(c, q, v.Operation.ID)
}

var _ socialinbox.InviteNoticeReader = Service{}
