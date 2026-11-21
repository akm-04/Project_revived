package guildcampaigncatalog

import "testing"

func TestBuiltinWavesCarryBattleMonstersWithUniquePartnerIDs(t *testing.T) {
	builtin, err := LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	copy, known := builtin.Catalog.Copy(7, 700028)
	if !known {
		t.Fatal("copy 700028 missing")
	}
	// battle.lua row 70028: fight_1/2/3 name the real monster rows; the
	// team_campaign monster_display_N ids are only the weaker map previews.
	want := map[string][]int64{
		"1": {91071010, 91071010, 91071006, 91071169},
		"2": {91071022, 91071008, 91071008, 91071009, 91071158},
		"3": {91071060, 91071077, 91071081, 91071179},
	}
	partners := map[int64]bool{}
	for wave, tableIDs := range want {
		rows := copy.Waves[wave]
		if len(rows) != len(tableIDs) {
			t.Fatalf("wave %s has %d enemies, want %d", wave, len(rows), len(tableIDs))
		}
		for index, tableID := range tableIDs {
			enemy := rows[index]
			if enemy.TableID != tableID || enemy.Lev != 60 || enemy.Star != 5 || enemy.Color < 6 || enemy.Health != 0 {
				t.Fatalf("wave %s enemy %d = %+v, want table %d at lev 60 star 5", wave, index, enemy, tableID)
			}
			if enemy.PartnerID <= 0 || partners[enemy.PartnerID] {
				t.Fatalf("wave %s enemy %d partner_id %d is not unique", wave, index, enemy.PartnerID)
			}
			partners[enemy.PartnerID] = true
		}
	}
	if copy.Waves["1"][0].PartnerID == copy.Waves["1"][1].PartnerID {
		t.Fatal("two identical monsters share a partner_id")
	}
}
