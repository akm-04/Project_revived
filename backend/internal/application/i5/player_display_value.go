package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type DisplayValueRequest struct{ RenameAmount, BuyID int64 }
type PreparedDisplayValue interface {
	ApplyDisplayValueTx(context.Context, tx.Tx) (map[string]any, error)
}
type DisplayValuePort interface {
	PrepareDisplayValueTx(context.Context, tx.Tx, identity.ActorContext, DisplayValueRequest, player.DisplayCatalog, string, time.Time, operation.Context) (PreparedDisplayValue, error)
}
type DisplayValueOwner struct {
	Store   MaterialCostStore
	Content ContentRuntime
	Grant   TxGrantSettler
}
type preparedDisplayValue struct {
	owner     DisplayValueOwner
	tx        tx.Tx
	actor     identity.ActorContext
	request   DisplayValueRequest
	amount    int64
	balance   economy.ScalarBalance
	at        time.Time
	operation operation.Context
	plan      grant.Plan
	applied   bool
}

func (s DisplayValueOwner) PrepareDisplayValueTx(c context.Context, t tx.Tx, a identity.ActorContext, q DisplayValueRequest, p player.DisplayCatalog, rev string, at time.Time, o operation.Context) (PreparedDisplayValue, error) {
	if s.Store == nil || t == nil || !a.PlayerID.Valid() || at.IsZero() || len(rev) != 64 || q.RenameAmount < 0 || q.BuyID < 0 || q.RenameAmount > 0 && q.BuyID > 0 {
		return nil, player.ErrDisplay
	}
	out := &preparedDisplayValue{owner: s, tx: t, actor: a, request: q, amount: q.RenameAmount, at: at, operation: o}
	if q.BuyID > 0 {
		v, ok := p.Find("avatar", q.BuyID)
		if !ok {
			v, ok = p.Find("frame", q.BuyID)
		}
		if !ok || v.Type != 5 || v.Days != -1 || v.Price <= 0 || s.Content == nil || s.Grant == nil {
			return nil, player.ErrDisplayUnavailable
		}
		out.amount = v.Price
		out.plan = grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "player-display", Operation: "purchase", BusinessKey: o.ID.String(), PolicyVersion: player.DisplayPolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: q.BuyID, Amount: 1}}}
		rp, e := s.Content.ResolveResourceTx(c, t, rev, out.plan.Lines[0])
		if e != nil || rp.Stack == nil || rp.Kind != grant.StackItem || rp.Stack.ItemID != q.BuyID || rp.Stack.StackCap != 1 {
			return nil, player.ErrDisplayUnavailable
		}
	}
	if out.amount <= 0 {
		return out, nil
	}
	if e := s.Store.LockEconomyOwnerTx(c, t, a.PlayerID); e != nil {
		return nil, e
	}
	b, ok, e := s.Store.LockScalarTx(c, t, a.PlayerID, "crystal", at)
	if e != nil {
		return nil, e
	}
	if !ok {
		return nil, economy.ErrUnknownResource
	}
	if at.Before(b.UpdatedAt) {
		return nil, player.ErrDisplay
	}
	if _, e = b.Debit(out.amount, at); e != nil {
		return nil, e
	}
	out.balance = b
	if q.BuyID > 0 {
		st, has, e := s.Store.LockStackTx(c, t, a.PlayerID, q.BuyID, at)
		if e != nil {
			return nil, e
		}
		if has && st.Quantity > 0 {
			return nil, errors.New("permanent cosmetic already owned")
		}
	}
	return out, nil
}
func (p *preparedDisplayValue) ApplyDisplayValueTx(c context.Context, t tx.Tx) (map[string]any, error) {
	if p == nil || t == nil || t != p.tx || p.applied {
		return nil, player.ErrDisplay
	}
	p.applied = true
	out := map[string]any{}
	if p.amount > 0 {
		b, e := p.balance.Debit(p.amount, p.at)
		if e != nil {
			return nil, e
		}
		if e = p.owner.Store.SaveScalarTx(c, t, b, true); e != nil {
			return nil, e
		}
		out["crystal"] = b.Amount
	}
	if p.request.BuyID > 0 {
		g, e := p.owner.Grant.SettleGrantTx(c, t, p.actor, p.plan, p.operation, GrantTxOptions{AllowOverflowMail: false})
		if e != nil {
			return nil, e
		}
		out["items"] = StockRepresentableBulkAwards(g.Awards)
	}
	return out, nil
}
