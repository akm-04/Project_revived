package hero

import (
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"testing"
	"time"
)

func fixture(kind character.HeroKind) character.Hero {
	now := time.Unix(1, 0).UTC()
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: identity.PlayerID(1), PartnerID: 7, TableID: 11001, OriginTableID: 11001, Kind: kind, Star: 2, Level: 3, Exp: 4, Color: 1, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}
func TestStockHeroNeutralShapesAndSpiritOmission(t *testing.T) {
	m, err := StockHero(fixture(character.SuperHero))
	if err != nil {
		t.Fatal(err)
	}
	if m["partner_type"] != int64(2) {
		t.Fatalf("partner_type=%v", m["partner_type"])
	}
	if m["star"] != int64(2) || m["lev"] != int64(3) || m["exp"] != int64(4) {
		t.Fatalf("persisted progression projection star=%v lev=%v exp=%v", m["star"], m["lev"], m["exp"])
	}
	if _, ok := m["spirit_item"]; ok {
		t.Fatal("spirit_item must be omitted")
	}
	for _, k := range []string{"equips", "fumos", "skill_ids"} {
		if got := len(m[k].([]any)); got != 6 {
			t.Fatalf("%s len=%d", k, got)
		}
	}
	if got := len(m["practice_attr"].([]any)); got != 3 {
		t.Fatal(got)
	}
	for i, v := range m["skills"].([]any) {
		if v != int64(1) {
			t.Fatalf("skills[%d]=%v, want neutral 1", i, v)
		}
	}
}

func TestStockRosterUsesPartnerIDMap(t *testing.T) {
	body, err := StockRoster(0, []character.Hero{fixture(character.NormalHero)})
	if err != nil {
		t.Fatal(err)
	}
	heroes, ok := body["heros"].(map[string]any)
	if !ok {
		t.Fatalf("heros shape %T", body["heros"])
	}
	if _, ok := heroes["7"]; !ok {
		t.Fatalf("partner-id key missing: %#v", heroes)
	}
}

func TestStockHeroProjectsDurableEquipmentValues(t *testing.T) {
	h := fixture(character.SuperHero)
	h.Equipment = character.HeroEquipmentSlots{0, 1, 2, 3, 0, 7}
	m, err := StockHero(h)
	if err != nil {
		t.Fatal(err)
	}
	got := m["equips"].([]any)
	want := []any{int64(0), int64(1), int64(2), int64(3), int64(0), int64(7)}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("equips[%d]=%v want=%v", i, got[i], want[i])
		}
	}
}

func TestStockHeroProjectsDurableFumoValues(t *testing.T) {
	h := fixture(character.NormalHero)
	h.Fumo = character.HeroFumoSlots{0, 20, 160, 1120, 1680, 3210}
	m, err := StockHero(h)
	if err != nil {
		t.Fatal(err)
	}
	got := m["fumos"].([]any)
	want := []any{int64(0), int64(20), int64(160), int64(1120), int64(1680), int64(3210)}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("fumos[%d]=%v want=%v", i, got[i], want[i])
		}
	}
	if _, ok := m["fumo_levels"]; ok {
		t.Fatal("general reload must not invent durable fumo_levels authority")
	}
}

func TestStockRosterViewProjectsSixDerivedFumoLevelsForNormalHeroOnly(t *testing.T) {
	normal := fixture(character.NormalHero)
	normal.PartnerID = 7
	super := fixture(character.SuperHero)
	super.PartnerID = 8
	body, err := StockRosterView(0, []RosterHeroView{{Hero: normal, FumoLevels: character.HeroFumoSlots{0, 1, 2, 3, 4, 5}, Appearance: AppearanceView{OwnerStateVersion: normal.StateVersion, CurrentSkinID: normal.CurrentSkinID, IllusionSkinID: normal.IllusionSkinID}}, {Hero: super, Appearance: AppearanceView{OwnerStateVersion: super.StateVersion, CurrentSkinID: super.CurrentSkinID, IllusionSkinID: super.IllusionSkinID}}})
	if err != nil {
		t.Fatal(err)
	}
	rows := body["heros"].(map[string]any)
	n := rows["7"].(map[string]any)
	got, ok := n["fumo_levels"].([]any)
	if !ok || len(got) != 6 {
		t.Fatalf("fumo_levels=%#v", n["fumo_levels"])
	}
	for i, want := range []any{int64(0), int64(1), int64(2), int64(3), int64(4), int64(5)} {
		if got[i] != want {
			t.Fatalf("level[%d]=%v want=%v", i, got[i], want)
		}
	}
	if _, ok := rows["8"].(map[string]any)["fumo_levels"]; ok {
		t.Fatal("SuperHero must not project Normal-Hero fumo_levels")
	}
}

func TestStockRosterViewProjectsEmptyLIVEAsStockSafeEmptyStrings(t *testing.T) {
	h := fixture(character.NormalHero)
	body, err := StockRosterView(0, []RosterHeroView{{Hero: h, FumoLevels: character.HeroFumoSlots{}, Appearance: AppearanceView{OwnerStateVersion: h.StateVersion, CurrentSkinID: h.CurrentSkinID, IllusionSkinID: h.IllusionSkinID}}})
	if err != nil {
		t.Fatal(err)
	}
	wire := body["heros"].(map[string]any)["7"].(map[string]any)
	if wire["unlocked_dynamic_card"] != "" || wire["dynamic_card_state"] != "" {
		t.Fatalf("empty LIVE wire=%#v/%#v", wire["unlocked_dynamic_card"], wire["dynamic_card_state"])
	}
}

func TestStockRosterViewProjectsQualifiedAppearanceWire(t *testing.T) {
	h := fixture(character.NormalHero)
	h.CurrentSkinID = 40001001
	h.IllusionSkinID = -1
	expires := time.Unix(500, 0).UTC()
	appearance := AppearanceView{
		OwnerStateVersion: h.StateVersion,
		CurrentSkinID:     h.CurrentSkinID,
		IllusionSkinID:    h.IllusionSkinID,
		Skins:             []QualifiedSkinView{{ModelID: 40001001}, {ModelID: 40001002, ExpiresAt: &expires}},
		LIVE:              []QualifiedLIVEView{{ModelID: 40001003, IsShow: true}, {ModelID: 40001004, IsShow: false}},
	}
	body, err := StockRosterView(0, []RosterHeroView{{Hero: h, FumoLevels: character.HeroFumoSlots{}, Appearance: appearance}})
	if err != nil {
		t.Fatal(err)
	}
	wire := body["heros"].(map[string]any)["7"].(map[string]any)
	if wire["current_skin_id"] != int64(40001001) || wire["illusion_skin_id"] != int64(-1) {
		t.Fatalf("selectors=%#v/%#v", wire["current_skin_id"], wire["illusion_skin_id"])
	}
	skins := wire["skin_ids"].(map[string]any)
	if skins["40001001"] != int64(-1) || skins["40001002"] != int64(500) {
		t.Fatalf("skin_ids=%#v", skins)
	}
	if wire["unlocked_dynamic_card"] != "40001003|40001004" || wire["dynamic_card_state"] != "1|0" {
		t.Fatalf("LIVE wire=%#v/%#v", wire["unlocked_dynamic_card"], wire["dynamic_card_state"])
	}
}
