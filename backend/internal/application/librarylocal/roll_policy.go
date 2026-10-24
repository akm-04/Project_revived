package librarylocal

import (
	"encoding/binary"
	"fmt"

	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// NegativeProbabilityBP implements the authorized reconstruction interpretation,
// not recovered original-server mathematics. All arithmetic is integer based.
func NegativeProbabilityBP(rules library.FeedRules, methodID int64, axis int, applied int64) (int64, error) {
	if rules.Validate() != nil || methodID < 1 || methodID > 3 || axis < 0 || axis >= library.AxisCount {
		return 0, library.ErrUnqualified
	}
	a := rules.Axes[axis]
	m := rules.Methods[methodID-1]
	if applied < 0 || applied > a.Cap {
		return 0, library.ErrInvalidFacts
	}
	progress := applied * 10000 / a.Cap
	begin := rules.DecreaseBeginPercent * 100
	if progress < begin {
		return 0, nil
	}
	steps := (progress - begin) / (m.ChangeStepPercent * 100)
	probability := m.InitialRates[0]*100 + steps*m.NegativeStepBP
	if probability > 9900 {
		probability = 9900
	}
	return probability, nil
}

// RollFeedingV1 is retry stable for a semantic operation. A new paid operation
// gets a fresh operation seed; transaction retry count never enters entropy.
func RollFeedingV1(op operation.Context, catalog library.Catalog, facts library.HeroFacts, template library.TemplateRule, methodID int64) (library.Candidate, error) {
	var result library.Candidate
	if facts.Validate() != nil || !library.ValidRevision(catalog.ContentRevision) || catalog.Feeding.ValidateApplied(facts.Applied) != nil || op.ID.IsZero() || op.StartedAt.IsZero() || template.TableID <= 0 || !template.DialogEnabled || methodID < 1 || methodID > 3 {
		return result, library.ErrUnqualified
	}
	if qualified, ok := catalog.Templates[template.TableID]; !ok || qualified != template {
		return result, library.ErrUnqualified
	}
	if !facts.Married {
		return result, library.ErrNotMarried
	}
	allCap := true
	for i, x := range facts.Applied {
		if x < catalog.Feeding.Axes[i].Cap {
			allCap = false
			break
		}
	}
	if allCap {
		return result, library.ErrAtCap
	}
	result = library.Candidate{OperationID: op.ID, Revision: facts.StateVersion + 1, PolicyVersion: library.FeedPolicyV1, ContentRevision: catalog.ContentRevision, Base: facts.Applied, CreatedAt: op.StartedAt}
	for i, a := range catalog.Feeding.Axes {
		probability, err := NegativeProbabilityBP(catalog.Feeding, methodID, i, facts.Applied[i])
		if err != nil {
			return library.Candidate{}, err
		}
		baseLabel := fmt.Sprintf("librarylocal.feed.reconstruction.v1/cost=%d/axis=%d", methodID, a.AttrID)
		negative := draw(op, baseLabel+"/direction", 10000) < uint64(probability)
		span := a.Positive
		if negative {
			span = a.Negative
		}
		delta := span[0] + int64(draw(op, baseLabel+"/amount", uint64(span[1]-span[0]+1)))
		if negative {
			delta = -delta
		}
		proposed := facts.Applied[i] + delta
		if proposed < 0 {
			proposed = 0
		}
		if proposed > a.Cap {
			proposed = a.Cap
		}
		result.Proposed[i] = proposed
		result.Delta[i] = proposed - facts.Applied[i]
	}
	return result, nil
}
func draw(op operation.Context, label string, n uint64) uint64 {
	const space = uint64(1) << 32
	if n == 0 || n > space {
		panic("library: invalid sampling support")
	}
	limit := space - space%n
	for round := uint64(0); ; round++ {
		block := op.Derive(fmt.Sprintf("%s/round=%d", label, round), 0)
		for i := 0; i < len(block); i += 4 {
			x := uint64(binary.BigEndian.Uint32(block[i : i+4]))
			if x < limit {
				return x % n
			}
		}
	}
}
