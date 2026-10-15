package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
)

// InscriptionValueRequest closes all potential scalar/stack credit destinations
// before entropy or writes. Amounts in Support are bounds, never an entitlement.
type InscriptionValueRequest struct {
	Cost    MaterialCost
	Support grant.Plan
}
type PreparedInscriptionValue struct {
	actor       identity.ActorContext
	op          operation.Context
	revision    string
	debit       MaterialDebitResult
	support     grant.Plan
	grantPF     grantPreflight
	transaction tx.Tx
	applied     bool
}
type TxInscriptionValue interface {
	PrepareInscriptionValueTx(context.Context, tx.Tx, identity.ActorContext, InscriptionValueRequest, operation.Context) (*PreparedInscriptionValue, error)
	ApplyInscriptionValueTx(context.Context, tx.Tx, *PreparedInscriptionValue, []grant.Line) (GrantResult, error)
}

func valueIdentity(a, b grant.Line) bool {
	return a.Kind == b.Kind && a.ItemID == b.ItemID && a.ResourceKey == b.ResourceKey && a.Domain == b.Domain
}
func (s Service) PrepareInscriptionValueTx(ctx context.Context, t tx.Tx, a identity.ActorContext, req InscriptionValueRequest, op operation.Context) (*PreparedInscriptionValue, error) {
	if e := s.validate(); e != nil {
		return nil, e
	}
	if t == nil || !a.PlayerID.Valid() || !reflect.TypeOf(t).Comparable() {
		return nil, errors.New("inscription value: transaction/actor required")
	}
	rev, e := requireContentRevision(op)
	if e != nil {
		return nil, e
	}
	if op.StartedAt.IsZero() {
		return nil, errors.New("inscription value: operation time required")
	}
	p := &PreparedInscriptionValue{actor: a, op: op, revision: rev, transaction: t, support: req.Support}
	// Copy caller-owned plans before retaining them.
	p.support.Lines = append([]grant.Line(nil), req.Support.Lines...)
	var locks []grantLockRequirement
	hasCost := len(req.Cost.Scalars)+len(req.Cost.Stacks) > 0
	var costPF materialCostPreflight
	debiter := MaterialCostDebiter{Store: s.Store, Content: s.Content}
	if hasCost {
		costPF, e = debiter.preflightMaterialCostTx(ctx, t, a.PlayerID, req.Cost, op)
		if e != nil {
			return nil, e
		}
		locks = append(locks, costPF.Locks...)
	}
	if len(p.support.Lines) > 0 {
		if p.support.PlayerID != a.PlayerID || p.support.Source.Domain != "inscription" {
			return nil, errors.New("inscription value: source scope mismatch")
		}
		if e = p.support.Validate(); e != nil {
			return nil, e
		}
		for i, l := range p.support.Lines {
			if len(l.Metadata) > 0 || (l.Kind != grant.StackItem && l.Kind != grant.ScalarCurrency) {
				return nil, ErrUnsupportedGrantDestination
			}
			for _, prev := range p.support.Lines[:i] {
				if valueIdentity(l, prev) {
					return nil, errors.New("inscription value: duplicate support identity")
				}
			}
			for _, x := range req.Cost.Stacks {
				if l.Kind == grant.StackItem && x.ItemID == l.ItemID {
					return nil, ErrMaterialExchangeResourceCollision
				}
			}
			for _, x := range req.Cost.Scalars {
				if l.Kind == grant.ScalarCurrency && x.ResourceKey == l.ResourceKey {
					return nil, ErrMaterialExchangeResourceCollision
				}
			}
		}
		id, _, e := p.support.ReceiptIdentities()
		if e != nil {
			return nil, e
		}
		if _, ok, e := s.Receipts.FindTx(ctx, t, id); e != nil {
			return nil, e
		} else if ok {
			return nil, ErrMaterialExchangeGrantAlreadySettled
		}
		p.grantPF, e = s.preflightGrantTx(ctx, t, p.support, rev, grantPreflightOptions{AllowOverflowMail: true}, op.StartedAt)
		if e != nil {
			return nil, e
		}
		locks = append(locks, p.grantPF.Locks...)
	}
	if len(locks) == 0 {
		return nil, errors.New("inscription value: empty plan")
	}
	locks, e = canonicalGrantLockRequirements(locks)
	if e != nil {
		return nil, e
	}
	p.grantPF.Locks = locks
	if e = s.acquireGrantLocksTx(ctx, t, a.PlayerID, p.grantPF, op.StartedAt); e != nil {
		return nil, e
	}
	if len(p.support.Lines) > 0 {
		id, _, _ := p.support.ReceiptIdentities()
		if _, ok, e := s.Receipts.FindTx(ctx, t, id); e != nil {
			return nil, e
		} else if ok {
			return nil, ErrMaterialExchangeGrantAlreadySettled
		}
	}
	if hasCost {
		p.debit, e = debiter.prepareMaterialDebitStateTx(ctx, t, a.PlayerID, costPF)
		if e != nil {
			return nil, e
		}
	}
	return p, nil
}
func (s Service) ApplyInscriptionValueTx(ctx context.Context, t tx.Tx, p *PreparedInscriptionValue, lines []grant.Line) (GrantResult, error) {
	if p == nil || t == nil || t != p.transaction || p.applied {
		return GrantResult{}, errors.New("inscription value: stale prepared plan")
	}
	pf := p.grantPF
	pf.Lines = nil
	for i, line := range lines {
		if len(line.Metadata) > 0 {
			return GrantResult{}, ErrUnsupportedGrantDestination
		}
		if e := line.Validate(); e != nil {
			return GrantResult{}, e
		}
		found := false
		for j, prior := range lines {
			if j < i && valueIdentity(line, prior) {
				return GrantResult{}, errors.New("inscription value: duplicate credit")
			}
		}
		for _, planned := range p.grantPF.Lines {
			if valueIdentity(line, planned.Line) && line.Amount <= planned.Line.Amount {
				planned.Line = line
				planned.Ordinal = i
				pf.Lines = append(pf.Lines, planned)
				found = true
				break
			}
		}
		if !found {
			return GrantResult{}, errors.New("inscription value: unplanned credit")
		}
	}
	plan := p.support
	plan.Lines = append([]grant.Line(nil), lines...)
	if len(lines) > 0 {
		id, _, e := plan.ReceiptIdentities()
		if e != nil {
			return GrantResult{}, e
		}
		if _, ok, e := s.Receipts.FindTx(ctx, t, id); e != nil {
			return GrantResult{}, e
		} else if ok {
			return GrantResult{}, ErrMaterialExchangeGrantAlreadySettled
		}
	}
	if e := (MaterialCostDebiter{Store: s.Store, Content: s.Content}).applyPreparedMaterialDebitTx(ctx, t, p.debit); e != nil {
		return GrantResult{}, e
	}
	p.applied = true
	if len(lines) == 0 {
		return GrantResult{}, nil
	}
	id, _, _ := plan.ReceiptIdentities()
	fp, e := receiptFingerprintForGrant(plan)
	if e != nil {
		return GrantResult{}, e
	}
	return s.applyPreparedGrantTx(ctx, t, p.actor, plan, p.op, true, p.revision, pf, id, fp)
}

var _ TxInscriptionValue = Service{}
