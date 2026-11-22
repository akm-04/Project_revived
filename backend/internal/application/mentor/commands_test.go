package mentor

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/mentor"
)

func TestPlayerStateFromRelationsCarriesBothSlots(t *testing.T) {
	player := identity.PlayerID(100001)
	mentor := identity.PlayerID(100002)
	student := identity.PlayerID(100003)
	relations := []domain.Relationship{
		{Mentor: mentor, Student: player},
		{Mentor: player, Student: student},
	}
	state := playerStateFromRelations(relations, player, 40, 1)
	if !state.HasMentor || state.MentorID != mentor || !state.HasStudent || state.StudentID != student || state.AcademyLevel != 40 || state.LogicalServerID != 1 {
		t.Fatalf("state %#v", state)
	}
	if err := state.Validate(); err != nil {
		t.Fatalf("state %#v: %v", state, err)
	}
}

func TestPlayerStateFromRelationsEmpty(t *testing.T) {
	state := playerStateFromRelations(nil, identity.PlayerID(100001), 20, 1)
	if state.HasMentor || state.HasStudent || state.MentorID.Valid() || state.StudentID.Valid() {
		t.Fatalf("empty relations produced occupancy %#v", state)
	}
}

// A closed function-50 gate has no mentor message row, so the refusal is the stock generic 35028.
func TestApplicationRefusalMapsClosedFunctionGate(t *testing.T) {
	err := applicationRefusal(domain.ErrGateUnqualified, 20, domain.Rules{StudentLevelLimit: 90})
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != 35028 {
		t.Fatalf("closed function gate refused with %v, want 35028", err)
	}
}
