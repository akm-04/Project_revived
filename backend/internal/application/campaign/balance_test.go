package campaign

import (
	"context"
	"errors"
	"testing"

	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type typedEnergy struct{ err error }

func (e typedEnergy) DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error) {
	return economy.TemporalState{}, e.err
}

func (e typedEnergy) TemporalBalanceTx(context.Context, tx.Tx, identity.PlayerID, string, operation.Context) (int64, error) {
	return 0, nil
}

func TestCampaignDebitKeepsTypedBalanceCause(t *testing.T) {
	mode := Mode{Energy: typedEnergy{err: economy.InsufficientBalance(campaignEnergy)}}
	err := mode.debit(context.Background(), awardScope(t), identity.PlayerID(7), 6)
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("debit error %v lost the typed balance cause", err)
	}
	var balance *economy.InsufficientBalanceError
	if !errors.As(err, &balance) || balance.ResourceKey != campaignEnergy {
		t.Fatalf("debit resource key = %+v", balance)
	}
}

func TestCampaignPreviewShortfallIsTyped(t *testing.T) {
	err := energyShortfall(2, 6)
	if !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("shortfall error %v is not the typed cause", err)
	}
	var balance *economy.InsufficientBalanceError
	if !errors.As(err, &balance) || balance.ResourceKey != campaignEnergy {
		t.Fatalf("shortfall resource key = %+v", balance)
	}
	if err = energyShortfall(6, 6); err != nil {
		t.Fatalf("exact balance refused: %v", err)
	}
}

func TestPurchaseErrorKeepsBalanceAndRefusesUnknownResource(t *testing.T) {
	short := purchaseError(economy.InsufficientBalance("crystal"))
	if !errors.Is(short, economy.ErrInsufficientBalance) {
		t.Fatalf("purchase error %v lost the typed balance cause", short)
	}
	unknown := purchaseError(economy.ErrUnknownResource)
	if !errors.Is(unknown, d.ErrRefused) {
		t.Fatalf("unknown resource %v is not a rule refusal", unknown)
	}
	if errors.Is(unknown, economy.ErrInsufficientBalance) {
		t.Fatalf("unknown resource became a balance refusal: %v", unknown)
	}
}
