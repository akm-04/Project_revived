package topfloor

import (
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestSelectPresetDefenseUsesHighestOwnedCopyInPolicyOrder(t *testing.T) {
	owner := identity.PlayerID(1001)
	heroes := []character.Hero{
		presetHero(owner, 51, 10001019, 10001019, 6),
		presetHero(owner, 41, 10001004, 10001004, 8),
		presetHero(owner, 42, 11001004, 10001004, 20),
		presetHero(owner, 11, 10001001, 10001001, 4),
		presetHero(owner, 10, 10001001, 10001001, 4),
		presetHero(owner, 20, 10001002, 10001002, 5),
		presetHero(owner, 30, 10001003, 10001003, 5),
	}

	selected, err := SelectPresetDefense(heroes, owner)
	if err != nil {
		t.Fatal(err)
	}
	want := []int64{10, 20, 30, 42, 51}
	if len(selected) != len(want) {
		t.Fatalf("selected %d heroes, want %d", len(selected), len(want))
	}
	for index, hero := range selected {
		if hero.PartnerID != want[index] {
			t.Fatalf("slot %d selected partner %d, want %d", index, hero.PartnerID, want[index])
		}
	}
	if selected[3].TableID != 11001004 {
		t.Fatalf("selected Lightning table %d, want awakened form", selected[3].TableID)
	}
}

func TestSelectPresetDefenseReturnsOwnedSubsetAndRejectsForeignHeroes(t *testing.T) {
	owner := identity.PlayerID(1001)
	selected, err := SelectPresetDefense([]character.Hero{presetHero(owner, 1, 10001003, 10001003, 1)}, owner)
	if err != nil || len(selected) != 1 || selected[0].PartnerID != 1 {
		t.Fatalf("owned subset %+v, err %v", selected, err)
	}
	if selected, err = SelectPresetDefense(nil, owner); err != nil || len(selected) != 0 {
		t.Fatalf("empty subset %+v, err %v", selected, err)
	}
	if _, err = SelectPresetDefense([]character.Hero{presetHero(identity.PlayerID(1002), 1, 10001001, 10001001, 1)}, owner); !errors.Is(err, ErrConflict) {
		t.Fatalf("foreign hero err %v, want ErrConflict", err)
	}
}

func presetHero(owner identity.PlayerID, partnerID, tableID, originTableID, level int64) character.Hero {
	at := time.Date(2026, 11, 7, 12, 0, 0, 0, time.UTC)
	return character.Hero{PlayerID: owner, PartnerID: partnerID, TableID: tableID, OriginTableID: originTableID, Star: 1, Level: level, Color: 1,
		CreationContentRevision: strings.Repeat("a", 64), RawSkills: character.NewHeroRawSkillSeed(), StateVersion: 1, CreatedAt: at, UpdatedAt: at}
}
