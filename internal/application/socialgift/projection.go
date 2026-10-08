package socialgift

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// GiftNoticeValidityTx is a pure owner read. Visibility never owns entitlement.
// Validate the full recognized batch before the composer truncates its window.
func (s Service) GiftNoticeValidityTx(c context.Context, q tx.Queryer, pid identity.PlayerID, ns []socialinbox.Notice) (map[socialinbox.NoticeID]bool, error) {
	if q == nil || s.Store == nil || s.Content == nil || !pid.Valid() {
		return nil, ErrInvalid
	}
	out := map[socialinbox.NoticeID]bool{}
	for _, n := range ns {
		if n.RecipientPlayerID != pid || socialinbox.ValidateGiftLifecycle(n) != nil {
			return nil, ErrConflict
		}
		u, e := ids.ParseUUID(n.Source.Key)
		if e != nil || u.String() != n.Source.Key {
			return nil, ErrConflict
		}
		v, ok, e := s.Store.ReadTransfer(c, q, u)
		if e != nil {
			return nil, e
		}
		if !ok || v.Validate() != nil || v.NoticeID != n.NoticeID || socialinbox.MatchGift(n, v.Descriptor()) != nil {
			return nil, ErrConflict
		}
		content, e := s.Content.ReadGiftContent(c, q, v.RewardRevision)
		if e != nil {
			return nil, e
		}
		if content.Validate() != nil || !content.Compatible(v) {
			return nil, ErrContent
		}
		if v.ClaimOperation.IsZero() != n.Active {
			return nil, ErrConflict
		}
		out[n.NoticeID] = n.Active
	}
	return out, nil
}
