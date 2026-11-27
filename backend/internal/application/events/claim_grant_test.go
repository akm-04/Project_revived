package events

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// TestChoiceGrantRefusesAnUnexpandedTierChoice covers the permanent refusal the
// settlement records instead of wedging an occurrence (I11A-2 E4c).
func TestChoiceGrantRefusesAnUnexpandedTierChoice(t *testing.T) {
	tier := events.Tier{ID: 1, Choices: []events.Choice{{}}}
	_, err := (ChoiceGrant{}).Grant(context.Background(), nil, identity.ActorContext{}, operation.Context{}, &events.Occurrence{}, tier, 1, "")
	if !errors.Is(err, ErrClaimRejected) {
		t.Fatalf("unexpanded choice error = %v, want ErrClaimRejected", err)
	}
}
