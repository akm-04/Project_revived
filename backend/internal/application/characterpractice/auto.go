package characterpractice

import (
	"errors"
	"math"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const (
	AutoSavePredicatePolicyV1 = "PRACTICE_AUTO_SAVE_PREDICATE_V1"
	AutoBatchPolicyV1         = "PRACTICE_AUTO_BATCH_V1"
)

var (
	ErrInvalidAutoBatch          = errors.New("character practice: invalid AUTO batch size")
	ErrInvalidAutoSavePredicates = errors.New("character practice: invalid AUTO save predicates")
)

// AutoSavePredicates is the exact stock wire ordering: Str, Int, Agi, Total.
// Selected predicates are AND-composed over the effective bounded delta.
type AutoSavePredicates [4]bool

func (p AutoSavePredicates) Validate(locks PracticeLocks) error {
	selected := false
	for _, v := range p {
		selected = selected || v
	}
	if !selected {
		return ErrInvalidAutoSavePredicates
	}
	for axis := range 3 {
		if locks[axis] && !p[axis] {
			return ErrInvalidAutoSavePredicates
		}
	}
	return nil
}

func validAutoBatchSize(n int64) bool {
	switch n {
	case 2, 4, 6, 8, 10:
		return true
	default:
		return false
	}
}

func autoSavePredicateAccept(delta PracticeDelta, p AutoSavePredicates) bool {
	for axis := range 3 {
		if p[axis] && delta[axis] <= 0 {
			return false
		}
	}
	if p[3] && delta[0]+delta[1]+delta[2] <= 0 {
		return false
	}
	return true
}

// AutoCommand is the typed CA6-4 service input. CA6-4A defines the exact
// shape but intentionally does not activate MID127/132 routing.
type AutoCommand struct {
	Target    Target
	Locks     PracticeLocks
	Method    int64
	BatchSize int64
	Save      AutoSavePredicates
}

// AutoResult is the exact stock AUTO projection. AddAttrs and IsAdds retain
// every requested attempt, while PracticeAttr is the directly applied final
// owner state; AUTO never creates a CA6-3 pending proposal.
type AutoResult struct {
	Info         Info
	AddAttrs     []PracticeDelta
	IsAdds       []int64
	PracticeAttr character.PracticeAttrs
	Replayed     bool
}

func (c AutoCommand) validate() error {
	if c.Target.validate() != nil || c.Method < 1 || c.Method > 3 {
		return ErrPracticeAdmission
	}
	if !validAutoBatchSize(c.BatchSize) {
		return ErrInvalidAutoBatch
	}
	return c.Save.Validate(c.Locks)
}

// AutoBatchPlan is a pure pre-mutation effect plan. AddAttrs and IsAdds always
// contain exactly BatchSize entries. RollDraws is diagnostic proof that the
// terminal-cap compatibility rule draws no entropy for the zero/rejected suffix.
type AutoBatchPlan struct {
	AddAttrs    []PracticeDelta
	IsAdds      []int64
	FinalAttrs  character.PracticeAttrs
	CurrencyKey string
	TotalCost   int64
	BlessCost   int64
	NextRoot    Root
	RollDraws   int
}

func checkedMulNonNegative(a, b int64) (int64, error) {
	if a < 0 || b < 0 {
		return 0, errors.New("character practice: accounting overflow")
	}
	if a == 0 || b == 0 {
		return 0, nil
	}
	if a > math.MaxInt64/b {
		return 0, errors.New("character practice: accounting overflow")
	}
	return a * b, nil
}

// planAutoAccounting implements PRACTICE_AUTO_BATCH_V1 accounting after
// Root450 has been locked and any newer daily generation has already been
// planned in memory. AUTO never consumes/restarts the manual free entitlement.
func planAutoAccounting(root Root, method Method, advanced Method, lock *LockCost, lockCount, batchSize int64) (currency string, total, blessDebit int64, next Root, err error) {
	if root.Validate() != nil || !validAutoBatchSize(batchSize) || method.ID < 1 || method.ID > 3 || method.BaseCost <= 0 || method.VIPMin < 0 || lockCount < 0 || lockCount > 3 {
		return "", 0, 0, Root{}, errors.New("character practice: invalid AUTO accounting input")
	}
	if method.CurrencyType != 1 && method.CurrencyType != 2 {
		return "", 0, 0, Root{}, errors.New("character practice: invalid method currency")
	}
	if lockCount == 0 && lock != nil {
		return "", 0, 0, Root{}, errors.New("character practice: unexpected zero-lock policy row")
	}
	if lockCount > 0 {
		if lock == nil || lock.Count != lockCount || lock.ManaStep < 0 || lock.CrystalStep < 0 || lock.BlessCost < 0 {
			return "", 0, 0, Root{}, errors.New("character practice: invalid lock accounting row")
		}
	}

	methodBase := method.BaseCost
	if method.CurrencyType == 2 && lockCount == 3 {
		if advanced.ID != 2 || advanced.CurrencyType != 2 || advanced.BaseCost <= 0 {
			return "", 0, 0, Root{}, errors.New("character practice: invalid Advanced method for three-lock pricing")
		}
		methodBase = advanced.BaseCost
	}
	baseTotal, err := checkedMulNonNegative(methodBase, batchSize)
	if err != nil {
		return "", 0, 0, Root{}, err
	}

	next = root
	var running, step int64
	switch method.CurrencyType {
	case 1:
		currency = "mana"
		running = root.BaseMana
		if lock != nil {
			step = lock.ManaStep
		}
	case 2:
		currency = "crystal"
		running = root.BaseCrystal
		if lock != nil {
			step = lock.CrystalStep
		}
	}

	var surcharge int64
	for attempt := int64(0); attempt < batchSize; attempt++ {
		for axis := int64(0); axis < lockCount; axis++ {
			running, err = checkedAddNonNegative(running, step)
			if err != nil {
				return "", 0, 0, Root{}, err
			}
			surcharge, err = checkedAddNonNegative(surcharge, running)
			if err != nil {
				return "", 0, 0, Root{}, err
			}
		}
	}
	total, err = checkedAddNonNegative(baseTotal, surcharge)
	if err != nil || total <= 0 {
		if err == nil {
			err = errors.New("character practice: invalid AUTO aggregate cost")
		}
		return "", 0, 0, Root{}, err
	}

	if lockCount > 0 {
		blessDebit, err = checkedMulNonNegative(lock.BlessCost, batchSize)
		if err != nil {
			return "", 0, 0, Root{}, err
		}
		// Stock AUTO admission is strict: equality is rejected.
		if root.BlessRemaining <= blessDebit {
			return "", 0, 0, Root{}, ErrPracticeBless
		}
		next.BlessRemaining -= blessDebit
		if method.CurrencyType == 1 {
			next.BaseMana = running
		} else {
			next.BaseCrystal = running
		}
	}
	return currency, total, blessDebit, next, nil
}

// planAutoBatchV1 composes the frozen single-attempt roll policy with the
// CA6-4 batch/save/accounting policy. It is pure: no SQL, locks, receipts, or
// durable owner writes occur here.
func planAutoBatchV1(op operation.Context, root Root, method Method, advanced Method, lock *LockCost, current character.PracticeAttrs, locks PracticeLocks, batchSize int64, save AutoSavePredicates) (AutoBatchPlan, error) {
	if current.Validate() != nil {
		return AutoBatchPlan{}, ErrPracticeAdmission
	}
	if allPracticeAtCap(current) {
		return AutoBatchPlan{}, ErrAllPracticeAttrsAtCap
	}
	if !validAutoBatchSize(batchSize) {
		return AutoBatchPlan{}, ErrInvalidAutoBatch
	}
	if err := save.Validate(locks); err != nil {
		return AutoBatchPlan{}, err
	}
	lockCount := countLocks(locks)
	currency, total, blessDebit, nextRoot, err := planAutoAccounting(root, method, advanced, lock, lockCount, batchSize)
	if err != nil {
		return AutoBatchPlan{}, err
	}

	plan := AutoBatchPlan{
		AddAttrs:    make([]PracticeDelta, 0, batchSize),
		IsAdds:      make([]int64, 0, batchSize),
		FinalAttrs:  current,
		CurrencyKey: currency,
		TotalCost:   total,
		BlessCost:   blessDebit,
		NextRoot:    nextRoot,
	}
	running := current
	for i := int64(0); i < batchSize; i++ {
		if allPracticeAtCap(running) {
			plan.AddAttrs = append(plan.AddAttrs, PracticeDelta{})
			plan.IsAdds = append(plan.IsAdds, 0)
			continue
		}
		roll, err := RollPracticeV1(op, method.ID, running, locks, uint64(i))
		if err != nil {
			return AutoBatchPlan{}, err
		}
		plan.RollDraws++
		delta := PracticeDelta(roll.Effective)
		if delta.Validate() != nil {
			return AutoBatchPlan{}, errors.New("character practice: invalid AUTO effective delta")
		}
		accepted := autoSavePredicateAccept(delta, save)
		plan.AddAttrs = append(plan.AddAttrs, delta)
		if !accepted {
			plan.IsAdds = append(plan.IsAdds, 0)
			continue
		}
		next, err := addEffective(running, roll.Effective)
		if err != nil {
			return AutoBatchPlan{}, err
		}
		running = next
		plan.IsAdds = append(plan.IsAdds, 1)
	}
	plan.FinalAttrs = running
	return plan, nil
}
