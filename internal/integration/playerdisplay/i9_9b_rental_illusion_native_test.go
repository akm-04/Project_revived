//go:build postgres

package playerdisplay_test

import (
	"testing"

	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/domain/guild"
)

// BUGS #96: the Illusion rent window offers a hero under mode 32 (ILLUSION),
// while the battle's content type is 8 (ELEMENT). START must key the loan on
// the offered mode, not the content type.
func TestI9_9BIllusionRentedHeroUsesIllusionBorrowMode(t *testing.T) {
	f := newRentalFixture(t)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.second, opPinned(f.revision)); err != nil {
		t.Fatal("place", err)
	}
	exec(t, f.pool, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,43,$2,'function.lua:43:1|65',clock_timestamp()-interval '1 minute')
		ON CONFLICT(player_id,function_id)DO NOTHING`, int64(f.borrower.PlayerID), f.revision)
	exec(t, f.pool, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(f.borrower.PlayerID))
	owned := bornHero(t, f.pool, f.borrower, f.revision, genuineHeroTable, 1)

	mode := illusionService(t, f.pool, illusionTime(t), illusionPrivileges{level: 3}, illusionGuildSource{})
	mode.Combat = f.combat
	if _, err := mode.Start(ctx, f.borrower, il.StartRequest{
		Formation: []int64{owned.PartnerID}, RentPlayer: int64(f.lender.PlayerID), RentUnit: f.second,
	}, op()); err != nil {
		t.Fatalf("illusion fight with a rented hero: %v", err)
	}
}
