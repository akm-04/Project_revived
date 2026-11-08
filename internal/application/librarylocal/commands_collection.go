package librarylocal

import (
	"context"
	"strconv"

	"gxb.local/backend/v2/internal/application/broadcast"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// claimCGTx inserts the once-per-player CG claim before granting its item row.
func (s Service) claimCGTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog lib.Catalog) ([]i5.Award, error) {
	rule, ok := catalog.CGs[d.Command.Value]
	if !ok {
		return nil, lib.ErrUnqualified
	}
	if s.Grants == nil {
		return nil, ErrUnavailable
	}
	inserted, e := s.Library.InsertCGClaimTx(ctx, t, lib.CGClaimFact{PlayerID: a.PlayerID, CGID: rule.ID, ClaimedAt: d.DecisionAt})
	if e != nil {
		return nil, e
	}
	if !inserted {
		return nil, lib.ErrCGClaimed
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "library", Operation: "cg-claim", BusinessKey: "library:cg:" + strconv.FormatInt(rule.ID, 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: rule.ItemID, Amount: rule.Num}}}
	result, e := s.Grants.SettleGrantTx(ctx, t, a, plan, d.Operation, i5.GrantTxOptions{AllowOverflowMail: true})
	if e != nil {
		return nil, e
	}
	if s.Broadcast != nil {
		message := broadcast.Message{MID: broadcast.SystemMID, MsgType: broadcast.UnlockCG, Server: a.LogicalServerID, Player: a.PlayerID, Fields: broadcast.Fields{CGID: rule.ID}}
		if e = s.Broadcast.EmitTx(ctx, t, message); e != nil {
			return nil, e
		}
	}
	return result.Awards, nil
}
