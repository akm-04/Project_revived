package characterhero

import (
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
)

// Hero promotion receipt/source identity remains frozen at the accepted CA4-3B
// policy name even though the calculator is now owned by the family-neutral I5
// restoration seam introduced for CA4-4B.
const HeroPromotionRestorationPolicyVersion = "P0_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER"

type heroPromotionRestorationInput = appi5.PromotionRestorationInput

func planBasePromotionRestoration(in []heroPromotionRestorationInput, policy character.HeroPromotionRestorationPolicy) ([]grant.Line, error) {
	return appi5.PlanPromotionRestoration(in, policy)
}
