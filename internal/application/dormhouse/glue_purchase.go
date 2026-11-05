package dormhouse

import (
	"context"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type GluePurchaseOwner interface {
	ReadGluePurchasesTx(context.Context, tx.Queryer, identity.PlayerID) (dorm.GluePurchases, bool, error)
	SaveGluePurchasesTx(context.Context, tx.Tx, dorm.GluePurchases, int64) error
}
type GluePrivilegeReader interface {
	ReadCosmeticPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (privilege.Snapshot, error)
}

func (service Service) buyGlueTx(ctx context.Context, transaction tx.Tx, actor identity.ActorContext, admission Admission, catalog dorm.Catalog) (map[string]any, error) {
	if catalog.Glue == nil {
		return nil, dorm.ErrUnqualified
	}
	if service.GluePurchases == nil || service.GlueValues == nil || service.GluePrivileges == nil {
		return nil, ErrUnavailable
	}
	at := admission.DecisionAt
	privileges, err := service.GluePrivileges.ReadCosmeticPrivilegeTx(ctx, transaction, actor.PlayerID, admission.ContentRevision, at)
	if errors.Is(err, privilege.ErrConflict) {
		return nil, ErrStale
	}
	if err != nil {
		return nil, err
	}
	if err = privileges.Validate(actor.PlayerID, admission.ContentRevision, at); err != nil {
		return nil, err
	}
	stored, exists, err := service.GluePurchases.ReadGluePurchasesTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	var previous *dorm.GluePurchases
	if exists {
		previous = &stored
	}
	planned, cost, err := catalog.Glue.PlanPurchase(previous, actor.PlayerID, privileges.State.VIPLevel, modes.Day(at), at)
	if err != nil {
		return nil, err
	}
	current := admission.Operation
	current.StartedAt = at
	request := i5.GluePurchaseRequest{CrystalCost: cost, GlueAmount: catalog.Glue.PurchaseAmount, StartLimit: catalog.Glue.PurchaseStartLimit, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: BuyGlue, BusinessKey: strconv.FormatInt(int64(actor.PlayerID), 10), Occurrence: current.ID.String(), PolicyVersion: LifecyclePolicy}}
	prepared, err := service.GlueValues.PrepareGluePurchaseTx(ctx, transaction, actor, request, current)
	if err != nil {
		return nil, err
	}
	applied, err := service.GlueValues.ApplyGluePurchaseTx(ctx, transaction, prepared)
	if err != nil {
		return nil, err
	}
	if err = service.GluePurchases.SaveGluePurchasesTx(ctx, transaction, planned, stored.StateVersion); err != nil {
		return nil, err
	}
	return map[string]any{"buy_glue_times": planned.Count, "economy_": map[string]any{"glue": applied.Glue.Amount, "crystal": applied.Crystal.Amount}}, nil
}
