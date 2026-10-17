package builtin

import (
	"encoding/json"
	"testing"
)

func TestLoadGeneratedCatalog(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := c.RevisionID(), "2a44f1c205ab6d8e9da0c42c9ab994644c3ec41a689fb13414b2899afbb27559"; got != want {
		t.Fatalf("revision id = %s, want %s", got, want)
	}
	if got, want := len(c.PlayerProgression.Rows), 100; got != want {
		t.Fatalf("player rows = %d, want %d", got, want)
	}
	if got, want := len(c.PetProgression.Templates), 54; got != want {
		t.Fatalf("pet progression templates = %d, want %d", got, want)
	}
	if got, want := len(c.PetProgression.SkillSlots), 270; got != want {
		t.Fatalf("pet progression skill slots = %d, want %d", got, want)
	}
	if got, want := c.Manifest.Diagnostics["item_rows"], 5838; got != want {
		t.Fatalf("item rows diagnostic = %d, want %d", got, want)
	}
	if got, want := c.Manifest.Diagnostics["positive_stack_items"], 5540; got != want {
		t.Fatalf("positive stack diagnostic = %d, want %d", got, want)
	}
	if got, want := c.Manifest.Diagnostics["specialized_type24_items"], 378; got != want {
		t.Fatalf("type24 diagnostic = %d, want %d", got, want)
	}
}

func TestGeneratedManifestIsCanonicalJSON(t *testing.T) {
	raw, err := GeneratedFile("manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	var v any
	if err := json.Unmarshal(raw, &v); err != nil {
		t.Fatal(err)
	}
	canonical, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	if string(raw) != string(canonical)+"\n" {
		t.Fatal("manifest.json is not canonical compact sorted-key JSON with one trailing newline")
	}
}

func TestCapabilityBoundary(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	mana, ok := c.ResourceByDefinitionKey("scalar_currency:mana")
	if !ok || mana.SettlementActivation != "ENABLED_R4" {
		t.Fatalf("Mana activation = %#v, %v", mana, ok)
	}
	energy, ok := c.ResourceByDefinitionKey("temporal:energy")
	if !ok || energy.SettlementActivation != "ENABLED_R5" || energy.CapRule != "PLAYER_LEVEL_ENERGY" {
		t.Fatalf("Energy definition = %#v, %v", energy, ok)
	}
	invitation, ok := c.ResourceByDefinitionKey("temporal:invitation")
	if !ok || invitation.SettlementActivation != "FAIL_CLOSED" || invitation.CapRule != "UNRESOLVED" {
		t.Fatalf("Invitation definition = %#v, %v", invitation, ok)
	}
}

func TestSpecializedAndUnknownItemsFailClosed(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	var type24, type0 int
	for _, row := range c.Resources.Resources {
		if row.Class == "SPECIALIZED_DOMAIN" {
			type24++
			if row.SettlementActivation != "FAIL_CLOSED" || row.SpecializedOwner == "" {
				t.Fatalf("specialized row not fail-closed: %#v", row)
			}
		}
		if row.Reason == "ITEM_TYPE_ZERO_UNQUALIFIED" {
			type0++
			if row.SettlementActivation != "FAIL_CLOSED" {
				t.Fatalf("type0 row not fail-closed: %#v", row)
			}
		}
	}
	if type24 != 378 || type0 != 3 {
		t.Fatalf("specialized/type0 counts = %d/%d, want 378/3", type24, type0)
	}
}

func TestPetCoreCatalogLineageAndCapability(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(c.PetCore.Templates) != 54 {
		t.Fatalf("pet templates=%d", len(c.PetCore.Templates))
	}
	origins := map[int64]int{}
	for _, p := range c.PetCore.Templates {
		origins[p.OriginTableID]++
		if p.IsAwakened && (p.TableID == p.OriginTableID || p.AwakenTableID != 0) {
			t.Fatalf("bad awakened lineage: %+v", p)
		}
		if !p.IsAwakened && (p.TableID != p.OriginTableID || p.AwakenTableID <= 0) {
			t.Fatalf("bad base lineage: %+v", p)
		}
	}
	if len(origins) != 27 {
		t.Fatalf("origin families=%d", len(origins))
	}
	for origin, n := range origins {
		if n != 2 {
			t.Fatalf("origin %d members=%d", origin, n)
		}
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "PET_CORE_CA3" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("PET_CORE_CA3 missing")
	}
}

func TestEquipmentPrimitivesCA4SourceTopology(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(c.EquipmentPrimitives.Items); got != 1176 {
		t.Fatalf("equipment items=%d", got)
	}
	if got := len(c.EquipmentPrimitives.RootItemIDs); got != 604 {
		t.Fatalf("equipment roots=%d", got)
	}
	if got := len(c.EquipmentPrimitives.RecipeEdges); got != 1934 {
		t.Fatalf("equipment edges=%d", got)
	}
	parents := map[int64]bool{}
	repeatedParents := map[int64]bool{}
	seenByParent := map[int64]map[int64]bool{}
	lastParent, lastOrdinal := int64(0), int64(0)
	for _, e := range c.EquipmentPrimitives.RecipeEdges {
		parents[e.ParentItemID] = true
		if e.ParentItemID < lastParent || (e.ParentItemID == lastParent && e.Ordinal <= lastOrdinal) {
			t.Fatal("recipe edges not source-ordinal sorted")
		}
		if e.ParentItemID != lastParent {
			lastParent, lastOrdinal = e.ParentItemID, 0
		}
		if e.Ordinal != lastOrdinal+1 {
			t.Fatalf("non-dense source ordinal parent=%d ordinal=%d last=%d", e.ParentItemID, e.Ordinal, lastOrdinal)
		}
		lastOrdinal = e.Ordinal
		m := seenByParent[e.ParentItemID]
		if m == nil {
			m = map[int64]bool{}
			seenByParent[e.ParentItemID] = m
		}
		if m[e.ComponentItemID] {
			repeatedParents[e.ParentItemID] = true
		}
		m[e.ComponentItemID] = true
	}
	if len(parents) != 797 || len(repeatedParents) != 29 {
		t.Fatalf("recipe parents/repeated=%d/%d", len(parents), len(repeatedParents))
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "EQUIPMENT_PRIMITIVES_CA4" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("EQUIPMENT_PRIMITIVES_CA4 missing")
	}
}

func TestHeroEquipmentCA42SourceTopology(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(c.HeroEquipment.Positions); got != 53280 {
		t.Fatalf("hero equipment positions=%d", got)
	}
	zero, ordinary, special := 0, 0, 0
	ordinaryIDs, specialIDs := map[int64]bool{}, map[int64]bool{}
	lastHero, lastColor, lastSlot := int64(0), int64(0), int64(0)
	for _, p := range c.HeroEquipment.Positions {
		if p.HeroTableID < lastHero || (p.HeroTableID == lastHero && (p.Color < lastColor || (p.Color == lastColor && p.Slot <= lastSlot))) {
			t.Fatalf("non-canonical Hero equipment order at %+v", p)
		}
		if p.HeroTableID != lastHero {
			lastHero, lastColor, lastSlot = p.HeroTableID, 0, 0
		}
		if p.Color != lastColor {
			lastColor, lastSlot = p.Color, 0
		}
		if p.Slot != lastSlot+1 {
			t.Fatalf("non-dense Hero equipment slot at %+v", p)
		}
		lastSlot = p.Slot
		switch {
		case p.ItemID == 0:
			zero++
			if p.OrdinaryEligible {
				t.Fatal("zero slot marked ordinary")
			}
		case p.OrdinaryEligible:
			ordinary++
			ordinaryIDs[p.ItemID] = true
		default:
			special++
			specialIDs[p.ItemID] = true
		}
	}
	if zero != 1130 || ordinary != 50504 || special != 1646 || len(ordinaryIDs) != 214 || len(specialIDs) != 164 {
		t.Fatalf("hero equipment topology zero/ordinary/special/unique=%d/%d/%d/%d/%d", zero, ordinary, special, len(ordinaryIDs), len(specialIDs))
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "HERO_EQUIPMENT_CA4_2" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("HERO_EQUIPMENT_CA4_2 missing")
	}
}

func TestHeroFumoCA43ASourceTopology(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(c.HeroFumo.Targets); got != 359 {
		t.Fatalf("fumo targets=%d", got)
	}
	if got := len(c.HeroFumo.Materials); got != 516 {
		t.Fatalf("fumo materials=%d", got)
	}
	stages := map[int]int{}
	for _, target := range c.HeroFumo.Targets {
		stages[len(target.ThresholdIncrements)]++
		if target.ItemID <= 0 || target.ManaPerFumo < 0 || len(target.ThresholdIncrements) == 0 || len(target.StageDeltaByAttr) != len(target.ThresholdIncrements) {
			t.Fatalf("invalid fumo target: %+v", target)
		}
	}
	if stages[1]+stages[3]+stages[5] != 359 || len(stages) != 3 {
		t.Fatalf("fumo stage distribution=%v", stages)
	}
	for _, material := range c.HeroFumo.Materials {
		if material.ItemID <= 0 || material.Moneng <= 0 {
			t.Fatalf("invalid fumo material: %+v", material)
		}
		switch material.ItemType {
		case 1, 2, 4, 5, 6:
		default:
			t.Fatalf("invalid material type: %+v", material)
		}
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "HERO_FUMO_CA4_3A" {
			found = true
		}
	}
	if !found {
		t.Fatal("HERO_FUMO_CA4_3A missing")
	}
}

func TestHeroPromotionRestorationCA43BSourceFacts(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	cat := c.HeroPromotionRestoration
	if len(cat.EligibleEquipment) != 195 || len(cat.QualityFractions) != 5 || len(cat.Denominations) != 3 {
		t.Fatalf("restoration counts equipment=%d fractions=%d denominations=%d", len(cat.EligibleEquipment), len(cat.QualityFractions), len(cat.Denominations))
	}
	qualities := map[int64]int{}
	lastID := int64(0)
	for _, row := range cat.EligibleEquipment {
		if row.EquipmentItemID <= lastID || row.SourceQuality < 2 || row.SourceQuality > 6 {
			t.Fatalf("invalid restoration equipment row: %+v", row)
		}
		lastID = row.EquipmentItemID
		qualities[row.SourceQuality]++
	}
	wantQuality := map[int64]int{2: 35, 3: 35, 4: 65, 5: 42, 6: 18}
	for q, want := range wantQuality {
		if qualities[q] != want {
			t.Fatalf("quality %d count=%d want=%d", q, qualities[q], want)
		}
	}
	wantFractions := [][3]int64{{2, 1, 1}, {3, 3, 8}, {4, 9, 50}, {5, 9, 100}, {6, 9, 200}}
	for i, want := range wantFractions {
		got := cat.QualityFractions[i]
		if got.Quality != want[0] || got.Numerator != want[1] || got.Denominator != want[2] {
			t.Fatalf("fraction[%d]=%+v want=%v", i, got, want)
		}
	}
	wantDenoms := [][3]int64{{50001007, 0, 200}, {50001006, 1, 60}, {50001003, 2, 10}}
	for i, want := range wantDenoms {
		got := cat.Denominations[i]
		if got.ItemID != want[0] || got.Ordinal != want[1] || got.Value != want[2] {
			t.Fatalf("denomination[%d]=%+v want=%v", i, got, want)
		}
	}
	found := false
	for _, capability := range c.Manifest.EnabledCapabilities {
		if capability == "HERO_PROMOTION_RESTORATION_CA4_3B" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("HERO_PROMOTION_RESTORATION_CA4_3B missing")
	}
}

func TestPetEquipmentCA44ASourceTopology(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(c.PetEquipment.Positions); got != 2592 {
		t.Fatalf("pet equipment positions=%d", got)
	}
	zero, ordinary, awakening := 0, 0, 0
	ordinaryIDs, awakeningIDs := map[int64]bool{}, map[int64]bool{}
	perPet := map[int64]int{}
	byPet := map[int64]map[[2]int64]PetEquipmentPosition{}
	lastPet, lastColor, lastSlot := int64(0), int64(0), int64(0)
	for _, p := range c.PetEquipment.Positions {
		if p.PetTableID < lastPet || (p.PetTableID == lastPet && (p.Color < lastColor || (p.Color == lastColor && p.Slot <= lastSlot))) {
			t.Fatalf("non-canonical Pet equipment order at %+v", p)
		}
		if p.PetTableID != lastPet {
			lastPet, lastColor, lastSlot = p.PetTableID, 0, 0
		}
		if p.Color != lastColor {
			lastColor, lastSlot = p.Color, 0
		}
		if p.Slot != lastSlot+1 {
			t.Fatalf("non-dense Pet equipment slot at %+v", p)
		}
		lastSlot = p.Slot
		perPet[p.PetTableID]++
		if byPet[p.PetTableID] == nil {
			byPet[p.PetTableID] = map[[2]int64]PetEquipmentPosition{}
		}
		byPet[p.PetTableID][[2]int64{p.Color, p.Slot}] = p
		switch p.Classification {
		case "EMPTY":
			zero++
			if p.ItemID != 0 {
				t.Fatalf("empty Pet equipment position has item: %+v", p)
			}
		case "ORDINARY":
			ordinary++
			ordinaryIDs[p.ItemID] = true
			if p.ItemID == 0 {
				t.Fatalf("ordinary Pet equipment position has no item: %+v", p)
			}
		case "AWAKENING":
			awakening++
			awakeningIDs[p.ItemID] = true
			if p.Slot != 1 || p.Color < 12 || p.Color > 16 || p.ItemID == 0 {
				t.Fatalf("bad Awakening Pet equipment position: %+v", p)
			}
		default:
			t.Fatalf("unknown Pet equipment classification: %+v", p)
		}
	}
	if len(perPet) != 54 {
		t.Fatalf("Pet equipment forms=%d", len(perPet))
	}
	for id, n := range perPet {
		if n != 48 {
			t.Fatalf("Pet %d equipment positions=%d", id, n)
		}
	}
	if zero != 70 || ordinary != 2322 || awakening != 200 || len(ordinaryIDs) != 73 || len(awakeningIDs) != 20 {
		t.Fatalf("Pet equipment topology zero/ordinary/awakening/unique=%d/%d/%d/%d/%d", zero, ordinary, awakening, len(ordinaryIDs), len(awakeningIDs))
	}
	petByID := map[int64]PetTemplate{}
	for _, pet := range c.PetCore.Templates {
		petByID[pet.TableID] = pet
	}
	for _, pet := range c.PetCore.Templates {
		if pet.IsAwakened {
			continue
		}
		awake := petByID[pet.AwakenTableID]
		basePositions, awakePositions := byPet[pet.TableID], byPet[awake.TableID]
		for color := int64(1); color <= 16; color++ {
			for slot := int64(1); slot <= 3; slot++ {
				b, a := basePositions[[2]int64{color, slot}], awakePositions[[2]int64{color, slot}]
				if b.ItemID != a.ItemID || b.Classification != a.Classification {
					t.Fatalf("Pet base/awakened topology mismatch base=%d awake=%d color=%d slot=%d: %+v %+v", pet.TableID, awake.TableID, color, slot, b, a)
				}
			}
		}
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "PET_EQUIPMENT_CA4_4A" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("PET_EQUIPMENT_CA4_4A missing")
	}
}

func TestPetPromotionRestorationCA44BSourceEligibility(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	rows := c.PetPromotionRestoration.EligibleEquipment
	if got := len(rows); got != 73 {
		t.Fatalf("Pet promotion restoration eligible equipment=%d", got)
	}
	qualityCounts := map[int64]int{}
	q1 := []int64{}
	seen := map[int64]bool{}
	for _, row := range rows {
		if row.EquipmentItemID <= 0 || row.SourceQuality < 1 || row.SourceQuality > 6 {
			t.Fatalf("invalid Pet promotion restoration row: %+v", row)
		}
		if seen[row.EquipmentItemID] {
			t.Fatalf("duplicate Pet promotion restoration item %d", row.EquipmentItemID)
		}
		seen[row.EquipmentItemID] = true
		qualityCounts[row.SourceQuality]++
		if row.SourceQuality == 1 {
			q1 = append(q1, row.EquipmentItemID)
		}
	}
	wantCounts := map[int64]int{1: 3, 2: 13, 3: 11, 4: 24, 5: 15, 6: 7}
	for quality, want := range wantCounts {
		if got := qualityCounts[quality]; got != want {
			t.Fatalf("Pet promotion restoration quality %d count=%d want=%d", quality, got, want)
		}
	}
	wantQ1 := []int64{80001001, 80001006, 80001010}
	if len(q1) != len(wantQ1) {
		t.Fatalf("Pet promotion restoration q1=%v want=%v", q1, wantQ1)
	}
	for i := range wantQ1 {
		if q1[i] != wantQ1[i] {
			t.Fatalf("Pet promotion restoration q1=%v want=%v", q1, wantQ1)
		}
	}
	for _, p := range c.PetEquipment.Positions {
		if p.Classification == "AWAKENING" && seen[p.ItemID] {
			t.Fatalf("Awakening Pet equipment %d entered restoration eligibility", p.ItemID)
		}
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "PET_PROMOTION_RESTORATION_CA4_4B" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("PET_PROMOTION_RESTORATION_CA4_4B missing")
	}
}

func TestSuperEquipmentCA45Catalog(t *testing.T) {
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if got := len(c.SuperEquipment.Positions); got != 84 {
		t.Fatalf("positions=%d", got)
	}
	if got := len(c.SuperEquipment.EnhancementCaps); got != 10 {
		t.Fatalf("caps=%d", got)
	}
	if got := len(c.SuperEquipment.EnhancementTiers); got != 6 {
		t.Fatalf("tiers=%d", got)
	}
	seenHeroes := map[int64]int{}
	seenItems := map[int64]bool{}
	primitives := map[int64]EquipmentPrimitive{}
	for _, primitive := range c.EquipmentPrimitives.Items {
		primitives[primitive.ItemID] = primitive
	}
	for _, p := range c.SuperEquipment.Positions {
		seenHeroes[p.HeroTableID]++
		seenItems[p.ItemID] = true
		primitive, ok := primitives[p.ItemID]
		if !ok || primitive.SourceItemType != 1 || primitive.RequiredLevel != 89 {
			t.Fatalf("invalid Super primitive mapping=%+v primitive=%+v ok=%v", p, primitive, ok)
		}
	}
	if len(seenHeroes) != 14 || len(seenItems) != 12 {
		t.Fatalf("heroes/items=%d/%d", len(seenHeroes), len(seenItems))
	}
	for id, n := range seenHeroes {
		if id < 11001 || id > 11014 || n != 6 {
			t.Fatalf("hero=%d slots=%d", id, n)
		}
	}
	wantCaps := []int64{10, 10, 10, 10, 10, 20, 30, 40, 50, 60}
	for i, row := range c.SuperEquipment.EnhancementCaps {
		if row.Star != int64(i+1) || row.MaxEnhancement != wantCaps[i] || row.EffectiveClientReachable != (row.Star <= 8) {
			t.Fatalf("cap[%d]=%+v", i, row)
		}
	}
	wantMinStar := []int64{1, 6, 7, 8, 9, 10}
	wantCopies := []int64{1, 1, 1, 1, 2, 2}
	for i, row := range c.SuperEquipment.EnhancementTiers {
		if row.Tier != int64(i+1) || row.MinStar != wantMinStar[i] || row.DuplicateCount != wantCopies[i] || row.EffectiveClientReachable != (row.MinStar <= 8) {
			t.Fatalf("tier[%d]=%+v", i, row)
		}
	}
	found := false
	for _, cap := range c.Manifest.EnabledCapabilities {
		if cap == "SUPER_EQUIPMENT_CA4_5" {
			found = true
		}
	}
	if !found {
		t.Fatal("SUPER_EQUIPMENT_CA4_5 missing")
	}
}
