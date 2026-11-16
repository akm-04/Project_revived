package mentor

import (
	"errors"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/mentor"
)

// A closed function-50 gate has no mentor message row, so the refusal is the stock generic 35028.
func TestApplicationRefusalMapsClosedFunctionGate(t *testing.T) {
	err := applicationRefusal(domain.ErrGateUnqualified, 20, domain.Rules{StudentLevelLimit: 90})
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != 35028 {
		t.Fatalf("closed function gate refused with %v, want 35028", err)
	}
}
