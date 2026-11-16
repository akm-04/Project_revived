//go:build postgres

package playerdisplay_test

import (
	"errors"
	"testing"

	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
)

// The battle content type and the rent-list mode are separate facts. These
// tests fix each site's content type and prove the loan follows RentalMode:
// an enabled policy mode lends, the site's client mode (disabled or not in the
// policy) refuses. The client rent values are cited in the domain constants.
func TestI9_9BWorldBossRentalUsesClientMode(t *testing.T) {
	f := newRentalFixture(t)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, opPinned(f.revision)); err != nil {
		t.Fatal("place", err)
	}
	if _, err := f.borrowMode(t, "wb-valid", 8, 32, f.hero, 0); err != nil {
		t.Fatalf("enabled rental mode: %v", err)
	}
	if _, err := f.borrowMode(t, "wb-client", 8, 8, f.hero, 0); !errors.Is(err, cd.ErrLoanRefused) {
		t.Fatalf("World Boss client mode 8 must refuse, got %v", err)
	}
}

func TestI9_9BAdventureSitesRentalUseClientMode(t *testing.T) {
	for _, site := range []struct {
		name    string
		content int64
		client  int64
	}{
		{"illusion-single", 8, 60},
		{"defense", 62, 62},
		{"coop", 61, 0},
	} {
		t.Run(site.name, func(t *testing.T) {
			f := newRentalFixture(t)
			if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, opPinned(f.revision)); err != nil {
				t.Fatal("place", err)
			}
			if _, err := f.borrowMode(t, site.name+"-valid", site.content, 32, f.hero, 0); err != nil {
				t.Fatalf("enabled rental mode: %v", err)
			}
			if _, err := f.borrowMode(t, site.name+"-client", site.content, site.client, f.hero, 0); !errors.Is(err, cd.ErrLoanRefused) {
				t.Fatalf("%s client mode %d must refuse, got %v", site.name, site.client, err)
			}
		})
	}
}
