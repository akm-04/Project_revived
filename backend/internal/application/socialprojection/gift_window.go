package socialprojection

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// The 50-row presentation window follows qualification, never entitlement.
func (s Service) qualifiedWindow(c context.Context, t tx.Tx, p identity.PlayerID) ([]socialinbox.Notice, error) {
	if s.NoticePages == nil || s.Gifts == nil {
		return nil, ErrInvalidRead
	}
	out := []socialinbox.Notice{}
	after := socialinbox.NoticeCursor{}
	evaluated := 0
	for evaluated < 4096 {
		limit := 128
		if 4096-evaluated < limit {
			limit = 4096 - evaluated
		}
		page, e := s.NoticePages.NoticePageTx(c, t, p, after, limit)
		if e != nil {
			return nil, e
		}
		if len(page) > limit {
			return nil, ErrInvalidRead
		}
		gifts := []socialinbox.Notice{}
		prev := after
		for _, n := range page {
			if n.RecipientPlayerID != p || !n.NoticeID.WireSafe() || n.NoticeTime.IsZero() || !prev.At.IsZero() && (n.NoticeTime.After(prev.At) || n.NoticeTime.Equal(prev.At) && n.NoticeID >= prev.ID) {
				return nil, ErrInvalidRead
			}
			prev = socialinbox.NoticeCursor{At: n.NoticeTime, ID: n.NoticeID}
			if n.Source.Kind == socialinbox.GiftSourceKind {
				gifts = append(gifts, n)
			}
		}
		valid, e := s.Gifts.GiftNoticeValidityTx(c, t, p, gifts)
		if e != nil {
			return nil, e
		}
		if len(valid) != len(gifts) {
			return nil, ErrInvalidRead
		}
		for _, n := range page {
			evaluated++
			eligible := false
			switch n.Source.Kind {
			case socialinbox.GiftSourceKind:
				eligible = valid[n.NoticeID]
			case "social-relation.request.v1", "social-relation.friendship.v1":
				if socialinbox.ValidateRelationLifecycle(n) != nil {
					return nil, ErrInvalidRead
				}
				eligible = n.Active
			}
			if eligible && n.RelatedPlayerID.Valid() && !n.RelatedPlayerDeleted && len(out) < 50 {
				out = append(out, n)
			}
		}
		if len(out) == 50 || len(page) < limit {
			return out, nil
		}
		after = prev
	}
	return nil, ErrSearchSaturated
}
