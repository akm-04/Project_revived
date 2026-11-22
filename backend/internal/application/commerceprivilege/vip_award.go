package commerceprivilege

import (
	"context"
	"encoding/json"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	vipAwardOperationClass = "I9_10G_VIP_AWARD"
	vipAwardResultSchema   = "gxb.commerce.charge-vip-award.v1"
	vipAwardPolicy         = "I10_CHARGE_VIP_AWARD_V1"
)

// ClaimVIPAward answers stock MID 657 (C11): one VIP level's gift, once.
func (s Charge) ClaimVIPAward(c context.Context, a identity.ActorContext, level int64, op operation.Context) (map[string]any, error) {
	if !s.readyClaim() {
		return nil, d.ErrUnavailable
	}
	if level < 1 || level > 15 {
		return nil, d.ErrChargeRefused
	}
	op, revision, e := s.pin(c, op)
	if e != nil {
		return nil, e
	}
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "commerce-charge", Operation: "vip-award", SemanticKey: strconv.FormatInt(level, 10)}
	fingerprint, e := receipt.FingerprintRequest(struct {
		Player identity.PlayerID
		Server identity.LogicalServerID
		Level  int64
	}{a.PlayerID, a.LogicalServerID, level})
	if e != nil {
		return nil, e
	}
	var out map[string]any
	_, result, e := s.Timed.Run(c, op, tapProfile(), tx.Options{Isolation: tx.Serializable}, tapRetry(), timedReceipt{receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fingerprint}}, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		stored, found, e := s.Receipts.FindTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: id}
			}
			return json.Unmarshal(stored.ResultPayload, &out)
		}
		root, rooted, e := s.Store.ReadPrivilegeTx(c, sc.Tx, a.PlayerID, true)
		if e != nil {
			return e
		}
		if !rooted || root.Validate() != nil || root.VIPLevel < level {
			return d.ErrChargeRefused
		}
		catalog, e := s.Content.ChargeCatalogTx(c, sc.Tx, revision)
		if e != nil {
			return e
		}
		award := catalog.VipAwards[level-1]
		inserted, e := s.Store.ClaimVIPAwardTx(c, sc.Tx, a.PlayerID, level, at)
		if e != nil {
			return e
		}
		if !inserted {
			return d.ErrChargeRefused
		}
		current := sc.Operation.Operation()
		source := grant.SourceIdentity{Domain: "commerce-charge", Operation: "vip-award", BusinessKey: strconv.FormatInt(level, 10), Occurrence: current.ID.String(), PolicyVersion: vipAwardPolicy}
		lines := make([]grant.Line, 0, len(award.Items)+1)
		for index, item := range award.Items {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item, Amount: award.ItemNums[index]})
		}
		if award.Crystal > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: award.Crystal})
		}
		if _, e = s.Grants.SettleGrantTx(c, sc.Tx, a, grant.Plan{PlayerID: a.PlayerID, Source: source, Lines: lines}, current, i5.GrantTxOptions{AllowOverflowMail: true}); e != nil {
			return e
		}
		out = map[string]any{"awards": vipAwardWire(award)}
		raw, e := json.Marshal(out)
		if e != nil {
			return e
		}
		r, e := receipt.New(current, id, vipAwardOperationClass, vipAwardResultSchema, raw, fingerprint)
		if e != nil {
			return e
		}
		r.PolicyVersion = vipAwardPolicy
		_, e = s.Receipts.PutTx(c, sc.Tx, r)
		return e
	})
	if e == nil && result.Reconciled {
		stored, ok := result.Evidence.(receipt.Receipt)
		if !ok {
			return nil, d.ErrUnavailable
		}
		e = json.Unmarshal(stored.ResultPayload, &out)
	}
	return out, e
}

func vipAwardWire(award d.VipAward) []map[string]any {
	out := make([]map[string]any, 0, len(award.Items)+1)
	for index, item := range award.Items {
		out = append(out, map[string]any{"table_id": item, "item_num": award.ItemNums[index]})
	}
	if award.Crystal > 0 {
		out = append(out, map[string]any{"table_id": int64(-1), "item_num": award.Crystal, "crystal": award.Crystal})
	}
	return out
}

func (s Charge) readyClaim() bool {
	return s.Timed.Runner.DB != nil && s.Timed.Binder.Time != nil && s.Store != nil && s.Content != nil && s.Grants != nil && s.Fence != nil && s.Receipts != nil && s.ReceiptRead != nil
}
