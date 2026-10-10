package guildinvite

import "gxb.local/backend/v2/internal/foundation/ids"

// CoveredEvidence binds the retained owner payloads and Foundation records
// already validated by each committed target page. Later recovery compares all
// covered payloads/receipts, so an earlier-page restore cannot hide corruption.
type CoveredEvidence struct{ SourcePayloads, TargetPayloads, Receipts SetWitness }

func (v CoveredEvidence) Validate(covered SetWitness) error {
	if v.SourcePayloads.Validate() != nil || v.TargetPayloads.Validate() != nil || v.Receipts.Validate() != nil || v.SourcePayloads.Count != covered.Count || v.TargetPayloads.Count != covered.Count || v.Receipts.Count < 1 {
		return ErrEvidence
	}
	return nil
}

type OwnerPayloadSet struct {
	Payloads   SetWitness
	ReceiptIDs []ids.UUID
}
