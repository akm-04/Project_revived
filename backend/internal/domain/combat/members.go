package combat

import (
	"errors"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

var (
	// ErrRoomRefused is the shared-room capability refusing a member roster.
	ErrRoomRefused = errors.New("combat: member roster refused by the room capability")
	// ErrMemberSettled is a member already settled under another receipt.
	ErrMemberSettled = errors.New("combat: member already settled under another receipt")
)

// MemberLimit bounds an attempt's roster, convener included
// (I8_MULTI_PARTICIPANT_ATTEMPT_V1 private policy; the original is UNKNOWN).
const MemberLimit = 8

// ValidMembers checks a roster: the convener at seat 0, then distinct other
// players, at least two and at most MemberLimit seats.
func ValidMembers(convener int64, members []int64) error {
	if len(members) < 2 || len(members) > MemberLimit || members[0] != convener {
		return ErrInvalid
	}
	for i, member := range members {
		if member <= 0 || slices.Contains(members[:i], member) {
			return ErrInvalid
		}
	}
	return nil
}

// MemberSettlement records that the mode settled one member of a terminal
// attempt, under that member's semantic receipt.
type MemberSettlement struct {
	AttemptID         ids.UUID
	Member            int64
	SemanticReceiptID string
	SettledAt         time.Time
}

func (s MemberSettlement) Validate() error {
	if s.AttemptID.IsZero() || s.Member <= 0 || s.SemanticReceiptID == "" || len(s.SemanticReceiptID) > 256 || s.SettledAt.IsZero() {
		return ErrInvalid
	}
	return nil
}

// Settleable reports a terminal attempt whose outcome the mode settles; a
// superseded, rejected or practice end carries no value to fan out.
func (a Attempt) Settleable() bool {
	return a.State == Terminal && a.TerminalKind != SupersededKind && a.TerminalKind != RejectedKind && a.TerminalKind != PracticeKind
}
