package characterhero

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// ApplyDormEXPLockedTx is Character's narrow same-transaction timed EXP port.
// Caller has fenced the actor and acquired the complete Player/Character/Dorm/
// value plan, including this live Hero's canonical lock. Re-locking the same
// planned Hero identity is allowed; this port discovers no new lock or clock.
// AtCap tells Dorm to consume elapsed time without banking EXP beyond the cap.
func (s Service) ApplyDormEXPLockedTx(ctx context.Context, t tx.Tx, ref character.HeroRef, amount, playerLevel int64, revision string, observed time.Time) (character.Hero, bool, error) {
	if t == nil || ref.Validate() != nil || amount < 0 || observed.IsZero() || s.ProgressionStore == nil || s.Progression == nil {
		return character.Hero{}, false, errors.New("character: invalid Dorm EXP composition")
	}
	h, e := s.ProgressionStore.LockHeroByPartnerIDTx(ctx, t, ref.PlayerID, ref.PartnerID)
	if e != nil {
		return h, false, e
	}
	if observed.Before(h.UpdatedAt) {
		return h, false, errors.New("character: stale Dorm EXP time")
	}
	max, e := s.Progression.HeroMaxLevelTx(ctx, t, revision, playerLevel)
	if e != nil {
		return h, false, e
	}
	thresholds, e := s.Progression.HeroExpPolicyTx(ctx, t, revision, max)
	if e != nil {
		return h, false, e
	}
	if max <= 0 || int64(len(thresholds)) != max || h.Level > max || h.Exp > thresholds[len(thresholds)-1].TotalExp {
		return h, false, errors.New("character: unqualified Dorm EXP cap")
	}
	capExp := thresholds[len(thresholds)-1].TotalExp
	if h.Level >= max || h.Exp >= capExp {
		return h, true, nil
	}
	if amount == 0 {
		return h, false, nil
	}
	next, e := h.AddSourceEXP(amount, max, thresholds, observed)
	if e != nil {
		return h, false, e
	}
	if e = s.ProgressionStore.SaveHeroProgressionTx(ctx, t, next, h.StateVersion); e != nil {
		return h, false, e
	}
	return next, next.Level >= max || next.Exp >= capExp, nil
}
