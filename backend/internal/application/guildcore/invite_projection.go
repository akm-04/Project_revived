package guildcore

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) admitInviteProjection(c context.Context, op operation.Context) (operation.Context, bool, error) {
	if s.InviteProjection == nil {
		return op, false, nil
	}
	return s.InviteProjection.Admit(c, op, s.Policy.Revision)
}

func (s Service) bindProjectionResolver(r *dynamicResolver, id ids.UUID, issue bool) {
	if s.InviteProjection != nil {
		r.proof = func(c context.Context) error { return s.InviteProjection.ValidateCommitted(c, id, issue) }
	}
}

func (s Service) validateMembershipProjectionTx(c context.Context, q tx.Queryer, m guild.Membership) error {
	if s.InviteProjection == nil {
		return nil
	}
	ev, ok, e := s.Store.LatestMembershipEventTx(c, q, m.PlayerID)
	if e != nil {
		return e
	}
	if !ok || ev.Kind != guild.EventJoin || ev.GuildID != m.GuildID {
		return ErrMembershipIncarnation
	}
	return s.InviteProjection.ValidateMembershipTx(c, q, ev)
}

func (s Service) appendProjectionEventTx(c context.Context, t tx.Tx, ev guild.MembershipEvent, op ids.UUID, projected bool) (guild.MembershipEvent, error) {
	if projected {
		return s.InviteProjection.Bindings.AppendMembershipEventReturningTx(c, t, ev, op)
	}
	return ev, s.Store.AppendMembershipEventTx(c, t, ev, op)
}

func (s Service) putAckReceiptReturning(ctx context.Context, t tx.Tx, bound operation.Context, actorUID string, contextID ids.UUID, rid receipt.Identity, fp [32]byte, schema string, out AckResult) (receipt.Receipt, error) {
	raw, e := json.Marshal(out)
	if e != nil {
		return receipt.Receipt{}, e
	}
	rr, e := receipt.New(bound, rid, "I6C_GUILD", schema, raw, fp)
	if e != nil {
		return receipt.Receipt{}, e
	}
	rr.ActorAccountUID = actorUID
	rr.ContextID = contextID
	rr.PolicyVersion = s.Policy.Revision
	result, e := s.Receipts.PutTx(ctx, t, rr)
	return result.Receipt, e
}
