package guildbroadcast

import (
	"context"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ImmutableSourceReader composes only owner ports. It proves the committed
// source/receipt/all bindings before exposing fixed facts to I5. No Guild lock
// or mutable membership query is involved.
type ImmutableSourceReader struct {
	Store    SourceStore
	Receipts receipt.Store
	Content  ContentReader
}

func (r ImmutableSourceReader) ReadGuildBroadcastMailSourceTx(c context.Context, q tx.Queryer, id ids.UUID, pid identity.PlayerID) (gb.Source, gb.Binding, error) {
	if r.Store == nil || r.Receipts == nil || r.Content == nil {
		return gb.Source{}, gb.Binding{}, ErrConflict
	}
	s, ok, e := r.Store.ReadSourceTx(c, q, id)
	if e != nil {
		return s, gb.Binding{}, e
	}
	if !ok {
		return s, gb.Binding{}, ErrConflict
	}
	p, e := r.Content.ReadBroadcastPolicy(c, q, s.ContentRevision)
	if e != nil {
		return s, gb.Binding{}, e
	}
	if p.Validate() != nil || p.Revision != s.ContentRevision || p.GuildCoreRevision != s.GuildCoreRevision || p.PolicyID != s.PolicyID {
		return s, gb.Binding{}, ErrContent
	}
	rr, ok, e := r.Receipts.FindTx(c, q, sourceReceipt(s.LeaderID, id))
	if e != nil {
		return s, gb.Binding{}, e
	}
	rid, e2 := r.Store.ReadSourceReceiptIDTx(c, q, id)
	fp, e3 := receipt.FingerprintRequest(s.Request)
	result, decodeErr := decodeSubmitResult(rr.ResultPayload)
	if e2 != nil || e3 != nil || !ok || rr.Validate() != nil || rr.ID != rid || rr.Identity != sourceReceipt(s.LeaderID, id) || rr.OperationClass != "I7A8A_GUILD_SOURCE" || rr.ResultSchema != "gxb.guild-broadcast.submit.v1" || rr.PolicyVersion != s.PolicyID || rr.RequestFingerprint != fp || rr.OperationStartedAt.UnixMicro() != s.Operation.StartedAt.UnixMicro() || !rr.OperationPolicyRefs.Equal(s.Operation.Policies) || decodeErr != nil || result != (SubmitResult{SourceID: id, RecipientCount: len(s.Recipients)}) {
		return s, gb.Binding{}, ErrConflict
	}
	var bound gb.Binding
	found := false
	for _, m := range s.Recipients {
		b, ok, e := r.Store.ReadBindingTx(c, q, id, m.PlayerID)
		if e != nil {
			return s, b, e
		}
		if !ok || b.Validate() != nil {
			return s, b, ErrConflict
		}
		if m.PlayerID == pid {
			bound = b
			found = true
		}
	}
	if !found {
		return s, bound, ErrConflict
	}
	return s, bound, nil
}
