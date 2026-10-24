package character

import "errors"

// EquipmentTemplateID is a source/content template identity. It is deliberately
// not a durable equipment-instance identity: current authoritative CA4 source
// represents ordinary Hero/Pet/Super equipment as owner-qualified slot state
// plus fungible source item/template ids.
type EquipmentTemplateID int64

func (id EquipmentTemplateID) Valid() bool { return id > 0 }

// Family-qualified slot references prevent accidental collapse into a
// universal Equipment aggregate. CA4-1 validates only positivity; each later
// family stage owns its source-qualified slot-count/range invariant.
type HeroEquipmentSlotRef struct{ Slot int64 }
type PetEquipmentSlotRef struct{ Slot int64 }
type SuperEquipmentSlotRef struct{ Slot int64 }

// SuperEquipmentPosition is the immutable CA4-5 fixed six-slot mapping for
// one Super Hero template. Unlike Normal Hero equipment, this mapping is not
// color-qualified.
type SuperEquipmentPosition struct {
	HeroTableID int64
	Slot        int64
	ItemID      EquipmentTemplateID
}

func (p SuperEquipmentPosition) Validate() error {
	if p.HeroTableID <= 0 || p.Slot < 1 || p.Slot > HeroEquipmentSlotCount || !p.ItemID.Valid() {
		return errors.New("character equipment: invalid Super equipment content position")
	}
	return nil
}

// SuperEquipmentEnhancementCap is immutable source policy. Rows 9-10 are
// retained as physical source facts but remain unreachable under the accepted
// effective-client eight-star contract.
type SuperEquipmentEnhancementCap struct {
	Star                     int64
	MaxEnhancement           int64
	EffectiveClientReachable bool
}

func (c SuperEquipmentEnhancementCap) Validate() error {
	if c.Star < 1 || c.Star > 10 || c.MaxEnhancement <= 0 {
		return errors.New("character equipment: invalid Super equipment enhancement cap")
	}
	if c.EffectiveClientReachable != (c.Star <= 8) {
		return errors.New("character equipment: invalid Super equipment cap reachability")
	}
	return nil
}

// SuperEquipmentEnhancementTier is immutable duplicate-item enhancement
// policy. Only tiers whose minimum star is <=8 are effective-client reachable.
type SuperEquipmentEnhancementTier struct {
	Tier                     int64
	MinStar                  int64
	DuplicateCount           int64
	EffectiveClientReachable bool
}

func (t SuperEquipmentEnhancementTier) Validate() error {
	if t.Tier < 1 || t.Tier > 6 || t.MinStar < 1 || t.MinStar > 10 || t.DuplicateCount <= 0 {
		return errors.New("character equipment: invalid Super equipment enhancement tier")
	}
	if t.EffectiveClientReachable != (t.MinStar <= 8) {
		return errors.New("character equipment: invalid Super equipment tier reachability")
	}
	return nil
}

func (r HeroEquipmentSlotRef) Validate() error {
	if r.Slot <= 0 {
		return errors.New("character equipment: invalid Hero slot")
	}
	return nil
}
func (r PetEquipmentSlotRef) Validate() error {
	if r.Slot <= 0 {
		return errors.New("character equipment: invalid Pet slot")
	}
	return nil
}
func (r SuperEquipmentSlotRef) Validate() error {
	if r.Slot <= 0 {
		return errors.New("character equipment: invalid Super slot")
	}
	return nil
}

const (
	HeroEquipmentSlotCount = 6
	PetEquipmentSlotCount  = 3
)

// PetEquipmentClassification is immutable family-qualified source topology.
// EMPTY is an explicit source position, not absence from the content catalog.
type PetEquipmentClassification string

const (
	PetEquipmentEmpty     PetEquipmentClassification = "EMPTY"
	PetEquipmentOrdinary  PetEquipmentClassification = "ORDINARY"
	PetEquipmentAwakening PetEquipmentClassification = "AWAKENING"
)

// PetEquipmentPosition is the exact CA4-4A Pet slot mapping for one
// table-id/color/slot tuple. ItemID=0 is valid only for EMPTY positions.
type PetEquipmentPosition struct {
	PetTableID     int64
	Color          int64
	Slot           int64
	ItemID         EquipmentTemplateID
	Classification PetEquipmentClassification
}

// PetEquipmentSlots is the CA4-4A family-owned durable collection state.
// Each position is a stock-visible collected bit; raw Pet Fumo remains CA4-4B.
type PetEquipmentSlots [PetEquipmentSlotCount]int64

func (s PetEquipmentSlots) Validate() error {
	for _, v := range s {
		if v < 0 || v > 1 {
			return errors.New("character equipment: Pet equipment slot must be a collected bit")
		}
	}
	return nil
}

func (s PetEquipmentSlots) Value(slot int64) (int64, error) {
	if slot < 1 || slot > PetEquipmentSlotCount {
		return 0, errors.New("character equipment: Pet equipment slot out of range")
	}
	return s[slot-1], nil
}

// PetFumoSlots is the CharacterPet-owned durable raw Fumo vector recovered
// from the stock private Pet payload. It is independent from equipment collected
// bits. No Pet Fumo level/cap semantics are inferred here.
type PetFumoSlots [PetEquipmentSlotCount]int64

func (s PetFumoSlots) Validate() error {
	for _, v := range s {
		if v < 0 {
			return errors.New("character equipment: negative Pet Fumo slot")
		}
	}
	return nil
}

func (s PetFumoSlots) Value(slot int64) (int64, error) {
	if slot < 1 || slot > PetEquipmentSlotCount {
		return 0, errors.New("character equipment: Pet Fumo slot out of range")
	}
	return s[slot-1], nil
}

func (p PetEquipmentPosition) Validate() error {
	if p.PetTableID <= 0 || p.Color < 1 || p.Color > 16 || p.Slot < 1 || p.Slot > PetEquipmentSlotCount || p.ItemID < 0 {
		return errors.New("character equipment: invalid Pet equipment content position")
	}
	switch p.Classification {
	case PetEquipmentEmpty:
		if p.ItemID != 0 {
			return errors.New("character equipment: nonzero Pet equipment classified empty")
		}
	case PetEquipmentOrdinary, PetEquipmentAwakening:
		if !p.ItemID.Valid() {
			return errors.New("character equipment: mapped Pet equipment missing item")
		}
	default:
		return errors.New("character equipment: invalid Pet equipment classification")
	}
	return nil
}

// EquipmentCompatibilityExpThreshold exposes the stock-compatible Hero
// partnerExp threshold curve to equipment planners without creating a
// CharacterPet -> CharacterHero owner dependency.
type EquipmentCompatibilityExpThreshold struct {
	Level    int64
	TotalExp int64
}

func ValidateEquipmentCompatibilityExpThresholds(rows []EquipmentCompatibilityExpThreshold, maxLevel int64) error {
	if maxLevel <= 0 || int64(len(rows)) != maxLevel {
		return errors.New("character equipment: invalid compatibility EXP threshold count")
	}
	var last int64 = -1
	for i, row := range rows {
		if row.Level != int64(i+1) || row.TotalExp < 0 || row.TotalExp < last {
			return errors.New("character equipment: invalid compatibility EXP thresholds")
		}
		last = row.TotalExp
	}
	return nil
}

// HeroEquipmentSlots is durable family-owned Hero equipment state. CA4-2
// Normal-Hero mechanics use values 0/1; the shared durable representation is
// intentionally only nonnegative because CA4-5 Super equipment encodes
// enhancement_level+1 in the same six positions.
type HeroEquipmentSlots [HeroEquipmentSlotCount]int64

func (s HeroEquipmentSlots) Validate() error {
	for _, v := range s {
		if v < 0 {
			return errors.New("character equipment: negative Hero equipment slot")
		}
	}
	return nil
}

func (s HeroEquipmentSlots) ValidateNormal() error {
	if err := s.Validate(); err != nil {
		return err
	}
	for _, v := range s {
		if v > 1 {
			return errors.New("character equipment: Normal Hero equipment slot exceeds collected bit")
		}
	}
	return nil
}

func (s HeroEquipmentSlots) Value(slot int64) (int64, error) {
	if slot < 1 || slot > HeroEquipmentSlotCount {
		return 0, errors.New("character equipment: Hero equipment slot out of range")
	}
	return s[slot-1], nil
}

// HeroFumoSlots is the Hero-owned durable raw Fumo progress vector. Fumo
// levels are derived from immutable content and are never independent durable
// gameplay authority.
type HeroFumoSlots [HeroEquipmentSlotCount]int64

func (s HeroFumoSlots) Validate() error {
	for _, v := range s {
		if v < 0 {
			return errors.New("character equipment: negative Hero Fumo slot")
		}
	}
	return nil
}
func (s HeroFumoSlots) Value(slot int64) (int64, error) {
	if slot < 1 || slot > HeroEquipmentSlotCount {
		return 0, errors.New("character equipment: Hero Fumo slot out of range")
	}
	return s[slot-1], nil
}

// HeroFumoTarget is the immutable content policy for one Fumo-capable Hero
// equipment template. Decimal stat deltas remain exact strings; CA4-3A does
// not materialize final battle stats.
type HeroFumoTarget struct {
	ItemID              EquipmentTemplateID
	ThresholdIncrements []int64
	TotalCap            int64
	ManaPerFumo         int64
	StageDeltaByAttr    []map[int64]string
}

func (t HeroFumoTarget) Validate() error {
	if !t.ItemID.Valid() || len(t.ThresholdIncrements) == 0 || len(t.StageDeltaByAttr) != len(t.ThresholdIncrements) || t.TotalCap <= 0 || t.ManaPerFumo < 0 {
		return errors.New("character equipment: invalid Hero Fumo target")
	}
	var total int64
	for _, v := range t.ThresholdIncrements {
		if v <= 0 {
			return errors.New("character equipment: invalid Hero Fumo threshold")
		}
		total += v
	}
	if total != t.TotalCap {
		return errors.New("character equipment: Hero Fumo cap mismatch")
	}
	return nil
}

type HeroFumoMaterial struct {
	ItemID   EquipmentTemplateID
	ItemType int64
	Moneng   int64
}

func (m HeroFumoMaterial) Validate() error {
	if !m.ItemID.Valid() || m.Moneng <= 0 {
		return errors.New("character equipment: invalid Hero Fumo material")
	}
	switch m.ItemType {
	case 1, 2, 4, 5, 6:
		return nil
	default:
		return errors.New("character equipment: Hero Fumo material type not eligible")
	}
}

// HeroEquipmentPosition is immutable Normal-Hero family reachability content.
// ItemID=0 is a meaningful source position and is never ordinary-eligible.
type HeroEquipmentPosition struct {
	HeroTableID      int64
	Color            int64
	Slot             int64
	ItemID           EquipmentTemplateID
	OrdinaryEligible bool
}

func (p HeroEquipmentPosition) Validate() error {
	if p.HeroTableID <= 0 || p.Color < 1 || p.Color > 16 || p.Slot < 1 || p.Slot > HeroEquipmentSlotCount || p.ItemID < 0 {
		return errors.New("character equipment: invalid Hero equipment content position")
	}
	if p.ItemID == 0 && p.OrdinaryEligible {
		return errors.New("character equipment: zero Hero equipment position cannot be ordinary")
	}
	return nil
}

// EquipmentPrimitive is the cross-family immutable item fact compiled in
// CA4-1. Family reachability/mapping and Fumo/enhancement policy remain later
// CA4-stage content.
type EquipmentPrimitive struct {
	ItemID         EquipmentTemplateID
	SourceItemType int64
	RequiredLevel  int64
	ComposeMana    int64
}

func (p EquipmentPrimitive) Validate() error {
	if !p.ItemID.Valid() || p.RequiredLevel < 0 || p.ComposeMana < 0 {
		return errors.New("character equipment: invalid immutable primitive")
	}
	return nil
}

// EquipmentRecipeEdge preserves source ordinal. Duplicate component ids at
// different ordinals are legal and must not be deduplicated by content compile.
type EquipmentRecipeEdge struct {
	ParentItemID    EquipmentTemplateID
	Ordinal         int64
	ComponentItemID EquipmentTemplateID
	ComponentCount  int64
}

func (e EquipmentRecipeEdge) Validate() error {
	if !e.ParentItemID.Valid() || e.Ordinal <= 0 || !e.ComponentItemID.Valid() || e.ComponentCount <= 0 {
		return errors.New("character equipment: invalid recipe edge")
	}
	return nil
}

// SpiritRef is a borrowed foreign-owner reference only. CA4 explicitly does
// not own Spirit/Horcrux creation, enhancement, locking, campaign or lifecycle.
type SpiritRef struct{ SpiritID int64 }

func (r SpiritRef) Validate() error {
	if r.SpiritID <= 0 {
		return errors.New("character equipment: invalid borrowed Spirit reference")
	}
	return nil
}

// HeroPromotionRestorationEligibility is a source-derived CA4-3B fact for an
// ordinary, reachable, Fumo-capable Normal-Hero equipment template. It does
// not encode the compatibility rounding/decomposition algorithm.
type HeroPromotionRestorationEligibility struct {
	ItemID        EquipmentTemplateID
	SourceQuality int64
}

func (e HeroPromotionRestorationEligibility) Validate() error {
	if !e.ItemID.Valid() || e.SourceQuality < 2 || e.SourceQuality > 6 {
		return errors.New("character equipment: invalid Hero promotion restoration eligibility")
	}
	return nil
}

// HeroPromotionRestorationFraction preserves the exact source fraction for a
// refundable equipment quality. Numerator/Denominator are never converted to
// floating point by content or application code.
type PromotionRestorationFraction struct {
	Quality     int64 `json:"quality"`
	Numerator   int64 `json:"numerator"`
	Denominator int64 `json:"denominator"`
}

func (f PromotionRestorationFraction) Validate() error {
	if f.Quality < 2 || f.Quality > 6 || f.Numerator <= 0 || f.Denominator <= 0 || f.Numerator > f.Denominator {
		return errors.New("character equipment: invalid Hero promotion restoration fraction")
	}
	return nil
}

// HeroPromotionRestorationDenomination preserves source material order and its
// Fumo-equivalent denomination. Stack/overflow policy remains I5/content
// resource authority and is deliberately not duplicated here.
type PromotionRestorationDenomination struct {
	ItemID  EquipmentTemplateID `json:"item_id"`
	Ordinal int64               `json:"ordinal"`
	Value   int64               `json:"value"`
}

func (d PromotionRestorationDenomination) Validate() error {
	if !d.ItemID.Valid() || d.Ordinal < 0 || d.Value <= 0 {
		return errors.New("character equipment: invalid Hero promotion restoration denomination")
	}
	return nil
}

// HeroPromotionRestorationPolicy is immutable source content. The separate
// named compatibility policy owns aggregate-floor/greedy decomposition.
type PromotionRestorationPolicy struct {
	Fractions     []PromotionRestorationFraction
	Denominations []PromotionRestorationDenomination
}

func (p PromotionRestorationPolicy) Validate() error {
	if len(p.Fractions) != 5 || len(p.Denominations) != 3 {
		return errors.New("character equipment: incomplete Hero promotion restoration policy")
	}
	for i, f := range p.Fractions {
		if err := f.Validate(); err != nil || f.Quality != int64(i+2) {
			return errors.New("character equipment: invalid Hero promotion restoration fraction order")
		}
	}
	for i, d := range p.Denominations {
		if err := d.Validate(); err != nil || d.Ordinal != int64(i) {
			return errors.New("character equipment: invalid Hero promotion restoration denomination order")
		}
		if i > 0 && p.Denominations[i-1].Value <= d.Value {
			return errors.New("character equipment: Hero promotion restoration denominations not descending")
		}
	}
	return nil
}

// Hero promotion names remain source-compatible aliases over the family-neutral
// global restoration fractions/denominations. Hero eligibility stays separate.
type HeroPromotionRestorationFraction = PromotionRestorationFraction
type HeroPromotionRestorationDenomination = PromotionRestorationDenomination
type HeroPromotionRestorationPolicy = PromotionRestorationPolicy

// PetPromotionRestorationEligibility is the exact CA4-4B ordinary Pet
// equipment identity and source quality. Quality 1 is deliberately representable
// so promotion can fail closed on legacy nonzero raw Fumo rather than inventing
// a source refund coefficient.
type PetPromotionRestorationEligibility struct {
	ItemID        EquipmentTemplateID
	SourceQuality int64
}

func (e PetPromotionRestorationEligibility) Validate() error {
	if !e.ItemID.Valid() || e.SourceQuality < 1 || e.SourceQuality > 6 {
		return errors.New("character equipment: invalid Pet promotion restoration eligibility")
	}
	return nil
}
