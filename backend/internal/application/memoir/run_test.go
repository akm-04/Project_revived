package memoir

import (
	"context"
	"errors"
	"testing"

	dm "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

// The Girls Log observer is mandatory: a composition that omits it must fail
// closed at the readiness guard instead of nil-panicking inside a settlement.
func TestPinRefusesAMissingBattleCountsObserver(t *testing.T) {
	mode := newFinalAwardFixture(t).mode
	mode.BattleCounts = nil
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := mode.pin(context.Background(), operation.Context{Policies: policies}); !errors.Is(err, dm.ErrUnavailable) {
		t.Fatalf("pin without BattleCounts = %v, want ErrUnavailable", err)
	}
}
