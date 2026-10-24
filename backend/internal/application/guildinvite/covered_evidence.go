package guildinvite

import (
	"context"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (r SourceReader) CoveredEvidenceTx(c context.Context, q tx.Queryer, target ProgressTarget, m gi.Marker, cursor int64, covered gi.SetWitness) (gi.CoveredEvidence, error) {
	var out gi.CoveredEvidence
	witness, ok := r.Receipts.(ReceiptWitness)
	if !ok || target == nil {
		return out, gi.ErrEvidence
	}
	source, e := r.Store.CoveredSourcePayloadsTx(c, q, m, cursor)
	if e != nil {
		return out, e
	}
	social, e := target.CoveredTargetPayloadsTx(c, q, m, cursor)
	if e != nil {
		return out, e
	}
	keys := append(source.ReceiptIDs, social.ReceiptIDs...)
	keys = append(keys, m.Core.ID)
	out.SourcePayloads = source.Payloads
	out.TargetPayloads = social.Payloads
	out.Receipts, e = witness.GuildInviteReceiptSetWitnessTx(c, q, keys)
	if e != nil {
		return out, e
	}
	return out, out.Validate(covered)
}
func (r SourceReader) ValidateCoveredEvidenceTx(c context.Context, q tx.Queryer, target ProgressTarget, m gi.Marker, p gi.MarkerProgress) error {
	if p.CursorProof == nil {
		return nil
	}
	got, e := r.CoveredEvidenceTx(c, q, target, m, p.CursorSerial, p.CursorProof.Request.Covered)
	if e != nil {
		return e
	}
	if got != p.CursorProof.Request.Evidence {
		return gi.ErrEvidence
	}
	return nil
}
