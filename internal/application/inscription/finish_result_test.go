package inscription

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/economy"
)

func TestFinishResultRecoversTypedBalanceCause(t *testing.T) {
	_, err := finishResult(Result{Rejected: economy.InsufficientBalance("crystal").Error()})
	if !errors.Is(err, ErrRejected) {
		t.Fatalf("rejection class lost: %v", err)
	}
	var balance *economy.InsufficientBalanceError
	if !errors.As(err, &balance) || balance.ResourceKey != "crystal" {
		t.Fatalf("balance resource lost: %v", err)
	}
	_, err = finishResult(Result{Rejected: "inscription: stale captured decision time"})
	if !errors.Is(err, ErrRejected) || errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatalf("generic rejection misclassified: %v", err)
	}
}
