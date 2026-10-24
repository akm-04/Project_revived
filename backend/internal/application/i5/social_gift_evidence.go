package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
)

// ReadGrantEvidenceTx validates the owning I5 receipt without settlement,
// activation or source mutation. Absence is never replay authorization.
func (s Service) ReadGrantEvidenceTx(c context.Context, q tx.Queryer, p grant.Plan) (GrantResult, bool, error) {
	fp, e := receiptFingerprintForGrant(p)
	if e != nil {
		return GrantResult{}, false, e
	}
	r, ok, e := s.findGrantReceiptTx(c, q, p, fp)
	if e != nil || !ok {
		return GrantResult{}, ok, e
	}
	v, e := decodeGrantReceiptResult(r)
	return v, true, e
}

// GiftGrantIdentityExistsTx detects an orphaned grant even when source facts
// are missing and their amount cannot be reconstructed. It asserts no outcome.
func (s Service) GiftGrantIdentityExistsTx(c context.Context, q tx.Queryer, pid identity.PlayerID, op ids.UUID) (bool, error) {
	p := grant.Plan{PlayerID: pid, Source: grant.SourceIdentity{Domain: "social-gift", Operation: "claim-batch", BusinessKey: strconv.FormatInt(int64(pid), 10), Occurrence: op.String(), PolicyVersion: "SOCIAL_GIFT_CLAIM_BATCH_V1"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "friendship_coin", Amount: 5}}}
	a, b, e := p.ReceiptIdentities()
	if e != nil {
		return false, e
	}
	_, x, e := s.Receipts.FindTx(c, q, a)
	if e != nil {
		return false, e
	}
	_, y, e := s.Receipts.FindTx(c, q, b)
	return x || y, e
}

func (s Service) VerifyGiftBalanceTx(c context.Context, q tx.Queryer, pid identity.PlayerID) error {
	v, ok, e := s.Store.ReadScalarTx(c, q, pid, "friendship_coin")
	if e != nil {
		return e
	}
	if !ok || v.PlayerID != pid || v.ResourceKey != "friendship_coin" || v.Amount < 0 || v.StateVersion < 1 || v.UpdatedAt.IsZero() {
		return errors.New("missing SocialGift scalar restore evidence")
	}
	return nil
}
