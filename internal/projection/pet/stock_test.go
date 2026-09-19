package pet

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func stockFixture() character.Pet {
	now := time.Unix(100, 0).UTC()
	return character.Pet{
		PlayerID: identity.PlayerID(7), PetID: 3, TableID: 10030001, OriginTableID: 10030001,
		Star: 1, Level: 1, Exp: 0, Color: 1, Equipment: character.PetEquipmentSlots{1, 0, 1}, Fumo: character.PetFumoSlots{7, 80, 900}, Skills: character.DefaultPetSkillLevels(), Birthday: 1700000000, IsShow: false,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            1, CreatedAt: now, UpdatedAt: now,
	}
}

func TestStockPrivateUsesCA3NeutralCompatibilityDefaults(t *testing.T) {
	m, err := StockPrivate(stockFixture(), true)
	if err != nil {
		t.Fatal(err)
	}
	if m["player_id"] != int64(7) || m["pet_id"] != int64(3) || m["is_show"] != int64(0) || m["is_born"] != int64(0) {
		t.Fatalf("identity/lifecycle projection=%#v", m)
	}
	if len(m["skills"].([]any)) != 5 || len(m["equips"].([]any)) != 3 || len(m["fumos"].([]any)) != 3 || len(m["practice_attr"].([]any)) != 3 {
		t.Fatalf("neutral compatibility shape=%#v", m)
	}
	if got := m["equips"].([]any); got[0] != int64(1) || got[1] != int64(0) || got[2] != int64(1) {
		t.Fatalf("durable Pet equipment projection=%#v", got)
	}
	if got := m["fumos"].([]any); got[0] != int64(7) || got[1] != int64(80) || got[2] != int64(900) {
		t.Fatalf("durable Pet raw Fumo projection=%#v", got)
	}
	for _, k := range []string{"active_style", "pet_styles", "origin_table_id", "creation_content_revision"} {
		if _, ok := m[k]; ok {
			t.Fatalf("private/internal field %q leaked: %#v", k, m)
		}
	}
}

func TestStockRosterPreservesPetIDOrderAndShape(t *testing.T) {
	p1 := stockFixture()
	p2 := stockFixture()
	p2.PetID = 4
	p2.TableID = 10040001
	p2.OriginTableID = 10040001
	body, err := StockRoster([]character.Pet{p1, p2})
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["pets"].([]any)
	if !ok || len(rows) != 2 {
		t.Fatalf("pets shape=%T %#v", body["pets"], body["pets"])
	}
	if rows[0].(map[string]any)["pet_id"] != int64(3) || rows[1].(map[string]any)["pet_id"] != int64(4) {
		t.Fatalf("pet order=%#v", rows)
	}
}
