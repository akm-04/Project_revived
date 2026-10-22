package combat

import (
	"encoding/json"
	"fmt"
)

// ProducerProfileID names the frozen battle producer registry a schema 2
// snapshot pins (D05: an unsupported enabled producer blocks START; an absent
// feature is declared inactive). A registry change takes a new ID.
const ProducerProfileID = "I8_BATTLE_PRODUCERS_V1"

type ProducerStatus string

const (
	ProducerActive           ProducerStatus = "ACTIVE"
	ProducerDeclaredInactive ProducerStatus = "DECLARED_INACTIVE"
)

// Producer owns the populate params keys it writes into owned actors. Required
// keys are written whenever the producer is active, so their absence means the
// producer was unavailable and START refuses instead of defaulting.
type Producer struct {
	ID       string
	Status   ProducerStatus
	Owner    string
	HeroKeys []string
	PetKeys  []string
	Required []string
}

type ProducerProfile struct {
	ID        string
	Producers []Producer
}

var producerProfiles = map[string]ProducerProfile{ProducerProfileID: {ID: ProducerProfileID, Producers: []Producer{
	{ID: "HERO_CORE", Status: ProducerActive, Owner: "CharacterHero stock projection (Normal: fumo_levels; Super: partner_type)",
		HeroKeys: []string{"partner_id", "table_id", "star", "lev", "exp", "color", "skills", "skill_ids", "equips", "fumos", "fumo_levels", "is_like", "practice_attr", "partner_type"}, Required: []string{"fumos"}},
	{ID: "COMBAT_OWNER", Status: ProducerActive, Owner: "Combat freezer owner identity", HeroKeys: []string{"player_id"}, PetKeys: []string{"player_id"}},
	{ID: "APPEARANCE", Status: ProducerActive, Owner: "CharacterAsset effective appearance at the decision instant (AUDIT-PROFILE-02 timed skins)",
		HeroKeys: []string{"current_skin_id", "illusion_skin_id", "skin_ids", "unlocked_dynamic_card", "dynamic_card_state"}, Required: []string{"skin_ids"}},
	{ID: "LIBRARY_LOCAL", Status: ProducerActive, Owner: "LibraryLocal I7C-2B favor/marriage/feed/collection (D15(a))",
		HeroKeys: []string{"favor_degree", "is_married", "feed_attrs", "collect_quality_stage", "collect_star_stage"}, Required: []string{"favor_degree"}},
	{ID: "DORM_HOUSE", Status: ProducerActive, Owner: "DormHouse I7C-2C", HeroKeys: []string{"house_id", "house_table_id", "house_comfort", "house_equips", "house_expand_lev"}, Required: []string{"house_id"}},
	{ID: "BOOK_SKILL", Status: ProducerActive, Owner: "BookSkill I7C-2D", HeroKeys: []string{"skill_book_info", "book_shelf_lev"}, Required: []string{"skill_book_info"}},
	{ID: "INSCRIPTION", Status: ProducerActive, Owner: "Inscription", HeroKeys: []string{"inscript_items"}, Required: []string{"inscript_items"}},
	{ID: "COURSE", Status: ProducerActive, Owner: "Course I7C-2E", HeroKeys: []string{"courses", "courses_exp", "courses_progress", "courses_quality", "courses_skill"}, Required: []string{"courses"}},
	{ID: "SPIRIT", Status: ProducerActive, Owner: "Spirit I7C-2H", HeroKeys: []string{"spirit_equip", "spirit_item"}, Required: []string{"spirit_equip", "spirit_item"}},
	{ID: "ELEMENT_EQUIPMENT", Status: ProducerActive, Owner: "ElementEquipment", HeroKeys: []string{"element_equips", "element_levels", "element_bak_equips", "element_bak_levels"}, Required: []string{"element_equips"}},
	{ID: "HERO_EVOLUTION", Status: ProducerActive, Owner: "HeroEvolution", HeroKeys: []string{"evo_stage", "evo_attr_points"}, Required: []string{"evo_stage"}},
	{ID: "RAW_AWAKENING", Status: ProducerActive, Owner: "Character raw awakening, birth stage 0 only (PASS727)", HeroKeys: []string{"twice_awake_stage"}, Required: []string{"twice_awake_stage"}},
	{ID: "CONQUER_SCHOOL", Status: ProducerActive, Owner: "ConquerSchool I7C-2J (keys only when positive)", HeroKeys: []string{"conquer_lev", "conquer_loop_id"}},
	{ID: "CHAR_PET", Status: ProducerActive, Owner: "CharacterPet roster and appearance",
		PetKeys: []string{"pet_id", "table_id", "star", "lev", "exp", "color", "skills", "equips", "fumos", "practice_attr", "birthday", "is_born", "is_show", "active_style", "pet_styles"}},
	{ID: "TWICE_AWAKE_POSITIVE", Status: ProducerDeclaredInactive, Owner: "AwakeningMission -> I9 (I7R09); a positive twice_awake_stage refuses START"},
	{ID: "CHAR_RUNE", Status: ProducerDeclaredInactive, Owner: "PASS509 PROFILE1_EXPLICITLY_DEFERRED; no populate key"},
	{ID: "HERO_ROW_BUFFS", Status: ProducerDeclaredInactive, Owner: "no qualified owner; original hero-row buffs content UNKNOWN", HeroKeys: []string{"buffs"}},
	{ID: "HERO_DISPLAY", Status: ProducerDeclaredInactive, Owner: "display-only model fields with no battle reader", HeroKeys: []string{"is_board", "board_card", "board_model_id", "force", "region_arena_times"}},
}}}

// LookupProducerProfile returns a registered profile; pinned IDs stay registered.
func LookupProducerProfile(id string) (ProducerProfile, bool) {
	profile, ok := producerProfiles[id]
	return profile, ok
}

// CurrentProducerProfile is the registry new snapshots pin.
func CurrentProducerProfile() ProducerProfile { return producerProfiles[ProducerProfileID] }

// Keys returns every populate key the profile assigns for kind, active or not.
func (p ProducerProfile) Keys(kind ActorKind) map[string]ProducerStatus {
	keys := map[string]ProducerStatus{}
	for _, producer := range p.Producers {
		for _, key := range producer.KeysFor(kind) {
			keys[key] = producer.Status
		}
	}
	return keys
}

// KeysFor returns the populate keys the producer writes for kind.
func (p Producer) KeysFor(kind ActorKind) []string {
	if kind == PetActor {
		return p.PetKeys
	}
	return p.HeroKeys
}

// CheckOwned refuses owned-actor params that carry a key no producer owns, a
// key of a declared-inactive producer, a positive twice-awake stage, or that
// miss a key an active producer always writes.
func (p ProducerProfile) CheckOwned(kind ActorKind, params json.RawMessage) error {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(params, &fields); err != nil {
		return err
	}
	keys := p.Keys(kind)
	for key := range fields {
		status, known := keys[key]
		if !known {
			return fmt.Errorf("populate key %s has no registered producer", key)
		}
		if status == ProducerDeclaredInactive {
			return fmt.Errorf("populate key %s belongs to a declared-inactive producer", key)
		}
	}
	for _, producer := range p.Producers {
		if producer.Status != ProducerActive || kind == PetActor {
			continue
		}
		for _, key := range producer.Required {
			if _, ok := fields[key]; !ok {
				return fmt.Errorf("producer %s did not write %s", producer.ID, key)
			}
		}
	}
	if stage, ok := fields["twice_awake_stage"]; ok && string(stage) != "0" {
		return fmt.Errorf("twice_awake_stage %s comes from the declared-inactive TWICE_AWAKE_POSITIVE producer", stage)
	}
	return nil
}
