package characterpractice

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const RollPolicyV1 = "PRACTICE_ROLL_POLICY_V1"

var (
	ErrInvalidPracticeMethod = errors.New("character practice: invalid practice method")
	ErrAllPracticeAttrsAtCap = errors.New("character practice: all practice attributes are at cap")
	ErrEmptyRollSupport      = errors.New("character practice: empty roll support")
)

type PracticeLocks [3]bool

type RollCandidate struct {
	Mask      uint8
	Raw       [3]int64
	Effective [3]int64
}

type RollResult struct {
	Index       int
	SupportSize int
	RollCandidate
}

// RollPracticeV1 implements the frozen PRACTICE_ROLL_POLICY_V1 compatibility
// policy. Entropy is derived solely from the semantic operation context and the
// explicit attempt ordinal; SQL/transaction retry count must never be supplied.
func RollPracticeV1(op operation.Context, methodID int64, current character.PracticeAttrs, locks PracticeLocks, attemptOrdinal uint64) (RollResult, error) {
	support, err := practiceRollSupportV1(methodID, current, locks)
	if err != nil {
		return RollResult{}, err
	}
	idx := practiceUnbiasedIndexV1(op, methodID, attemptOrdinal, len(support))
	return RollResult{Index: idx, SupportSize: len(support), RollCandidate: support[idx]}, nil
}

func practiceRollSupportV1(methodID int64, current character.PracticeAttrs, locks PracticeLocks) ([]RollCandidate, error) {
	if methodID < 1 || methodID > 3 {
		return nil, ErrInvalidPracticeMethod
	}
	if err := current.Validate(); err != nil {
		return nil, err
	}
	if current[0] >= character.MaxPracticeAttr && current[1] >= character.MaxPracticeAttr && current[2] >= character.MaxPracticeAttr {
		return nil, ErrAllPracticeAttrsAtCap
	}

	out := make([]RollCandidate, 0, 8)
	for mask := uint8(0); mask < 8; mask++ {
		var candidate RollCandidate
		candidate.Mask = mask
		effectiveTotal := int64(0)
		compatible := true
		for axis := 0; axis < 3; axis++ {
			raw := int64(-1)
			if mask&(1<<axis) != 0 {
				raw = 1
			}
			if locks[axis] && raw != 1 {
				compatible = false
				break
			}
			candidate.Raw[axis] = raw
			candidate.Effective[axis] = boundedPracticeDelta(current[axis], raw)
			effectiveTotal += candidate.Effective[axis]
		}
		if !compatible {
			continue
		}
		if methodID != 1 && effectiveTotal <= 0 {
			continue
		}
		out = append(out, candidate)
	}
	if len(out) == 0 {
		return nil, ErrEmptyRollSupport
	}
	return out, nil
}

func boundedPracticeDelta(current, raw int64) int64 {
	next := current + raw
	if next < 0 {
		next = 0
	}
	if next > character.MaxPracticeAttr {
		next = character.MaxPracticeAttr
	}
	return next - current
}

func practiceUnbiasedIndexV1(op operation.Context, methodID int64, attemptOrdinal uint64, n int) int {
	if n <= 0 || n > 255 {
		panic("character practice: invalid selector support size")
	}
	limit := 256 - (256 % n)
	for round := uint64(0); ; round++ {
		label := fmt.Sprintf("characterpractice.roll.v1.selector/method=%d/round=%d", methodID, round)
		block := op.Derive(label, attemptOrdinal)
		for _, b := range block {
			if int(b) < limit {
				return int(b) % n
			}
		}
	}
}
