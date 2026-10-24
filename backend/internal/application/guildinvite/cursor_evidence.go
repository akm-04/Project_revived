package guildinvite

import (
	"context"
	"fmt"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func CursorReceiptIdentity(m gi.Marker, r gi.CursorRequest) receipt.Identity {
	return receipt.Identity{OwnerKind: "guild", OwnerKey: fmt.Sprint(m.GuildID), Domain: "guild-invite", Operation: "marker_ack", SemanticKey: fmt.Sprintf("%s:cursor:%d:%d", m.Operation.ID.String(), r.From, r.To)}
}

// This checks the retained source/Kernel part only. A cleanup/recovery caller
// must additionally match the typed target set before trusting covered progress.
func (r SourceReader) ValidateCursorEvidenceTx(c context.Context, q tx.Queryer, m gi.Marker, p gi.MarkerProgress) error {
	if p.Validate() != nil || p.MarkerID != m.Operation.ID || p.MaxIssueSerial != m.MaxIssueSerial {
		return gi.ErrEvidence
	}
	if p.CursorProof == nil {
		return nil
	}
	proof := *p.CursorProof
	if proof.Validate(m) != nil {
		return gi.ErrEvidence
	}
	identity := CursorReceiptIdentity(m, proof.Request)
	rr, ok, e := r.Receipts.FindTx(c, q, identity)
	if e != nil {
		return e
	}
	fp, e := proof.Request.Fingerprint(m)
	if e != nil {
		return e
	}
	decoded, de := gi.DecodeCursorProof(rr.ResultPayload, m)
	if !ok || de != nil || decoded != proof || rr.Validate() != nil || rr.RetainUntil != nil || rr.ID != proof.ReceiptID || rr.Identity != identity || rr.RequestFingerprint != fp || rr.OperationClass != "I7A8B_GUILD_MARKER_ACK" || rr.ResultSchema != "gxb.guild-invite.marker-ack.v1" || rr.PolicyVersion != m.PolicyID || rr.ActorAccountUID != m.ActorAccountUID || rr.ContextID != m.Core.ContextID || rr.OperationStartedAt.UnixMicro() != m.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(m.Operation.Policies) {
		return gi.ErrEvidence
	}
	witness, e := r.Store.SourceSetThroughCursorTx(c, q, m, p.CursorSerial)
	if e != nil {
		return e
	}
	if witness != proof.Request.Covered {
		return gi.ErrEvidence
	}
	return nil
}
