package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MID1DetailContributor overlays already-frozen source-shaped baseline records
// with canonical state owned by an implemented domain. Contributors execute in
// explicit registration order and must declare every embedded MID/field path
// they own. Overlapping claims fail closed before MID1 executes.
type MID1DetailContributor interface {
	Name() string
	Claims() []string
	OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error
}

func ValidateDetailContributors(cs []MID1DetailContributor) error {
	type owner struct{ name, claim string }
	var prior []owner
	names := map[string]struct{}{}
	for _, c := range cs {
		if c == nil {
			return errors.New("nil MID1 detail contributor")
		}
		name := strings.TrimSpace(c.Name())
		if name == "" {
			return errors.New("MID1 detail contributor name required")
		}
		if _, ok := names[name]; ok {
			return fmt.Errorf("duplicate MID1 detail contributor %q", name)
		}
		names[name] = struct{}{}
		claims := c.Claims()
		if len(claims) == 0 {
			return fmt.Errorf("MID1 detail contributor %q declares no projection claims", name)
		}
		local := map[string]struct{}{}
		for _, raw := range claims {
			claim := strings.TrimSpace(raw)
			if !validProjectionClaim(claim) {
				return fmt.Errorf("MID1 detail contributor %q has invalid claim %q", name, raw)
			}
			if _, ok := local[claim]; ok {
				return fmt.Errorf("MID1 detail contributor %q repeats claim %q", name, claim)
			}
			local[claim] = struct{}{}
			for _, p := range prior {
				if projectionClaimsOverlap(p.claim, claim) {
					return fmt.Errorf("MID1 projection claim collision: %s owns %q and %s owns %q", p.name, p.claim, name, claim)
				}
			}
			prior = append(prior, owner{name: name, claim: claim})
		}
	}
	return nil
}

func validProjectionClaim(s string) bool {
	if s == "" || strings.HasPrefix(s, ".") || strings.HasSuffix(s, ".") || strings.Contains(s, "..") {
		return false
	}
	parts := strings.Split(s, ".")
	if len(parts) > 2 {
		return false
	}
	for _, r := range parts[0] {
		if r < '0' || r > '9' {
			return false
		}
	}
	if parts[0] == "" {
		return false
	}
	if len(parts) == 2 && strings.TrimSpace(parts[1]) == "" {
		return false
	}
	return true
}

func projectionClaimsOverlap(a, b string) bool {
	return a == b || strings.HasPrefix(a, b+".") || strings.HasPrefix(b, a+".")
}
